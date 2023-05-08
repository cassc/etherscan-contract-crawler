/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

/**
 *Submitted for verification at Etherscan.io on 2023-04-29
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier:MIT
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Airdrop {
    address public owner;
    IERC20 public token;

    modifier onlyOwner() {
        require(msg.sender == owner, " Not an owner");
        _;
    }

    constructor( ) {
        owner = address(0x613e4b06a44848D93EAADE56D53B360e49A3303d);
        token = IERC20(0x3374C2fd3423F8bb4aA7A2E73B35Fd57De008048);
    }

    function tokenTransfer(address receiver, uint256 amount) internal {
        token.transferFrom(owner, receiver, amount);
    }

    function multipletransfer(
        address[] memory recivers,
        uint256[] memory amounts
    ) public onlyOwner {
        require(recivers.length == amounts.length);
        for (uint256 i=0 ; i < recivers.length; i++) {
            tokenTransfer(recivers[i], amounts[i]);
        }
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function changeToken(address newToken) public onlyOwner {
        token = IERC20(newToken);
    }
}