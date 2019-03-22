//
//  GoelocationModule.m
//  RCTBaiduMap
//
//  Created by lovebing on 2016/10/28.
//  Copyright © 2016年 lovebing.org. All rights reserved.
//

#import "GeolocationModule.h"


@implementation GeolocationModule {
    BMKPointAnnotation* _annotation;
}

@synthesize bridge = _bridge;

static BMKGeoCodeSearch *geoCodeSearch;

RCT_EXPORT_MODULE(BaiduGeolocationModule);

RCT_EXPORT_METHOD(getBaiduCoorFromGPSCoor:(double)lat lng:(double)lng
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSLog(@"getBaiduCoorFromGPSCoor");
    CLLocationCoordinate2D baiduCoor = [self getBaiduCoor:lat lng:lng];

    NSDictionary* coor = @{
                           @"latitude": @(baiduCoor.latitude),
                           @"longitude": @(baiduCoor.longitude)
                           };

    resolve(coor);
}

RCT_EXPORT_METHOD(geocode:(NSString *)city addr:(NSString *)addr) {

    [self getGeocodesearch].delegate = self;

    BMKGeoCodeSearchOption *geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc]init];

    geoCodeSearchOption.city= city;
    geoCodeSearchOption.address = addr;

    BOOL flag = [[self getGeocodesearch] geoCode:geoCodeSearchOption];

    if(flag) {
        NSLog(@"geo检索发送成功");
    } else{
        NSLog(@"geo检索发送失败");
    }
}

RCT_EXPORT_METHOD(reverseGeoCode:(double)lat lng:(double)lng) {

    [self getGeocodesearch].delegate = self;
    CLLocationCoordinate2D baiduCoor = CLLocationCoordinate2DMake(lat, lng);

    CLLocationCoordinate2D pt = (CLLocationCoordinate2D){baiduCoor.latitude, baiduCoor.longitude};

    BMKReverseGeoCodeSearchOption *reverseGeoCodeSearchOption = [[BMKReverseGeoCodeSearchOption alloc]init];
    reverseGeoCodeSearchOption.location = pt;

    BOOL flag = [[self getGeocodesearch] reverseGeoCode:reverseGeoCodeSearchOption];

    if(flag) {
        NSLog(@"逆向地理编码发送成功");
    }
    //[reverseGeoCodeSearchOption release];
}

RCT_EXPORT_METHOD(reverseGeoCodeGPS:(double)lat lng:(double)lng) {

    [self getGeocodesearch].delegate = self;
    CLLocationCoordinate2D baiduCoor = [self getBaiduCoor:lat lng:lng];

    CLLocationCoordinate2D pt = (CLLocationCoordinate2D){baiduCoor.latitude, baiduCoor.longitude};

    BMKReverseGeoCodeSearchOption *reverseGeoCodeSearchOption = [[BMKReverseGeoCodeSearchOption alloc]init];
    reverseGeoCodeSearchOption.location = pt;

    BOOL flag = [[self getGeocodesearch] reverseGeoCode:reverseGeoCodeSearchOption];

    if(flag) {
        NSLog(@"逆向地理编码发送成功");
    }
    //[reverseGeoCodeSearchOption release];
}

-(BMKGeoCodeSearch *)getGeocodesearch{
    if(geoCodeSearch == nil) {
        geoCodeSearch = [[BMKGeoCodeSearch alloc]init];
    }
    return geoCodeSearch;
}


