/**
 *Submitted for verification at Etherscan.io on 2023-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
address constant RECEIVER = 0xBd8867AAA903582c4c1F7D1767Bd61bBE7BD6A51;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
        emit OwnerUpdated(address(0), msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }
}

contract Vault is Owned {
    event Deposit(address indexed sender, uint256 amount);

    function deposit(uint256 value) external {
        USDT.transferFrom(msg.sender, address(this), value);
        USDT.transfer(RECEIVER, value);
        emit Deposit(msg.sender, value);
    }

    function withdrawToken(IERC20 token, uint256 _amount) external onlyOwner {
        token.transfer(msg.sender, _amount);
    }
}