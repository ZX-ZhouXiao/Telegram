/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGMessageImageView.h"

#import "UIImage+TG.h"
#import "TGModernButton.h"

#import "TGMessageImageViewOverlayView.h"
#import "TGMessageImageViewTimestampView.h"
#import "TGMessageImageAdditionalDataView.h"
#import "TGStaticBackdropImageData.h"

#import "TGModernGalleryTransitionView.h"

#import "TGFont.h"

static const CGFloat circleDiameter = 50.0f;

static const CGFloat timestampWidth = 100.0f;
static const CGFloat timestampHeight = 18.0f;
static const CGFloat timestampRightPadding = 6.0f;
static const CGFloat timestampBottomPadding = 6.0f;

static const CGFloat additionalDataWidth = 200.0f;
static const CGFloat additionalDataHeight = 18.0f;
static const CGFloat additionalDataLeftPadding = 6.0f;
static const CGFloat additionalDataTopPadding = 6.0f;

@interface TGMessageImageViewContainer () <TGModernGalleryTransitionView>
{
    TGMessageImageViewTimestampView *_timestampView;
}

@end

@interface TGMessageImageView ()
{
    TGModernButton *_buttonView;
    TGMessageImageViewOverlayView *_overlayView;
    
    TGMessageImageAdditionalDataView *_additionalDataView;
    TGStaticBackdropAreaData *_additionalDataBackdropArea;
    
    UIImageView *_detailStringsBackground;
    UILabel *_detailStringLabel1;
    UILabel *_detailStringLabel2;
}

@property (nonatomic, strong) NSString *viewIdentifier;
@property (nonatomic, strong) NSString *viewStateIdentifier;

@property (nonatomic, strong) TGMessageImageViewTimestampView *timestampView;

@end

@implementation TGMessageImageView

- (void)loadUri:(NSString *)uri withOptions:(NSDictionary *)options
{
    self.viewStateIdentifier = [[NSString alloc] initWithFormat:@"TGMessageImageView/%@", uri];
    
    [super loadUri:uri withOptions:options];
}

- (void)willBecomeRecycled
{
    self.viewStateIdentifier = nil;
    
    [_timestampView setDisplayProgress:false];
    
    [self reset];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _buttonView = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, circleDiameter, circleDiameter)];
        _buttonView.exclusiveTouch = true;
        _buttonView.modernHighlight = true;
        [_buttonView addTarget:self action:@selector(actionButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        _overlayView = [[TGMessageImageViewOverlayView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, circleDiameter, circleDiameter)];
        _overlayView.userInteractionEnabled = false;
        [_buttonView addSubview:_overlayView];
        
        static UIImage *highlightImage = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(circleDiameter, circleDiameter), false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, UIColorRGBA(0x000000, 0.4f).CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, circleDiameter, circleDiameter));
            highlightImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        });
        
        _buttonView.highlightImage = highlightImage;
    }
    return self;
}

- (UIImage *)currentImage
{
    return self.image;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CGRect buttonFrame = _buttonView.frame;
    buttonFrame.origin = CGPointMake(CGFloor(frame.size.width - buttonFrame.size.width) / 2.0f, CGFloor(frame.size.height - buttonFrame.size.height) / 2.0f);
    if (!CGRectEqualToRect(_buttonView.frame, buttonFrame))
    {
        _buttonView.frame = buttonFrame;
    }
    
    _timestampView.frame = CGRectMake(frame.size.width - timestampWidth - timestampRightPadding, frame.size.height - timestampHeight - timestampBottomPadding, timestampWidth, timestampHeight);
    
    if (_detailStringsBackground.superview != nil)
    {
        CGFloat height = _detailStringsBackground.frame.size.height;
        _detailStringsBackground.frame = CGRectMake(2.0f, self.frame.size.height - height - 1, self.frame.size.width - 4, height);
    }
}

- (void)performTransitionToImage:(UIImage *)image duration:(NSTimeInterval)duration
{
    [super performTransitionToImage:image duration:duration];
    
    TGStaticBackdropImageData *backdropData = [image staticBackdropImageData];
    UIImage *actionCircleImage = [backdropData backdropAreaForKey:TGStaticBackdropMessageActionCircle].background;
    
    [_overlayView setBlurredBackgroundImage:actionCircleImage];
    
    [_timestampView setBackdropArea:[backdropData backdropAreaForKey:TGStaticBackdropMessageTimestamp] transitionDuration:duration];
    
    _additionalDataBackdropArea = [backdropData backdropAreaForKey:TGStaticBackdropMessageAdditionalData];
    [_additionalDataView setBackdropArea:_additionalDataBackdropArea transitionDuration:duration];
}

- (void)setOverlayType:(int)overlayType
{
    [self setOverlayType:overlayType animated:false];
}

