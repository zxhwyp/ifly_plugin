package com.example.iflyplugin;

import android.content.Context;
import android.os.Bundle;
import androidx.annotation.NonNull;
import com.iflytek.cloud.InitListener;
import com.iflytek.cloud.RecognizerListener;
import com.iflytek.cloud.RecognizerResult;
import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechError;
import com.iflytek.cloud.SpeechRecognizer;
import com.iflytek.cloud.SpeechUtility;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedHashMap;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static com.iflytek.cloud.VerifierResult.TAG;

/** IflypluginPlugin */
public class IflypluginPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private SpeechRecognizer recognizer;

  // 用HashMap存储听写结果
  private HashMap<String, String> mIatResults = new LinkedHashMap<String, String>();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "iflyplugin");
    channel.setMethodCallHandler(this);
    initIfly(flutterPluginBinding.getApplicationContext());
  }

  private void initIfly(Context context) {
    SpeechUtility.createUtility(context, SpeechConstant.APPID +"=5f3dca21");

    recognizer = SpeechRecognizer.createRecognizer(context, mInitListener);
    recognizer.setParameter(SpeechConstant.AUDIO_SOURCE, "-1");
    recognizer.setParameter(SpeechConstant.ENGINE_TYPE, SpeechConstant.TYPE_CLOUD);
    recognizer.setParameter( SpeechConstant.RESULT_TYPE, "json" );
    //设置语音输入语言，zh_cn为简体中文
    recognizer.setParameter(SpeechConstant.LANGUAGE, "zh_cn");
    recognizer.setParameter(SpeechConstant.SAMPLE_RATE,"16000");
    recognizer.setParameter(SpeechConstant.ASR_PTT, "1");
    recognizer.setParameter(SpeechConstant.DOMAIN, "iat");
  }

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "iflyplugin");
    channel.setMethodCallHandler(new IflypluginPlugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("recognizer")) {
      String path = (String)call.arguments;
      recognizer(path);
      result.success(0);
    } else {
      result.notImplemented();
    }
  }


  private void recognizer(String path) {
    recognizer.startListening(mRecognizerListener);
    FileInputStream fis = null;
    final byte[] buffer = new byte[64*1024];
    try {
      fis = new FileInputStream(new File(path));
      if (0 == fis.available()) {
        recognizer.cancel();
      } else {
        int lenRead = buffer.length;
        lenRead = fis.read( buffer );
        recognizer.writeAudio( buffer, 0, lenRead );
        recognizer.stopListening();
      }

    } catch (Exception e) {
      e.printStackTrace();
    } finally {
      try {
        if (null != fis) {
          fis.close();
          fis = null;
        }
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  /**
   * 识别监听器。
   */
  private RecognizerListener mRecognizerListener = new RecognizerListener() {

    @Override
    public void onVolumeChanged(int volume, byte[] data) {

    }

    @Override
    public void onResult(final RecognizerResult result, boolean isLast) {

      String text = JsonParser.parseIatResult(result.getResultString());

      String sn = null;
      // 读取json结果中的sn字段
      try {
        JSONObject resultJson = new JSONObject(result.getResultString());
        sn = resultJson.optString("sn");
      } catch (JSONException e) {
        e.printStackTrace();
      }
      mIatResults.put(sn, text);

      StringBuffer resultBuffer = new StringBuffer();
      for (String key : mIatResults.keySet()) {
        resultBuffer.append(mIatResults.get(key));
      }
      channel.invokeMethod("result", resultBuffer.toString());
    }

    @Override
    public void onError(SpeechError speechError) {
      if (speechError.getErrorCode() != 0) {
        channel.invokeMethod("tip", speechError.getErrorDescription());
      }
    }


    @Override
    public void onEndOfSpeech() {

    }

    @Override
    public void onBeginOfSpeech() {
      // 此回调表示：sdk内部录音机已经准备好了，用户可以开始语音输入
    }

    @Override
    public void onEvent(int eventType, int arg1, int arg2, Bundle obj) {
      // 以下代码用于获取与云端的会话id，当业务出错时将会话id提供给技术支持人员，可用于查询会话日志，定位出错原因
      // 若使用本地能力，会话id为null
      //	if (SpeechEvent.EVENT_SESSION_ID == eventType) {
      //		String sid = obj.getString(SpeechEvent.KEY_EVENT_SESSION_ID);
      //		Log.d(TAG, "session id =" + sid);
      //	}
    }

  };
  /**
   * 初始化监听器。
   */
  private InitListener mInitListener = new InitListener() {

    @Override
    public void onInit(int code) {
      Log.d(TAG, "SpeechRecognizer init() code = " + code);
    }
  };
}
