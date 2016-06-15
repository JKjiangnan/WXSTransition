
#import "WXSTransitionManager.h"
#import "UIViewController+WXSTransition.h"
#import <objc/runtime.h>
#import <objc/message.h>
@interface WXSTransitionManager ()

@property (nonatomic, copy) void(^completionBlock)();
@property (nonatomic, assign) WXSTransitionAnimationType backAnimationType;

@end


@implementation WXSTransitionManager

-(instancetype)init {
    self = [super init];
    if (self) {
     
        _animationTime = 0.400082;
//        _backAnimationTime = _animationTime;
        self.animationType = WXSTransitionAnimationTypeDefault;
        _completionBlock = nil;
        
    }
    return self;
}


#pragma mark Delegate
//UIViewControllerAnimatedTransitioning
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    return _animationTime - 0.5;
}


- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext{
    
    //系统
    if (self.animationType == WXSTransitionAnimationTypeDefault) {
        self.animationType = WXSTransitionAnimationTypeSysPushFromLeft;
    }
    //
    switch (_transitionType) {
        case WXSTransitionTypePush:
        case WXSTransitionTypePresent:
            [self transitionActionAnimation:transitionContext withAnimationType:self.animationType];
            break;
        case WXSTransitionTypePop:
        case WXSTransitionTypeDismiss:
            [self transitionBackAnimation:transitionContext withAnimationType:self.animationType];
            break;
        default:
            break;
    }
    
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
 
    if (flag) {
        _completionBlock ? _completionBlock() : nil;
    }
    
}
#pragma mark Action
-(void)transitionActionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext withAnimationType:(WXSTransitionAnimationType )animationType{
    
    if ((NSInteger)animationType < (NSInteger)WXSTransitionAnimationTypeDefault) {
        [self sysTransitionAnimationWithType:animationType  context:transitionContext];
    }
    
    unsigned int count = 0;
    Method *methodlist = class_copyMethodList([WXSTransitionManager class], &count);
    int tag= 0;
    for (int i = 0; i < count; i++) {
        Method method = methodlist[i];
        SEL selector = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);
        if ([methodName rangeOfString:@"NextTransitionAnimation"].location != NSNotFound) {
            tag++;
            if (tag == animationType - WXSTransitionAnimationTypeDefault) {
                ((void (*)(id,SEL,id<UIViewControllerContextTransitioning>,WXSTransitionAnimationType))objc_msgSend)(self,selector,transitionContext,animationType);
                tag = 0;
                break;
            }
            
        }
    }
    
}

-(void)transitionBackAnimation:(id<UIViewControllerContextTransitioning>)transitionContext withAnimationType:(WXSTransitionAnimationType )animationType{
    
    if ((NSInteger)animationType < (NSInteger)WXSTransitionAnimationTypeDefault) {
        [self backSysTransitionAnimationWithType:_backAnimationType  context:transitionContext];
    }
    
    unsigned int count = 0;
    Method *methodlist = class_copyMethodList([WXSTransitionManager class], &count);
    int tag= 0;
    for (int i = 0; i < count; i++) {
        Method method = methodlist[i];
        SEL selector = method_getName(method);
        NSString *methodName = NSStringFromSelector(selector);
        if ([methodName rangeOfString:@"BackTransitionAnimation"].location != NSNotFound) {
            tag++;
            if (tag == animationType - WXSTransitionAnimationTypeDefault) {
                ((void (*)(id,SEL,id<UIViewControllerContextTransitioning>,WXSTransitionAnimationType))objc_msgSend)(self,selector,transitionContext,animationType);
                tag = 0;
                break;
            }
            
        }
    }

}


#pragma mark Animations
//
-(void)sysTransitionAnimationWithType:(WXSTransitionAnimationType) type context:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *tempView = [toVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *temView1 = [fromVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:fromVC.view];
    [containerView addSubview:toVC.view];

    CATransition *tranAnimation = [self getSysTransitionWithType:type];
    [containerView.layer addAnimation:tranAnimation forKey:nil];
    
    __weak __typeof (&*self)weakSelf = self;
    _completionBlock = ^(){
        
        if ([transitionContext transitionWasCancelled]) {
            [transitionContext completeTransition:NO];
        }else{
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            if (weakSelf.isSysBackAnimation) {
                fromVC.transitioningDelegate = nil;
                fromVC.navigationController.delegate = nil;
            }
        }
        [tempView removeFromSuperview];
        [temView1 removeFromSuperview];
    };
    
}

