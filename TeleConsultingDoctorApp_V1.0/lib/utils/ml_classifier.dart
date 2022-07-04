//ignore_for_file: non_constant_identifier_names

import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:doctor_app/utils/preprocessing_stuff.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

Future<List<double>> MLClassifier(String audioPath) async {
  print(audioPath);
  Uint8List data = File(audioPath).readAsBytesSync();
  //0-3
  String riff = String.fromCharCodes(data.sublist(0, 4));
  print("Invalid File Format");
  //4-7
  int fileSize =
      ((data[7] << 24) | (data[6] << 16) | (data[5] << 8) | data[4]) + 8;
  print(fileSize);
  //8-15
  String Wavefmt = String.fromCharCodes(data.sublist(8, 16));
  print("Corrupted File");
  //16-19
  int formatSize =
      (data[19] << 24) | (data[18] << 16) | (data[17] << 8) | data[16];
  //20-21
  int type = data[21] << 8 | data[20];
  //22-23
  int Nchannels = data[23] << 8 | data[22];
  //24-27
  int SampleRate = data[27] << 24 | data[26] << 16 | data[25] << 8 | data[24];
  //34-35
  int BitsPerSample = data[35] << 8 | data[34];
  //36-39
  String dat = String.fromCharCodes(data.sublist(36, 40));
  //40-43
  int dataSize = data[43] << 24 | data[42] << 16 | data[41] << 8 | data[40];
  print(dataSize);
  if (riff != "RIFF" ||
      Wavefmt != "WAVEfmt " ||
      formatSize != 16 ||
      fileSize <= 0 ||
      type != 1 ||
      Nchannels != 1 ||
      SampleRate != 16000 ||
      BitsPerSample != 16 ||
      dat != "data" ||
      dataSize <= 0) {
    print("Not A Valid File");
    return [0.0, 0.0, 0.0];
  }
  int numSamples = (dataSize >> ((BitsPerSample >> 3) - 1));
  print(numSamples);
  int maxSample = 0, minSample = 0;
  ByteBuffer buffer = data.sublist(44).buffer;
  List<int> samples = [];
  ByteData bytedata = new ByteData.view(buffer);
  for (int i = 0; i < numSamples; i++) {
    int sample = bytedata.getInt16((i << 1), Endian.little);
    samples.add(sample);
    minSample = min(minSample, sample);
    maxSample = max(maxSample, sample);
  }
  print(minSample);
  print(maxSample);
  double scaling = max(1 / maxSample, -1 / minSample);

  List<double> normX = [];
  for (int i = 0; i < numSamples; i++) {
    normX.add(samples[i] * scaling);
  }
  final interpreter = await Interpreter.fromAsset('bandpass_model.tflite');

  // if output tensor shape [1,2] and type is float32
  List<double> X = lowpassFilter2K(normX);
  X = downsample(X, 8);
  X = bandpassFilter40(X);
  var input = X.sublist(10000, 20000).reshape([1, 10000, 1]);
  var output = List.filled(3, 0).reshape([1, 3]);

  // inference
  interpreter.run(input, output);

  print(output);

  return output[0];
}
