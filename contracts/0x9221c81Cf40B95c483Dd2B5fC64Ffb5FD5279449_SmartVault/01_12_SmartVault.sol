// SPDX-License-Identifier: MIT
/*
Smart Vault - safe smart contract
(c) 2022 Ethernal Labs, Inc.
Author: [email protected]
Smart Vault that holds funds and allows several wallets to have access to its funds,
and includes security mechanisms to minimize losses in case of hack, scams, etc.
*/
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SmartVault is Ownable, AccessControl, ReentrancyGuard {

    bool public debug;
    uint public pauseHours = 24;  // Pause interval from performing an operation 
    uint public timestamp = 1663693200;  // seteable timestamp for debug 9/19
    mapping(address => uint) public actions;
    uint256 public maxTokens;  // Max ERC20 tokens per day allowance (without decimals)
    uint256 public maxEth; // Max ETH per day allowance (without decimals)
    uint public wallets;
    bytes32 private adminRole = bytes32(
        0x0000000000000000000000000000000000000000000000000000000000000000
    );

    event ActionTaken(address indexed _fromWallet, string _action);

    /// @notice Contract constructor
    /// @param _maxTokens Max ERC20 tokens allowed to be withdrawn
    /// @param _maxEth Max ETH allowed to be withdrawn each time
    /// @param _pauseHours Pause wallet for these hours after an operation
    /// @param _debug Debug flag - set to false in prod
    constructor(uint256 _maxTokens, uint256 _maxEth, uint _pauseHours, bool _debug) {
        maxTokens = _maxTokens;
        maxEth = _maxEth;
        pauseHours = _pauseHours;
        debug = _debug;
        _grantAdminRole(msg.sender);
        actions[msg.sender] = timeNow();  // Deployer becomes authorized wallet
        wallets += 1;
    }

    /// @notice Modifier to check wallet is allowed to operate
    modifier onlyAuthAction() {
        uint _lastAction = actions[msg.sender];
        uint _interval = pauseHours * 3600;
        require(_lastAction > 0, "Wallet not registered for withdrawals");
        require(
            _lastAction + pauseHours <= timeNow(),
            "Cannot perform any action, need to wait [pauseHours]"
        );
        _;
    }

    /// @notice Internal function to grant admin role
    /// @param _wallet Wallet address to grant admin role to
    function _grantAdminRole(address _wallet) private {
        _setupRole(
            adminRole,
            _wallet
        );
    }

    /// @notice Withdraw ETH
    /// @param _walletTo Address to withdraw ETH to
    /// @param _amount ETH amount to withdraw
    function withdrawEth(
        address payable _walletTo, uint256 _amount
    ) external onlyAuthAction nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount <= maxEth * 10**18, "Cannot withdraw more than maxEth");
        _walletTo.transfer(_amount);
        actions[msg.sender] = timeNow();
        emit ActionTaken(msg.sender, "Withdrawn ETH");
    }

    /// @notice Withdraw ERC20 tokens
    /// @param _tokenAddress ERC20 token address. Needs to be OpenZeppelin compatible
    /// @param _walletTo Address to withdraw tokens to
    /// @param _amount Raw amount (amount * 10^[token decimals]) to withdraw
    function withdrawTokens(
        address _tokenAddress, address _walletTo, uint256 _amount
    ) external onlyAuthAction nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC20 _token = ERC20(_tokenAddress);
        uint256 _balance = _token.balanceOf(address(this));
        require(_amount <= _balance, "Not enough tokens in balance");
        require(
            _amount <= maxTokens * 10**_token.decimals(), "Cannot withdraw more than maxTokens"
        );
        _token.transfer(_walletTo, _amount);
        actions[msg.sender] = timeNow();
        emit ActionTaken(msg.sender, "Withdrawn tokens");
    }

    /// @notice Returns total token balance
    /// @param _tokenAddress ERC20 token address
    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        ERC20 _token = ERC20(_tokenAddress);
        return _token.balanceOf(address(this));
    }

    /// @notice Authorizes a wallet to operate with the smart vault
    /// @param _wallet Authorized wallet address
    function authorizeWallet(address _wallet) external onlyAuthAction onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantAdminRole(_wallet);
        actions[_wallet] = timeNow();
        actions[msg.sender] = timeNow();
        emit ActionTaken(msg.sender, "Authorized wallet");
    }

    /// @notice Removes an authorized wallet
    /// @param _wallet Authorized wallet address
    function removeWallet(address _wallet) external onlyAuthAction onlyRole(DEFAULT_ADMIN_ROLE) {
        require(wallets >= 1, "At least 1 wallet needs to be authorized");
        require(_wallet != msg.sender, "Cannot remove self");
        _revokeRole(
            adminRole,
            _wallet
        );
        actions[_wallet] = 0;
        emit ActionTaken(msg.sender, "Removed wallet");
    }

    /// @notice Set timestamp for debugging
    /// @param _timestamp Epoch time in seconds
    function setNow(uint _timestamp) public onlyOwner {
        timestamp = _timestamp;
    }

    /// @notice Timestamp function enhanced for debugging
    function timeNow() public view returns (uint) {
        if (debug) {
            return timestamp;
        } else {
            return block.timestamp;
        }
    }

    /// @notice Interface override
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

}