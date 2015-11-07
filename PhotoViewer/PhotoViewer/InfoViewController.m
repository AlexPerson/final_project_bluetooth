//
//  InfoViewController.m
//  PhotoViewer
//
//  Created by Joe Zhou on 07/11/2015.
//  Copyright © 2015 Joe Zhou. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()


@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;

@end

@implementation InfoViewController

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *notes = self.currentPhoto.notes;
    self.detailsLabel.text = notes;
    // Do any additional setup after loading the view.
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
