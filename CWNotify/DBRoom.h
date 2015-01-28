//
//  Copyright (c) 2015 feedtailor Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DBRoom : NSManagedObject

@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * roomId;

@end
