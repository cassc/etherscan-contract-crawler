// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract CollectSignsBooster is Booster {
    uint256 _numSigns;

    constructor(
        IPigletz pigletz,
        uint256 boostPercentage,
        uint256 numSigns,
        uint256 level
    ) Booster(pigletz, boostPercentage, level) {
        _pigletz = pigletz;
        _numSigns = numSigns;
        assert(numSigns <= 12);
    }

    function getName() external view virtual override returns (string memory) {
        return "Collect Different Signs";
    }

    function numInCollection() public view virtual override returns (uint256) {
        return _numSigns;
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _numSigns;
        return ("Collect ${0} sign", values);
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
                signs[uint256(_pigletz.getSign(id))]++;
            }
        }

        uint256 count = 0;
        for (uint256 i = 0; i < 12; i++) {
            if (signs[i] > 0) {
                count++;
            }
        }
        return count >= _numSigns;
    }

    function _haveDifferentSigns(uint256[] memory tokens) internal view returns (bool) {
        uint16[] memory signs = new uint16[](12);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 sign = uint256(_pigletz.getSign(tokens[i]));
            signs[sign]++;
            if (signs[sign] > 1) {
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
        require(_haveDifferentSigns(tokens), "All piglets must have different signs");

        _setBoosted(tokens, true);

        _updateTokenBalance(tokens);
    }
}