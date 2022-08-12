// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./Interfaces.sol";

contract DFXSnapshot {
    IMasterChef public constant CHEF = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);

    IERC20 public constant DFX_ETH_STAKING_POOL = IERC20(0xE690E93Fd96b2b8d1cdeCDe5F08422F3dd82e164);
    IERC20 public constant DFX_ETH_SUSHI_LP = IERC20(0xBE71372995E8e920E4E72a29a51463677A302E8d);
    IERC20 public constant DFX = IERC20(0x888888435FDe8e7d4c54cAb67f206e4199454c60);
    IVault public constant DFX_BALANCER_VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IERC20 public constant DFX_ETH_BALANCER_LP = IERC20(0x3F7C10701b14197E2695dEC6428a2Ca4Cf7FC3B8);
    bytes32 public constant DFX_BALANCER_POOL_ID = 0x3f7c10701b14197e2695dec6428a2ca4cf7fc3b800020000000000000000023c;
    IERC20 public constant DFX_BAL_AURA_GAUGE = IERC20(0x7CDc9dC877b69328ca8b1Ff11ebfBe2a444Cf350);

    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "DFX Snapshot";
    }

    function symbol() external pure returns (string memory) {
        return "DFXS";
    }

    function totalSupply() external view returns (uint256) {
        return DFX.totalSupply();
    }

    function balanceOf(address _voter) public view returns (uint256) {
        // Onsen DFX/ETH is pool id 172
        (uint256 _stakedSlpAmount, ) = CHEF.userInfo(172, _voter);
        
        // Just bare LP 
        uint256 slpAmount = DFX_ETH_SUSHI_LP.balanceOf(_voter);

        // 50 DFX/50WETH Balancer LP
        uint256 blpAmount = DFX_ETH_BALANCER_LP.balanceOf(_voter);

        // Balancer LP in Aura
        uint256 blpInAuraAmount = DFX_BAL_AURA_GAUGE.balanceOf(_voter);
        
        // DFX Pool 2
        uint256 pool2StakedAmount = DFX_ETH_STAKING_POOL.balanceOf(_voter);
        
        // Bare amount
        uint256 bareAmount = DFX.balanceOf(_voter);

        uint256 votePower = getAmountFromSLP(_stakedSlpAmount) + getAmountFromSLP(pool2StakedAmount) + getAmountFromSLP(slpAmount) + getAmountFromBLP(blpAmount + blpInAuraAmount) + bareAmount;

        return votePower;
    }

    function getAmountFromSLP(uint256 _slpAmount) public view returns (uint256) {
        uint256 tokenAmount = DFX.balanceOf(address(DFX_ETH_SUSHI_LP));
        uint256 tokenSupply = DFX_ETH_SUSHI_LP.totalSupply();

        return _slpAmount * 1e18 / tokenSupply * tokenAmount / 1e18;
    }

    function getAmountFromBLP(uint256 _blpAmout) public view returns (uint256) {
        uint256 tokenSupply = DFX_ETH_BALANCER_LP.totalSupply();
        (uint256 cash, , ,) = DFX_BALANCER_VAULT.getPoolTokenInfo(DFX_BALANCER_POOL_ID, DFX);
        return _blpAmout * 1e18 / tokenSupply * cash / 1e18;
    }
}