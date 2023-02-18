import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool choolCheckDone = false;
  GoogleMapController? mapController;

  // latitude - 위도 , logitude - 경도
  static final LatLng companyLatLng = LatLng(37.5233273, 126.921252);

  // zoom 정보도 줘야
  static final CameraPosition initialPosition = CameraPosition(
    target: companyLatLng,
    zoom: 15,
  );

  static final double okDistance = 100; // 100미터
  static final Circle withinDistanceCircle = Circle(
    circleId: CircleId('withinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.blue.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.blue,
    strokeWidth: 1,
  );

  static final Circle notwithinDistanceCircle = Circle(
    circleId: CircleId('notwithinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.red.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.red,
    strokeWidth: 1,
  );

  static final Circle checkDoneCircle = Circle(
    circleId: CircleId('checkDoneCircle'),
    center: companyLatLng,
    fillColor: Colors.green.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.green,
    strokeWidth: 1,
  );

  static final Marker marker = Marker(
    markerId: MarkerId('marker'),
    position: companyLatLng,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      // FutureBuilder에서 future 부분은 Future로 된 메소드로 불러와 그 값에 맞게 빌더를 다시그려주는
      body: FutureBuilder<String>(
        future: checkPermission(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          // 로딩상태 처리
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // snapshot에서 checkpermission 상태를 받아올 수 있음
          // print(snapshot.data); 로 확인 가능
          // print(snapshot.connectionState); - done으로 됨

          if (snapshot.data == '위치 권한이 허가되었습니다.') {
            // StreamBuilder 사용
            // FutureBuilder
            return StreamBuilder<Position>(
                stream: Geolocator.getPositionStream(),
                // 포지션 바뀔 때 마다 불린다 - snapshot이 바뀌기에
                // builder가 다시 호출되므로 불리는 것
                builder: (context, snapshot) {
                  // 위치에 따라
                  bool isWithinRange = false;

                  // 데이터가 있다면
                  if (snapshot.hasData) {
                    final start = snapshot.data!; // 내위치
                    final end = companyLatLng; // 회사 위치

                    final distance = Geolocator.distanceBetween(start.latitude,
                        start.longitude, end.latitude, end.longitude);
                    if (distance < okDistance) {
                      // 내 위치와 회사위치간 거리가 원 안이면 isWithinRange가 true
                      isWithinRange = true;
                    }
                    // 참고 *
                    // FutureBuilder은 일회성 요청에 - 사진 등등
                    // StreamBuilder은 다회성 요청에 - 위치 조회 등등
                  }

                  return Column(
                    children: [
                      _CustomGoogleMap(
                        initialPosition: initialPosition,
                        // choolCheckDone이 초기에 false로 지정되어 있는데
                        // 만약 출근한 상태면 초록색 원, 아니면
                        // isWithinRange를 판별해 true면 파란색, false면 빨간색 원
                        circle: choolCheckDone
                            ? checkDoneCircle
                            : isWithinRange
                                ? withinDistanceCircle
                                : notwithinDistanceCircle,
                        marker: marker,
                        onMapCreated: onMapCreated,
                      ),
                      _ChoolCheckButton(
                        isWithinRange: isWithinRange,
                        choolCheckDone: choolCheckDone,
                        onPressed: onChoolCheckPressed,
                      ),
                    ],
                  );
                });
          }
          return Center(
            child: Text(snapshot.data),
          );
        },
      ),
    );
  }

  onMapCreated(GoogleMapController controller){
    mapController = controller;
  }


  onChoolCheckPressed() async {
    // result는 pop한 결과로 던져주는 값이 true이냐 false냐를 담고 있다,
    // 즉 출근하면 result는 true, 취소버튼을 누르면 false
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('출근하기'),
          content: Text('출근을 하시겠습니까?'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text('출근하기')),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('취소')),
          ],
        );
      },
    );
    if (result) {
      setState(() {
        choolCheckDone = true;
      });
    }
  }

// 권한요청
Future<String> checkPermission() async {
  final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

  if (!isLocationEnabled) {
    return '위치 서비스를 활성화 해주세요.';
  }

  LocationPermission checkedPermission = await Geolocator.checkPermission();

  if (checkedPermission == LocationPermission.denied) {
    // 권한요청
    checkedPermission = await Geolocator.requestPermission();

    if (checkedPermission == LocationPermission.denied) {
      return "위치 권한을 허가해주세요.";
    }
    if (checkedPermission == LocationPermission.deniedForever) {
      return "앱의 위치 권한을 세팅에서 허가해야합니다. 허가해주세요.";
    }
  }

  return '위치 권한이 허가되었습니다.';
}

AppBar renderAppBar() {
  return AppBar(
    title: Text(
      '오늘도 출근',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
    ),
    backgroundColor: Colors.white,
    // 내 위치로 이동
    actions: [
      IconButton(onPressed: () async {
        if(mapController == null){
          return;
        }
        final location = await Geolocator.getCurrentPosition();

        mapController!.animateCamera(CameraUpdate.newLatLng(
          LatLng(
              location.latitude,
              location.longitude,
          )
        ));
      },
        color: Colors.blue,
          icon: Icon(
            Icons.my_location,)
        ,),
    ],
  );
}
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;
  final Circle circle;
  final Marker marker;
  final MapCreatedCallback onMapCreated;

  const _CustomGoogleMap(
      {required this.initialPosition,
      required this.circle,
      required this.marker,
        required this.onMapCreated,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initialPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        // 세트로 넣어줘야 - ID 값이 들어간 리스트 형을 세트로 던져주면 됨
        circles: Set.from([circle]),
        markers: Set.from([marker]),
        onMapCreated: onMapCreated,
      ),
    );
  }
}

class _ChoolCheckButton extends StatelessWidget {
  final bool isWithinRange;
  final VoidCallback onPressed;
  final bool choolCheckDone;

  const _ChoolCheckButton(
      {required this.isWithinRange,
      required this.onPressed,
      required this.choolCheckDone,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timelapse,
            size: 50.0,
            color: choolCheckDone
                ? Colors.green
                : isWithinRange
                    ? Colors.blue
                    : Colors.red,
          ),
          const SizedBox(
            height: 20.0,
          ),
          if (!choolCheckDone && isWithinRange)
            TextButton(
              onPressed: onPressed,
              child: Text('출근하기'),
            ),
        ],
      ),
    );
  }
}
