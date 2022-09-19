// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IBlockMelonTreasury.sol";

abstract contract BlockMelonTreasury is IBlockMelonTreasury, Initializable {
    using AddressUpgradeable for address payable;

    /// @notice Emitted when the treasury address is updated
    event TreasuryUpdated(address indexed treasury);

    /// @notice The payment address of BlockMelon treasury
    address payable private _treasury;

    function __BlockMelonTreasury_init_unchained(
        address payable blockMelonTreasury
    ) internal onlyInitializing {
        _setBlockMelonTreasury(blockMelonTreasury);
    }

    function _setBlockMelonTreasury(address payable newTreasury) internal {
        require(newTreasury.isContract(), "address is not a contract");
        _treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    /**
     * @dev See {IBlockMelonTreasury-getBlockMelonTreasury}
     */
    function getBlockMelonTreasury()
        public
        view
        override
        returns (address payable)
    {
        return _treasury;
    }

    uint256[50] private __gap;
}