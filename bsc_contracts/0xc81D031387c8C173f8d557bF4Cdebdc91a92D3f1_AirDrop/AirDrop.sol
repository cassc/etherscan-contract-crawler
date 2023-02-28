/**
 *Submitted for verification at BscScan.com on 2023-02-27
*/

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function transferFrom(address owner , address recipient,uint256 amount)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract AirDrop {
    address public owner;

        address public tokenAddress;
        uint256 public totalAmount;
        uint256 public totalClaimed;
        uint256 public totalUsers;
        uint256 public airDropAmount;

    struct User {
        address  userAddress;
        uint256  amount;
        bool claimed;
        bool isWhitelisted;
        bool airDropClaimed;
    }

     mapping(address => User) public users;

    constructor(address _tokenAddress) {
        owner = 0x754ddA1A30F4e2d8aDDcDf7A254298e365224273;
        tokenAddress = _tokenAddress;
        airDropAmount = 10_000 ether;
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function airDrop(
        address[] memory _users
    ) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]].amount = airDropAmount;
            users[_users[i]].userAddress = _users[i];
            users[_users[i]].isWhitelisted = true;
            users[_users[i]].claimed = false;
            totalAmount += airDropAmount;
            totalUsers += 1;
        }
    }


    function claim() public {
        require(
            users[msg.sender].isWhitelisted,
            "You are not whitelisted"
        );
        require(
            !users[msg.sender].claimed,
            "You have already claimed"
        );
        {
            IERC20(tokenAddress).transferFrom(
                owner,
                msg.sender,
                users[msg.sender].amount
            );
        }
        users[msg.sender].claimed = true;
        totalClaimed += users[msg.sender]
            .amount;
    }


}