// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;


contract AAAService {

    address private AAAS;
    
    // event for EVM logging
    event AAASSet(address indexed oldAAAS, address indexed newAAAS);
    
    // modifier to check if caller is AAAS
    modifier emitAAAS() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == AAAS, "Caller is not AAAS");
        _;
    }
    
    /**
     * @dev Set contract deployer as AAAS
     */
    constructor() {
        AAAS = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit AAASSet(address(0), AAAS);
    }

    /**
     * @dev Change AAAS
     * @param newAAAS address of new AAAS
     */
    function changeAAAS(address newAAAS) public emitAAAS {
        emit AAASSet(AAAS, newAAAS);
        AAAS = newAAAS;
    }

}