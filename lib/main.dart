import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late File _file;

  @override
  void initState() {
    super.initState();
    _filePathFirst();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _filePathFirst() async{
    final directory = await getApplicationDocumentsDirectory();
    _file =  File('${directory.path}/counter.txt');
    try {
      //存在文件 就正常读取一次
      String contents = await _file.readAsString();
    } catch (e) {
      //不存在文件 就新建
      _file.writeAsString("",mode: FileMode.write);
    }

  }

  getRequest(String add) async {
    ///创建Dio对象
    Dio dio = Dio();
    ///请求地址 获取用户列表
    // String url = "https://www.baidu.com";
    String url = "https://api.etherscan.io/api?module=account&action=balance&address=$add&tag=latest&apikey=EVZVNXX3PX623TYXS7WSPAXUFK47ZVC8AE";
    ///发起get请求
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.findProxy = (url) {
        return "PROXY 127.0.0.1:7890";
        ///设置代理 电脑ip地址
        return "PROXY 127.0.0.1:7890";
      };
      ///忽略证书
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    };
    Response response = await dio.get(url);
    ///响应数据
    Map data = response.data;
    return data["result"].toString() != "null" ?  data["result"].toString() : "失败";
  }

  int _count = 0;
  final List _re = [];
  
  void _pick() async{
    var rng = Random.secure();
    BigInt privKey = generateNewPrivateKey(rng);
    String mprivate = privKey.toRadixString(16);
    Credentials credentials = EthPrivateKey.fromHex(mprivate);
    EthereumAddress address = await credentials.extractAddress();
    String mAddress = address.hexEip55;
    String mResult = await getRequest(mAddress);
    _re.insert(0,'${DateTime.now()}｜===｜$mAddress｜===｜余额:$mResult');
    if(_re.length > 50){
      _re.removeRange(50, _re.length);
    }
    await _file.writeAsString('${DateTime.now()}私钥:$mprivate｜===｜$mAddress｜===｜余额:$mResult\n',mode: FileMode.append);
    setState((){});
  }

  //计时器
  Timer? _timer;

  void _startTimer() { //累加1
    const oneSec = Duration(seconds: 5);//间隔1秒
    _timer = Timer.periodic(oneSec, (Timer timer){
      if(!mounted){
        return;
      }
      _count ++ ;
      setState(() {
        _pick();
      });
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: [
                IconButton(
                  onPressed: () async{
                    print("开始");
                    _startTimer();
                  },
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  onPressed: () async{
                    print("停止");
                    if(_timer != null){
                      _timer!.cancel();
                    }
                  },
                  icon: const Icon(Icons.ac_unit_rounded),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text("第$_count次"),
                  ),
                )
              ],
            ),
            const Divider(height: 2,color: Colors.black,),
            Expanded(
              child: ListView.builder(
                itemCount: _re.length,
                itemBuilder: (context,index){
                  return Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(5),
                    child: Text(_re[index],style: TextStyle(fontSize: 8,color: _re[index].toString().endsWith("余额:0") ? Colors.black : Colors.red),),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
