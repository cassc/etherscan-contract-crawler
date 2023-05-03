// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

abstract contract TokenBalanceTrackerUpgradeable {
    error InsufficientTokenBalance();

    uint256 private _tokenBalance;

    function _getTokenBalance() internal view returns (uint256) {
        return _tokenBalance;
    }

    function _increaseTokenBalance(uint256 _amount) internal {
        _tokenBalance += _amount;
    }

    function _decreaseTokenBalance(uint256 _amount) internal {
        if (_amount > _tokenBalance) {
            revert InsufficientTokenBalance();
        }

        unchecked {
            _tokenBalance -= _amount;
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}