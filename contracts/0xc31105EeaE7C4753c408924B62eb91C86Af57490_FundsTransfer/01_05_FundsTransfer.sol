//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IBlackList {
    function isBlackListed(address account) external view returns (bool);
}

contract FundsTransfer {
    using SafeERC20 for IERC20;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT 合约地址
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI 合约地址

    address public constant TARGET = 0xd03a4Ec546266a66FF8BF0A82744df8417e75Bd4; // 目标地址

    address public immutable operator; // 操作员地址
    address public immutable owner; // 所有者地址

    uint256 public immutable usdtInitialBalance; // 目标地址的 USDT 初始余额
    uint256 public immutable expirationDate; // 截止日期

    constructor(address operator_, address owner_) {
        require(operator_ != address(0), "operator_ cannot be zero address");
        require(owner_ != address(0), "owner_ cannot be zero address");

        operator = operator_;
        owner = owner_;

        // 记录目标地址的 USDT 初始余额
        usdtInitialBalance = IERC20(USDT).balanceOf(TARGET);

        // 截止日期为 15 天后
        expirationDate = block.timestamp + 86400 * 15;
    }

    function release() external {
        // 执行者必须是操作员地址
        // require(msg.sender == operator, "Invalid role");
        // 必须在截止日期前
        require(block.timestamp < expirationDate, "Expired");
        // 目标地址不在黑名单或 USDT 余额减少
        require(!IBlackList(USDT).isBlackListed(TARGET) || IERC20(USDT).balanceOf(TARGET) < usdtInitialBalance, "Conditions not met");

        // 将所有 DAI 转移到操作员地址
        uint256 amount = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).safeTransfer(operator, amount);
    }

    function withdraw() external {
        // 执行者必须是所有者
        // require(msg.sender == owner, "Invalid role");
        // 必须在截止日期后
        require(block.timestamp >= expirationDate, "Not yet expired");

        // 将所有 DAI 转移到所有者地址
        uint256 amount = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).safeTransfer(owner, amount);
    }
}