-(void)backSysTransitionAnimationWithType:(WXSTransitionAnimationType) type context:(id<UIViewControllerContextTransitioning>)transitionContext{

    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *tempView = [toVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *temView1 = [fromVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:fromVC.view];
    [containerView addSubview:toVC.view];
    
    CATransition *tranAnimation = [self getSysTransitionWithType:type];
    [containerView.layer addAnimation:tranAnimation forKey:nil];
    
    _completionBlock = ^(){
        
        if ([transitionContext transitionWasCancelled]) {
            [transitionContext completeTransition:NO];
        }else{
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            toVC.transitioningDelegate = nil;
            toVC.navigationController.delegate = nil;
        }
        [tempView removeFromSuperview];
        [temView1 removeFromSuperview];
    };
    
}

//
-(void)pageNextTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *tempView = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:toVC.view];
    [containerView addSubview:tempView];
    [containerView insertSubview:toVC.view atIndex:0];
    
    tempView.frame = fromVC.view.frame;
    fromVC.view.hidden = YES;
    CGPoint point = CGPointMake(0, 0.5);
    tempView.frame = CGRectOffset(tempView.frame, (point.x - tempView.layer.anchorPoint.x) * tempView.frame.size.width, (point.y - tempView.layer.anchorPoint.y) * tempView.frame.size.height);
    tempView.layer.anchorPoint = point;
    CATransform3D transfrom3d = CATransform3DIdentity;
    transfrom3d.m34 = -0.002;
    containerView.layer.sublayerTransform = transfrom3d;
    
    __weak __typeof (&*self)weakSelf = self;
    [UIView animateWithDuration:_animationTime animations:^{
        tempView.layer.transform = CATransform3DMakeRotation(-M_PI_2, 0, 1, 0);
        
    } completion:^(BOOL finished) {
                
        if ([transitionContext transitionWasCancelled]) {
            [tempView removeFromSuperview];
            fromVC.view.hidden = NO;
            [transitionContext completeTransition:NO];
        }else{
            [transitionContext completeTransition:YES];
            if (weakSelf.isSysBackAnimation) {
                fromVC.transitioningDelegate = nil;
                fromVC.navigationController.delegate = nil;
            }
        }
    }];
    
}
-(void)pageBackTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = [transitionContext containerView];
    UIView *tempView = containerView.subviews.lastObject;
    [containerView addSubview:toVC.view];

    [UIView animateWithDuration:_animationTime animations:^{
        tempView.layer.transform = CATransform3DIdentity;
        fromVC.view.alpha = 0.2;
        
    } completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
            
            fromVC.view.alpha = 1;
            [transitionContext completeTransition:NO];
        }else{
            [transitionContext completeTransition:YES];
            [tempView removeFromSuperview];
            toVC.view.hidden = NO;
            toVC.view.alpha = 1;
            //remove delegate of last view controller from self .
            toVC.navigationController.delegate = nil;
            toVC.transitioningDelegate = nil;        }
    }];
    
}


