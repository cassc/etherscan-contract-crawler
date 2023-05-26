// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "lib/forge-std/src/interfaces/IERC20.sol";
import "./interface/IUniswapV2Factory.sol";

error FailedToProvideLiquidity();
error CallerNotOwner();
error LiquidityLocked();

contract Memecoin is ERC20Upgradeable {
    address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public TEAM_PERCENTAGE;
    uint256 public LIQUIDITY_LOCKED_UNTIL;
    address public DEPLOYER;

    function initialize (
        string calldata name,
        string calldata sym,
        uint256 _totalSupply,
        address _deployer,
        uint256 _teamPercentage,
        uint256 liquidityLockPeriodInSeconds
    ) initializer external payable {
        TEAM_PERCENTAGE = _teamPercentage;
        LIQUIDITY_LOCKED_UNTIL = block.timestamp + liquidityLockPeriodInSeconds;
        DEPLOYER = _deployer;
        __ERC20_init(name, sym);

        uint256 fullTotalSupply = _totalSupply * 10 ** decimals();
        uint256 teamTokens = (fullTotalSupply * TEAM_PERCENTAGE) / 100;
        uint256 poolTokens = fullTotalSupply - teamTokens;

        _mint(DEPLOYER, teamTokens);

        if (TEAM_PERCENTAGE == 100) return;

        _mint(address(this), poolTokens);
        _approve(address(this), UNISWAP_ROUTER, poolTokens);

        address liquidityRecipient = liquidityLockPeriodInSeconds == 0 ? DEPLOYER : address(this);

        (bool success, ) = UNISWAP_ROUTER.call{value: msg.value}(
            abi.encodeWithSelector(
                0xf305d719,
                address(this),
                poolTokens,
                0,
                0,
                liquidityRecipient,
                block.timestamp
            )
        );

        if (!success) revert FailedToProvideLiquidity();
    }

    function withdrawLP() external {
        if (msg.sender != DEPLOYER) revert CallerNotOwner();
        if (block.timestamp < LIQUIDITY_LOCKED_UNTIL) revert LiquidityLocked();

        address pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).getPair(address(this), WETH);
        uint256 balance = IERC20(pair).balanceOf(address(this));
        pair.call(abi.encodeWithSelector(0xa9059cbb, DEPLOYER, balance));
    }
}