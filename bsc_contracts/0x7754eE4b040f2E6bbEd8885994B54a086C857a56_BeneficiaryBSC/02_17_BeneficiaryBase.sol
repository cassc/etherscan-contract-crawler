// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IBeneficiaryBase.sol";

abstract contract BeneficiaryBase is IBeneficiaryBase, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");
    address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
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

    function VOLT() public pure virtual returns (address) {
        return 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;
    }

    function UNISWAP_V2_ROUTER() internal pure virtual returns (IUniswapV2Router02);

    function UNISWAP_FACTORY() internal pure virtual returns (IUniswapV2Factory);

    function burn(uint256 _amountOutMin) external onlyRole(BURN_ROLE) {
        if (address(this).balance > 0) {
            address[] memory path;
            path = new address[](2);
            path[0] = WETH;
            path[1] = VOLT();
            UNISWAP_V2_ROUTER().swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
                _amountOutMin,
                path,
                deadAddress,
                block.timestamp
            );
        }
    }

    function rescue(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != VOLT(), "Cannot rescue VOLT");
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function addWhitelistAddr(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenWhitelist[_addr] = true;
    }

    function removeWhitelistAddr(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenWhitelist[_addr] = false;
    }

    receive() external payable {}
}