-(void)viewMoveNextTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *startView = [toVC.starView snapshotViewAfterScreenUpdates:NO];
    UIView *containerView = [transitionContext containerView];
  
    [containerView addSubview:toVC.view];
    [containerView addSubview:startView];
    
    startView.frame = [toVC.starView convertRect:toVC.starView.bounds toView: containerView];
    toVC.view.alpha = 0;
    toVC.starView.hidden = NO;
    toVC.targetView.hidden = YES;
    fromVC.view.alpha = 1;

    __weak __typeof (&*self) weakSelf = self;
    [UIView animateWithDuration:_animationTime delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:1 / 0.6 options:0 animations:^{
        startView.frame = [toVC.targetView convertRect:toVC.targetView.bounds toView:containerView];
        toVC.view.alpha = 1;
        fromVC.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        startView.hidden = YES;
        toVC.targetView.hidden = NO;
        if (weakSelf.isSysBackAnimation) {
            fromVC.transitioningDelegate = nil;
            fromVC.navigationController.delegate = nil;
        }
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];

    
}
-(void)viewMoveBackTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    UIView *tempView = containerView.subviews.lastObject;
    toVC.starView = fromVC.targetView;
    toVC.targetView = fromVC.starView;
    
    [containerView insertSubview:toVC.view atIndex:0];
    
    //Default values
    toVC.starView.hidden = YES;
    toVC.targetView.hidden = YES;
    tempView.hidden = NO;
    toVC.view.hidden = NO;
    toVC.view.alpha = 1;
    fromVC.view.alpha = 1;
    tempView.frame = [fromVC.targetView convertRect:fromVC.targetView.bounds toView:fromVC.view];
    
    [UIView animateWithDuration:_animationTime delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:1 / 0.7 options:0 animations:^{
        
        tempView.frame = [toVC.targetView convertRect:toVC.targetView.bounds toView:containerView];
        fromVC.view.alpha = 0;
        toVC.view.alpha = 1;
        
    } completion:^(BOOL finished) {
        
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        if ([transitionContext transitionWasCancelled]) {
            
            tempView.hidden = YES;
            toVC.targetView.hidden = NO;
            toVC.starView.hidden = NO;
            
        }else{
            
            toVC.targetView.hidden = NO;
            toVC.starView.hidden = YES;
            toVC.view.hidden = NO;
            [tempView removeFromSuperview];
            //remove delegate of last view controller from self.
            toVC.navigationController.delegate = nil;
            toVC.transitioningDelegate = nil;
        }
    }];
    
}

//
-(void)coverNextTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *tempView = [toVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *containView = [transitionContext containerView];

    [containView addSubview:toVC.view];
    [containView addSubview:fromVC.view];
    [containView addSubview:tempView];
    
    tempView.layer.transform = CATransform3DMakeScale(4, 4, 1);
    tempView.alpha = 0.1;
    tempView.hidden = NO;
    
    
    __weak __typeof (&*self)weakSelf = self;
    [UIView animateWithDuration:_animationTime animations:^{
        
        tempView.layer.transform = CATransform3DIdentity;
        tempView.alpha = 1;
        
    } completion:^(BOOL finished) {
        
        if ([transitionContext transitionWasCancelled]) {
            toVC.view.hidden = YES;
            [transitionContext completeTransition:NO];
        }else{
            toVC.view.hidden = NO;
            [transitionContext completeTransition:YES];
            if (weakSelf.isSysBackAnimation) {
                fromVC.transitioningDelegate = nil;
                fromVC.navigationController.delegate = nil;
            }
        }
        [tempView removeFromSuperview];
        
    }];
}

