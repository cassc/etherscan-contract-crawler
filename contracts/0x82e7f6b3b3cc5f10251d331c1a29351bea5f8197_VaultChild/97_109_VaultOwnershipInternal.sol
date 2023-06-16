// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { VaultFees } from '../vault-fees/VaultFees.sol';
import { VaultOwnershipStorage } from './VaultOwnershipStorage.sol';

import { IERC165 } from '@solidstate/contracts/interfaces/IERC165.sol';
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { ERC721BaseInternal, ERC165Base } from '@solidstate/contracts/token/ERC721/SolidStateERC721.sol';

import { ERC165BaseStorage } from '@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol';

import { ERC721MetadataStorage } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';

import { Constants } from '../lib/Constants.sol';

contract VaultOwnershipInternal is
    ERC721BaseInternal, //ERC165BaseInternal causes Linearization issue in vaultParentErc721
    VaultFees
{
    uint internal constant _MANAGER_TOKEN_ID = 0;
    uint internal constant _PROTOCOL_TOKEN_ID = 1;

    uint internal constant BURN_LOCK_TIME = 24 hours;

    event FeesLevied(
        uint tokenId,
        uint streamingFees,
        uint performanceFees,
        uint currentUnitPrice
    );

    function initialize(
        string memory _name,
        string memory _symbol,
        address _manager,
        uint _managerStreamingFeeBasisPoints,
        uint _managerPerformanceFeeBasisPoints,
        address _protocolAddress
    ) internal {
        super.initialize(
            _managerStreamingFeeBasisPoints,
            _managerPerformanceFeeBasisPoints
        );
        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
        l.name = _name;
        l.symbol = _symbol;

        _createManagerHolding(_manager);
        _createProtocolHolding(_protocolAddress);
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        tokenId = l._tokenIdCounter;
        _safeMint(to, tokenId);
        l._tokenIdCounter++;
    }

    function _createManagerHolding(address manager) internal {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        require(
            _exists(_MANAGER_TOKEN_ID) == false,
            'manager holding already exists'
        );
        require(
            l._tokenIdCounter == _MANAGER_TOKEN_ID,
            'manager holding must be token 0'
        );
        _mint(manager);
    }

    function _createProtocolHolding(address protocolTreasury) internal {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        require(
            _exists(_PROTOCOL_TOKEN_ID) == false,
            'protcool holding already exists'
        );
        require(
            l._tokenIdCounter == _PROTOCOL_TOKEN_ID,
            'protocol holding must be token 1'
        );
        _mint(protocolTreasury);
    }

    function _issueShares(
        uint tokenId,
        address owner,
        uint shares,
        uint currentUnitPrice,
        uint lockupTime
    ) internal returns (uint) {
        // Managers cannot deposit directly into their holding, they can only accrue fees there.
        // Users or the Manger can pass tokenId == 0 and it will create a new holding for them.
        require(_exists(tokenId), 'token does not exist');

        if (tokenId == _MANAGER_TOKEN_ID) {
            tokenId = _mint(owner);
        }

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        if (holding.totalShares == 0) {
            holding.streamingFee = _managerStreamingFee();
            holding.performanceFee = _managerPerformanceFee();
            holding.lastStreamingFeeTime = block.timestamp;
            holding.lastPerformanceFeeUnitPrice = currentUnitPrice;
            holding.averageEntryPrice = currentUnitPrice;
        } else {
            _levyFees(tokenId, currentUnitPrice);
            holding.averageEntryPrice = _calculateAverageEntryPrice(
                holding.totalShares,
                holding.averageEntryPrice,
                shares,
                currentUnitPrice
            );
        }

        l.totalShares += shares;
        holding.unlockTime = block.timestamp + lockupTime;
        holding.totalShares += shares;

        return tokenId;
    }

    function _burnShares(
        uint tokenId,
        uint shares,
        uint currentUnitPrice
    ) internal {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];
        require(block.timestamp >= holding.unlockTime, 'locked');
        // Enforces 1 withdraw per 24 hours
        require(
            block.timestamp >= holding.lastBurnTime + BURN_LOCK_TIME,
            'burn locked'
        );

        _levyFees(tokenId, currentUnitPrice);
        require(shares <= holding.totalShares, 'not enough shares');
        holding.lastBurnTime = block.timestamp;
        holding.totalShares -= shares;
        l.totalShares -= shares;
    }

    function _levyFees(uint tokenId, uint currentUnitPrice) internal {
        if (isSystemToken(tokenId)) {
            return;
        }

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();

        (uint streamingFees, uint performanceFees) = _levyFeesOnHolding(
            tokenId,
            _managerStreamingFee(),
            _managerPerformanceFee(),
            currentUnitPrice
        );

        emit FeesLevied(
            tokenId,
            streamingFees,
            performanceFees,
            currentUnitPrice
        );

        uint totalManagerFees = streamingFees + performanceFees;

        uint protocolFees = _protocolFee(streamingFees + performanceFees);
        uint managerFees = totalManagerFees - protocolFees;
        require(protocolFees + managerFees == totalManagerFees, 'fee math');

        l.holdings[_PROTOCOL_TOKEN_ID].totalShares += protocolFees;
        l.holdings[_MANAGER_TOKEN_ID].totalShares += managerFees;
    }

    function _levyFeesOnHolding(
        uint tokenId,
        uint newStreamingFee,
        uint newPerformanceFee,
        uint currentUnitPrice
    ) internal returns (uint streamingFees, uint performanceFees) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        uint initialTotalShares = holding.totalShares;

        holding.lastManagerFeeLevyTime = block.timestamp;

        (streamingFees, performanceFees) = _calculateUnpaidFees(
            tokenId,
            currentUnitPrice
        );

        if (streamingFees > 0 || holding.streamingFee != newStreamingFee) {
            holding.lastStreamingFeeTime = block.timestamp;
        }

        if (
            performanceFees > 0 || holding.performanceFee != newPerformanceFee
        ) {
            holding.lastPerformanceFeeUnitPrice = currentUnitPrice;
        }

        holding.totalShares -= streamingFees + performanceFees;

        if (holding.streamingFee != newStreamingFee) {
            holding.streamingFee = newStreamingFee;
        }

        if (holding.performanceFee != newPerformanceFee) {
            holding.performanceFee = newPerformanceFee;
        }

        require(
            holding.totalShares + streamingFees + performanceFees ==
                initialTotalShares,
            'check failed'
        );

        return (streamingFees, performanceFees);
    }

    function _setDiscountForHolding(
        uint tokenId,
        uint streamingFeeDiscount,
        uint performanceFeeDiscount
    ) internal {
        require(
            streamingFeeDiscount <= Constants.BASIS_POINTS_DIVISOR,
            'invalid streamingFeeDiscount'
        );
        require(
            performanceFeeDiscount <= Constants.BASIS_POINTS_DIVISOR,
            'invalid performanceFeeDiscount'
        );

        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        holding.streamingFeeDiscount = streamingFeeDiscount;
        holding.performanceFeeDiscount = performanceFeeDiscount;
    }

    function _holdings(
        uint tokenId
    ) internal view returns (VaultOwnershipStorage.Holding memory) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        return l.holdings[tokenId];
    }

    function _totalShares() internal view returns (uint) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        return l.totalShares;
    }

    function _calculateUnpaidFees(
        uint tokenId,
        uint currentUnitPrice
    ) internal view returns (uint streamingFees, uint performanceFees) {
        VaultOwnershipStorage.Layout storage l = VaultOwnershipStorage.layout();
        VaultOwnershipStorage.Holding storage holding = l.holdings[tokenId];

        uint initialTotalShares = holding.totalShares;

        streamingFees = _streamingFee(
            holding.streamingFee,
            holding.streamingFeeDiscount,
            holding.lastStreamingFeeTime,
            initialTotalShares,
            block.timestamp
        );

        performanceFees = _performanceFee(
            holding.performanceFee,
            holding.performanceFeeDiscount,
            // We levy performance fees after levying streamingFees
            initialTotalShares - streamingFees,
            holding.lastPerformanceFeeUnitPrice,
            currentUnitPrice
        );
    }

    function _calculateAverageEntryPrice(
        uint currentShares,
        uint previousPrice,
        uint newShares,
        uint newPrice
    ) internal pure returns (uint) {
        return
            ((currentShares * previousPrice) + (newShares * newPrice)) /
            (currentShares + newShares);
    }

    function isSystemToken(uint tokenId) internal pure returns (bool) {
        return tokenId == _PROTOCOL_TOKEN_ID || tokenId == _MANAGER_TOKEN_ID;
    }
}