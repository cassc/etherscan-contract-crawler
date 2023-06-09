// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ChadsToken.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Pool is ERC20, ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20;
    using SafeERC20 for ChadsToken;
    using EnumerableSet for EnumerableSet.AddressSet;

    ChadsToken public token;
    EnumerableSet.AddressSet private _users;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event WithdrawStatus(bool enabled);
    event DepositStatus(bool enabled);

    error DepositDisabled();
    error WithdrawDisabled();
    error NotInStakingPhase();
    error StakingPeriodEnded();
    error NotInClaimPhase();
    error NotInSwapPhase();
    error NotInWithdrawPhase();
    error NotAllowedToTransfer(address from);
    error NowAllowedToRecoverThisToken();

    bool public IsWithdrawEnabled = false;
    bool public IsDepositEnabled = false;
    mapping (address => bool) public allowTransfer;

    constructor(address payable _token, string memory name, string memory symbol)
    ERC20(name, symbol)
    {
        token = ChadsToken(_token);
        allowTransfer[msg.sender] = true;
    }
    function recover(address tokenAddress, address to) external onlyOwner {
        if (tokenAddress == address(this) || tokenAddress == address(token) )
            revert NowAllowedToRecoverThisToken();
        IERC20 _token = IERC20(tokenAddress);
        _token.transfer(to, _token.balanceOf(address(this)));
        payable(to).transfer(address(this).balance);
    }

    // only controller can transfer tokens
    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/ ) internal view override {
        // only allow transfer from controller or if we are minting or burning:
        // should allow when burning or minting:
        if (allowTransfer[msg.sender] == false && from != address(0) && to != address(0) ) {
            revert NotAllowedToTransfer(msg.sender);
        }
    }

    function deposit(address user, uint _amount) external onlyOwner {

        if( !IsDepositEnabled )
            revert DepositDisabled();

        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after - _before; // Additional check for deflationary tokens

        _mint(user, _amount);

        _users.add(user);

        emit Deposit(user, _amount);
    }

    function withdrawFromController(address user) external onlyOwner {
        _withdraw(user, balanceOf(user));
    }

    function withdraw() external nonReentrant {
        // for safety reasons only, use withdraw from controller,
        // to allow reward collection.
        _withdraw(msg.sender, balanceOf(msg.sender));
    }

    function _withdraw(address user, uint _amount) internal {

        if (!IsWithdrawEnabled)
            revert WithdrawDisabled();

        token.safeTransfer(user, _amount);
        _burn(user, _amount);

        if( balanceOf(address(this)) == 0 )
            _users.remove(user);

        emit Withdraw(user, _amount);
    }

    // TODO: check if necessary
    function setDepositEnabled(bool status) external onlyOwner {
        IsDepositEnabled = status;
        emit DepositStatus(IsDepositEnabled);
    }
    function setWithdrawStatus(bool status) external onlyOwner {
        IsWithdrawEnabled = status;
        emit WithdrawStatus(IsWithdrawEnabled);
    }

    function usersLength() external view returns (uint256) {
        return _users.length();
    }
    function getUserAt(uint256 index) external view returns (address) {
        return _users.at(index);
    }

    struct PoolInfo {
        uint256 totalSupply;
        uint256 balanceOfUser;
        uint256 totalUsers;
        bool IsDepositEnabled;
        bool IsWithdrawEnabled;
        string symbol;
    }
    // get pool info:
    function getPoolInfo(address user) external view returns (PoolInfo memory poolInfo) {
        poolInfo.totalSupply = totalSupply();
        poolInfo.balanceOfUser = balanceOf(user);
        poolInfo.totalUsers = _users.length();
        poolInfo.IsDepositEnabled = IsDepositEnabled;
        poolInfo.IsWithdrawEnabled = IsWithdrawEnabled;
        poolInfo.symbol = symbol();
    }

}