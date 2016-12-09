//
//  ViewController.m
//  RechercheHtml
//
//  Created by William MERLE-MARTY on 23/11/2016.
//  Copyright © 2016 William MERLE-MARTY. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"
#import <CommonCrypto/CommonDigest.h>

@interface ViewController ()

    @property (weak, nonatomic) IBOutlet UITextField *findUrl;
    - (IBAction)searchButton:(id)sender;
    @property (weak, nonatomic) IBOutlet UITextView *writeHtml;
    - (IBAction)webView:(id)sender;
    @property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressLoader;
    @property (weak, nonatomic) IBOutlet UIImageView *imgHtml;

@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [_progressLoader setHidden:YES];
    _writeHtml.editable = NO;

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)searchButton:(id)sender {
    
    // Activation du loader
    [_progressLoader setHidden:NO];
    [_progressLoader startAnimating];
    
    // Recupération de la velue de l'input
    NSString *str = self.findUrl.text;
    
    // Verification que la valeu contient http ou https et ne contient pas QUE http ou https

    if(([str hasPrefix:@"http://"] || [str hasPrefix:@"https://"]) && ![str  isEqual: @"https://"] && ![str  isEqual: @"http://"]){
        
        // Passage de la value dans le regex

        Boolean validate = [self validateUrl:str];
        if(validate){
        
            // Initialisation du fichier cache

            NSFileManager* fileManager = [NSFileManager defaultManager];
            NSString *hash = [self generateMD5:str]; // Hash de la value pour le nom du fichier
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *URL = [paths objectAtIndex:0];
            NSString *sep = @"/";
            NSString *fileFinal = [NSString stringWithFormat:@"%@%@%@", URL, sep, hash]; // chemin + nom de fichier
            
            //Verification si le fichier ache existe deja
            if([fileManager fileExistsAtPath:fileFinal]){

                // Récupération de la date de création du fichier cache
                NSDictionary* attrs = [fileManager attributesOfItemAtPath:fileFinal error:nil];
                NSDate *dc = [attrs fileCreationDate];
                NSDate *dn = [NSDate date];
                NSTimeInterval diff = [dc timeIntervalSinceDate:dn];
                int numberOfDays = diff / 86400;
                
                //Verification si le fichier a plus moins de 7 jours

                if(numberOfDays < 7){
                    
                    //Recuération du contenu HTML
                    NSString* fileContents = [NSString stringWithContentsOfFile:fileFinal encoding:NSUTF8StringEncoding error:nil];

                        dispatch_async(dispatch_get_main_queue(), ^{
                            //Ecriture du contenu sur la storyboard
                            _writeHtml.text = fileContents;
                            //Fin d'animation du loader
                            [_progressLoader stopAnimating];
                            [_progressLoader setHidden:YES];
                        });
                }else{
                    
                    //Recuperation du contenu depuis l'URL

                    NSURL *toLoad = [NSURL URLWithString:str];
                    NSURLSession *session = [NSURLSession sharedSession];
                    NSURLSessionDataTask * task = [session dataTaskWithURL:toLoad completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        
                       
                            
                        // JE VAIS VERIFIER SI LE CONTENU EST DE TYPE TEXT OU IMAGE
                        NSDictionary *httpResponse = [(NSHTTPURLResponse *)response allHeaderFields];
                        NSString *rep = httpResponse[@"Content-Type"];
                            
                        if([rep hasPrefix:@"text/html"]){
                            
                            //Suppression et Création du fichier
                            [fileManager removeItemAtPath:fileFinal error:nil];
                            [fileManager createFileAtPath:fileFinal contents:nil attributes:nil];
                            
                            [_imgHtml setHidden:YES];
                            NSString *test = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            if (test == (id)[NSNull null] || test.length == 0 ){
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    _writeHtml.text =  @"Cette URL n'est pas correcte";
                                    [_progressLoader stopAnimating];
                                    [_progressLoader setHidden:YES];
                                });
                            }else{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [test writeToFile:fileFinal atomically:YES encoding:NSUTF8StringEncoding error:nil];
                                    NSString * contents = [[NSString alloc]initWithContentsOfFile:fileFinal encoding:NSUTF8StringEncoding error:nil];
                                    _writeHtml.text = contents;
                                    [_progressLoader stopAnimating];
                                    [_progressLoader setHidden:YES];
                                        
                                });
                            }
                        }else if ([rep hasPrefix:@"image/jpeg"]){
                            [_imgHtml setHidden:NO];
                            
                            UIImage *img = [[UIImage alloc] initWithData:data];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                _imgHtml.image = img;
                                [_progressLoader stopAnimating];
                                [_progressLoader setHidden:YES];
                                        
                            });
    
                        }
                    }];
                    [task resume];
                }
            }else{
                NSURL *toLoad = [NSURL URLWithString:str];
                NSURLSession *session = [NSURLSession sharedSession];
                NSURLSessionDataTask * task = [session dataTaskWithURL:toLoad completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                    if(error == NULL){

                        // JE VAIS VERIFIER SI TEXT OU IMAGE
                        NSDictionary *httpResponse = [(NSHTTPURLResponse *)response allHeaderFields];
                        NSString *rep = httpResponse[@"Content-Type"];
                    
                        if([rep hasPrefix:@"text/html"]){
                            
                            [fileManager createFileAtPath:fileFinal contents:nil attributes:nil];
                            [_imgHtml setHidden:YES];

                            NSString *test = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            if (test == (id)[NSNull null] || test.length == 0 ){
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    _writeHtml.text =  @"Cette URL n'est pas correcte";
                                    [_progressLoader stopAnimating];
                                    [_progressLoader setHidden:YES];
                                });
                            }else{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [test writeToFile:fileFinal atomically:YES encoding:NSUTF8StringEncoding error:nil];
                                    NSString * contents = [[NSString alloc]initWithContentsOfFile:fileFinal encoding:NSUTF8StringEncoding error:nil];
                                    _writeHtml.text = contents;
                                    [_progressLoader stopAnimating];
                                    [_progressLoader setHidden:YES];
                                
                                });
                            }
                        }else if ([rep hasPrefix:@"image/jpeg"]){
                            [_imgHtml setHidden:NO];
                            UIImage *img = [[UIImage alloc] initWithData:data];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                _imgHtml.image = img;
                                [_progressLoader stopAnimating];
                                [_progressLoader setHidden:YES];
                            
                            });
                        }
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _writeHtml.text =  @"Cette URL n'est pas correcte";
                            [_progressLoader stopAnimating];
                            [_progressLoader setHidden:YES];
                        });
                    }
                }];
                [task resume];
            }
        }else{
            _writeHtml.text =  @"Cette URL n'est pas correcte";
            [_progressLoader stopAnimating];
            [_progressLoader setHidden:YES];
        }
            
    }else{
        _writeHtml.text =  @"Cette URL n'est pas correcte";
        [_progressLoader stopAnimating];
        [_progressLoader setHidden:YES];

    }
    
}

