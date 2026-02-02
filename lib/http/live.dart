import 'package:pilipala/models/live/follow.dart';

import '../models/live/item.dart';
import '../models/live/room_info.dart';
import '../models/live/room_info_h5.dart';
import 'api.dart';
import 'init.dart';

class LiveHttp {
  // live.dart
  static Future liveIndexList() async {
    var res = await Request().get(Api.liveListNew, data: {
      'platform': 'web',
      'web_location': '444.7',
    });

    if (res.data['code'] == 0) {
      var roomList = res.data['data']['room_list'] as List;

      // 1. 处理“我的关注”
      var followModule = roomList.firstWhere(
        (m) => m['module_info']['title'] == "我的关注",
        orElse: () => null,
      );
      List<LiveItemModel> follows = [];
      if (followModule != null) {
        follows = (followModule['list'] as List).map<LiveItemModel>((e) {
          // 【关键】手动补齐映射，因为这个接口返回的是 roomid
          return LiveItemModel.fromJson({
            ...e,
            'roomid': e['roomid'], // 确保对应模型里的 json['roomid']
            'cover': e['pic'], // 确保对应模型里的 json['cover']
          });
        }).toList();
      }

      // 2. 处理“推荐”
      var recommendModule = roomList.firstWhere(
        (m) => m['module_info']['title'].contains("推荐"),
        orElse: () => roomList.last,
      );
      List<LiveItemModel> recommends =
          (recommendModule['list'] as List).map<LiveItemModel>((e) {
        // 【关键】推荐接口返回的是 room_id，要转成模型认的 roomid
        return LiveItemModel.fromJson(e);
      }).toList();

      return {'status': true, 'follows': follows, 'recommends': recommends};
    }
    return {'status': false, 'msg': res.data['message']};
  }

  static Future liveList(
      {int? vmid, int? pn, int? ps, String? orderType}) async {
    var res = await Request().get(Api.liveList,
        data: {'page': pn, 'page_size': 30, 'platform': 'web'});
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data']['list']
            .map<LiveItemModel>((e) => LiveItemModel.fromJson(e))
            .toList()
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future liveRoomInfo({roomId, qn}) async {
    var res = await Request().get(Api.liveRoomInfo, data: {
      'room_id': roomId,
      'protocol': '0, 1',
      'format': '0, 1, 2',
      'codec': '0, 1',
      'qn': qn,
      'platform': 'web',
      'ptype': 8,
      'dolby': 5,
      'panorama': 1,
    });
    if (res.data['code'] == 0) {
      return {'status': true, 'data': RoomInfoModel.fromJson(res.data['data'])};
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  static Future liveRoomInfoH5({roomId, qn}) async {
    var res = await Request().get(Api.liveRoomInfoH5, data: {
      'room_id': roomId,
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': RoomInfoH5Model.fromJson(res.data['data'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 获取弹幕信息
  static Future liveDanmakuInfo({roomId}) async {
    var res = await Request().get(Api.getDanmuInfo, data: {
      'id': roomId,
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data'],
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 发送弹幕
  static Future sendDanmaku({roomId, msg}) async {
    var res = await Request().post(
      Api.sendLiveMsg,
      data: {
        'bubble': 0,
        'msg': msg,
        'color': 16777215, // 颜色
        'mode': 1, // 模式
        'room_type': 0,
        'jumpfrom': 71001, // 直播间来源
        'reply_mid': 0,
        'reply_attr': 0,
        'replay_dmid': '',
        'statistics': {"appId": 100, "platform": 5},
        'fontsize': 25, // 字体大小
        'rnd': DateTime.now().millisecondsSinceEpoch ~/ 1000, // 时间戳
        'roomid': roomId,
        'csrf': await Request.getCsrf(),
        'csrf_token': await Request.getCsrf(),
      },
    );
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': res.data['data'],
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 我的关注 正在直播
  static Future liveFollowing({int? pn, int? ps}) async {
    var res = await Request().get(Api.getFollowingLive, data: {
      'page': pn,
      'page_size': ps,
      'platform': 'web',
      'ignoreRecord': 1,
      'hit_ab': true,
    });
    if (res.data['code'] == 0) {
      return {
        'status': true,
        'data': LiveFollowingModel.fromJson(res.data['data'])
      };
    } else {
      return {
        'status': false,
        'data': [],
        'msg': res.data['message'],
      };
    }
  }

  // 直播历史记录
  static Future liveRoomEntry({required int roomId}) async {
    await Request().post(
      Api.liveRoomEntry,
      data: {
        'room_id': roomId,
        'platform': 'pc',
        'csrf_token': await Request.getCsrf(),
        'csrf': await Request.getCsrf(),
        'visit_id': '',
      },
    );
  }
}
