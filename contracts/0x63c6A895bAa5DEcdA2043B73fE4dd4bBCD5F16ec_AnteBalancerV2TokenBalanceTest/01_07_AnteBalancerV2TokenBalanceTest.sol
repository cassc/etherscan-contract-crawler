// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

import "@openzeppelin-contracts-old/contracts/token/ERC20/ERC20.sol";
import "../AnteTest.sol";

/// @title Ante Test to check BalancerV2 token supply (as of April 2022)
/// @dev We are snapshotting the balance of WETH, USDC, wlstE, WBTC, and DAI for the balancerV2
/// contracts as of 2022-04-22.
/// We expect the invariant to hold that the balance of each of these coins
/// will not dip below 10% of their value at the time of the deployment of this test
contract AnteBalancerV2TokenBalanceTest is
    AnteTest("Balancer major token balances do not drop 90% from time of test deployment")
{
    // https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48#code
    address public immutable balancerAddr;
    address public immutable usdcAddr;
    address public immutable wethAddr;
    address public immutable wsteAddr;
    address public immutable wbtcAddr;
    address public immutable daiAddr;

    uint256 public immutable usdcDeploymentBalance;
    uint256 public immutable wethDeploymentBalance;
    uint256 public immutable wsteDeploymentBalance;
    uint256 public immutable wbtcDeploymentBalance;
    uint256 public immutable daiDeploymentBalance;

    /// @param _balancerAddr balancerV2 contract address (0xBA12222222228d8Ba445958a75a0704d566BF2C8 on mainnet)
    /// @param _usdcAddr usdc contract address (0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 on mainnet)
    /// @param _wethAddr weth contract address (0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 on mainnet)
    /// @param _wsteAddr wstEther contract address (0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0 on mainnet)
    /// @param _wbtcAddr wbtc contract address (0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599 on mainnet)
    /// @param _daiAddr dai contract address (0x6B175474E89094C44Da98b954EedeAC495271d0F on mainnet)
    constructor(
        address _balancerAddr,
        address _usdcAddr,
        address _wethAddr,
        address _wsteAddr,
        address _wbtcAddr,
        address _daiAddr
    ) {
        balancerAddr = _balancerAddr;
        usdcAddr = _usdcAddr;
        wethAddr = _wethAddr;
        wsteAddr = _wsteAddr;
        wbtcAddr = _wbtcAddr;
        daiAddr = _daiAddr;

        ERC20 usdcToken = ERC20(_usdcAddr);
        ERC20 wethToken = ERC20(_wethAddr);
        ERC20 wsteToken = ERC20(_wsteAddr);
        ERC20 wbtcToken = ERC20(_wbtcAddr);
        ERC20 daiToken = ERC20(_daiAddr);
        protocolName = "BalancerV2";
        testedContracts = [_balancerAddr];
        usdcDeploymentBalance = usdcToken.balanceOf(_balancerAddr);
        wethDeploymentBalance = wethToken.balanceOf(_balancerAddr);
        wsteDeploymentBalance = wsteToken.balanceOf(_balancerAddr);
        wbtcDeploymentBalance = wbtcToken.balanceOf(_balancerAddr);
        daiDeploymentBalance = daiToken.balanceOf(_balancerAddr);
    }

    /// @notice test to check if USDC, WETH, wlstE, WBTC, and DAI balances fall below
    /// 10% of their amount circa 2022-04.
    function checkTestPasses() external view override returns (bool) {
        ERC20 usdcToken = ERC20(usdcAddr);
        ERC20 wethToken = ERC20(wethAddr);
        ERC20 wsteToken = ERC20(wsteAddr);
        ERC20 wbtcToken = ERC20(wbtcAddr);
        ERC20 daiToken = ERC20(daiAddr);
        if (usdcToken.balanceOf(balancerAddr) * 100 <= usdcDeploymentBalance * 10) {
            return false;
        } else if (wethToken.balanceOf(balancerAddr) * 100 <= wethDeploymentBalance * 10) {
            return false;
        } else if (wsteToken.balanceOf(balancerAddr) * 100 <= wsteDeploymentBalance * 10) {
            return false;
        } else if (wbtcToken.balanceOf(balancerAddr) * 100 <= wbtcDeploymentBalance * 10) {
            return false;
        } else if (daiToken.balanceOf(balancerAddr) * 100 <= daiDeploymentBalance * 10) {
            return false;
        } else {
            return true;
        }
    }
}