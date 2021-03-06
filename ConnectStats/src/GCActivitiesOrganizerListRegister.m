//  MIT Licence
//
//  Created on 04/10/2016.
//
//  Copyright (c) 2016 Brice Rosenzweig.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  

#import "GCActivitiesOrganizerListRegister.h"
#import "GCActivitiesOrganizer.h"
#import "GCService.h"

@interface GCActivitiesOrganizerListRegister ()
@property (nonatomic,retain) NSArray<GCActivity*>*activities;
@property (nonatomic,assign) NSUInteger reachedExisting;
@property (nonatomic,retain) NSArray<NSString*>*childIds;
@property (nonatomic,retain) GCService * service;
@property (nonatomic,assign) BOOL isFirst;

@end

@implementation GCActivitiesOrganizerListRegister

+(instancetype)listRegisterFor:(NSArray<GCActivity*>*)activities from:(GCService*)service isFirst:(BOOL)isFirst{
    GCActivitiesOrganizerListRegister * rv = [[[GCActivitiesOrganizerListRegister alloc] init] autorelease];
    if(rv){
        rv.activities = activities;
        rv.service = service;
        rv.isFirst = isFirst;
    }
    return rv;
}

-(void)dealloc{
    [_activities release];
    [_childIds release];
    [_service release];

    [super dealloc];
}
-(void)addToOrganizer:(GCActivitiesOrganizer*)organizer{
    NSMutableArray * existingInService = [NSMutableArray array];

    // Find childIds not in organizer yet
    NSMutableDictionary * childIds = [NSMutableDictionary dictionary];

    for (GCActivity * one in _activities) {
        if( one.childIds.count > 0){
            for (NSString * childId in one.childIds) {
                [existingInService addObject:childId];
                BOOL foundInOrganizer = [organizer activityForId:childId] != nil;
                if(!foundInOrganizer){
                    childIds[childId] = one.activityId;
                }
            }
        }else if( [one.activityType isEqualToString:GC_TYPE_MULTISPORT]){
            // If it's a multispot and there are no childIds, then force load detail
            // for that activity
            childIds[one.activityId] = one.activityId;
        }
    }
    self.childIds = childIds.count > 0 ? childIds.allKeys : nil;

    _reachedExisting = 0;
    NSUInteger newActivitiesCount = 0;
    if (self.activities) {
        for (GCActivity * activity in _activities) {
            [existingInService addObject:activity.activityId];
            BOOL foundInOrganizer = [organizer activityForId:activity.activityId] != nil;
            if (foundInOrganizer) {
                _reachedExisting++;
            }
            if (!foundInOrganizer) {
                newActivitiesCount++;
            }
            [organizer registerActivity:activity forActivityId:activity.activityId];
        }
        RZLog(RZLogInfo, @"Found %lu new %lu existing out of %lu [%@-%@] for %@ (new total %d)",
              (unsigned long)newActivitiesCount,
              (unsigned long)self.reachedExisting,
              (unsigned long)self.activities.count,
              [self.activities.firstObject activityId],
              [self.activities.lastObject activityId],
              self.service.displayName,
              (int)[organizer countOfActivities]);
        
        // FIXME: check for deleted
        if (existingInService.count ) {
            NSArray * deleteCandidate = [organizer findActivitiesNotIn:existingInService isFirst:self.isFirst];

            // don't delete if didn't found last.
            if (deleteCandidate && deleteCandidate.count) {
                NSMutableArray * toTrash = [NSMutableArray arrayWithCapacity:deleteCandidate.count];
                for (NSString * one in deleteCandidate) {
                    // Only delete if it's coming from same service. Maybe redundant check?
                    if ([GCService serviceForActivityId:one].service == self.service.service){
                        [toTrash addObject:one];
                    }else{
                        RZLog(RZLogWarning, @"Attempt to delete an activity from different service: %@ from %@ and %@", one, [GCService serviceForActivityId:one], self.service);
                    }
                }
                if (toTrash.count>0) {
                    RZLog(RZLogWarning, @"Found %d activities to delete from %@", (int)[toTrash count], self.service.displayName);
                    organizer.activitiesTrash = toTrash;
                    [organizer deleteActivitiesInTrash];
                }
            }
            if (deleteCandidate == nil) {
                RZLog(RZLogError, @"didn't find last inorg=%d delete=%d ingc=%d",
                      (int)[organizer countOfActivities],
                      (int)[deleteCandidate count],
                      (int)[existingInService count]);
            }
        }
    }
}

@end
