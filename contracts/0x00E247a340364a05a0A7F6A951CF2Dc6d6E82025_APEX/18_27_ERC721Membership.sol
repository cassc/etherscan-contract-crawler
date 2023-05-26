// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IERC721Membership.sol";
import "./APEXAccessControl.sol";

import {Errors} from "../libraries/Errors.sol";

abstract contract ERC721Membership is
    ERC721Enumerable,
    IERC721Membership,
    APEXAccessControl
{
    using Strings for uint256;

    // mapping `tokenId` => `points`
    mapping(uint256 => uint256) private _pointsOf;
    // mapping `tokenId` => `level`
    mapping(uint256 => uint256) private _levelOf;
    // mapping `level` => `points`
    mapping(uint256 => uint256) private _requiredPointsOf;
    // mapping `level` => `baseURI`
    mapping(uint256 => string) private _baseURIOf;

    uint256 private _lastLevel;

    function increasePoints(
        uint256 tokenId,
        uint256 points
    )
        external
        override
        onlyRole(MEMBERSHIP_CONTRACT)
        returns (bool isUpgraded)
    {
        _requireMinted(tokenId);

        uint256 originalPoints = _pointsOf[tokenId];
        uint256 updatedPoints = originalPoints + points;
        _pointsOf[tokenId] = updatedPoints;

        emit IncreasePoints(tokenId, msg.sender, originalPoints, updatedPoints);

        uint256 level = _levelOf[tokenId];
        if (level == _lastLevel) {
            return false;
        }

        uint256 nextLevel = level + 1;
        uint256 nextLevelRequiredPoints = _requiredPointsOf[nextLevel];
        if (updatedPoints >= nextLevelRequiredPoints) {
            _levelOf[tokenId] += 1;

            emit UpdateLevel(tokenId, level, nextLevel);

            return true;
        }

        return false;
    }

    function upgradeToken(uint256 tokenId, uint256 level) external override {
        _requireMinted(tokenId);
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert Errors.NotBeApprovedOrOwner(msg.sender, tokenId);
        }

        if (level > _lastLevel) {
            revert Errors.OutOfLastLevel(level, _lastLevel);
        }

        uint256 requiredPoints = _requiredPointsOf[level];
        uint256 ownedPoints = _pointsOf[tokenId];
        if (ownedPoints < requiredPoints) {
            revert Errors.InsufficientPoints(ownedPoints, requiredPoints);
        }

        uint256 originalLevel = _levelOf[tokenId];
        _levelOf[tokenId] = level;

        emit UpdateLevel(tokenId, originalLevel, level);
    }

    function setLevel(
        uint256 level,
        uint256 points,
        string calldata baseURI
    ) external override onlyRole(BUSINESS_MANAGER) {
        if (level == 0) {
            if (_lastLevel != 0) {
                revert Errors.CannotBeSet(level);
            }

            // `_pointsOf[0]` always be `0`
            _baseURIOf[level] = baseURI;
            return;
        }

        if (level != _lastLevel && level != _lastLevel + 1) {
            revert Errors.CannotBeSet(level);
        }

        uint256 prevLevel = level - 1;
        uint256 prevLevelRequiredPoints = _requiredPointsOf[prevLevel];
        if (points <= prevLevelRequiredPoints) {
            revert Errors.InvalidPoints(points);
        }

        if (level == _lastLevel + 1) {
            _lastLevel = level;
        }

        _requiredPointsOf[level] = points;
        _baseURIOf[level] = baseURI;
    }

    function lastLevel() public view override returns (uint256) {
        return _lastLevel;
    }

    function pointsOf(uint256 tokenId) public view override returns (uint256) {
        return _pointsOf[tokenId];
    }

    function levelOf(uint256 tokenId) public view override returns (uint256) {
        return _levelOf[tokenId];
    }

    function requiredPointsOf(
        uint256 level
    ) public view override returns (uint256) {
        return _requiredPointsOf[level];
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        uint256 level = levelOf(tokenId);
        string memory baseURI = _baseURIOfLevel(level);

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Membership).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _baseURIOfLevel(
        uint256 level
    ) internal view returns (string memory) {
        return _baseURIOf[level];
    }
}