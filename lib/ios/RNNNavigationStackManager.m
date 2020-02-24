#import "RNNNavigationStackManager.h"
#import "RNNErrorHandler.h"
#import <React/RCTI18nUtil.h>

typedef void (^RNNAnimationBlock)(void);

@implementation RNNNavigationStackManager

- (void)push:(UIViewController *)newTop onTop:(UIViewController *)onTopViewController animated:(BOOL)animated completion:(RNNTransitionCompletionBlock)completion rejection:(RCTPromiseRejectBlock)rejection {
	UINavigationController* nvc = [self navigationControllerFromViewController:onTopViewController];

	if([[RCTI18nUtil sharedInstance] isRTL]) {
		nvc.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
		nvc.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
	} else {
		nvc.view.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
		nvc.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
	}
	
	[self performAnimationBlock:^{
		[nvc pushViewController:newTop animated:animated];
	} completion:completion];
}

- (void)pop:(UIViewController *)viewController animated:(BOOL)animated completion:(RNNTransitionCompletionBlock)completion rejection:(RNNTransitionRejectionBlock)rejection {
    UINavigationController* nvc = [self navigationControllerFromViewController:viewController];
    if ([nvc.viewControllers indexOfObject:viewController] < 0) {
        [RNNErrorHandler reject:rejection withErrorCode:1012 errorDescription:@"popping component failed"];
        return;
    }
    
    if ([nvc topViewController] != viewController) {
        NSMutableArray * vcs = nvc.viewControllers.mutableCopy;
        [vcs removeObject:viewController];
        [self performAnimationBlock:^{
            [nvc setViewControllers:vcs animated:animated];
        } completion:^{
            completion();
        }];
    } else {
        [self performAnimationBlock:^{
            [nvc popViewControllerAnimated:animated];
        } completion:^{
            completion();
        }];
    }
}

- (void)popTo:(UIViewController *)viewController animated:(BOOL)animated completion:(RNNPopCompletionBlock)completion rejection:(RNNTransitionRejectionBlock)rejection; {
	__block NSArray* poppedVCs;
	
    UINavigationController* nvc = [self navigationControllerFromViewController:viewController];
    
	if ([nvc.childViewControllers containsObject:viewController]) {
		[self performAnimationBlock:^{
			poppedVCs = [nvc popToViewController:viewController animated:animated];
		} completion:^{
			if (completion) {
				completion(poppedVCs);
			}
		}];
	} else {
		[RNNErrorHandler reject:rejection withErrorCode:1011 errorDescription:@"component not found in stack"];
	}
}

- (void)popToRoot:(UIViewController*)viewController animated:(BOOL)animated completion:(RNNPopCompletionBlock)completion rejection:(RNNTransitionRejectionBlock)rejection {
	__block NSArray* poppedVCs;
	
    UINavigationController* nvc = [self navigationControllerFromViewController:viewController];
    
	[self performAnimationBlock:^{
		poppedVCs = [nvc popToRootViewControllerAnimated:animated];
	} completion:^{
		completion(poppedVCs);
	}];
}

- (void)setStackChildren:(NSArray<UIViewController *> *)children fromViewController:(UIViewController *)fromViewController animated:(BOOL)animated completion:(RNNTransitionCompletionBlock)completion rejection:(RNNTransitionRejectionBlock)rejection {
	UINavigationController* nvc = [self navigationControllerFromViewController:fromViewController];
	
	[self performAnimationBlock:^{
		[nvc setViewControllers:children animated:animated];
	} completion:completion];
}

- (UINavigationController *)navigationControllerFromViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:UINavigationController.class]) {
        return (UINavigationController *)viewController;
    } else {
        return viewController.navigationController;
    }
}

# pragma mark Private

- (void)performAnimationBlock:(RNNAnimationBlock)animationBlock completion:(RNNTransitionCompletionBlock)completion {
	[CATransaction begin];
	[CATransaction setCompletionBlock:^{
		if (completion) {
			completion();
		}
	}];
	
	animationBlock();
	
	[CATransaction commit];
}


@end
