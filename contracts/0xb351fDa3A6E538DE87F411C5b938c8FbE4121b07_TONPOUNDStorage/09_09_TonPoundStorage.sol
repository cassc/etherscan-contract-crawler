// SPDX-License-Identifier: MIT
//
// Smart-contract TonPound Storage

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TONPOUNDStorage is ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    //
    // Vars
    uint256 internal min_amount;
    IERC20 internal USDT;
    IERC20 internal USDC;
    //
    mapping(address => uint256) internal donation_amount;

    // Modifiers
    modifier CorrectAmount(uint256 _amount) {
    require(_amount > 0, 'Insufficient amount');
    _;
    }
 
    //
    constructor(uint256 _amount, IERC20 _USDT, IERC20 _USDC) {
        min_amount = _amount;
        USDT = _USDT;
        USDC = _USDC;
    }

    //
    // View, pure helpers functions
    // Get token address by id
    function getToken(uint256 _id) public view returns(IERC20 _address) {
        if (_id == 2) {
            _address = USDC;
        } else {
            _address = USDT;
        }
    }
    //
    function getDonationAmount(address _address) public view returns(uint256 _amount) {
        _amount = donation_amount[_address];
    }

    // Donate
    function Donate(uint256 select_token, uint256 _amount) CorrectAmount(_amount) external nonReentrant  {
        require(select_token == 1 || select_token == 2, 'Only 1 or 2 select_token available');
        require(_amount >= min_amount, 'Amount too low');
        _stake(getToken(select_token), _amount, _msgSender());
        _setDonateAmount(_msgSender(), _amount);
    }
    //
    // ADMIN Functions
    //
    function SetMinAmount(uint256 _amount) onlyOwner() CorrectAmount(_amount) external nonReentrant {
        min_amount = _amount;
    } 
    function Send(IERC20 _token, address _to, uint256 _amount) onlyOwner() CorrectAmount(_amount) external nonReentrant {
        _send(_token, _to, _amount);
    } 
    //
    // Internal functions
    //
    function _setDonateAmount(address _id, uint256 _amount) internal {
        donation_amount[_id] = donation_amount[_id].add(_amount);
    }
    //
    // TX functions
    // send tokens from contract
    function _send(IERC20 _token, address _to, uint256 _amount) internal {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Contract not enought token");

        SafeERC20.safeTransfer(_token, _to, _amount);
    }
    // Request payment
    function _stake(IERC20 token, uint256 _amount, address from) internal {
        require(IERC20(token).balanceOf(from) >= _amount, "User not enought token");
        uint256 allow_amount = IERC20(token).allowance(from, address(this));
        require(_amount <= allow_amount, "Not approved amount");

        SafeERC20.safeTransferFrom(token, from, address(this), _amount);
    }


}