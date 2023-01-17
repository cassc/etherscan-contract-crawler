// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IFlatLaunchpeg.sol";
import "./BaseLaunchpeg.sol";

/// @title FlatLaunchpeg
/// @author Trader Joe
/// @notice Implements a simple minting NFT contract with an allowlist and public sale phase.
contract FlatLaunchpeg is BaseLaunchpeg, IFlatLaunchpeg {
    /// @notice Price of one NFT for people on the mint list
    /// @dev allowlistPrice is scaled to 1e18
    uint256 public override allowlistPrice;

    /// @notice Price of one NFT during the public sale
    /// @dev salePrice is scaled to 1e18
    uint256 public override salePrice;

    /// @dev Emitted on initializePhases()
    /// @param preMintStartTime Pre-mint start time in seconds
    /// @param allowlistStartTime Allowlist mint start time in seconds
    /// @param publicSaleStartTime Public sale start time in seconds
    /// @param publicSaleEndTime Public sale end time in seconds
    /// @param allowlistPrice Price of the allowlist sale in Avax
    /// @param salePrice Price of the public sale in Avax
    event Initialized(
        uint256 preMintStartTime,
        uint256 allowlistStartTime,
        uint256 publicSaleStartTime,
        uint256 publicSaleEndTime,
        uint256 allowlistPrice,
        uint256 salePrice
    );

    /// @notice FlatLaunchpeg initialization
    /// Can only be called once
    /// @param _collectionData Launchpeg collection data
    /// @param _ownerData Launchpeg owner data
    function initialize(
        CollectionData calldata _collectionData,
        CollectionOwnerData calldata _ownerData
    ) external override initializer {
        initializeBaseLaunchpeg(_collectionData, _ownerData);
    }

    /// @notice Initialize the two phases of the sale
    /// @dev Can only be called once
    /// @param _preMintStartTime Pre-mint start time in seconds
    /// @param _allowlistStartTime Allowlist mint start time in seconds
    /// @param _publicSaleStartTime Public sale start time in seconds
    /// @param _publicSaleEndTime Public sale end time in seconds
    /// @param _allowlistPrice Price of the allowlist sale in Avax
    /// @param _salePrice Price of the public sale in Avax
    function initializePhases(
        uint256 _preMintStartTime,
        uint256 _allowlistStartTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _allowlistPrice,
        uint256 _salePrice
    ) external override onlyOwner atPhase(Phase.NotStarted) {
        if (
            _preMintStartTime < block.timestamp ||
            _allowlistStartTime < _preMintStartTime ||
            _publicSaleStartTime < _allowlistStartTime ||
            _publicSaleEndTime < _publicSaleStartTime
        ) {
            revert Launchpeg__InvalidPhases();
        }

        if (_allowlistPrice > _salePrice) {
            revert Launchpeg__InvalidAllowlistPrice();
        }

        salePrice = _salePrice;
        allowlistPrice = _allowlistPrice;

        preMintStartTime = _preMintStartTime;
        allowlistStartTime = _allowlistStartTime;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;

        emit Initialized(
            preMintStartTime,
            allowlistStartTime,
            publicSaleStartTime,
            publicSaleEndTime,
            allowlistPrice,
            salePrice
        );
    }

    /// @notice Set the pre-mint start time. Can only be set after phases
    /// have been initialized.
    /// @dev Only callable by owner
    /// @param _preMintStartTime New pre-mint start time
    function setPreMintStartTime(uint256 _preMintStartTime)
        external
        override
        onlyOwner
        isTimeUpdateAllowed(preMintStartTime)
        isNotBeforeBlockTimestamp(_preMintStartTime)
    {
        if (allowlistStartTime < _preMintStartTime) {
            revert Launchpeg__InvalidPhases();
        }
        preMintStartTime = _preMintStartTime;
        emit PreMintStartTimeSet(_preMintStartTime);
    }

    /// @notice Returns the current phase
    /// @return phase Current phase
    function currentPhase()
        public
        view
        override(IBaseLaunchpeg, BaseLaunchpeg)
        returns (Phase)
    {
        if (
            preMintStartTime == 0 ||
            allowlistStartTime == 0 ||
            publicSaleStartTime == 0 ||
            publicSaleEndTime == 0 ||
            block.timestamp < preMintStartTime
        ) {
            return Phase.NotStarted;
        } else if (totalSupply() >= collectionSize) {
            return Phase.Ended;
        } else if (
            block.timestamp >= preMintStartTime &&
            block.timestamp < allowlistStartTime
        ) {
            return Phase.PreMint;
        } else if (
            block.timestamp >= allowlistStartTime &&
            block.timestamp < publicSaleStartTime
        ) {
            return Phase.Allowlist;
        } else if (
            block.timestamp >= publicSaleStartTime &&
            block.timestamp < publicSaleEndTime
        ) {
            return Phase.PublicSale;
        }
        return Phase.Ended;
    }

    /// @dev Returns true if this contract implements the interface defined by
    /// `interfaceId`. See the corresponding
    /// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    /// to learn more about how these IDs are created.
    /// This function call must use less than 30 000 gas.
    /// @param _interfaceId InterfaceId to consider. Comes from type(Interface).interfaceId
    /// @return isInterfaceSupported True if the considered interface is supported
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(BaseLaunchpeg, IERC165Upgradeable)
        returns (bool)
    {
        return
            _interfaceId == type(IFlatLaunchpeg).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @dev Returns pre-mint price. Used by mint methods.
    function _getPreMintPrice() internal view override returns (uint256) {
        return allowlistPrice;
    }

    /// @dev Returns allowlist price. Used by mint methods.
    function _getAllowlistPrice() internal view override returns (uint256) {
        return allowlistPrice;
    }

    /// @dev Returns public sale price. Used by mint methods.
    function _getPublicSalePrice() internal view override returns (uint256) {
        return salePrice;
    }
}