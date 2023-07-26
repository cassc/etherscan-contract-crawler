/**
 *Submitted for verification at Etherscan.io on 2023-07-05
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IVault {
    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;
}

interface IBaseRewardPool {
    function withdrawAndUnwrap(
        uint256 amount,
        bool claim
    ) external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function stakeAll() external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract BalancerAuraRDaiWithdraw {
    bytes32 public constant NAME = "BalancerAuraRDaiWithdraw";
    uint256 public constant VERSION = 1;

    address public constant AuraRDaiBLPVault =
        0xdC38CCAc2008547275878F5D89B642DA27910739;
    address public constant BalancerVault =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public constant AuraRDaiBLP =
        0x81c7bfAe0Cba2ed6F22682Ea7685718Ee4f49dEB;
    address public constant RDaiBLP =
        0x20a61B948E33879ce7F23e535CC7BAA3BC66c5a9;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant R = 0x183015a9bA6fF60230fdEaDc3F43b3D788b13e21;
    bytes32 public constant RDaiPoolId =
        0x20a61b948e33879ce7f23e535cc7baa3bc66c5a9000000000000000000000555;
    uint256 public constant BASE = 10000;

    function stakeAll() external {
        IERC20(AuraRDaiBLP).approve(AuraRDaiBLPVault, type(uint256).max);
        IBaseRewardPool(AuraRDaiBLPVault).stakeAll();
    }

    function withdrawWithSlippage(uint256 slippage) external returns (uint256) {
        IBaseRewardPool(AuraRDaiBLPVault).withdrawAllAndUnwrap(true);
        uint256 rDdaiBLPBalance = IERC20(RDaiBLP).balanceOf(address(this));
        uint256 daiAmount = ((rDdaiBLPBalance * (BASE - slippage)) / BASE);
        return withdraw(rDdaiBLPBalance, daiAmount);
    }

    function withdrawWithAmount(uint256 daiAmount) external returns (uint256) {
        IBaseRewardPool(AuraRDaiBLPVault).withdrawAllAndUnwrap(true);
        uint256 rDdaiBLPBalance = IERC20(RDaiBLP).balanceOf(address(this));
        return withdraw(rDdaiBLPBalance, daiAmount);
    }

    function withdraw(
        uint256 rDdaiBLPBalance,
        uint256 daiAmount
    ) internal returns (uint256) {
        IAsset[] memory _assets = new IAsset[](3);
        _assets[0] = IAsset(R);
        _assets[1] = IAsset(RDaiBLP);
        _assets[2] = IAsset(DAI);

        uint256[] memory _minAmountsOut = new uint256[](3);
        _minAmountsOut[0] = 0;
        _minAmountsOut[1] = 0;
        _minAmountsOut[2] = daiAmount;

        IVault.ExitPoolRequest memory exitPoolRequest = IVault.ExitPoolRequest({
            assets: _assets,
            minAmountsOut: _minAmountsOut,
            userData: abi.encode(0, rDdaiBLPBalance, 1), // RDAIBLP Balance
            toInternalBalance: false
        });

        IVault(BalancerVault).exitPool(
            RDaiPoolId,
            address(this),
            payable(address(this)),
            exitPoolRequest
        );

        return IERC20(DAI).balanceOf(address(this));
    }
}