// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

// this specific VerifiableNFT layer is all optional
abstract contract VerifiableNFT {
    uint256[][] public weights;

    // immutable limit
    // constructor(uint256[][] memory weighted_) {
    //     weights = weighted_;
    // }
    // constructor() {}

    function _supplyLimit() internal pure virtual returns (uint256);

    // getTraitSeed returns the
    function getTraitSeed() public view virtual returns (bytes32);

    function getWeights(uint256 layerNumber)
        public
        view
        returns (uint256[] memory)
    {
        return weights[layerNumber];
    }

    function getWeightTotal(uint256 layerNumber)
        public
        view
        returns (uint256 cumulativeWeight)
    {
        cumulativeWeight = sumArray(weights[layerNumber]);
    }

    // show individual card trait with given seed
    function getCardTraits(bytes32 traitseed_, uint256 _tokenId)
        public
        pure
        returns (bytes32)
    {
        if (traitseed_ == 0) {
            revert("unrevealed");
            // return 0; // unrevealed.
        }
        return keccak256(abi.encode(traitseed_, _tokenId)); // 0x 1233 24k2 3hjk fyhs 9f8y
    }

    // Choice A 50%    50<
    // Choice B 25%    50-75
    // Choice C 15%    75-90
    // Choice D 10%    90-100

    // random_number   = 0.64
    // combined_weight = 100
    // weighted_choice = 64 (combined_weight * random_number)
    // 64.... == choice B (returns 2)
    function applyWeight(uint256 value_, uint256[] memory layerWeights_)
        public
        pure
        returns (uint256 ret)
    {
        uint256 totalWeight = sumArray(layerWeights_);
        // console.log("totalWeight:", totalWeight);
        // console.log("value_:     ", value_);
        // require(value_ < totalWeight, "not random");
        uint256 value = value_ % totalWeight;
        // console.log("value:      ", value);
        uint256 cumulativeWeight = 0;
        for (uint256 dot = 0; dot < layerWeights_.length; dot++) {
            cumulativeWeight += layerWeights_[dot];
            if (value <= cumulativeWeight) {
                // console.log("found:", cumulativeWeight, value, dot);
                ret = dot;
                break;
            }
        }
        return ret;
    }

    function sumArray(uint256[] memory arr)
        public
        pure
        returns (uint256 totalWeight)
    {
        for (uint256 i = 0; i < arr.length; ++i) {
            // solhint-disable-next-line
            assembly {
                totalWeight := add(
                    totalWeight,
                    mload(add(add(arr, 0x20), mul(i, 0x20)))
                )
            } // solhint-disable-line
        }
        return totalWeight;
    }

    function layerDecodeW(
        bytes32 traitseed_,
        uint256 tokenId,
        uint256 layerNumber,
        uint256[] memory weighted_
    ) public pure returns (uint256) {
        if (layerNumber >= 16) {
            // shift and rehash for layer16+
            traitseed_ = keccak256(abi.encode(traitseed_));
            layerNumber -= 16;
        }
        bytes32 traitBuffer = getCardTraits(traitseed_, tokenId);
        // console.logBytes(abi.encode(traitB)); // is same as trait
        uint256 i = layerNumber * 2; // doublechunk
        uint256 exact = (uint256(uint8(traitBuffer[i])) << 4) +
            uint256(uint8(traitBuffer[i + 1])); // random 2 bytes
        return applyWeight(exact, weighted_); // show one of possibilities, 0-65535
    }

    function layerDecodeTokenLayer(uint256 tokenId_, uint256 layerNumber)
        public
        view
        returns (
            uint256 // the trait. 0-65535
        )
    {
        require(weights.length != 0, "weights are not set yet");
        return
            layerDecodeW(
                getTraitSeed(),
                tokenId_,
                layerNumber,
                weights[layerNumber]
            );
    }

    function numLayers() public view returns (uint256) {
        return weights.length;
    }

    function layerDecodeTokenAll(uint256 tokenId_)
        public
        view
        returns (
            uint256[] memory // 9 layer burrito
        )
    {
        uint256 weightLength = weights.length;
        require(weightLength != 0, "weights array doesnt exist yet");
        require(weights[0][0] != 0, "weights is invalid");

        uint256[] memory layers = new uint256[](weightLength);
        bytes32 verifyTraitseed = getTraitSeed();
        for (uint256 i = 0; i < weights.length; i++) {
            // console.log("weight", i);
            layers[i] = layerDecodeW(verifyTraitseed, tokenId_, i, weights[i]);
        }
        return layers;
    }

    // reset the weights array
    function _newWeights(uint256 numLayers_) internal {
        weights = new uint256[][](numLayers_);
    }

    // edit a weight
    function _editWeight(uint256 numLayer, uint256[] memory choices) internal {
        weights[numLayer] = choices;
    }

    bytes32 public weightHash = 0x0;

    function _weightSet() internal {
        weightHash = keccak256(abi.encode(weights));
    }
}