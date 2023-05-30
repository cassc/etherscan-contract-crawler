// SPDX-License-Identifier: No License
// /**
//  * @title Vendor Generic Lending Pool Implementation
//  * @author 0xTaiga
//  * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
//  */

// /**
// TO-DO:
// TODO:- Reentrancy check
// TODO:- PAusable
// TODO: Factory setter
//  */

pragma solidity ^0.8.11;
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IPoolFactory} from "../interfaces/IPoolFactory.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStrategy.sol";

contract Vendor4626Strategy is IStrategy, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC4626 public immutable vault;
    IPoolFactory public immutable factory;

    constructor(address _vault, address _factory) {
        vault = IERC4626(_vault);
        factory = IPoolFactory(_factory);
    }

    ///@notice              Destination strategy that the token is going to. 
    ///@return              Strategy contract address.
    function getDestination() external view override returns (address){
        return address(vault);
    }

    ///@notice              Current balance of the given token that we can currently withdraw back to the pool. 
    ///@return              Withdrawable balance.
    function currentBalance() external view override returns (uint256){
        return vault.maxWithdraw(msg.sender);
    }

    ///@notice              Withdraw the funds from the vault into the pool. 
    ///@param _amount       Exact amount of lend tokens to withdraw. When uint256 max passed all shares are redeemed.
    ///@dev                 Pool shares will be burned without any transfers since the approval was given to this contract.
    ///                     Lend funds will be going directly to the pool.
    function beforeLendTokensSent(uint256 _amount) external {
        _withdraw(_amount);
    }

    ///@notice              Deposit the funds from the pool into the vault. 
    ///@param _amount       Exact amount of lend tokens to deposit.
    ///@dev                 Pool will get the shares directly bypassing this contract since it is mentioned as receiver.
    function afterLendTokensReceived(uint256 _amount) external {
        _deposit(_amount);
    }

    ///@notice              Withdraw the funds from the vault into the pool. 
    ///@param _amount       Exact amount of col tokens to withdraw. When uint256 max passed all shares are redeemed.
    ///@dev                 Pool shares will be burned without any transfers since the approval was given to this contract.
    ///                     Lend funds will be going directly to the pool.
    function beforeColTokensSent(uint256 _amount) external {
        _withdraw(_amount);
    }

    ///@notice              Deposit the funds from the pool into the vault. 
    ///@param _amount       Exact amount of col tokens to deposit.
    ///@dev                 Pool will get the shares directly bypassing this contract since it is mentioned as receiver.
    function afterColTokensReceived(uint256 _amount) external {
        _deposit(_amount);
    }

    ///@notice              Contains logic covering the beforeTokensSent cases.
    ///@param _amount       Exact amount of tokens to withdraw. When uint256 max passed all shares are redeemed.
    ///@dev                 Logic is split from calling functions to eliminate repeat code while maintaining a standard interface.
    function _withdraw(uint256 _amount) private nonReentrant whenNotPaused {
        if (!factory.pools(msg.sender)) revert NotAPool(); //This is not required but will prevent others from using this contract outside Vendor
        if (_amount == type(uint256).max){
            vault.redeem(vault.balanceOf(msg.sender), msg.sender, msg.sender);
        }else{
            vault.withdraw(_amount, msg.sender, msg.sender);
        }
    }

    ///@notice              Contains logic covering the afterTokensReceived cases.
    ///@param _amount       Exact amount of tokens to deposit.
    ///@dev                 Logic is split from calling functions to eliminate repeat code while maintaining a standard interface.
    function _deposit(uint256 _amount) private nonReentrant whenNotPaused {
        if (!factory.pools(msg.sender)) revert NotAPool(); //This is not required but will prevent others from using this contract
        IERC20 asset = IERC20(vault.asset());
        asset.safeTransferFrom(msg.sender, address(this), _amount);
        asset.approve(address(vault), _amount);
        vault.deposit(_amount, msg.sender);
    }

    ///@notice                  Pause the strategy contract.
    ///@param _pauseEnable      If true, will pause the contract.
    function setPause(bool _pauseEnable) external onlyOwner {
        if (_pauseEnable) {
            _pause();
        } else {
            _unpause();
        }
    }

}