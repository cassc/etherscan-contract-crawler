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

import './Storage.sol';

contract UUPS {

  function _getImplementation() internal view returns (address) {
    return Storage.getAddress(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc).value; //keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
  }

  function _upgradeTo(address _implement) internal {
    assembly {
      sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _implement) //keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    }
  }

  function upgradeTo(address _implement) external {    
    require(Storage.getAddress(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103).value == msg.sender, "E3"); //keccak-256 hash of "eip1967.proxy.admin" subtracted by 1

    address oldImplementation = _getImplementation();

    _upgradeTo(_implement);
    
    Storage.BooleanStorage storage rollbackActive = Storage.getBoolean(0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143); //keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1

    if (rollbackActive.value == false) {
      rollbackActive.value = true;

      (bool success, ) = _implement.delegatecall(abi.encodeWithSignature("upgradeTo(address)", oldImplementation));
      
      require(success, "E25");
      
      rollbackActive.value = false;
      
      require(oldImplementation == _getImplementation(), "E25");
              
      _upgradeTo(_implement);
    }
  }
}