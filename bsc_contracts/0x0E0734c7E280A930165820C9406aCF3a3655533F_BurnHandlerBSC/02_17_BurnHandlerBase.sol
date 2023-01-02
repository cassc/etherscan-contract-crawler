// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../interfaces/IBurnHandler.sol";

abstract contract BurnHandlerBase is IBurnHandler, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");
    address internal constant nullAddress = 0x000000000000000000000000000000000000dEaD;
    // it's cheaper to store the address once and read than getting it from the router on every call
    address WETH;
    mapping(address => bool) public tokenWhitelist;

    function initialize() public initializer {
        __AccessControl_init();
        WETH = UNISWAP_V2_ROUTER().WETH();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BURN_ROLE, msg.sender);
        _grantRole(DEVELOPER_ROLE, msg.sender);
    }

    //need to override here
    function LUFFY() public pure virtual returns (address);

    function UNISWAP_V2_ROUTER() internal pure virtual returns (IUniswapV2Router02);

    function UNISWAP_FACTORY() internal pure virtual returns (IUniswapV2Factory);

    function burn(uint256 _amountOutMin) external onlyRole(BURN_ROLE) {
        if (address(this).balance > 0) {
            address[] memory path;
            path = new address[](2);
            path[0] = WETH;
            path[1] = LUFFY();
            UNISWAP_V2_ROUTER().swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: address(this).balance
            }(_amountOutMin, path, nullAddress, block.timestamp);
        }
    }

    function rescue(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != LUFFY(), "Cannot rescue LUFFY");
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function addTokenWhitelist(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenWhitelist[_addr] = true;
    }

    function removeTokenWhitelist(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenWhitelist[_addr] = false;
    }

    receive() external payable {}
}