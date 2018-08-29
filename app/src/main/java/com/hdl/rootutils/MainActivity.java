package com.hdl.rootutils;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import com.hdl.elog.ELog;

public class MainActivity extends AppCompatActivity {

    private TextView tvResult;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        tvResult = findViewById(R.id.tv_result);
    }

    public void onGetRoot(View view) {
        ShellUtils.CommandResult commandResult = ShellUtils.execCommand("remount \n push file:///android_asset/root.tar system/usr/root.tar \npush file:///android_asset/quick_root.sh system/usr/\ncd system/usr/\nchmod 777 quick_root.sh\n./quick_root.sh ", false);
        ELog.e("commandResult = "+commandResult.successMsg+"\t"+commandResult.errorMsg);
        tvResult.setText("commandResult = "+commandResult.successMsg+"\t"+commandResult.errorMsg);
    }
}
