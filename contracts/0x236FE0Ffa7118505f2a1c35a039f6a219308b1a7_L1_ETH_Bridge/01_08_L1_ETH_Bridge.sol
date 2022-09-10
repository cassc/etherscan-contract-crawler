// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __                                             
 *     /      \           |       \ |  \                                            
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______  
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \ 
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *                                                                                  
 *                                                                                  
 *                                                                                  
 */
 
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./L1Loop.sol";

/**
 * @dev A L1Loop that uses an ETH as the canonical token
 */

contract L1_ETH_Bridge is L1Loop {
    constructor (address[] memory executors, address _governance) public L1Loop(executors, _governance) {}

    /* ========== Override Functions ========== */

    function _transferFromBridge(address recipient, uint256 amount) internal override {
        (bool success, ) = recipient.call{value: amount}(new bytes(0));
        require(success, 'L1_ETH_BRG: ETH transfer failed');
    }

    function _transferToBridge(address /*from*/, uint256 amount) internal override {
        require(msg.value == amount, "L1_ETH_BRG: Value does not match amount");
    }
}