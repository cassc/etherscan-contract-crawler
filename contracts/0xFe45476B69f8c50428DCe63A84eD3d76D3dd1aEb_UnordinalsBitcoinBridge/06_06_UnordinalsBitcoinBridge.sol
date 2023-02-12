// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface Unordinals is IERC721Enumerable {
    function BurnToken(uint256[] calldata tokenIds) external;

    function setBurnEnabled(bool _state) external;

    function owner() external view returns (address);

    function burn(uint256 tokenId) external;

    function mint(uint256 _mintAmount) external payable;

    function cost() external view returns (uint256);
}

contract UnordinalsBitcoinBridge is Ownable {
    Unordinals public immutable UNORDINALS;

    struct BurnRecord {
        address owner;
        uint128 tokenId;
        uint128 timestamp;
        string btcReceiverAddress;
        string btcTransactionHash;
    }

    mapping(uint256 => BurnRecord) public burnRecords;
    uint256[] public burntTokenIds;
    bool public burnEnabled;

    constructor(Unordinals unordinals) {
        UNORDINALS = unordinals;
    }

    function burn(uint256 tokenId, string calldata btcReceiverAddress) public {
        require(burnEnabled, 'Burn is disabled');
        require(msg.sender == UNORDINALS.ownerOf(tokenId), 'not owner');

        UNORDINALS.burn(tokenId);

        burnRecords[tokenId] = BurnRecord({
            owner: msg.sender,
            tokenId: uint128(tokenId),
            timestamp: uint128(block.timestamp),
            btcReceiverAddress: btcReceiverAddress,
            btcTransactionHash: ''
        });

        burntTokenIds.push(tokenId);
    }

    function batchBurn(
        uint256[] calldata tokenIds,
        string[] calldata btcReceiverAddresses
    ) external {
        require(tokenIds.length == btcReceiverAddresses.length, 'Invalid input');
        for (uint256 i; i < tokenIds.length; ) {
            burn(tokenIds[i], btcReceiverAddresses[i]);
            unchecked {
                i++;
            }
        }
    }

    function linkBtcTransactions(
        uint256[] calldata tokenIds,
        string[] calldata btcTransactionHash
    ) external onlyOwner {
        require(tokenIds.length == btcTransactionHash.length, 'Invalid input');

        for (uint256 i; i < tokenIds.length; ) {
            burnRecords[tokenIds[i]].btcTransactionHash = btcTransactionHash[i];
            unchecked {
                i++;
            }
        }
    }

    function getBurntTokenIds() external view returns (uint256[] memory) {
        return burntTokenIds;
    }

    function getBurnRecord(uint256 tokenId) external view returns (BurnRecord memory) {
        return burnRecords[tokenId];
    }

    function getBurnRecords(
        uint256[] calldata tokenId
    ) external view returns (BurnRecord[] memory records) {
        records = new BurnRecord[](tokenId.length);
        for (uint256 i; i < tokenId.length; ) {
            records[i] = burnRecords[tokenId[i]];
            unchecked {
                i++;
            }
        }
    }

    function getBurnRecords() external view returns (BurnRecord[] memory records) {
        uint256 n = burntTokenIds.length;
        records = new BurnRecord[](n);
        for (uint256 i; i < n; ) {
            records[i] = burnRecords[burntTokenIds[i]];
            unchecked {
                i++;
            }
        }
    }

    function setBurnEnabled(bool state) external onlyOwner {
        burnEnabled = state;
    }

    function adminBurnOverride(uint256 tokenId, BurnRecord calldata record) external onlyOwner {
        if (burnRecords[tokenId].timestamp == 0) {
            burntTokenIds.push(tokenId);
        }
        burnRecords[tokenId] = record;
    }
}