- (void)setOverlayType:(int)overlayType animated:(bool)animated
{
    if (_overlayType != overlayType)
    {
        _overlayType = overlayType;
        
        switch (_overlayType)
        {
            case TGMessageImageViewOverlayDownload:
            {
                if (_buttonView.superview == nil)
                    [self addSubview:_buttonView];
                
                _buttonView.alpha = 1.0f;
                
                [_overlayView setDownload];
                
                break;
            }
            case TGMessageImageViewOverlayPlay:
            {
                if (_buttonView.superview == nil)
                    [self addSubview:_buttonView];
                
                _buttonView.alpha = 1.0f;
                
                [_overlayView setPlay];
                
                break;
            }
            case TGMessageImageViewOverlaySecret:
            case TGMessageImageViewOverlaySecretViewed:
            {
                if (_buttonView.superview == nil)
                    [self addSubview:_buttonView];
                
                _buttonView.alpha = 1.0f;
                
                [_overlayView setSecret:_overlayType == TGMessageImageViewOverlaySecretViewed];
                
                break;
            }
            case TGMessageImageViewOverlayProgress:
            {
                if (_buttonView.superview == nil)
                    [self addSubview:_buttonView];
                
                _buttonView.alpha = 1.0f;
                
                [_overlayView setProgress:_progress animated:false];
                
                break;
            }
            case TGMessageImageViewOverlaySecretProgress:
            {
                if (_buttonView.superview == nil)
                    [self addSubview:_buttonView];
                
                _buttonView.alpha = 1.0f;
                
                [_overlayView setSecretProgress:_progress completeDuration:_completeDuration animated:false];
                
                break;
            }
            case TGMessageImageViewOverlayNone:
            default:
            {
                if (_buttonView.superview != nil)
                {
                    if (animated)
                    {
                        [UIView animateWithDuration:0.2 animations:^
                        {
                            _buttonView.alpha = 0.0f;
                        } completion:^(BOOL finished)
                        {
                            if (finished)
                                [_buttonView removeFromSuperview];
                        }];
                    }
                    else
                    {
                        [_buttonView removeFromSuperview];
                    }
                }
                
                break;
            }
        }
    }
}

- (void)setProgress:(float)progress
{
    [self setProgress:progress animated:false];
}

- (void)setProgress:(float)progress animated:(bool)animated
{
    if (ABS(_progress - progress) > FLT_EPSILON)
    {
        _progress = progress;
        
        if (_overlayType == TGMessageImageViewOverlayProgress)
            [_overlayView setProgress:progress animated:animated];
    }
}

- (void)setSecretProgress:(float)progress completeDuration:(NSTimeInterval)completeDuration animated:(bool)animated
{
    if (ABS(_progress - progress) > FLT_EPSILON || ABS(completeDuration - _completeDuration) > DBL_EPSILON)
    {
        _progress = progress;
        _completeDuration = completeDuration;
        
        if (_overlayType == TGMessageImageViewOverlaySecretProgress)
            [_overlayView setSecretProgress:progress completeDuration:completeDuration animated:animated];
    }
}

- (void)setTimestampHidden:(bool)timestampHidden
{
    _timestampView.hidden = timestampHidden;
}

- (void)setTimestampString:(NSString *)timestampString displayCheckmarks:(bool)displayCheckmarks checkmarkValue:(int)checkmarkValue animated:(bool)animated
{
    [_timestampView setTimestampString:timestampString displayCheckmarks:displayCheckmarks checkmarkValue:checkmarkValue animated:animated];
}

- (void)setAdditionalDataString:(NSString *)additionalDataString
{
    if (additionalDataString.length != 0)
    {
        if (_additionalDataView == nil)
        {
            _additionalDataView = [[TGMessageImageAdditionalDataView alloc] initWithFrame:CGRectMake(additionalDataLeftPadding, additionalDataTopPadding, additionalDataWidth, additionalDataHeight)];
        }
        
        [_additionalDataView setBackdropArea:_additionalDataBackdropArea transitionDuration:0.0];
        [_additionalDataView setText:additionalDataString];
        
        if (_additionalDataView.superview == nil)
            [self addSubview:_additionalDataView];
    }
    else
        [_additionalDataView removeFromSuperview];
}

- (void)setDisplayTimestampProgress:(bool)displayTimestampProgress
{
    [_timestampView setDisplayProgress:displayTimestampProgress];
}

- (void)setIsBroadcast:(bool)isBroadcast
{
    [_timestampView setIsBroadcast:isBroadcast];
}

