package com.qiniu.pili.droid.shortvideo.demo.tusdk;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.bitmap.RoundedCorners;
import com.bumptech.glide.request.RequestOptions;
import com.qiniu.pili.droid.shortvideo.demo.R;

import org.lasque.tusdk.core.TuSdkContext;
import org.lasque.tusdk.core.view.TuSdkImageView;

import java.io.IOException;
import java.io.InputStream;

public class TuEffectListAdapter extends RecyclerView.Adapter<TuEffectListAdapter.EffectItemViewHolder> {
    private String[] mEffectNames = {
            "None", "抖动", "幻视", "灵魂出窍", "魔法", "扭曲", "信号",
            "闪电", "X光", "心跳", "镜像", "晃动", "旧电视"
    };
    private String[] mEffectPaths = {
            "liveshake", "livemegrim", "livesoulout", "edgemagic", "livefancy", "livesignal",
            "livelightning", "livexray", "liveheartbeat", "livemirrorimage", "liveslosh", "liveoldtv"
    };
    private String[] mEffectCodes = {
            "None", "LiveShake01", "LiveMegrim01", "LiveSoulOut01", "EdgeMagic01", "LiveFancy01_1", "LiveSignal01",
            "LiveLightning01", "LiveXRay01", "LiveHeartbeat01", "LiveMirrorImage01", "LiveSlosh01", "LiveOldTV01"
    };
    private int[] mEffectColors = {
            R.color.effectBarTransparent, R.color.effectBar1, R.color.effectBar2, R.color.effectBar3, R.color.effectBar4, R.color.effectBar5, R.color.effectBar6,
            R.color.effectBar7, R.color.effectBar8, R.color.effectBar9, R.color.effectBar10, R.color.effectBar11, R.color.effectBar12
    };

    private Context mContext;
    private OnEffectTouchListener mOnEffectTouchListener;
    private boolean mIsDeletable;

    public TuEffectListAdapter(Context context) {
        mContext = context;
    }

    public void setEffectOnTouchListener(OnEffectTouchListener onEffectTouchListener) {
        mOnEffectTouchListener = onEffectTouchListener;
    }

    public void setDeletable(boolean canDelete) {
        mIsDeletable = canDelete;
    }

    public interface OnEffectTouchListener {
        void onDeleteClicked();
        boolean onTouch(View v, MotionEvent event, String effectCode, int color);
    }

    @Override
    public EffectItemViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        Context context = parent.getContext();
        LayoutInflater inflater = LayoutInflater.from(context);
        View contactView = inflater.inflate(R.layout.filter_item, parent, false);
        EffectItemViewHolder viewHolder = new EffectItemViewHolder(contactView);
        return viewHolder;
    }

    @Override
    public void onBindViewHolder(EffectItemViewHolder holder, final int position) {
        if (position == 0) {
            holder.mIcon.setImageDrawable(mContext.getResources().getDrawable(R.drawable.btn_delete));
            holder.mName.setVisibility(View.GONE);
            holder.itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (mOnEffectTouchListener != null && mIsDeletable) {
                        mOnEffectTouchListener.onDeleteClicked();
                    }
                }
            });
        } else {
            String screenCode = mEffectCodes[position];
            String screenImageCode = screenCode.toLowerCase();
            String screenImageName = getThumbPrefix() + screenImageCode;
            int screenId = TuSdkContext.getDrawableResId(screenImageName);
            //设置图片圆角角度
            RoundedCorners roundedCorners = new RoundedCorners(TuSdkContext.dip2px(8));
            RequestOptions options = RequestOptions.bitmapTransform(roundedCorners).override(holder.mIcon.getWidth(), holder.mIcon.getHeight());
            Glide.with(holder.mIcon.getContext()).asGif().load(screenId).apply(options).into(holder.mIcon);

            holder.mName.setText(mEffectNames[position]);
            holder.mIcon.setOnTouchListener(new View.OnTouchListener() {
                @Override
                public boolean onTouch(View v, MotionEvent event) {
                    if (mOnEffectTouchListener != null) {
                        return mOnEffectTouchListener.onTouch(v, event, mEffectCodes[position], mContext.getResources().getColor(mEffectColors[position]));
                    }
                    return false;
                }
            });
        }
        holder.itemView.setTag(position);
    }

    @Override
    public int getItemCount() {
        return mEffectNames.length;
    }

    @Override
    public int getItemViewType(int position) {
        return position;
    }

    public class EffectItemViewHolder extends RecyclerView.ViewHolder {
        TuSdkImageView mIcon;
        TextView mName;

        public EffectItemViewHolder(View itemView) {
            super(itemView);
            mIcon = itemView.findViewById(R.id.icon);
            mName = itemView.findViewById(R.id.name);
        }
    }

    /**
     * 缩略图前缀
     *
     * @return
     */
    protected String getThumbPrefix() {
        return "lsq_filter_thumb_";
    }
}