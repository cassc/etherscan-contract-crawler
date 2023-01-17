// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./BaseLaunchpeg.sol";
import "./interfaces/ILaunchpeg.sol";

/// @title Launchpeg
/// @author Trader Joe
/// @notice Implements a fair and gas efficient NFT launch mechanism. The sale takes place in 3 phases: dutch auction, allowlist mint, public sale.
contract Launchpeg is BaseLaunchpeg, ILaunchpeg {
    /// @notice Amount of NFTs available for the auction (e.g 8000)
    /// Unsold items are put up for sale during the public sale.
    uint256 public override amountForAuction;

    /// @notice Start time of the dutch auction in seconds
    /// @dev Timestamp
    uint256 public override auctionSaleStartTime;

    /// @notice Auction start price in AVAX
    /// @dev auctionStartPrice is scaled to 1e18
    uint256 public override auctionStartPrice;

    /// @notice Auction floor price in AVAX
    /// @dev auctionEndPrice is scaled to 1e18
    uint256 public override auctionEndPrice;

    /// @notice Duration of the auction in seconds
    /// @dev allowlistStartTime - auctionSaleStartTime
    uint256 public override auctionSaleDuration;

    /// @notice Time elapsed between each drop in price
    /// @dev In seconds
    uint256 public override auctionDropInterval;

    /// @notice Amount in AVAX deducted at each interval
    uint256 public override auctionDropPerStep;

    /// @notice The discount applied to the last auction price during the allowlist mint
    /// @dev In basis points e.g 500 for 5%
    uint256 public override allowlistDiscountPercent;

    /// @notice The discount applied to the last auction price during the public sale
    /// @dev In basis points e.g 2500 for 25%
    uint256 public override publicSaleDiscountPercent;

    /// @notice Tracks the amount of NFTs minted during the dutch auction
    uint256 public override amountMintedDuringAuction;

    /// @notice The price of the last NFT sold during the auction
    /// @dev lastAuctionPrice is scaled to 1e18
    uint256 public override lastAuctionPrice;

    /// @dev Emitted on initializePhases()
    /// @param auctionSaleStartTime Auction start time in seconds
    /// @param auctionStartPrice Auction start price in AVAX
    /// @param auctionEndPrice Auction floor price in AVAX
    /// @param auctionDropInterval Time elapsed between each drop in price in seconds
    /// @param preMintStartTime Pre-mint start time in seconds
    /// @param allowlistStartTime allowlist mint start time in seconds
    /// @param allowlistDiscountPercent Discount applied to the last auction price during the allowlist mint
    /// @param publicSaleStartTime Public sale start time in seconds
    /// @param publicSaleEndTime Public sale end time in seconds
    /// @param publicSaleDiscountPercent Discount applied to the last auction price during the public sale
    event Initialized(
        uint256 auctionSaleStartTime,
        uint256 auctionStartPrice,
        uint256 auctionEndPrice,
        uint256 auctionDropInterval,
        uint256 preMintStartTime,
        uint256 allowlistStartTime,
        uint256 allowlistDiscountPercent,
        uint256 publicSaleStartTime,
        uint256 publicSaleEndTime,
        uint256 publicSaleDiscountPercent
    );

    /// @dev Emitted on setAuctionSaleStartTime()
    /// @param auctionSaleStartTime New auction sale start time
    event AuctionSaleStartTimeSet(uint256 auctionSaleStartTime);

    /// @notice Launchpeg initialization
    /// Can only be called once
    /// @param _collectionData Launchpeg collection data
    /// @param _ownerData Launchpeg owner data
    function initialize(
        CollectionData calldata _collectionData,
        CollectionOwnerData calldata _ownerData
    ) external override initializer {
        initializeBaseLaunchpeg(_collectionData, _ownerData);
        if (
            _collectionData.amountForAuction +
                _collectionData.amountForAllowlist +
                _collectionData.amountForDevs >
            _collectionData.collectionSize
        ) {
            revert Launchpeg__LargerCollectionSizeNeeded();
        }
        amountForAuction = _collectionData.amountForAuction;
    }

    /// @notice Initialize the three phases of the sale
    /// @dev Can only be called once
    /// @param _auctionSaleStartTime Auction start time in seconds
    /// @param _auctionStartPrice Auction start price in AVAX
    /// @param _auctionEndPrice Auction floor price in AVAX
    /// @param _auctionDropInterval Time elapsed between each drop in price in seconds
    /// @param _preMintStartTime Pre-mint start time in seconds
    /// @param _allowlistStartTime Allowlist mint start time in seconds
    /// @param _allowlistDiscountPercent Discount applied to the last auction price during the allowlist mint
    /// @param _publicSaleStartTime Public sale start time in seconds
    /// @param _publicSaleEndTime Public sale end time in seconds
    /// @param _publicSaleDiscountPercent Discount applied to the last auction price during the public sale
    function initializePhases(
        uint256 _auctionSaleStartTime,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionDropInterval,
        uint256 _preMintStartTime,
        uint256 _allowlistStartTime,
        uint256 _allowlistDiscountPercent,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSaleDiscountPercent
    ) external override onlyOwner atPhase(Phase.NotStarted) {
        if (
            _auctionSaleStartTime < block.timestamp ||
            _auctionStartPrice <= _auctionEndPrice ||
            _preMintStartTime <= _auctionSaleStartTime ||
            _allowlistStartTime < _preMintStartTime ||
            _publicSaleStartTime < _allowlistStartTime ||
            _publicSaleEndTime < _publicSaleStartTime
        ) {
            revert Launchpeg__InvalidPhases();
        }

        if (
            _allowlistDiscountPercent > BASIS_POINT_PRECISION ||
            _publicSaleDiscountPercent > BASIS_POINT_PRECISION
        ) {
            revert Launchpeg__InvalidPercent();
        }

        auctionSaleDuration = _preMintStartTime - _auctionSaleStartTime;
        /// Ensure auction drop interval is not too high by enforcing it
        /// is at most 1/4 of the auction sale duration.
        /// There will be at least 3 price drops.
        if (
            _auctionDropInterval == 0 ||
            _auctionDropInterval > auctionSaleDuration / 4
        ) {
            revert Launchpeg__InvalidAuctionDropInterval();
        }

        auctionSaleStartTime = _auctionSaleStartTime;
        auctionStartPrice = _auctionStartPrice;
        lastAuctionPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;
        auctionDropInterval = _auctionDropInterval;
        auctionDropPerStep =
            (_auctionStartPrice - _auctionEndPrice) /
            (auctionSaleDuration / _auctionDropInterval);

        preMintStartTime = _preMintStartTime;
        allowlistStartTime = _allowlistStartTime;
        allowlistDiscountPercent = _allowlistDiscountPercent;

        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSaleDiscountPercent = _publicSaleDiscountPercent;

        emit Initialized(
            auctionSaleStartTime,
            auctionStartPrice,
            auctionEndPrice,
            auctionDropInterval,
            preMintStartTime,
            allowlistStartTime,
            allowlistDiscountPercent,
            publicSaleStartTime,
            publicSaleEndTime,
            publicSaleDiscountPercent
        );
    }

    /// @notice Set the auction sale start time. Can only be set after phases
    /// have been initialized.
    /// @dev Only callable by owner
    /// @param _auctionSaleStartTime New auction sale start time
    function setAuctionSaleStartTime(uint256 _auctionSaleStartTime)
        external
        override
        onlyOwner
        isTimeUpdateAllowed(auctionSaleStartTime)
        isNotBeforeBlockTimestamp(_auctionSaleStartTime)
    {
        if (preMintStartTime <= _auctionSaleStartTime) {
            revert Launchpeg__InvalidPhases();
        }
        auctionSaleStartTime = _auctionSaleStartTime;
        emit AuctionSaleStartTimeSet(_auctionSaleStartTime);
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
        if (
            _preMintStartTime <= auctionSaleStartTime ||
            allowlistStartTime < _preMintStartTime
        ) {
            revert Launchpeg__InvalidPhases();
        }

        preMintStartTime = _preMintStartTime;
        emit PreMintStartTimeSet(_preMintStartTime);
    }

    /// @notice Mint NFTs during the dutch auction
    /// @dev The price decreases every `auctionDropInterval` by `auctionDropPerStep`
    /// @param _quantity Quantity of NFTs to buy
    function auctionMint(uint256 _quantity)
        external
        payable
        override
        whenNotPaused
        atPhase(Phase.DutchAuction)
    {
        // use numberMinted() since pre-mint starts after auction
        if (numberMinted(msg.sender) + _quantity > maxPerAddressDuringMint) {
            revert Launchpeg__CanNotMintThisMany();
        }
        if (amountMintedDuringAuction + _quantity > amountForAuction) {
            revert Launchpeg__MaxSupplyReached();
        }
        lastAuctionPrice = getAuctionPrice(auctionSaleStartTime);
        uint256 totalCost = lastAuctionPrice * _quantity;
        amountMintedDuringAuction = amountMintedDuringAuction + _quantity;
        _mint(msg.sender, _quantity, "", false);
        emit Mint(
            msg.sender,
            _quantity,
            lastAuctionPrice,
            _totalMinted() - _quantity,
            Phase.DutchAuction
        );
        _refundIfOver(totalCost);
    }

    /// @notice Returns the current price of the dutch auction
    /// @param _saleStartTime Auction sale start time
    /// @return auctionSalePrice Auction sale price
    function getAuctionPrice(uint256 _saleStartTime)
        public
        view
        override
        returns (uint256)
    {
        if (block.timestamp < _saleStartTime) {
            return auctionStartPrice;
        }
        if (block.timestamp - _saleStartTime >= auctionSaleDuration) {
            return auctionEndPrice;
        } else {
            uint256 steps = (block.timestamp - _saleStartTime) /
                auctionDropInterval;
            return auctionStartPrice - (steps * auctionDropPerStep);
        }
    }

    /// @notice Returns the price of the allowlist mint
    /// @return allowlistSalePrice Mint List sale price
    function allowlistPrice() public view override returns (uint256) {
        return _getAllowlistPrice();
    }

    /// @notice Returns the price of the public sale
    /// @return publicSalePrice Public sale price
    function salePrice() public view override returns (uint256) {
        return _getPublicSalePrice();
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
            auctionSaleStartTime == 0 ||
            preMintStartTime == 0 ||
            allowlistStartTime == 0 ||
            publicSaleStartTime == 0 ||
            publicSaleEndTime == 0 ||
            block.timestamp < auctionSaleStartTime
        ) {
            return Phase.NotStarted;
        } else if (totalSupply() >= collectionSize) {
            return Phase.Ended;
        } else if (block.timestamp < preMintStartTime) {
            return Phase.DutchAuction;
        } else if (block.timestamp < allowlistStartTime) {
            return Phase.PreMint;
        } else if (block.timestamp < publicSaleStartTime) {
            return Phase.Allowlist;
        } else if (block.timestamp < publicSaleEndTime) {
            return Phase.PublicSale;
        }
        return Phase.Ended;
    }

    /// @dev Returns true if this contract implements the interface defined by
    /// `interfaceId`. See the corresponding
    /// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    /// to learn more about how these IDs are created.
    /// This function call must use less than 30 000 gas.
    /// @param _interfaceId InterfaceId to consider. Comes from type(InterfaceContract).interfaceId
    /// @return isInterfaceSupported True if the considered interface is supported
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(BaseLaunchpeg, IERC165Upgradeable)
        returns (bool)
    {
        return
            _interfaceId == type(ILaunchpeg).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @dev Returns pre-mint price. Used by mint methods.
    function _getPreMintPrice() internal view override returns (uint256) {
        return _getAllowlistPrice();
    }

    /// @dev Returns allowlist price. Used by mint methods.
    function _getAllowlistPrice() internal view override returns (uint256) {
        return
            lastAuctionPrice -
            (lastAuctionPrice * allowlistDiscountPercent) /
            BASIS_POINT_PRECISION;
    }

    /// @dev Returns public sale price. Used by mint methods.
    function _getPublicSalePrice() internal view override returns (uint256) {
        return
            lastAuctionPrice -
            (lastAuctionPrice * publicSaleDiscountPercent) /
            BASIS_POINT_PRECISION;
    }
}