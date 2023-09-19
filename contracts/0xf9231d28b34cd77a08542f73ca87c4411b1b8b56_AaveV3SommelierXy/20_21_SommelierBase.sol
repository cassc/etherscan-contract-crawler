// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "../../interfaces/sommelier/ISommelier.sol";

/// @dev This strategy will deposit collateral token in Sommelier and earn yield.
abstract contract SommelierBase {
    // Same as receiptToken but it's immutable and saves gas
    ICellar public immutable cellar;

    constructor(address cellar_) {
        cellar = ICellar(cellar_);
    }

    /**
     * @notice Time when withdraw and transfer will be unlocked.
     */
    function unlockTime() public view returns (uint256) {
        return cellar.userShareLockStartTime(address(this)) + cellar.shareLockPeriod();
    }

    function _depositInSommelier(uint256 amount_) internal returns (uint256 shares_) {
        shares_ = cellar.deposit(amount_, address(this));
    }

    function _getAssetsInSommelier() internal view returns (uint256) {
        return cellar.convertToAssets(cellar.balanceOf(address(this)));
    }

    /**
     * @dev Withdraw from sommelier vault
     * @param requireAmount_ equivalent value of the assets withdrawn, denominated in the cellar's asset
     * @return shares_ amount of shares redeemed
     */
    function _withdrawFromSommelier(uint256 requireAmount_) internal returns (uint256 shares_) {
        if (block.timestamp >= unlockTime()) {
            // withdraw asking more than available liquidity will fail. To do safe withdraw, check
            // requireAmount_ against available liquidity.
            uint256 _withdrawable = Math.min(
                requireAmount_,
                Math.min(_getAssetsInSommelier(), cellar.totalAssetsWithdrawable())
            );
            if (_withdrawable > 0) {
                shares_ = cellar.withdraw(_withdrawable, address(this), address(this));
            }
        }
    }
}