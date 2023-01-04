// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract CollectSameSignsBooster is Booster {
    uint256 _numWithSameSigns;

    constructor(
        IPigletz pigletz,
        uint256 boostPercentage,
        uint256 numSame,
        uint256 level
    ) Booster(pigletz, boostPercentage, level) {
        _pigletz = pigletz;
        _numWithSameSigns = numSame;
        assert(numSame <= 100);
    }

    function numInCollection() public view virtual override returns (uint256) {
        return _numWithSameSigns;
    }

    function getName() external view virtual override returns (string memory) {
        return "Collect Same Signs";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _numWithSameSigns;
        return ("Collect ${0} piglets with the same sign", values);
    }

    function _getSign(uint256 tokenId) internal view returns (uint256) {
        return uint256(_pigletz.getSign(tokenId));
    }

    function _isEligible(uint256 id) internal view returns (bool) {
        return !isLocked(id) && !isBoosted(id) && !_pigletz.isCelebrity(id);
    }

    function isLocked(uint256 id) public view override returns (bool) {
        return _pigletz.isCelebrity(id) || super.isLocked(id);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        address owner = _pigletz.ownerOf(tokenId);
        uint256 numberOfPiglets = _pigletz.balanceOf(owner);
        uint256[] memory signs = new uint256[](12);
        for (uint256 i = 0; i < numberOfPiglets; i++) {
            uint256 id = _pigletz.tokenOfOwnerByIndex(owner, i);

            if (_isEligible(id)) {
                uint256 sign = _getSign(id);

                signs[uint256(sign)]++;
            }
        }

        return signs[_getSign(tokenId)] >= _numWithSameSigns;
    }

    function _haveSameSign(uint256[] calldata tokens) internal view returns (bool) {
        uint256 sign = uint256(_pigletz.getSign(tokens[0]));
        for (uint256 i = 1; i < tokens.length; i++) {
            if (uint256(_pigletz.getSign(tokens[i])) != sign) {
                return false;
            }
        }
        return true;
    }

    function boost(uint256[] calldata tokens) public virtual override {
        require(tokens.length == numInCollection(), "Wrong number of piglets");
        require(_haveSameOwner(tokens), "Not all piglets are owned by the same owner");
        require(_haveNotBeenBoosted(tokens), "Some piglets have already been boosted");
        require(_areNotCelebrity(tokens), "Some piglets are celebrities");
        require(_haveCorrectLevel(tokens), "Some piglets are not of the correct level");
        require(_haveSameSign(tokens), "Some piglets dont have the same sign");

        _setBoosted(tokens, true);

        _updateTokenBalance(tokens);
    }
}