-(void)coverBackTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{

    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *tempView = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    UIView *toTempView = [toVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *containView = [transitionContext containerView];
    
    [containView addSubview:fromVC.view];
    [containView addSubview:toVC.view];
    [containView addSubview:toTempView];
    [containView addSubview:tempView];
    
    
    fromVC.view.hidden = YES;
    toVC.view.hidden = NO;
    toVC.view.alpha = 1;
    tempView.hidden = NO;
    tempView.alpha = 1;
    
    [UIView animateWithDuration:_animationTime animations:^{
        tempView.layer.transform = CATransform3DMakeScale(4, 4, 1);
        tempView.alpha = 0.0;
    } completion:^(BOOL finished) {
        
        if ([transitionContext transitionWasCancelled]) {
            
            [transitionContext completeTransition:NO];
            tempView.alpha = 1;
            tempView.layer.transform = CATransform3DIdentity;

        }else{
            
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;

            toVC.navigationController.delegate = nil;
            toVC.transitioningDelegate = nil;
        }
        
        [tempView removeFromSuperview];
        [toTempView removeFromSuperview];
    }];
    
    
}



-(void)spreadPresentNextTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{

    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *tempView = [toVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];
    [containerView addSubview:tempView];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    
    CGRect rect0 = CGRectMake(0, 0, screenWidth, 2);
    CGRect rect1 = CGRectMake(0, 0, screenWidth, screenHeight);
    
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRect:rect0];
    UIBezierPath *endPath =[UIBezierPath bezierPathWithRect:rect1];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = startPath.CGPath;
    tempView.layer.mask = maskLayer;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.delegate = self;
    
    animation.fromValue = (__bridge id)(startPath.CGPath);
    animation.toValue = (__bridge id)((endPath.CGPath));
    animation.duration = _animationTime+0.5;
    animation.timingFunction = [CAMediaTimingFunction  functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [maskLayer addAnimation:animation forKey:@"NextPath"];
    
    
    __weak __typeof (&*self) weakSelf = self;
    _completionBlock = ^(){
        
        if ([transitionContext transitionWasCancelled]) {
            [transitionContext completeTransition:NO];
        }else{
            
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            if (weakSelf.isSysBackAnimation) {
                fromVC.transitioningDelegate = nil;
                fromVC.navigationController.delegate = nil;
            }
        }
        [tempView removeFromSuperview];
    };
    
}

-(void)spreadPresentBackTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *tempView = [toVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];
    [containerView addSubview:tempView];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    
    CGRect rect0 = CGRectMake(0, screenHeight - 2, screenWidth, 2);
    CGRect rect1 = CGRectMake(0, 0, screenWidth, screenHeight);
    
    UIBezierPath *startPath = [UIBezierPath bezierPathWithRect:rect0];
    UIBezierPath *endPath =[UIBezierPath bezierPathWithRect:rect1];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = startPath.CGPath;
    tempView.layer.mask = maskLayer;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.delegate = self;
    animation.fromValue = (__bridge id)(startPath.CGPath);
    animation.toValue = (__bridge id)((endPath.CGPath));
    animation.duration = _animationTime+0.5;
    animation.timingFunction = [CAMediaTimingFunction  functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [maskLayer addAnimation:animation forKey:@"BackPath"];
    
    _completionBlock = ^(){
        
        if ([transitionContext transitionWasCancelled]) {
            [transitionContext completeTransition:NO];
        }else{
            
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            toVC.navigationController.delegate = nil;
            toVC.transitioningDelegate = nil;
        }
        [tempView removeFromSuperview];
        
    };
}


-(void)pointSpreadPresentNextTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *tempView = [toVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];
    [containerView addSubview:tempView];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    
    CGRect rect = CGRectMake(containerView.center.x, containerView.center.y, 10, 10);
    if (fromVC.starView) {
        rect = fromVC.starView.frame;
    }
    
    
    UIBezierPath *startPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    UIBezierPath *endPath = [UIBezierPath bezierPathWithArcCenter:containerView.center radius:sqrt(screenHeight * screenHeight + screenWidth * screenWidth)  startAngle:0 endAngle:M_PI*2 clockwise:YES];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = startPath.CGPath;
    tempView.layer.mask = maskLayer;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.delegate = self;
    
    animation.fromValue = (__bridge id)(startPath.CGPath);
    animation.toValue = (__bridge id)((endPath.CGPath));
    animation.duration = _animationTime;
    animation.timingFunction = [CAMediaTimingFunction  functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [maskLayer addAnimation:animation forKey:@"PointNextPath"];
    
    
    __weak __typeof (&*self)weakSelf = self;
    _completionBlock = ^(){
        
        if ([transitionContext transitionWasCancelled]) {
            [transitionContext completeTransition:NO];
        }else{
            
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            if (weakSelf.isSysBackAnimation) {
                fromVC.transitioningDelegate = nil;
                fromVC.navigationController.delegate = nil;
            }
        }
        [tempView removeFromSuperview];
    };
    
}
-(void)pointSpreadPresentBackTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    UIView *tempView = [fromVC.view snapshotViewAfterScreenUpdates:YES];
    
    [containerView addSubview:fromVC.view];
    [containerView addSubview:toVC.view];
    [containerView addSubview:tempView];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    
    CGRect rect = CGRectMake(containerView.center.x, containerView.center.y, 10, 10);
    if (toVC.starView) {
        rect = toVC.starView.frame;
    }
    
    UIBezierPath *startPath = [UIBezierPath bezierPathWithArcCenter:containerView.center radius:sqrt(screenHeight * screenHeight + screenWidth * screenWidth)  startAngle:0 endAngle:M_PI*2 clockwise:YES];
    
    UIBezierPath *endPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = startPath.CGPath;
    tempView.layer.mask = maskLayer;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.delegate = self;
    
    animation.fromValue = (__bridge id)(startPath.CGPath);
    animation.toValue = (__bridge id)((endPath.CGPath));
    animation.duration = _animationTime;
    animation.timingFunction = [CAMediaTimingFunction  functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [maskLayer addAnimation:animation forKey:@"PointBackPath"];
    
    
    _completionBlock = ^(){
        
        if ([transitionContext transitionWasCancelled]) {
            [transitionContext completeTransition:NO];
        }else{
            
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            toVC.navigationController.delegate = nil;
            toVC.transitioningDelegate = nil;
        }
        [tempView removeFromSuperview];
        
    };
    
}

-(void)boomPresentNextTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *tempView = [toVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *containView = [transitionContext containerView];
    
    [containView addSubview:toVC.view];
    [containView addSubview:fromVC.view];
    [containView addSubview:tempView];
    
    toVC.view.hidden = YES;
    tempView.layer.transform = CATransform3DMakeScale(0.01, 0.01, 1);
    
    __weak __typeof (&*self)weakSelf = self;
    [UIView animateWithDuration:_animationTime delay:0.0 usingSpringWithDamping:0.4 initialSpringVelocity:1/0.4 options:0 animations:^{
        
        tempView.layer.transform = CATransform3DIdentity;
        
    } completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
            [transitionContext completeTransition:NO];

        }else{
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            if (weakSelf.isSysBackAnimation) {
                fromVC.transitioningDelegate = nil;
                fromVC.navigationController.delegate = nil;
            }
        }
        [tempView removeFromSuperview];
    
    }];
    
}