- (BOOL) validateUrl: (NSString *) candidate {
    //NSString *urlRegEx = @"(http|https)?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\.]*(\\?\\S+)?)?)?";
    NSString *urlRegEx = @"http(s)?://([\\w-]+\\.)+[\\w-]+(/[\\w- ./?%&amp;=]*)?";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

- (NSString *) generateMD5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

- (IBAction)webView:(id)sender {
   NSString *str = self.findUrl.text;

    if (str == (id)[NSNull null] || str.length == 0 ){

        dispatch_async(dispatch_get_main_queue(), ^{
            [_imgHtml setHidden:YES];
            _writeHtml.text =  @"Cette URL n'est pas correcte";
        });
    }else{

        NSURL *toLoad = [NSURL URLWithString:str];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithURL:toLoad completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            

            NSString *test = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"REPONSE%@",test);

            if (test == (id)[NSNull null] || test.length == 0 ){
                NSLog(@"%s","JE SUIS LA 4");

                dispatch_async(dispatch_get_main_queue(), ^{
                    [_imgHtml setHidden:NO];
                    _writeHtml.text =  @"Cette URL n'est pas correcte";
                    
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"%s","JE SUIS LA 5");

                    WebViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"webView"];
                    vc.urlString = str;
                    [self.navigationController pushViewController:vc animated:YES];
                });
            }
        }];
        [task resume];
      
    }
}
@end
