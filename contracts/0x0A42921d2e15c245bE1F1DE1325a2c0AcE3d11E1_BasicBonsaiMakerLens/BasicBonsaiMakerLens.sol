/**
 *Submitted for verification at Etherscan.io on 2023-02-20
*/

// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.13;

enum PruneDegrees {NONE, LOW, MEDIUM, HIGH}

enum HealthStatus {OK, DRY, DEAD}

struct BonsaiProfile {
    uint256 modifiedSteps;

    uint64 adjustedStartTime;
    uint64 ratio;
    uint32 seed;
    uint8 trunkSVGNumber;

    uint64 lastWatered;
}

struct WateringStatus {
    uint64 lastWatered; 
    HealthStatus healthStatus;
    string status;
}

struct Vars {
    uint256 layer;
    uint256 strokeWidth;
    bytes32[12] gradients;
}

struct RawAttributes {
    bytes32 backgroundColor;
    bytes32 blossomColor;
    bytes32 wateringStatus;

    uint32 seed;
    uint64 ratio;
    uint64 adjustedStartTime;
    uint64 lastWatered;
    uint8 trunkSVGNumber;
    HealthStatus healthStatus;

    uint256[] modifiedSteps;
}

interface IBonsaiMaker {
    function totalSupply() external view returns(uint256);
    function tokenURIForRobots(uint256 tokenId) external view returns(RawAttributes memory);
}

contract BasicBonsaiMakerLens {

    IBonsaiMaker private _bonsaiMaker;

    constructor(address bonsaiMaker_) {
        _bonsaiMaker = IBonsaiMaker(bonsaiMaker_);
    }

    function bonsaiMaker() external returns(IBonsaiMaker) {
        return _bonsaiMaker;
    }

    function tokenURIsForRobots(uint256 fromTokenId, uint256 toTokenId) external view returns(RawAttributes[] memory ret) {
        (fromTokenId, toTokenId) = (toTokenId != 0) ? (fromTokenId, toTokenId) : (1, _bonsaiMaker.totalSupply());
        uint256 bound = toTokenId+1;
        ret = new RawAttributes[](bound-fromTokenId);
        uint256 idx;
        for (uint256 i = fromTokenId; i < bound; ++i) {
            ret[idx++] = _bonsaiMaker.tokenURIForRobots(i); 
        }
    }
}