-(void)boomPresentBackTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *tempView = [fromVC.view snapshotViewAfterScreenUpdates:YES];
    UIView *containView = [transitionContext containerView];
    
    [containView addSubview:toVC.view];
    [containView addSubview:fromVC.view];
    [containView addSubview:tempView];
    
    fromVC.view.hidden = YES;
    toVC.view.hidden = NO;
    tempView.layer.transform = CATransform3DIdentity;

    [UIView animateWithDuration:_animationTime animations:^{
        tempView.layer.transform = CATransform3DMakeScale(0.01, 0.01, 1);
    } completion:^(BOOL finished) {
        
        if ([transitionContext transitionWasCancelled]) {

            [transitionContext completeTransition:NO];
            fromVC.view.hidden = NO;
            
        }else{
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            fromVC.view.hidden = YES;
            toVC.transitioningDelegate = nil;
            toVC.navigationController.delegate = nil;
            [tempView removeFromSuperview];
        }
        
    }];

}

-(void)brickNextTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{

    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containView = [transitionContext containerView];
    
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    CGRect rect0 = CGRectMake(0 , 0 , screenWidth, screenHeight/2);
    CGRect rect1 = CGRectMake(0 , screenHeight/2 , screenWidth, screenHeight/2);
    
    
    UIImage *image0 = [self imageFromView:fromVC.view atFrame:rect0];
    UIImage *image1 = [self imageFromView:fromVC.view atFrame:rect1];
    
    UIImageView *imgView0 = [[UIImageView alloc] initWithImage:image0];
    UIImageView *imgView1 = [[UIImageView alloc] initWithImage:image1];
    
    [containView addSubview:fromVC.view];
    [containView addSubview:toVC.view];
    [containView addSubview:imgView0];
    [containView addSubview:imgView1];
    
  
    __weak __typeof (&*self)weakSelf = self;
    [UIView animateWithDuration:_animationTime animations:^{
        imgView0.layer.transform = CATransform3DMakeTranslation(0, -screenHeight/2, 0);
        imgView1.layer.transform = CATransform3DMakeTranslation(0, screenHeight/2, 0);
        
    } completion:^(BOOL finished) {
        
        if ([transitionContext transitionWasCancelled]) {
            [transitionContext completeTransition:NO];
        }else{
            [transitionContext completeTransition:YES];
            if (weakSelf.isSysBackAnimation) {
                fromVC.transitioningDelegate = nil;
                fromVC.navigationController.delegate = nil;
            }
            [imgView0 removeFromSuperview];
            [imgView1 removeFromSuperview];
        }
    }];
    
}

