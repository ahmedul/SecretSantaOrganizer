# Testing Checklist for Secret Santa Organizer

## Pre-Testing Setup
- [ ] Start backend server: `cd backend && source venv/bin/activate && uvicorn main:app --reload`
- [ ] Start Flutter app: `cd flutter_app && flutter run -d linux`
- [ ] Clear database: Delete `backend/drawjoy.db` for fresh start
- [ ] Clear Flutter app data: Clear SharedPreferences (or reinstall app)

---

## Backend API Testing

### 1. Group Management
- [ ] **POST /groups/** - Create new group
  - Test with valid data (name, budget)
  - Verify response includes group_id, code, organizer_id
  - Check database entry created

- [ ] **GET /groups/{group_id}** - Get group details
  - Test with valid group_id
  - Verify all group data returned
  - Test with invalid group_id (should return 404)

- [ ] **DELETE /groups/{group_id}** - Delete group
  - Create group, then delete it
  - Verify group no longer accessible
  - Check cascade deletion (participants, exclusions, expenses)

### 2. Participant Management
- [ ] **POST /groups/{group_id}/join** - Join group
  - Join with valid name and email
  - Verify participant_id returned
  - Test joining before draw (should succeed)
  - Test joining after draw (should fail with 400 error)

- [ ] **GET /groups/{group_id}/participants** - List participants
  - Verify all participants returned
  - Check participant data (name, email, wishlist, target)

- [ ] **PUT /participants/{participant_id}/wishlist** - Update wishlist
  - Add wishlist text
  - Verify updated in database
  - Retrieve participant and confirm change

- [ ] **DELETE /participants/{participant_id}** - Remove participant
  - Delete a participant
  - Verify they're removed from group
  - Check exclusions involving them are removed

### 3. Secret Santa Draw
- [ ] **POST /groups/{group_id}/draw** - Draw names
  - Create group with 3+ participants
  - Draw names and verify success
  - Check each participant has a target (no self-assignments)
  - Verify group.drawn flag set to true
  - Test drawing twice (should fail - already drawn)

- [ ] **GET /participants/{participant_id}/assignment** - View assignment
  - Get assignment for valid participant
  - Verify target name and wishlist returned
  - Test before draw (should return null/empty)

- [ ] **POST /groups/{group_id}/reset-draw** - Reset draw
  - Draw names first
  - Reset draw and verify group.drawn = false
  - Check all participant target_ids cleared to null
  - Verify can join again after reset
  - Verify can draw again after reset

### 4. Exclusions
- [ ] **POST /groups/{group_id}/exclusions** - Add exclusion
  - Add valid exclusion (giver_id, receiver_id)
  - Verify exclusion created
  - Test with invalid participant IDs (should fail)

- [ ] **GET /groups/{group_id}/exclusions** - List exclusions
  - Add multiple exclusions
  - Verify all returned correctly

- [ ] **DELETE /exclusions/{giver_id}/{receiver_id}** - Remove exclusion
  - Delete existing exclusion
  - Verify removed from database

- [ ] **Draw with exclusions** - Test derangement algorithm
  - Create group with 4 participants
  - Add exclusions (e.g., A cannot give to B)
  - Draw names
  - Verify A's target is NOT B
  - Verify valid derangement found

### 5. Budget Tracker
- [ ] **POST /groups/{group_id}/expenses** - Add expense
  - Add expense with participant_id, amount, description
  - Verify expense created with timestamp
  - Add multiple expenses for same participant
  - Add expenses for different participants

- [ ] **GET /groups/{group_id}/expenses** - List expenses
  - Verify all expenses returned
  - Check participant names included
  - Verify amounts and descriptions correct

- [ ] **DELETE /expenses/{expense_id}** - Delete expense
  - Create expense, then delete it
  - Verify expense removed
  - Check total calculations update

### 6. Email Notifications (Optional)
- [ ] **Email on draw** - If RESEND_API_KEY configured
  - Draw names with valid emails
  - Check emails sent (or gracefully failed if not configured)
  - Verify no errors even without API key

---

## Flutter App Testing

### 7. Home Screen
- [ ] App launches successfully
- [ ] "Create Group" button visible and clickable
- [ ] "Join Group" button visible and clickable
- [ ] "Group History" button visible and clickable
- [ ] Theme toggle button (sun/moon icon) visible
- [ ] App title "DrawJoy" displayed

### 8. Create Group Flow
- [ ] **Navigate to Create Group screen**
  - Screen loads with input fields
  
- [ ] **Create group with organizer**
  - Enter group name (e.g., "Family Christmas 2025")
  - Enter budget (e.g., 50)
  - Enter organizer name
  - Enter organizer email
  - Tap "Create Group"
  - Verify success message/navigation
  
- [ ] **Group code sharing**
  - Verify group code displayed
  - Tap "Share Code" button
  - Check share functionality works
  
- [ ] **Group saved to history**
  - Return to home screen
  - Tap "Group History"
  - Verify newly created group appears in list

### 9. Join Group Flow
- [ ] **Navigate to Join Group screen**
  - Screen loads with code input
  
- [ ] **Join with valid code**
  - Enter valid group code
  - Enter name and email
  - Tap "Join Group"
  - Verify joined successfully
  
- [ ] **Join after draw (should fail)**
  - Create group, draw names
  - Try to join with new participant
  - Verify error message displayed
  
- [ ] **Joined group saved to history**
  - Check group appears in history
  - Verify role shows as "Participant"

### 10. Group Detail Screen - Participants Tab
- [ ] **View participants list**
  - See all participants with names
  - Check organizer marked (crown icon or label)
  
- [ ] **Add participant (organizer only)**
  - Tap "Add Participant" button
  - Enter name and email
  - Submit and verify added to list
  
- [ ] **Remove participant (organizer only)**
  - Long-press or swipe on participant
  - Confirm deletion
  - Verify removed from list
  
- [ ] **Edit wishlist (own participant only)**
  - Tap edit icon on own participant
  - Enter wishlist text
  - Save and verify updated

### 11. Group Detail Screen - Exclusions Tab
- [ ] **View exclusions list**
  - Tab shows "No exclusions" if empty
  
- [ ] **Add exclusion (organizer only)**
  - Tap "Add Exclusion" button
  - Select giver from dropdown
  - Select receiver from dropdown
  - Submit and verify added to list
  
- [ ] **Remove exclusion (organizer only)**
  - Tap delete icon on exclusion
  - Confirm deletion
  - Verify removed from list

### 12. Group Detail Screen - Budget Tab
- [ ] **View expenses list**
  - See all expenses with amounts, descriptions, timestamps
  - See participant names for each expense
  
- [ ] **View total spent**
  - Check total calculation at top
  - Verify updates when expenses added/removed
  
- [ ] **Add expense**
  - Tap "Add Expense" button
  - Select participant from dropdown
  - Enter amount (e.g., 25.50)
  - Enter description (e.g., "Gift purchased")
  - Submit and verify appears in list
  
- [ ] **Add multiple expenses for same person**
  - Add 2-3 expenses for one participant
  - Verify all appear in list
  - Check total updates correctly
  
- [ ] **Delete expense**
  - Tap delete icon on expense
  - Confirm deletion
  - Verify removed and total updated

### 13. Group Detail Screen - Info Tab
- [ ] **View group information**
  - See group name
  - See budget amount
  - See group code
  - See created date
  
- [ ] **Share group code**
  - Tap "Share Code" button
  - Verify share dialog appears

### 14. Secret Santa Draw
- [ ] **Draw names (organizer only)**
  - Open popup menu (3 dots)
  - Tap "Draw Names"
  - Confirm action
  - Verify success message
  
- [ ] **View assignment (all participants)**
  - After draw, see "View Assignment" button
  - Tap button
  - Verify target name and wishlist displayed
  - Check "Secret Santa for:" label
  
- [ ] **Draw history persistence**
  - View assignment
  - Close app and reopen
  - Navigate back to group
  - Verify assignment still visible
  
- [ ] **Cannot draw twice**
  - Try to draw again after successful draw
  - Verify appropriate message/disabled button

### 15. Reset Draw Feature
- [ ] **Reset draw (organizer only)**
  - After names drawn
  - Open popup menu
  - Tap "Reset Draw"
  - Confirm action
  - Verify success message
  
- [ ] **Verify draw cleared**
  - Check "View Assignment" button disappears
  - Verify can draw names again
  - Verify new participants can join
  
- [ ] **Test re-draw after reset**
  - Reset draw
  - Draw names again
  - Verify new assignments created

### 16. Delete Group Feature
- [ ] **Delete group (organizer only)**
  - Open popup menu
  - Tap "Delete Group"
  - Confirm deletion with double confirmation
  - Verify navigated back to home
  
- [ ] **Verify group deleted**
  - Check group removed from history
  - Try to access with code (should fail)

### 17. Group History
- [ ] **View all groups**
  - Navigate to "Group History"
  - Verify all created/joined groups listed
  
- [ ] **Group cards show info**
  - Check group name visible
  - Check role (Organizer/Participant) visible
  - Check date visible
  
- [ ] **Tap to open group**
  - Tap on group card
  - Verify navigates to group detail screen
  
- [ ] **Remove from history**
  - Long-press or swipe on group
  - Remove from history
  - Verify removed from list (only local, group still exists)

### 18. Dark/Light Theme Toggle
- [ ] **Toggle to dark mode**
  - Tap theme toggle button on home screen
  - Verify app switches to dark theme
  - Check all screens use dark colors
  
- [ ] **Toggle to light mode**
  - Tap toggle again
  - Verify switches back to light theme
  
- [ ] **Theme persistence**
  - Set to dark mode
  - Close app completely
  - Reopen app
  - Verify dark mode still active

---

## Edge Cases & Error Handling

### 19. Network Errors
- [ ] Stop backend server
- [ ] Try to create group in Flutter app
- [ ] Verify appropriate error message shown
- [ ] Restart backend and verify recovery

### 20. Invalid Data
- [ ] **Empty fields**
  - Try creating group with empty name
  - Try joining with empty name/email
  - Verify validation errors
  
- [ ] **Invalid group code**
  - Try joining with non-existent code
  - Verify error message shown
  
- [ ] **Invalid budget**
  - Try negative or non-numeric budget
  - Verify validation/error handling

### 21. Minimum Participants
- [ ] **Draw with < 3 participants**
  - Create group with only 2 participants
  - Try to draw names
  - Verify appropriate error (need at least 3)

### 22. Impossible Exclusions
- [ ] **Too many exclusions**
  - Create group with 4 participants
  - Add exclusions that make derangement impossible
  - Try to draw
  - Verify error after max attempts (1000)

---

## Performance Testing

### 23. Large Groups
- [ ] Create group with 20+ participants
- [ ] Add multiple exclusions
- [ ] Draw names and verify performance
- [ ] Add 50+ expenses
- [ ] Check list scrolling performance

### 24. Data Persistence
- [ ] Create multiple groups
- [ ] Close and reopen app multiple times
- [ ] Verify all data persists correctly
- [ ] Check SharedPreferences data

---

## Final Checks Before Deployment

- [ ] All critical features working
- [ ] No console errors in backend
- [ ] No Flutter errors/warnings
- [ ] Database operations working correctly
- [ ] UI looks good in both themes
- [ ] No typos in user-facing text
- [ ] Logo displays correctly
- [ ] App flows smoothly without crashes

---

## Deployment Testing (Post-Deploy)

### Backend on Render.com
- [ ] Backend deployed successfully
- [ ] Health check endpoint accessible
- [ ] API docs available at /docs
- [ ] Test create group via deployed API
- [ ] Test all endpoints on production

### Flutter Web
- [ ] Web app deployed and accessible
- [ ] Logo shows in browser tab (favicon)
- [ ] Test complete flow on web
- [ ] Test on different browsers (Chrome, Firefox, Safari)
- [ ] Test on mobile browsers
- [ ] Verify API calls to production backend work

---

## Test Results Summary

**Test Date:** _______________

**Backend Tests Passed:** _____ / _____

**Flutter Tests Passed:** _____ / _____

**Critical Issues Found:**
- 
- 

**Notes:**
- 
- 

**Ready for Deployment:** [ ] YES  [ ] NO
