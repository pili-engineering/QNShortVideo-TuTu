package com.qiniu.pili.droid.shortvideo.demo.view;

import android.content.Context;
import android.util.AttributeSet;

import com.qiniu.pili.droid.shortvideo.demo.R;

public class EffectSectionProgressBar extends SectionProgressBar {

    public EffectSectionProgressBar(Context context) {
        super(context);
    }

    public EffectSectionProgressBar(Context paramContext, AttributeSet paramAttributeSet) {
        super(paramContext, paramAttributeSet);
    }

    public EffectSectionProgressBar(Context paramContext, AttributeSet paramAttributeSet, int paramInt) {
        super(paramContext, paramAttributeSet, paramInt);
    }

    @Override
    public synchronized void removeLastBreakPoint() {
        BreakPointInfo breakInfo = mBreakPointInfoList.removeLast();
        while (!mBreakPointInfoList.isEmpty() && breakInfo.getColor() == getResources().getColor(R.color.effectBarTransparent)) {
            breakInfo = mBreakPointInfoList.removeLast();
        }
    }
}
