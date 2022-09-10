// SPDX-License-Identifier: MIT
// Author: Luca Di Domenico: twitter.com/luca_dd7
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint) external;
}

// import "hardhat/console.sol";

contract BeneficiaryContractVoltiChange is AccessControlUpgradeable {
    bytes32 constant public BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 constant public DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");
    IUniswapV2Factory factory;
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public VOLT;

    address internal constant deadAddress =
        0x000000000000000000000000000000000000dEaD;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize() public initializer {
        __AccessControl_init();
        VOLT = 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BURN_ROLE, msg.sender);
        _grantRole(DEVELOPER_ROLE, msg.sender);
    }

    function burn() external onlyRole(BURN_ROLE) {
        // console.log("entered");
        address[] memory path;
        path = new address[](2);
        path[0] = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
        path[1] = VOLT;
        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(address(this).balance, path);
        uint256 _amountOutMin = (amountOutMins[path.length - 1] * 8000) / 10000;
        // console.log("starting first swap");
        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: address(this).balance
        }(_amountOutMin, path, address(this), block.timestamp);
        // console.log("first swap done");
        // console.log("transferring to burn address");
        IERC20Upgradeable(VOLT).safeTransfer(
            deadAddress,
            IERC20Upgradeable(VOLT).balanceOf(address(this))
        );
        // console.log("volt burned");
    }

    function setVolt(address _addr) public onlyRole(DEVELOPER_ROLE) {
        VOLT = _addr;
    }

    receive() external payable {}


}