// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NmsMigrate is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public oldNMS;
    address public newNMS;

    constructor( address _oldNMS, address _newNMS ) {
        oldNMS = _oldNMS;
        newNMS = _newNMS;
    }

    function migrateNMS(uint _amount ) external {
        IERC20( oldNMS ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( newNMS ).safeTransfer( msg.sender, _amount );
    }

    function setAddresses( address _oldNMS, address _newNMS ) external onlyOwner {
        oldNMS = _oldNMS;
        newNMS = _newNMS;
    }

    function withdrawTokens( address _token) external onlyOwner {
        uint _amount = IERC20( _token ).balanceOf( address(this) );
        IERC20( _token ).safeTransfer( owner(), _amount );
    }
}