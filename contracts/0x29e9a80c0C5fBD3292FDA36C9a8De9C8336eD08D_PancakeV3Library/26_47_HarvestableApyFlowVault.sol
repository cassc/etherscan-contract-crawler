// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ApyFlowVault.sol";
import "./interfaces/IHarvestableApyFlowVault.sol";

abstract contract HarvestableApyFlowVault is ApyFlowVault {
    event Harvested(uint256 assets);

    function _harvest() internal virtual;

    function _harvest(bool reinvest) internal returns (uint256 harvested) {
        uint256 balanceBefore = IERC20(asset()).balanceOf(address(this));
        _harvest();
        uint256 balanceAfter = IERC20(asset()).balanceOf(address(this));
        if (reinvest) {
            if (balanceAfter > 0) {
                _deposit(balanceAfter);
            }
        }
        harvested = balanceAfter - balanceBefore;
        emit Harvested(harvested);
    }

    function harvest() public returns (uint256 harvested) {
        return _harvest(true);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IHarvestableApyFlowVault).interfaceId || super.supportsInterface(interfaceId);
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        _harvest(true);
        return super.deposit(assets, receiver);
    }

    function _performRedeem(uint256 shares) internal override returns (uint256 assets) {
        // some protocols do not allow us to perform deposit and redeem in one transaction
        // for example, Aave do not allow to borrow and repay in a same block
        // also, this prevents errors which may occur due to paused deposits into the protocol
        _harvest(false);
        return super._performRedeem(shares);
    }
}