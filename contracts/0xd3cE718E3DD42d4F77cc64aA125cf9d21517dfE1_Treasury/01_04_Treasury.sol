/**
 * SPDX-License-Identifier: unlicensed
 */

pragma solidity 0.8.17;

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

abstract contract Auth {
    address internal _owner;
    mapping(address => bool) public isAuthorized;

    constructor(address owner) {
        _owner = owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Auth: owner only");
        _;
    }

    modifier authorized() {
        require(isAuthorized[msg.sender], "Auth: authorized only");
        _;
    }

    function setAuthorization(address address_, bool authorization) external onlyOwner {
        isAuthorized[address_] = authorization;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "Auth: owner address cannot be zero");
        _transferOwnership(newOwner);
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    event OwnershipTransferred(address owner);
}

contract Treasury is Auth {
    address private constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private weth;
    address private token;

    constructor(address tokenAddress) Auth(msg.sender) {
        require(tokenAddress != address(0), "VoxNET Treasury: token address cannot be zero");
        weth = IUniswapV2Router02(router).WETH();
        token = tokenAddress;

        bool approved = IERC20(token).approve(router, type(uint).max);
        require(approved == true, "VoxNET Treasury: approve failed");
    }

    function withdraw(
        address to,
        uint amount,
        uint minimum,
        uint gasFee,
        uint deadline
    ) external authorized {
        if (gasFee == 0) {
            IERC20(token).transfer(to, amount);
        } else {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = weth;

            uint[] memory amounts = IUniswapV2Router02(router).swapTokensForExactETH(
                gasFee,
                amount,
                path,
                msg.sender,
                deadline
            );

            uint remaining = amount - amounts[0];
            require(remaining >= minimum, "VoxNET Treasury: insufficient amount");

            bool transferred = IERC20(token).transfer(to, remaining);
            require(transferred == true, "VoxNET Treasury: transfer failed");
        }
    }
}