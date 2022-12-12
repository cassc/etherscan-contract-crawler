// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0 || ^0.8.1;

import "./interfaces/ILoyalty.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Loyalty is ILoyalty {
    mapping(uint256 => mapping(address => uint256)) public loyalties;
    mapping(uint256 => address) public creators;
    mapping(uint256 => bool) public hasLoyalty;
    mapping(uint256 => uint256) public resaleStatuses;

    uint256 public INIT_RESALE = 0;
    uint256 public RESALE_ALLOWED = 1;
    uint256 public RESALE_REJECTED = 2;

    using SafeMath for uint256;
    bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("isLoyalty()"));

    constructor() {}

    function isLoyalty() external pure override returns (bool) {
        return true;
    }

    function addLoyalty(
        uint256 assetId,
        address rightHolder,
        uint256 percent,
        uint256 resaleStatus
    ) internal {
        require(percent <= 10, "Loyalty percent must be between 0 and 10");

        require(!_isInLoyalty(assetId), "NFT already in loyalty");
        creators[assetId] = rightHolder;
        resaleStatuses[assetId] = resaleStatus;
        _addLoyalty(assetId, rightHolder, percent);
    }

    function getLoyalty(uint256 assetId, address rightHolder)
        public
        view
        override
        returns (uint256)
    {
        return loyalties[assetId][rightHolder];
    }

    function getLoyaltyCreator(uint256 assetId)
        external
        view
        override
        returns (address)
    {
        return _getLoyaltyCreator(assetId);
    }

    function _getLoyaltyCreator(uint256 assetId)
        internal
        view
        returns (address)
    {
        return creators[assetId];
    }

    function isInLoyalty(uint256 assetId)
        external
        view
        override
        returns (bool)
    {
        return _isInLoyalty(assetId);
    }

    function _isInLoyalty(uint256 assetId) internal view returns (bool) {
        return hasLoyalty[assetId];
    }

    function getCurent() external view returns (address) {
        return msg.sender;
    }

    function isResaleAllowed(uint256 assetId, address currentUser)
        external
        view
        override
        returns (bool)
    {
        return _isResaleAllowed(assetId, currentUser);
    }

    function _isResaleAllowed(uint256 assetId, address currentUser)
        internal
        view
        returns (bool)
    {
        return
            address(creators[assetId]) == currentUser
                ? true
                : resaleStatuses[assetId] != RESALE_REJECTED;
    }

    function _addLoyalty(
        uint256 assetId,
        address rightHolder,
        uint256 percent
    ) internal {
        loyalties[assetId][rightHolder] = percent;
        hasLoyalty[assetId] = true;
        emit AddLoyalty(address(this), assetId, rightHolder, percent);
    }

    function computeCreatorLoyaltyByAmount(
        uint256 assetId,
        address seller,
        uint256 sellerAmount
    ) external view override returns (address creator, uint256 creatorBenif) {
        if (_isInLoyalty(assetId)) {
            creator = _getLoyaltyCreator(assetId);
            if (creator != seller) {
                uint256 percent = getLoyalty(assetId, creator);
                if (percent > 0) {
                    creatorBenif = (sellerAmount).mul(percent).div(100);
                } else {
                    creatorBenif = 0;
                }
            } else {
                creatorBenif = 0;
            }
        } else {
            creator = address(0);
            creatorBenif = 0;
        }
    }
}