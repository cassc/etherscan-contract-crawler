// SPDX-License-Identifier: BSD-3-Clause

/**
 *  
 *         ##### ##                                                                         
 *      ######  /###                                                                        
 *     /#   /  /  ###                                                                       
 *    /    /  /    ###                                                                      
 *        /  /      ##                                                                      
 *       ## ##      ## ###  /###     /###     /###      /###     /##  ###  /###             
 *       ## ##      ##  ###/ #### / / ###  / / #### /  / ###  / / ###  ###/ #### /          
 *     /### ##      /    ##   ###/ /   ###/ ##  ###/  /   ###/ /   ###  ##   ###/           
 *    / ### ##     /     ##       ##    ## ####      ##    ## ##    ### ##                  
 *       ## ######/      ##       ##    ##   ###     ##    ## ########  ##                  
 *       ## ######       ##       ##    ##     ###   ##    ## #######   ##                  
 *       ## ##           ##       ##    ##       ### ##    ## ##        ##                  
 *       ## ##           ##       ##    ##  /###  ## ##    ## ####    / ##            n n n 
 *       ## ##           ###       ######  / #### /  #######   ######/  ###           u u u 
 *  ##   ## ##            ###       ####      ###/   ######     #####    ###          m m m 
 * ###   #  /                                        ##                               b b b 
 *  ###    /                                         ##                               e e e 
 *   #####/                                          ##                               r r r 
 *     ###                                            ##                              3 6 5 
 * 
 * Prosper 365 is the very first 100% sponsor matching bonus smart contract ever created.
 * https://www.prosper365.io
 * It’s Time To Learn, Earn, and Prosper 365!
 */

pragma solidity 0.8.17;

contract Events {
  event Registration(address indexed member, uint memberId, address sponsor, uint accountType, uint orderId);  
  event Upgrade(address indexed member, address sponsor, uint package, uint accountType, uint orderId);

  event AccountChange(address indexed member, uint accountType, uint orderId);
  event Passup(address indexed member, address passupFrom, uint package, uint orderId);

  event Placement(address indexed member, address sponsor, uint package, uint matrixNum, uint position, address placedUnder, bool cycle, uint orderId);
  event PlacementReEntry(address indexed member, address reEntryFrom, uint package, uint orderId);

  event Cycle(address indexed member, address fromPosition, uint package, uint cycleId, uint orderId);

  event CommissionTierUnpaid(address indexed member, address commissionFrom, uint package, uint amount, uint orderId);
  event CommissionBonusMatch(address indexed member, address commissionFrom, uint package, uint amount, uint orderId);
  event CommissionMatrix(address indexed member, address commissionFrom, uint package, uint amount, uint orderId);
      
  event PassupMatrix(address indexed member, address passupFrom, uint package, uint amount, uint orderId);
}