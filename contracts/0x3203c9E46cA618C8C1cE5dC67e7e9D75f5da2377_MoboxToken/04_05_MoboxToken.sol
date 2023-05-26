// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ERC20.sol";
import "./Ownable.sol";

contract MoboxToken is ERC20, Ownable {
    address public moboxBridge;

    constructor() ERC20("Mobox", "MBOX", 18) {
    }

    modifier onlyBridge() {
        require(_msgSender() == moboxBridge, "not bridge");
        _;
    }

    /** 
     * Set the bridge contract, only the bridge contract can mint and burn MBOX
     */
    function setMoboxBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "invalid addr");
        moboxBridge = _bridge;
    }

    /** 
     * Mint MBOX by the bridge contract. An equal amount of MBOX will be frozen on the BNB Smart Chain. 
     */
    function mint(address _dst, uint256 _amount) external onlyBridge {
        require(_dst != address(0), "invalid addr");
        require(totalSupply() + _amount <= 1000000000e18, "invalid amount");
        _mint(_dst, _amount); 
    }

    /** 
     * Burn MBOX by the bridge contract. An equal amount of MBOX will be unfrozen on the BNB Smart Chain. 
     */
    function burn(uint256 amount_) external onlyBridge { 
        _burn(msg.sender, amount_);
    }
}
