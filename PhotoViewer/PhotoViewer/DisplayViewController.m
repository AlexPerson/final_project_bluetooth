//
//  DisplayViewController.m
//  PhotoViewer
//
//  Created by Joe Zhou on 07/11/2015.
//  Copyright © 2015 Joe Zhou. All rights reserved.
//

#import "DisplayViewController.h"

@interface DisplayViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *currentImage;

@end

@implementation DisplayViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    InfoViewController *ivc = [segue destinationViewController];
    ivc.currentPhoto = self.currentPhoto;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImage *image = [UIImage imageNamed:self.currentPhoto.filename];
    [self.currentImage setImage:image];
    
    self.title = self.currentPhoto.name;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
