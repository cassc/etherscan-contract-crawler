// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IBooster.sol";
import "../piglet/IPigletz.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract Booster is IBooster {
    uint256 constant PIPS = 10000;
    IPigletz internal _pigletz;
    uint256 internal _boost;
    uint256 internal _level;
    mapping(uint256 => bool) _boosted;

    constructor(
        IPigletz piglet,
        uint256 boostPercentage,
        uint256 level
    ) {
        _pigletz = piglet;
        _boost = boostPercentage;
        _level = level;
        assert(_boost >= 1000);
    }

    function getStatus(uint256 tokenId) external view override returns (Status) {
        if (isBoosted(tokenId)) {
            return Status.Boosted;
        }

        if (isReady(tokenId)) {
            return Status.Ready;
        }

        if (isLocked(tokenId)) {
            return Status.Locked;
        }
        return Status.NotReady;
    }

    function getName() external view virtual override returns (string memory) {
        return "Base Booster";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](2);
        values[0] = 1;
        values[1] = 2;
        return ("You need to collect ${0} and ${1} in order to succeed", values);
    }

    function getBoost() public view virtual override returns (uint256) {
        return _boost;
    }

    function numInCollection() public view virtual override returns (uint256) {
        return 1;
    }

    function isReady(uint256 tokenID) public view virtual override returns (bool) {
        return !isLocked(tokenID);
    }

    function isLocked(uint256 tokenId) public view virtual override returns (bool) {
        return _pigletz.getLevel(tokenId) < _level;
    }

    function isBoosted(uint256 tokenId) public view virtual override returns (bool) {
        return _boosted[tokenId];
    }

    function _areBoostable(uint256[] memory tokens) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (!isReady(tokens[i])) {
                return false;
            }
        }
        return true;
    }

    function _haveCorrectLevel(uint256[] memory tokens) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (isLocked(tokens[i])) {
                return false;
            }
        }
        return true;
    }

    function _updateTokenBalance(uint256[] memory tokens) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            _pigletz.updatePiFiBalance(tokens[i]);
        }
    }

    function boost(uint256[] calldata tokens) public virtual override {
        require(tokens.length == numInCollection(), "Wrong number of piglets");
        require(_haveSameOwner(tokens), "Not all piglets are owned by the same owner");
        require(_haveNotBeenBoosted(tokens), "Some piglets have already been boosted");
        require(_areBoostable(tokens), "Some piglets are not boostable");
        require(_haveCorrectLevel(tokens), "Some piglets are not of the correct level");
        _updateTokenBalance(tokens);

        _setBoosted(tokens, true);
    }

    function unBoost(uint256[] calldata tokens) external virtual override {
        require(tokens.length == numInCollection(), "Wrong number of piglets");
        require(_haveSameOwner(tokens), "Not all piglets are owned by the same owner");
        require(!_haveNotBeenBoosted(tokens), "Some piglets have not been boosted");

        _updateTokenBalance(tokens);

        _setBoosted(tokens, false);
    }

    function _setBoosted(uint256[] calldata tokens, bool val) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            _boosted[tokens[i]] = val;
            emit Boosted(tokens[i], getBoost(), _level, val);
        }
    }

    function _haveSameOwner(uint256[] calldata tokens) internal view returns (bool) {
        address owner = _pigletz.ownerOf(tokens[0]); // allowed to be invoked by a non owner
        for (uint256 i = 1; i < tokens.length; i++) {
            if (_pigletz.ownerOf(tokens[i]) != owner) {
                return false;
            }
        }
        return true;
    }

    function _haveNotBeenBoosted(uint256[] calldata tokens) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (isBoosted(tokens[i])) {
                return false;
            }
        }
        return true;
    }

    function _areNotCelebrity(uint256[] memory tokens) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (_pigletz.isCelebrity(tokens[i])) {
                return false;
            }
        }
        return true;
    }

    function getBoostAmount(uint256 tokenId, uint256 amount) external view virtual override returns (uint256) {
        if (!isBoosted(tokenId)) {
            return 0;
        }

        return (amount * _boost) / PIPS;
    }
}