import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      body: FutureBuilder<String> (
        future: checkPermission(),
        builder: (BuildContext context, AsyncSnapshot snapshot){

          // 로딩상태 처리
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(
                child: CircularProgressIndicator()
            );
          }

          // snapshot에서 checkpermission 상태를 받아올 수 있음
          // print(snapshot.data); 로 확인 가능
          // print(snapshot.connectionState); - done으로 됨

          if(snapshot.data == '위치 권한이 허가되었습니다.'){
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
                if(snapshot.hasData){
                  final start = snapshot.data!; // 내위치
                  final end = companyLatLng; // 회사 위치
                  
                  final distance = Geolocator.distanceBetween(
                      start.latitude,
                      start.longitude, 
                      end.latitude,
                      end.longitude);
                  if(distance < okDistance){
                    isWithinRange = true;
                  }

                }

                return Column(
                  children: [
                    _CustomGoogleMap(
                        initialPosition: initialPosition,
                      circle: isWithinRange?
                      withinDistanceCircle :
                      notwithinDistanceCircle,
                      marker: marker,

                    ),
                    _ChoolCheckButton(),
                  ],
                );
              }
            );
          }
          return Center(
            child: Text(snapshot.data),
          );
        },
      ),
    );
  }
}


// 권한요청
Future<String> checkPermission() async {
  final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

  if(!isLocationEnabled){
    return '위치 서비스를 활성화 해주세요.';
  }

  LocationPermission checkedPermission = await Geolocator.checkPermission();

  if(checkedPermission == LocationPermission.denied){
    // 권한요청
    checkedPermission = await Geolocator.requestPermission();

    if(checkedPermission == LocationPermission.denied){
      return "위치 권한을 허가해주세요.";
    }
    if(checkedPermission == LocationPermission.deniedForever){
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
  );
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;
  final Circle circle;
  final Marker marker;

  const _CustomGoogleMap({
    required this.initialPosition,
    required this.circle,
    required this.marker,
    Key? key}) : super(key: key);

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
      ),
    );
  }
}

class _ChoolCheckButton extends StatelessWidget {
  const _ChoolCheckButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text('출근'),
    );
  }
}
