// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './JupiterNFT.sol';

/**
 * @dev Used to define a list of address allowed to mint.
 * Can be disabled to ignore the list.   
 */
abstract contract AllowList is JupiterNFT {
    // mapping that defines is the wallet is allowed or not
    mapping(address => bool) public isAllowed;

    bool private _isActive;

    constructor () {
        // by default the allow list is active, meaning no address is allowed to mint until setAllowList is called.
        _isActive = true;
    }

    /**
     *  @dev allows the operator to define the list of addresses allowed to mint
     * all addresses are initialized to true
     */
    function setAllowList(address[] calldata addresses) external {
        require(operators[msg.sender], "only operators");
        for (uint256 i = 0; i < addresses.length; i++) {
            isAllowed[addresses[i]] = true;
        }
    }

    /**
     * @dev allows an operator to modify or add a single address.
     */
    function setAllowListAddress(address _address, bool _allowed) external {
        require(operators[msg.sender], "only operators");
        isAllowed[_address] = _allowed;
    }

    /**
     * allows an operator to define if the allow list validation is active or not.
     */
    function setIsAllowListActive(bool isActive) external  {
        require(operators[msg.sender], "only operators");
        _isActive = isActive;
    }
    
    
    function isAllowListActive() public view returns(bool) {
        return _isActive;
    }
}