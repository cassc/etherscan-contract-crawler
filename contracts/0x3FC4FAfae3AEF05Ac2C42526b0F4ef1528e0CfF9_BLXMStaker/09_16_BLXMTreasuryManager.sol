// SPDX-License-Identifier: GPL-3.0 License

pragma solidity 0.8.7;

import "./interfaces/IBLXMTreasuryManager.sol";
import "./BLXMMultiOwnable.sol";

import "./interfaces/IBLXMTreasury.sol";
import "./libraries/BLXMLibrary.sol";


contract BLXMTreasuryManager is BLXMMultiOwnable, IBLXMTreasuryManager {

    address internal treasury;


    function getTreasury() public override view returns (address _treasury) {
        require(treasury != address(0), 'TSC_NOT_FOUND');
        _treasury = treasury;
    }

    function updateTreasury(address _treasury) external override onlyOwner {
        require(IBLXMTreasury(_treasury).SSC() == address(this), 'INVALID_TSC');
        address oldTreasury = treasury;
        treasury = _treasury;
        emit UpdateTreasury(msg.sender, oldTreasury, _treasury);
    }

    function getReserves() public view override returns (uint reserveBlxm, uint totalRewrads) {
        reserveBlxm = IBLXMTreasury(getTreasury()).totalBlxm();
        totalRewrads = IBLXMTreasury(getTreasury()).totalRewards();
    }

    function _addRewards(uint amount) internal {
        IBLXMTreasury(getTreasury()).addRewards(amount);
    }

    function _withdraw(address from, uint amount, uint rewards, address to) internal {
        IBLXMTreasury(getTreasury()).retrieveBlxmTokens(from, amount, rewards, to);
    }

    function _notify(uint amount, address to) internal {
        IBLXMTreasury(getTreasury()).addBlxmTokens(amount, to);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}