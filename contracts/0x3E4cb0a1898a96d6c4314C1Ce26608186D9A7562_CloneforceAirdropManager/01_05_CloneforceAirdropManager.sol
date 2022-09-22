// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....  
//                'dXMMWNO;                ....... 
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//               
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.16;

import "./ICloneforceAirdropManager.sol";
import "./ICloneforceClaimable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct AirdropConfig {
    address baseContract;
    address airdropContract;
    uint256 airdropTokenId;
    uint256 maxClaimCount;
    mapping(uint256 => uint256) claimHistory;
}

contract CloneforceAirdropManager is ICloneforceAirdropManager, Ownable {
    address private _admin;

    mapping(address => AirdropConfig[]) public contractToAirdropConfigs;

    constructor(address admin) {
        _admin = admin;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function setupAirdrop(
        address baseContract,
        address airdropContract,
        uint256 airdropTokenId,
        uint256 maxClaimCount
    ) external onlyOwnerOrAdmin {
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];
        AirdropConfig storage newConfig;
        
        for (uint256 i = 0; i < airdropConfigs.length;) {
            if (airdropConfigs[i].baseContract == baseContract
                && airdropConfigs[i].airdropContract == airdropContract
                && airdropConfigs[i].airdropTokenId == airdropTokenId) {
                // found an existing airdrop, update the max claim count
                newConfig = airdropConfigs[i];
                newConfig.maxClaimCount = maxClaimCount;
                return;
            }
            unchecked { i++; }
        }

        newConfig = airdropConfigs.push();
        newConfig.baseContract = baseContract;
        newConfig.airdropContract = airdropContract;
        newConfig.airdropTokenId = airdropTokenId;
        newConfig.maxClaimCount = maxClaimCount;
    }

    function stopAirdrop(
        address baseContract,
        address airdropContract,
        uint256 airdropTokenId
    ) external onlyOwnerOrAdmin {
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];

        for (uint256 i = 0; i < airdropConfigs.length;) {
            if (airdropConfigs[i].baseContract == baseContract
                && airdropConfigs[i].airdropContract == airdropContract
                && airdropConfigs[i].airdropTokenId == airdropTokenId) {
                delete airdropConfigs[i];
                break;
            }
            unchecked { i++; }
        }
    }

    function stopAirdrop(address baseContract) external onlyOwnerOrAdmin {
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];

        for (uint256 i = 0; i < airdropConfigs.length;) {
            if (airdropConfigs[i].baseContract == baseContract) {
                delete airdropConfigs[i];
            }
            unchecked { i++; }
        }
    }

    function getAirdropConfig(
        address baseContract,
        address airdropContract,
        uint256 airdropTokenId
    ) internal view returns (AirdropConfig storage config) {
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];
        for (uint256 i = 0; i < airdropConfigs.length;) {
            if (airdropConfigs[i].baseContract == baseContract
                && airdropConfigs[i].airdropContract == airdropContract
                && airdropConfigs[i].airdropTokenId == airdropTokenId
                && airdropConfigs[i].maxClaimCount > 0) {
                return airdropConfigs[i];
            }
            unchecked { i++; }
        }

        revert("Invalid airdrop");
    }

    function remainingClaims(
        address baseContract,
        uint256 tokenId,
        address airdropContract,
        uint256 airdropTokenId
    ) public view returns (uint256 count) {
        AirdropConfig storage config = getAirdropConfig(baseContract, airdropContract, airdropTokenId);
        return config.maxClaimCount - config.claimHistory[tokenId];
    }

    // Airdrop tokens to a single person
    function airdrop(
        address baseContract,
        address to,
        uint256[] calldata baseTokenIds,
        address airdropContract,
        uint256 airdropTokenId
    ) external onlyOwnerOrAdmin {
        AirdropConfig storage config = getAirdropConfig(baseContract, airdropContract, airdropTokenId);
        ICloneforceClaimable _airdropContract = ICloneforceClaimable(airdropContract);
        unchecked {
            // log in the claim history
            uint256 airdropCount = 0;
            for (uint256 j = 0; j < baseTokenIds.length; j++) {
                airdropCount += config.maxClaimCount - config.claimHistory[baseTokenIds[j]];
                config.claimHistory[baseTokenIds[j]] = config.maxClaimCount;
            }

            require(airdropCount > 0, "Airdrop is already claimed for the given tokens");
            _airdropContract.mintClaim(to, airdropTokenId, airdropCount);
        }
    }

    // Airdrop tokens to a multiple people
    function airdropBatch(
        address baseContract,
        address[] calldata to,
        uint256[][] calldata baseTokenIds,
        address airdropContract,
        uint256 airdropTokenId
    ) external onlyOwnerOrAdmin {
        AirdropConfig storage config = getAirdropConfig(baseContract, airdropContract, airdropTokenId);
        ICloneforceClaimable _airdropContract = ICloneforceClaimable(airdropContract);
        unchecked {
            for (uint256 i = 0; i < to.length; i++) {
                uint256[] calldata tokenIds = baseTokenIds[i];

                uint256 airdropCount = 0;
                for (uint256 j = 0; j < tokenIds.length; j++) {
                    airdropCount += config.maxClaimCount - config.claimHistory[tokenIds[j]];
                    config.claimHistory[tokenIds[j]] = config.maxClaimCount;
                }

                if (airdropCount > 0) {
                    _airdropContract.mintClaim(to[i], airdropTokenId, airdropCount);
                }
            }
        }
    }

    function hasAirdrops() external view returns (bool value) {
        require(msg.sender != tx.origin, "Caller must be a contract");
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[msg.sender];
        
        for (uint256 i = 0; i < airdropConfigs.length;) {
            AirdropConfig storage config = airdropConfigs[i];
            if (config.maxClaimCount > 0) {
                return true;
            }
            unchecked { i++; }
        }
        return false;
    }

    function claim(address to, uint256 baseTokenId, address airdropContract, uint256 airdropTokenId, uint256 count) external {
        require(msg.sender != tx.origin, "Caller must be a contract");
        
        address baseContract = msg.sender;
        AirdropConfig storage config = getAirdropConfig(baseContract, airdropContract, airdropTokenId);
        require(
            remainingClaims(baseContract, baseTokenId, airdropContract, airdropTokenId) >= count,
            "Count exceeds remaining claimable amount for this token");
        
        // log in the claim history
        unchecked {
            config.claimHistory[baseTokenId] += count;
        }

        // mint the tokens
        ICloneforceClaimable _airdropContract = ICloneforceClaimable(airdropContract);
        _airdropContract.mintClaim(to, airdropTokenId, count);
    }

    function claimAll(address to, uint256 baseTokenId) external {
        require(msg.sender != tx.origin, "Caller must be a contract");
        
        address baseContract = msg.sender;
        AirdropConfig[] storage airdropConfigs = contractToAirdropConfigs[baseContract];
        unchecked {
            for (uint256 i = 0; i < airdropConfigs.length; i++) {
                AirdropConfig storage config = airdropConfigs[i];
                
                uint256 remainingCount = config.maxClaimCount - config.claimHistory[baseTokenId];
                if (remainingCount <= 0) {
                    continue;
                }

                // log in the claim history
                config.claimHistory[baseTokenId] += remainingCount;
                // mint the tokens
                ICloneforceClaimable airdropContract = ICloneforceClaimable(config.airdropContract);
                airdropContract.mintClaim(to, config.airdropTokenId, remainingCount);
            }
        }
    }
}