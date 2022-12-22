//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract OfframpReceiver is AccessControl {
    bytes32 public constant WITHDRAWABLE_ROLE = keccak256("WITHDRAWABLE_ROLE");

    constructor()  {
        _grantRole(WITHDRAWABLE_ROLE, msg.sender);
    }

    event FallbackCalled(uint _amount);
    event Received(address, uint);
    
    function withdrawErc20(address token, uint256 amount) public onlyRole(WITHDRAWABLE_ROLE) {
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdrawNative(uint256 amount) public onlyRole(WITHDRAWABLE_ROLE) {
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent == true);
    }

    fallback() external payable {
        emit FallbackCalled(msg.value);
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    
}