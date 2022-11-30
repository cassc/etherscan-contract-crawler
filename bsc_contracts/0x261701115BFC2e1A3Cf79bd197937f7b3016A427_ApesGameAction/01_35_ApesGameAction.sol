// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract ApesGameAction is OwnableUpgradeable {
    IERC20Upgradeable public Token;
    mapping(bytes32 => bool) recordsTransfer;

    event Spent(address indexed sender, uint256 indexed amount);
    event Transfer(
        address indexed receiver,
        uint256 indexed amount,
        uint64 timestamp
    );

    function initialize(IERC20Upgradeable _token) public initializer {
        Token = _token;
        __Ownable_init();
    }

    function spend(uint256 _amount) public {
        require(_amount > 0, "amount too small");
        Token.transferFrom(msg.sender, address(this), _amount);
        emit Spent(msg.sender, _amount);
    }

    /// @notice Used to transfer peel token to '_to'
    /// @param _to Address of receiving peel token
    /// @param _amount peel token amount(wei)
    /// @param _timestamp transfer time (Recommended microseconds)
    /// @dev   _timestamp is the time to purchase Peel. '_to' and '_timestamp' will generate a unique hash to prevent repeated sending
    function transfer(
        address _to,
        uint256 _amount,
        uint64 _timestamp
    ) public onlyOwner {
        bytes32 hash_ = keccak256(abi.encodePacked(_to, _timestamp));
        require(!recordsTransfer[hash_], "record exists");
        Token.transfer(_to, _amount);
        recordsTransfer[hash_] = true;
        emit Transfer(_to, _amount, _timestamp);
    }
}