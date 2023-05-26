// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRxnegades is IERC721 {}

abstract contract RxnegadeCollection {
    IRxnegades Rxnegades;

    mapping(uint256 => uint256) _rxRoyaltyPts;
    mapping(uint256 => bool) _rxRoyaltyPtsSet;
    mapping(uint256 => uint256) _tokenRxId;

    // mapping from an RXNGD token id to the number of related tokens in the current collection
    mapping(uint256 => uint256) public rxCollectionSize;

    uint256 _nextTokenId;
    uint256 _maxTokenId;
    uint256 _minTokenId;

    uint256 defaultRoyaltyPts = 500;

    modifier onlyRx() {
        require(
            Rxnegades.balanceOf(msg.sender) > 0,
            "RxnegadeCollection: caller is not a RXNGD holder"
        );
        _;
    }

    /**
     * RXNGD Token Transfer
     * @dev allows a Rxnegade with multiple RXNGD tokens to change which RXNGD id a token is linked to
     * @param from the existing RXNGD token ID
     * @param to the new RXNGD token ID
     * @param tokenId the token that they want to change
     */
    function rxTransfer(
        uint256 from,
        uint256 to,
        uint256 tokenId
    ) public {
        require(from != to, "RxnegadeCollection: RXNGD Ids must be unique");
        require(
            Rxnegades.ownerOf(from) == msg.sender &&
                Rxnegades.ownerOf(to) == msg.sender,
            "RxnegadeCollection: caller must be the owner of both RXNGD tokens"
        );
        require(
            tokenRxId(tokenId) == from,
            "RxnegadeCollection: tokenId not in from's collection"
        );

        rxCollectionSize[from]--;
        rxCollectionSize[to]++;
        _tokenRxId[tokenId] = to;

        uint256 nextTokenId = tokenId + 1;
        if (nextTokenId < _nextTokenId && _tokenRxId[nextTokenId] == 0) {
            _tokenRxId[nextTokenId] = from;
        }
    }

    /**
     * @dev allows a Rxnegade to set the royalty percentage for tokens associated with their id
     * @param rxId Rxnegades tokenId
     * @param pts Percentage points to be used to calculate royalty amounts
     */
    function setRoyaltyPts(uint256 rxId, uint256 pts) public {
        require(
            msg.sender == Rxnegades.ownerOf(rxId),
            "RxnegadeCollection: caller is not the RXNGD token owner"
        );
        require(
            pts <= 1000,
            "RxnegadeCollection: royalty percentage can't be greater than 10%"
        );
        _rxRoyaltyPts[rxId] = pts;
        _rxRoyaltyPtsSet[rxId] = true;
    }

    /**
     * Token Royalty Percentage Points
     * @dev get the royalty points for a token by looking up the value set for the rx id associated with it
     * @param tokenId the tokenId from the collection
     * @return uint256 royalty percentage points
     */
    function tokenRoyaltyPts(uint256 tokenId) public view returns (uint256) {
        uint256 rxId = tokenRxId(tokenId);
        if (_rxRoyaltyPtsSet[rxId]) {
            return _rxRoyaltyPts[rxId];
        }
        return defaultRoyaltyPts;
    }

    /**
     * Token Related RXNGD ID
     * @dev get the Rxnegades RXNGD token related to the cpecified collection tokenId
     * @param tokenId the id of the token to find the id of the Rxnegade that minted it
     * @return uint256 the id of the RXNGD member that minted the specified token
     */
    function tokenRxId(uint256 tokenId) public view returns (uint256) {
        uint256 curr = tokenId;

        if (_minTokenId <= tokenId && tokenId < _nextTokenId) {
            uint256 rxId = _tokenRxId[tokenId];
            if (rxId != 0) {
                return rxId;
            }
            while (true) {
                curr--;
                rxId = _tokenRxId[curr];
                if (rxId != 0) {
                    return rxId;
                }
            }
        }
        revert("Owner query for nonexistent token");
    }

    /**
     * Token Rxnegade Owner
     * @dev fetches the address of the owner of the rx token associated with the given tokenId
     * @param tokenId the id of the token to find the id of the Rxnegade that minted it
     * @return address the address of the RXNGD member that minted the specified token
     */
    function tokenRxOwner(uint256 tokenId) public view returns (address) {
        return Rxnegades.ownerOf(tokenRxId(tokenId));
    }

    // INTERNAL

    /**
     * @dev adds to the quantity of tokens associated with a particular Rxnegade
     */
    function _addToRxCollection(uint256 quantity, uint256 rxId) internal {
        rxCollectionSize[rxId] += quantity;
    }

    /**
     * @dev initialises the contract counters and Rxnegades contract address
     */
    function _init(
        address rxngdAddress,
        uint256 firstTokenId,
        uint256 maxSupply
    ) internal {
        Rxnegades = IRxnegades(rxngdAddress);
        _minTokenId = firstTokenId;
        _nextTokenId = firstTokenId;
        _maxTokenId = maxSupply + firstTokenId - 1;
    }

    /**
     * @dev fetches the address of the owner of the rx token id
     */
    function _rxOwner(uint256 rxId) internal view returns (address) {
        return Rxnegades.ownerOf(rxId);
    }

    /**
     * @dev records the rx id used to mint tokens
     */
    function _setMintedByRx(
        uint256 tokenId,
        uint256 quantity,
        uint256 rxId
    ) internal {
        require(
            _rxOwner(rxId) != address(0),
            "RxnegadeCollection: RX token owner is zero address"
        );
        _addToRxCollection(quantity, rxId);
        _tokenRxId[tokenId] = rxId;
        _nextTokenId += quantity;
    }
}