-(void)brickBackTransitionAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containView = [transitionContext containerView];

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    CGRect rect0 = CGRectMake(0 , 0 , screenWidth, screenHeight/2);
    CGRect rect1 = CGRectMake(0 , screenHeight/2 , screenWidth, screenHeight/2);
    
    
    UIImage *image0 = [self imageFromView:toVC.view atFrame:rect0];
    UIImage *image1 = [self imageFromView:toVC.view atFrame:rect1];
    
    UIImageView *imgView0 = [[UIImageView alloc] initWithImage:image0];
    UIImageView *imgView1 = [[UIImageView alloc] initWithImage:image1];
    
    [containView addSubview:fromVC.view];
    [containView addSubview:toVC.view];
    [containView addSubview:imgView0];
    [containView addSubview:imgView1];
    
    toVC.view.hidden = YES;
    
    imgView0.layer.transform = CATransform3DMakeTranslation(0, -screenHeight/2, 0);
    imgView1.layer.transform = CATransform3DMakeTranslation(0, screenHeight/2, 0);
    
    [UIView animateWithDuration:_animationTime animations:^{
        imgView0.layer.transform = CATransform3DIdentity;
        imgView1.layer.transform = CATransform3DIdentity;
        
    } completion:^(BOOL finished) {
        
        if ([transitionContext transitionWasCancelled]) {
            [transitionContext completeTransition:NO];
        }else{
            [transitionContext completeTransition:YES];
            toVC.view.hidden = NO;
            fromVC.transitioningDelegate = nil;
            fromVC.navigationController.delegate = nil;
        }
        [imgView0 removeFromSuperview];
        [imgView1 removeFromSuperview];

    }];
    
    
}

