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

import './DataStorage.sol';

contract Access is DataStorage {

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;  

  modifier isOwner(address _account) {
    require(owner == _account, "E3");
    _;
  }

  modifier isMember(address _account) {
    require(members[_account].id > 0, "E26");
    _;
  }

  modifier isExchangeHandler(address _account) {
    require(exchangeHandler == _account, "E3");
    _;
  }

  modifier isRemoteHandler(address _account) {
    require(remoteHandler == _account, "E3");
    _;
  }

  modifier contractEnabled() {
    require(contractStatus == true, "E1");
    _;
  }

  modifier remoteEnabled() {
    require(remoteStatus == true, "E1");
    _;
  }

  modifier contractMaintenance() {
    require(contractStatus == false, "E2");
    _;
  }

  modifier blockReEntry() {
    require(reEntryStatus != ENTRY_DISABLED, "E4");
    reEntryStatus = ENTRY_DISABLED;

    _;

    reEntryStatus = ENTRY_ENABLED;
  }

  function changeOwner(address _addr) external isOwner(msg.sender) {
    owner = _addr;

    assembly {
      sstore(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103, _addr) //keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
    }
  }
}