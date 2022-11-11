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

contract DataStorage {
  /**
   * ERROR CODES:
   * E1: Closed For Maintenance
   * E2: Require Closed For Maintenance!
   * E3: Restricted Access!
   * E4: Security Block
   * E5: Compute error!
   * E6: Compute error 2!
   * E7: Exchange Issue
   * E10: Check price point!
   * E11: Invalid package.
   * E12: Transfer Failed
   * E13: Already Processed!
   * E14: Already Initiated!
   * E15: Invalid account type
   * E16: Invalid amount transferred!
   * E20: Valid account/package required!
   * E21: Sponsor dont exist!
   * E22: Already a member!
   * E23: Already active at package!
   * E24: Check percentage
   * E25: UUPS Fallback Safety
   * E26: Blockchain Sync Issue
   * E27: Blockchain Sync Issue
   * E28: Blockchain Sync Issue
   */

  struct Account {
    uint id;
    uint accountType;
    address sponsor;
    address payoutTo;
    mapping(uint => bool) ownPackage;
    mapping(uint => F1) x22Positions;
  }

  struct F1 {
    uint timestamp;
    uint matrixNum;
    uint position;
    uint depth;
    uint lastPlacedPosition;
    uint lastCycleId;
    uint reEntryCheck;
    uint[] rows;
    bool cycleInitiated;
    address sponsor;
    mapping(uint => uint) placedCount;
    mapping(uint => mapping(uint => F1Placement)) placedUnder;
    mapping(uint => address) x22Matrix;
  }

  struct F1Placement {
    uint timestamp;
    address under;
    uint placementSide;
  }

  struct Payout {
    uint amount;
    address receiver;
  }

  struct Row {
    uint start;
    uint end;
    uint total;
  }
  
  struct Package {
    uint cost;
    uint tierUnpaid;
    uint system;    
    uint matrix;
    uint matchBonus;
  }

  uint internal constant TYPE_MEMBER = 1;
  uint internal constant TYPE_AFFILIATE = 2;
  uint internal constant REENTRY_REQ = 3;
  
  uint internal lastId;
  uint internal orderId;
  uint internal cycleId;
  uint internal topPackage;
  uint internal reEntryStatus;

  uint internal exchangeRate;
  uint internal exchangeRateUpdated;
  uint internal exchangeRateTimeout;
  uint internal exchangeRatePrevious;
  
  bool internal payoutEnabled;
  bool internal remoteStatus;
  bool internal contractStatus;
  address internal owner;
  address internal prosper365Contract;
  address internal remoteHandler;
  address internal systemReceiver;
  address internal exchangeHandler;

  mapping(uint => Row) internal matrixRow;
  mapping(uint => address) internal idToMember;
  mapping(address => Account) internal members;
  mapping(uint => Package) internal packageCost;
}