#pragma mark Other
- (UIImage *)imageFromView: (UIView *)view atFrame:(CGRect)rect{
    
    UIGraphicsBeginImageContext(view.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    UIRectClip(rect);
    [view.layer renderInContext:context];
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return  theImage;
    

}

-(void)setAnimationType:(WXSTransitionAnimationType)animationType {
    _animationType = animationType;
    [self backAnimationTypeFromAnimationType:animationType];
}

-(void)backAnimationTypeFromAnimationType:(WXSTransitionAnimationType)type{
    
    switch (type) {
        case WXSTransitionAnimationTypeSysFade:{
            _backAnimationType = WXSTransitionAnimationTypeSysFade;
            
        }
            break;
        case WXSTransitionAnimationTypeSysPushFromRight:{
            _backAnimationType = WXSTransitionAnimationTypeSysPushFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysPushFromLeft:{
            _backAnimationType = WXSTransitionAnimationTypeSysPushFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysPushFromTop:{
            _backAnimationType = WXSTransitionAnimationTypeSysPushFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysPushFromBottom:{
            _backAnimationType = WXSTransitionAnimationTypeSysPushFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysRevealFromRight:{
            _backAnimationType = WXSTransitionAnimationTypeSysMoveInFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysRevealFromLeft:{
            _backAnimationType = WXSTransitionAnimationTypeSysMoveInFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysRevealFromTop:{
            _backAnimationType = WXSTransitionAnimationTypeSysMoveInFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysRevealFromBottom:{
            _backAnimationType = WXSTransitionAnimationTypeSysMoveInFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysMoveInFromRight:{
            _backAnimationType = WXSTransitionAnimationTypeSysRevealFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysMoveInFromLeft:{
            _backAnimationType = WXSTransitionAnimationTypeSysRevealFromRight;

        }
            break;
        case WXSTransitionAnimationTypeSysMoveInFromTop:{
            _backAnimationType = WXSTransitionAnimationTypeSysRevealFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysMoveInFromBottom:{
            _backAnimationType = WXSTransitionAnimationTypeSysRevealFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysCubeFromRight:{
            _backAnimationType = WXSTransitionAnimationTypeSysCubeFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysCubeFromLeft:{
            _backAnimationType = WXSTransitionAnimationTypeSysCubeFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysCubeFromTop:{
            _backAnimationType = WXSTransitionAnimationTypeSysCubeFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysCubeFromBottom:{
            _backAnimationType = WXSTransitionAnimationTypeSysCubeFromTop;

        }
            break;
        case WXSTransitionAnimationTypeSysSuckEffect:{
            _backAnimationType = WXSTransitionAnimationTypeSysSuckEffect;
        }
            break;
        case WXSTransitionAnimationTypeSysOglFlipFromRight:{
            _backAnimationType = WXSTransitionAnimationTypeSysOglFlipFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysOglFlipFromLeft:{
            _backAnimationType = WXSTransitionAnimationTypeSysOglFlipFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysOglFlipFromTop:{
            _backAnimationType = WXSTransitionAnimationTypeSysOglFlipFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysOglFlipFromBottom:{
            _backAnimationType = WXSTransitionAnimationTypeSysOglFlipFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysRippleEffect:{
            _backAnimationType = WXSTransitionAnimationTypeSysRippleEffect;
        }
            break;
        case WXSTransitionAnimationTypeSysPageCurlFromRight:{
            _backAnimationType = WXSTransitionAnimationTypeSysPageUnCurlFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysPageCurlFromLeft:{
            _backAnimationType = WXSTransitionAnimationTypeSysPageUnCurlFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysPageCurlFromTop:{
            _backAnimationType = WXSTransitionAnimationTypeSysPageUnCurlFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysPageCurlFromBottom:{
            _backAnimationType = WXSTransitionAnimationTypeSysPageUnCurlFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysPageUnCurlFromRight:{
            _backAnimationType = WXSTransitionAnimationTypeSysPageCurlFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysPageUnCurlFromLeft:{
            _backAnimationType = WXSTransitionAnimationTypeSysPageCurlFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysPageUnCurlFromTop:{
            _backAnimationType = WXSTransitionAnimationTypeSysPageCurlFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysPageUnCurlFromBottom:{
            _backAnimationType = WXSTransitionAnimationTypeSysPageCurlFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysCameraIrisHollowOpen:{
            _backAnimationType = WXSTransitionAnimationTypeSysCameraIrisHollowClose;
        }
            break;
        case WXSTransitionAnimationTypeSysCameraIrisHollowClose:{
            _backAnimationType = WXSTransitionAnimationTypeSysCameraIrisHollowOpen;

        }
            break;
        default:
            break;
    }
}

-(CATransition *)getSysTransitionWithType:(WXSTransitionAnimationType )type{
    
    CATransition *tranAnimation=[CATransition animation];
    tranAnimation.duration= _animationTime;
    tranAnimation.delegate = self;
    switch (type) {
        case WXSTransitionAnimationTypeSysFade:{
            tranAnimation.type=kCATransitionFade;
        }
            break;
        case WXSTransitionAnimationTypeSysPushFromRight:{
            tranAnimation.type = kCATransitionPush;
            tranAnimation.subtype=kCATransitionFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysPushFromLeft:{
            tranAnimation.type = kCATransitionPush;
            tranAnimation.subtype=kCATransitionFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysPushFromTop:{
            tranAnimation.type = kCATransitionPush;
            tranAnimation.subtype=kCATransitionFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysPushFromBottom:{
            tranAnimation.type = kCATransitionPush;
            tranAnimation.subtype=kCATransitionFromBottom;
            
        }
            break;
        case WXSTransitionAnimationTypeSysRevealFromRight:{
            tranAnimation.type = kCATransitionReveal;
            tranAnimation.subtype=kCATransitionFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysRevealFromLeft:{
            tranAnimation.type = kCATransitionReveal;
            tranAnimation.subtype=kCATransitionFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysRevealFromTop:{
            tranAnimation.type = kCATransitionReveal;
            tranAnimation.subtype=kCATransitionFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysRevealFromBottom:{
            tranAnimation.type = kCATransitionReveal;
            tranAnimation.subtype=kCATransitionFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysMoveInFromRight:{
            tranAnimation.type = kCATransitionMoveIn;
            tranAnimation.subtype=kCATransitionFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysMoveInFromLeft:{
            tranAnimation.type = kCATransitionMoveIn;
            tranAnimation.subtype=kCATransitionFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysMoveInFromTop:{
            tranAnimation.type = kCATransitionMoveIn;
            tranAnimation.subtype=kCATransitionFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysMoveInFromBottom:{
            tranAnimation.type = kCATransitionMoveIn;
            tranAnimation.subtype=kCATransitionFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysCubeFromRight:{
            tranAnimation.type = @"cube";
            tranAnimation.subtype=kCATransitionFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysCubeFromLeft:{
            tranAnimation.type = @"cube";
            tranAnimation.subtype=kCATransitionFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysCubeFromTop:{
            tranAnimation.type=@"cube";
            tranAnimation.subtype=kCATransitionFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysCubeFromBottom:{
            tranAnimation.type=@"cube";
            tranAnimation.subtype=kCATransitionFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysSuckEffect:{
            tranAnimation.type=@"suckEffect";
        }
            break;
        case WXSTransitionAnimationTypeSysOglFlipFromRight:{
            tranAnimation.type=@"oglFlip";
            tranAnimation.subtype=kCATransitionFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysOglFlipFromLeft:{
            tranAnimation.type=@"oglFlip";
            tranAnimation.subtype=kCATransitionFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysOglFlipFromTop:{
            tranAnimation.type=@"oglFlip";
            tranAnimation.subtype=kCATransitionFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysOglFlipFromBottom:{
            tranAnimation.type=@"oglFlip";
            tranAnimation.subtype=kCATransitionFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysRippleEffect:{
            tranAnimation.type=@"rippleEffect";
        }
            break;
        case WXSTransitionAnimationTypeSysPageCurlFromRight:{
            tranAnimation.type=@"pageCurl";
            tranAnimation.subtype=kCATransitionFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysPageCurlFromLeft:{
            tranAnimation.type=@"pageCurl";
            tranAnimation.subtype=kCATransitionFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysPageCurlFromTop:{
            tranAnimation.type=@"pageCurl";
            tranAnimation.subtype=kCATransitionFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysPageCurlFromBottom:{
            tranAnimation.type=@"pageCurl";
            tranAnimation.subtype=kCATransitionFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysPageUnCurlFromRight:{
            tranAnimation.type=@"pageUnCurl";
            tranAnimation.subtype=kCATransitionFromRight;
        }
            break;
        case WXSTransitionAnimationTypeSysPageUnCurlFromLeft:{
            tranAnimation.type=@"pageUnCurl";
            tranAnimation.subtype=kCATransitionFromLeft;
        }
            break;
        case WXSTransitionAnimationTypeSysPageUnCurlFromTop:{
            tranAnimation.type=@"pageUnCurl";
            tranAnimation.subtype=kCATransitionFromTop;
        }
            break;
        case WXSTransitionAnimationTypeSysPageUnCurlFromBottom:{
            tranAnimation.type=@"pageUnCurl";
            tranAnimation.subtype=kCATransitionFromBottom;
        }
            break;
        case WXSTransitionAnimationTypeSysCameraIrisHollowOpen:{
            tranAnimation.type=@"cameraIrisHollowOpen";
        }
            break;
        case WXSTransitionAnimationTypeSysCameraIrisHollowClose:{
            tranAnimation.type=@"cameraIrisHollowClose";
        }
            break;
            
            
        default:
            break;
    }
    return tranAnimation;
}

@end
