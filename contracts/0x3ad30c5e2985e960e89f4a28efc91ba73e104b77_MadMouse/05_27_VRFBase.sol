// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import './Ownable.sol';

error RandomSeedNotSet();
error RandomSeedAlreadySet();

contract VRFBase is VRFConsumerBase, Ownable {
    bytes32 private immutable keyHash;
    uint256 private immutable fee;

    uint256 public randomSeed;

    constructor(
        bytes32 keyHash_,
        uint256 fee_,
        address vrfCoordinator_,
        address link_
    ) VRFConsumerBase(vrfCoordinator_, link_) {
        keyHash = keyHash_;
        fee = fee_;
    }

    /* ------------- Owner ------------- */

    function requestRandomSeed() external payable virtual onlyOwner whenRandomSeedUnset {
        requestRandomness(keyHash, fee);
    }

    // this function should not be needed and is just an emergency fail-safe if
    // for some reason chainlink is not able to fulfill the randomness callback
    function forceFulfillRandomness() external payable virtual onlyOwner whenRandomSeedUnset {
        randomSeed = uint256(blockhash(block.number - 1));
    }

    /* ------------- Internal ------------- */

    function fulfillRandomness(bytes32, uint256 randomNumber) internal virtual override {
        randomSeed = randomNumber;
    }

    function _shiftRandomSeed(uint256 randomNumber) internal {
        randomSeed = uint256(keccak256(abi.encode(randomSeed, randomNumber)));
    }

    /* ------------- View ------------- */

    function randomSeedSet() public view returns (bool) {
        return randomSeed > 0;
    }

    /* ------------- Modifier ------------- */

    modifier whenRandomSeedSet() {
        if (!randomSeedSet()) revert RandomSeedNotSet();
        _;
    }

    modifier whenRandomSeedUnset() {
        if (randomSeedSet()) revert RandomSeedAlreadySet();
        _;
    }
}

// get your shit together Chainlink...
contract VRFBaseMainnet is
    VRFBase(
        0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445,
        2 * 1e18,
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
        0x514910771AF9Ca656af840dff83E8264EcF986CA
    )
{

}

contract VRFBaseRinkeby is
    VRFBase(
        0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311,
        0.1 * 1e18,
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B,
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709
    )
{}

contract VRFBaseMumbai is
    VRFBase(
        0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4,
        0.0001 * 1e18,
        0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    )
{}