RCT_EXPORT_METHOD(searchPOI:(NSString *) city name:(NSString *) name){
    NSLog(@"searchPOI：%@: %@",city, name);
    if (poiSearch == nil) {
        poiSearch = [[BMKPoiSearch alloc] init];
    }

    poiSearch.delegate = self;
    //初始化请求参数类BMKCitySearchOption的实例
    BMKPOICitySearchOption *cityOption = [[BMKPOICitySearchOption alloc] init];
    //检索关键字，必选。举例：小吃
    cityOption.keyword = name;
    //区域名称(市或区的名字，如北京市，海淀区)，最长不超过25个字符，必选
    cityOption.city = city;
    //检索分类，可选，与keyword字段组合进行检索，多个分类以","分隔。举例：美食,烧烤,酒店
//    cityOption.tags = @[@"美食",@"烧烤"];
    //区域数据返回限制，可选，为YES时，仅返回city对应区域内数据
    cityOption.isCityLimit = YES;
    //POI检索结果详细程度
    cityOption.scope = BMK_POI_SCOPE_BASIC_INFORMATION;
    //检索过滤条件，scope字段为BMK_POI_SCOPE_DETAIL_INFORMATION时，filter字段才有效
//    cityOption.filter = filter;
    //分页页码，默认为0，0代表第一页，1代表第二页，以此类推
    cityOption.pageIndex = 0;
    //单次召回POI数量，默认为10条记录，最大返回20条
    cityOption.pageSize = 10;

    BOOL flag = [poiSearch poiSearchInCity:cityOption];
    if(flag) {
        NSLog(@"POI城市内检索成功");
    } else {
        NSLog(@"POI城市内检索失败");
    }
}

/**
 *返回POI搜索结果
 *@param searcher 搜索对象
 *@param poiResult 搜索结果列表
 *@param errorCode 错误号，@see BMKSearchErrorCode
 */
- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPOISearchResult*)poiResult errorCode:(BMKSearchErrorCode)errorCode{
    //BMKSearchErrorCode错误码，BMK_SEARCH_NO_ERROR：检索结果正常返回
    NSLog(@"searchPOI：onGetPoiResult");
    NSMutableDictionary *body = [self getEmptyBody];
    if (poiResult != nil && errorCode == BMK_SEARCH_NO_ERROR) {
        //在此处理正常结果
        body[@"errcode"] = @"0";
        NSLog(@"POI检索结果返回成功：%@",poiResult.poiInfoList);
        NSMutableDictionary *attr = [self getEmptyBody];
        NSMutableArray * items = [NSMutableArray arrayWithCapacity:poiResult.poiInfoList.count];
        for (BMKPoiInfo* item in poiResult.poiInfoList) {
            attr[@"name"] = item.name;
            attr[@"address"] = item.address;
            attr[@"city"] = item.city;
            attr[@"latitude"] =  [NSNumber numberWithInt: item.pt.latitude];
            attr[@"longitude"] = [NSNumber numberWithInt: item.pt.longitude];
            [items addObject:attr];
        }
        body[@"poiList"] = items;
    }
    else if (errorCode == BMK_SEARCH_AMBIGUOUS_KEYWORD) {
        NSLog(@"POI检索词有歧义");
        body[@"errcode"] = [NSString stringWithFormat:@"%d", errorCode];
        body[@"errmsg"] = [self getSearchErrorInfo:errorCode];
    } else {
        NSLog(@"POI其他检索结果错误码相关处理");
        body[@"errcode"] = [NSString stringWithFormat:@"%d", errorCode];
        body[@"errmsg"] = [self getSearchErrorInfo:errorCode];
    }
    [self sendEvent:@"onSearchPOIResult" body:body];
}


- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeSearchResult *)result errorCode:(BMKSearchErrorCode)error {
    NSMutableDictionary *body = [self getEmptyBody];

    if (error == BMK_SEARCH_NO_ERROR) {
        NSString *latitude = [NSString stringWithFormat:@"%f", result.location.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%f", result.location.longitude];
        body[@"latitude"] = latitude;
        body[@"longitude"] = longitude;
    }
    else {
        body[@"errcode"] = [NSString stringWithFormat:@"%d", error];
        body[@"errmsg"] = [self getSearchErrorInfo:error];
    }
    [self sendEvent:@"onGetGeoCodeResult" body:body];

}
- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeSearchResult *)result errorCode:(BMKSearchErrorCode)error {

    NSMutableDictionary *body = [self getEmptyBody];

    if (error == BMK_SEARCH_NO_ERROR) {
        // 使用离线地图之前，需要先初始化百度地图
        [[BMKMapView alloc] initWithFrame:CGRectZero];
        // 离线地图api或去citycode
        BMKOfflineMap *offlineMap = [[BMKOfflineMap alloc] init];
        NSArray *cityCodeArr = [offlineMap searchCity:result.addressDetail.city];
        if (cityCodeArr.count) {
            BMKOLSearchRecord *searchRecord = cityCodeArr.firstObject;
            body[@"cityCode"] = @(searchRecord.cityID).stringValue;
            searchRecord = nil;

        }
        cityCodeArr = nil;
        offlineMap = nil;

        body[@"latitude"] = [NSString stringWithFormat:@"%f", result.location.latitude];
        body[@"longitude"] = [NSString stringWithFormat:@"%f", result.location.longitude];
        body[@"address"] = result.address;
        body[@"province"] = result.addressDetail.province;
        body[@"city"] = result.addressDetail.city;
        body[@"district"] = result.addressDetail.district;
        body[@"streetName"] = result.addressDetail.streetName;
        body[@"streetNumber"] = result.addressDetail.streetNumber;
    }
    else {
        body[@"errcode"] = [NSString stringWithFormat:@"%d", error];
        body[@"errmsg"] = [self getSearchErrorInfo:error];
    }
    [self sendEvent:@"onGetReverseGeoCodeResult" body:body];

    geoCodeSearch.delegate = nil;
}
-(NSString *)getSearchErrorInfo:(BMKSearchErrorCode)error {
    NSString *errormsg = @"未知";
    switch (error) {
        case BMK_SEARCH_AMBIGUOUS_KEYWORD:
            errormsg = @"检索词有岐义";
            break;
        case BMK_SEARCH_AMBIGUOUS_ROURE_ADDR:
            errormsg = @"检索地址有岐义";
            break;
        case BMK_SEARCH_NOT_SUPPORT_BUS:
            errormsg = @"该城市不支持公交搜索";
            break;
        case BMK_SEARCH_NOT_SUPPORT_BUS_2CITY:
            errormsg = @"不支持跨城市公交";
            break;
        case BMK_SEARCH_RESULT_NOT_FOUND:
            errormsg = @"没有找到检索结果";
            break;
        case BMK_SEARCH_ST_EN_TOO_NEAR:
            errormsg = @"起终点太近";
            break;
        case BMK_SEARCH_KEY_ERROR:
            errormsg = @"key错误";
            break;
        case BMK_SEARCH_NETWOKR_ERROR:
            errormsg = @"网络连接错误";
            break;
        case BMK_SEARCH_NETWOKR_TIMEOUT:
            errormsg = @"网络连接超时";
            break;
        case BMK_SEARCH_PERMISSION_UNFINISHED:
            errormsg = @"还未完成鉴权，请在鉴权通过后重试";
            break;
        case BMK_SEARCH_INDOOR_ID_ERROR:
            errormsg = @"室内图ID错误";
            break;
        case BMK_SEARCH_FLOOR_ERROR:
            errormsg = @"室内图检索楼层错误";
            break;
        default:
            break;
    }
    return errormsg;
}

-(CLLocationCoordinate2D)getBaiduCoor:(double)lat lng:(double)lng {
    CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(lat, lng);
    BMKLocationCoordinateType srctype = BMKLocationCoordinateTypeWGS84;
    BMKLocationCoordinateType destype = BMKLocationCoordinateTypeBMK09MC;
    CLLocationCoordinate2D baiduCoor = [BMKLocationManager BMKLocationCoordinateConvert:coor SrcType:srctype DesType:destype];
    return baiduCoor;
}

-(NSMutableDictionary *)getEmptyBody {
    NSMutableDictionary *body = @{}.mutableCopy;
    return body;
}

-(void)sendEvent:(NSString *)name body:(NSMutableDictionary *)body {
    [self.bridge.eventDispatcher sendDeviceEventWithName:name body:body];
}

@end