- (void)setDetailStrings:(NSArray *)detailStrings
{
    [_timestampView setTransparent:detailStrings.count != 0];
    
    if (detailStrings.count == 0)
    {
        [_detailStringsBackground removeFromSuperview];
        [_detailStringLabel1 removeFromSuperview];
        [_detailStringLabel2 removeFromSuperview];
    }
    else
    {
        if (_detailStringsBackground == nil)
        {
            static UIImage *backgroundImage = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                CGFloat diameter = 26.0f;
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(diameter, diameter / 2 + 1), false, 0.0f);
                CGContextRef context = UIGraphicsGetCurrentContext();
                
                CGContextSetFillColorWithColor(context, UIColorRGBA(0x000000, 0.5f).CGColor);
                CGContextFillEllipseInRect(context, CGRectMake(0.0f, -diameter / 2, diameter, diameter));
                
                backgroundImage = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:(NSInteger)(diameter / 2) topCapHeight:1];
                UIGraphicsEndImageContext();
            });
            _detailStringsBackground = [[UIImageView alloc] initWithImage:backgroundImage];
        }
        
        if (_detailStringsBackground.superview == nil)
            [self insertSubview:_detailStringsBackground belowSubview:_timestampView];
        
        CGFloat height = 41.0f;
        
        _detailStringsBackground.frame = CGRectMake(2.0f, self.frame.size.height - height - 1, self.frame.size.width - 4, height);
        
        if (_detailStringLabel1 == nil)
        {
            _detailStringLabel1 = [[UILabel alloc] init];
            _detailStringLabel1.backgroundColor = [UIColor clearColor];
            _detailStringLabel1.textColor = [UIColor whiteColor];
            _detailStringLabel1.font = TGSystemFontOfSize(13.0f);
            
            _detailStringLabel1.text = @" ";
            [_detailStringLabel1 sizeToFit];
        }
        
        if (_detailStringLabel1.superview == nil)
            [self addSubview:_detailStringLabel1];
        
        _detailStringLabel1.text = detailStrings[0];
        
        _detailStringLabel1.frame = CGRectMake(12.0f, _detailStringsBackground.frame.origin.y + 4.0f, self.frame.size.width - 30.0f, _detailStringLabel1.frame.size.height);
        
        if (detailStrings.count >= 2)
        {
            if (_detailStringLabel2 == nil)
            {
                _detailStringLabel2 = [[UILabel alloc] init];
                _detailStringLabel2.backgroundColor = [UIColor clearColor];
                _detailStringLabel2.textColor = [UIColor whiteColor];
                _detailStringLabel2.font = TGSystemFontOfSize(12.0f);
                
                _detailStringLabel2.text = @" ";
                [_detailStringLabel2 sizeToFit];
            }
            
            if (_detailStringLabel2.superview == nil)
                [self addSubview:_detailStringLabel2];
            
            _detailStringLabel2.text = detailStrings[1];
            
            _detailStringLabel2.frame = CGRectMake(12.0f, _detailStringsBackground.frame.origin.y + 20.0f, self.frame.size.width - 24.0f - 60.0f, _detailStringLabel2.frame.size.height);
        }
        else
            [_detailStringLabel2 removeFromSuperview];
    }
}

- (void)actionButtonPressed
{
    TGMessageImageViewActionType action = TGMessageImageViewActionDownload;
    
    switch (_overlayType)
    {
        case TGMessageImageViewOverlayDownload:
        {
            action = TGMessageImageViewActionDownload;
            break;
        }
        case TGMessageImageViewOverlayProgress:
        {
            action = TGMessageImageViewActionCancelDownload;
            break;
        }
        case TGMessageImageViewOverlayPlay:
        {
            action = TGMessageImageViewActionPlay;
            break;
        }
        case TGMessageImageViewOverlaySecret:
        {
            action = TGMessageImageViewActionSecret;
            break;
        }
        case TGMessageImageViewOverlaySecretViewed:
        {
            action = TGMessageImageViewActionSecret;
            break;
        }
        default:
            break;
    }
    
    id<TGMessageImageViewDelegate> delegate = _delegate;
    if ([delegate respondsToSelector:@selector(messageImageViewActionButtonPressed:withAction:)])
        [delegate messageImageViewActionButtonPressed:self withAction:action];
}

@end

@implementation TGMessageImageViewContainer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _imageView = [[TGMessageImageView alloc] initWithFrame:(CGRect){CGPointZero, frame.size}];
        _imageView.userInteractionEnabled = true;
        [self addSubview:_imageView];
        
        _timestampView = [[TGMessageImageViewTimestampView alloc] initWithFrame:CGRectMake(frame.size.width - timestampWidth - timestampRightPadding, frame.size.height - timestampHeight - timestampBottomPadding, timestampWidth, timestampHeight)];
        _timestampView.userInteractionEnabled = false;
        [self addSubview:_timestampView];
        _imageView.timestampView = _timestampView;
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    _imageView.frame = (CGRect){CGPointZero, frame.size};
}

- (void)setViewIdentifier:(NSString *)viewIdentifier
{
    [_imageView setViewIdentifier:viewIdentifier];
}

- (NSString *)viewIdentifier
{
    return [_imageView viewIdentifier];
}

- (void)setViewStateIdentifier:(NSString *)viewStateIdentifier
{
    [_imageView setViewStateIdentifier:viewStateIdentifier];
}

- (NSString *)viewStateIdentifier
{
    return _imageView.viewStateIdentifier;
}

- (void)willBecomeRecycled
{
    [_imageView willBecomeRecycled];
}

- (UIImage *)transitionImage
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0f);
    if ([UIView instancesRespondToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
    {
        [_imageView drawViewHierarchyInRect:_imageView.frame afterScreenUpdates:false];
        [_timestampView drawViewHierarchyInRect:_timestampView.frame afterScreenUpdates:false];
    }
    else
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        [_imageView.layer renderInContext:context];
        CGContextTranslateCTM(context, _timestampView.frame.origin.x, _timestampView.frame.origin.y);
        [_timestampView.layer renderInContext:context];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
