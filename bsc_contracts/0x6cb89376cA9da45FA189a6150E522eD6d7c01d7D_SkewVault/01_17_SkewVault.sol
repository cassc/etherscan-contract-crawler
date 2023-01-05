/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDODO} from "./intf/IDODO.sol";
import {IERC20} from "./intf/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IvBEP20} from "./intf/IvBEP20.sol";
import {IUnitroller} from "./intf/IUnitroller.sol";
import {ISToken} from "./intf/ISToken.sol";
import "hardhat/console.sol";


contract SkewVault is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_AMOUNT = 2**256-1;
    uint256 public constant exchangeDecimal = 10**6;

    address public vaultToken;
    ISToken sToken;
    uint256 public totalDeposit;
    uint256 public totalReward;
    uint256 public minWithdrawAmount;
    uint256 public totalFastWithdrawAmount;
    uint256 public totalNormalWithdrawAmount;

    mapping(address=>uint256) public fastWithdrawalQueue;
    mapping(address=>uint256) public normalWithdrawalQueue;
    mapping(address=>uint256) public depositInfo;
    address[] fastWithdrawUsers;
    address[] normalWithdrawUsers;

    constructor(address _token, address _sToken, uint256 _minWithdrawAmount) {
        vaultToken = _token;
        sToken = ISToken(_sToken);
        minWithdrawAmount = _minWithdrawAmount;
    }

    function setMinWithdrawAmount(uint256 _newMinWithdrawAmount) external onlyOwner {
        minWithdrawAmount = _newMinWithdrawAmount;
    }

    function deposit(uint256 _amount) external {
        IERC20(vaultToken).transferFrom(msg.sender, address(this),_amount);

        depositInfo[msg.sender] += _amount;
        uint256 mintAmount = getsTokenAmount(_amount);
        sToken.mint(_msgSender(), mintAmount);
        totalDeposit += _amount;
    }


    function depositReward(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transferFrom(msg.sender, address(this),_amount);     
        totalReward += _amount;
    }

    function getExchangeRate() public view returns(uint256) {
        if(totalDeposit == 0) return exchangeDecimal;
        return (totalDeposit+totalReward)*exchangeDecimal/totalDeposit;
    }

    function getsTokenAmount(uint256 _amount) public view returns(uint256) {
        return _amount * exchangeDecimal / getExchangeRate();
    }

    function getAssetAmount(uint256 _amount) public view returns(uint256) {
        return _amount * getExchangeRate() / exchangeDecimal;
    }

    function withdrawUnderlying(
        uint256 _amount,             //asset amount
        bool _bFast
    ) external {
        //burn sToken
        uint256 sTokenAmount = getsTokenAmount(_amount);
        sToken.burnFrom(_msgSender(), sTokenAmount);
        require(_amount >= minWithdrawAmount, "amount should bigger than minWithdraw");
        // add to queue
        if( _bFast ) {
            if(fastWithdrawalQueue[_msgSender()] == 0 ) {
                fastWithdrawUsers.push(_msgSender());
            }
            fastWithdrawalQueue[_msgSender()] += _amount;
            totalFastWithdrawAmount += _amount;
        }
        else {
            if(normalWithdrawalQueue[_msgSender()] == 0 ) {
                normalWithdrawUsers.push(_msgSender());
            }
            normalWithdrawalQueue[_msgSender()] += _amount;
            totalNormalWithdrawAmount += _amount;
        }
    }

    function withdraw( 
        uint256 _amount,             //sToken amount
        bool _bFast
    ) external {
        sToken.burnFrom(_msgSender(), _amount);
        uint256 assetAmount = getAssetAmount(_amount);
        require(assetAmount >= minWithdrawAmount, "amount should bigger than minWithdraw");
        // add to queue
        if( _bFast ) {
            if(fastWithdrawalQueue[_msgSender()] == 0 ) {
                fastWithdrawUsers.push(_msgSender());
            }
            fastWithdrawalQueue[_msgSender()] += assetAmount;
            totalFastWithdrawAmount += assetAmount;
        }
        else {
            if(normalWithdrawalQueue[_msgSender()] == 0 ) {
                normalWithdrawUsers.push(_msgSender());
            }
            normalWithdrawalQueue[_msgSender()] += assetAmount;
            totalNormalWithdrawAmount += assetAmount;
        }
    }

    function botWithdraw(uint256 _amount) external onlyOwner {
        IERC20(vaultToken).transfer( _msgSender(), _amount);
    }

    function botDeposit(uint256 _amount) external onlyOwner {
        IERC20(vaultToken).transferFrom(_msgSender(), address(this),_amount);
    }

    function fastWithdraw() external onlyOwner {
        require(totalFastWithdrawAmount > 0, "nothing to withdraw");
        uint256 balance = IERC20(vaultToken).balanceOf(address(this));
        require(totalFastWithdrawAmount >= balance, "not enough balance");
        uint256 length = fastWithdrawUsers.length;
        for(uint256 i = 0; i < length; i++) {
            address user = fastWithdrawUsers[i];
            uint256 amount = fastWithdrawalQueue[user];
            IERC20(vaultToken).transfer( user, amount);
            delete fastWithdrawalQueue[user];
        }
        delete fastWithdrawUsers;
    }

    function normalWithdraw() external onlyOwner {
        require(totalNormalWithdrawAmount > 0, "nothing to withdraw");
        uint256 balance = IERC20(vaultToken).balanceOf(address(this));
        require(totalNormalWithdrawAmount >= balance, "not enough balance");
        uint256 length = normalWithdrawUsers.length;
        for(uint256 i = 0; i < length; i++) {
            address user = normalWithdrawUsers[i];
            uint256 amount = normalWithdrawalQueue[user];
            IERC20(vaultToken).transfer( user, amount);
            delete normalWithdrawalQueue[user];
        }
        delete normalWithdrawUsers;        
    }

    function updateSTokenAddress(address _sToken) public onlyOwner{
        sToken = ISToken(_sToken);
    }
}