// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/IDeal.sol";
import "./DealChores.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Deal is IDeal, DealChores {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Offer {
        uint256 offerNonce;
        IERC20Upgradeable[] erc20Tokens; // Needs to be approved
        uint256[] erc20TokenAmounts;
        IERC721Upgradeable[] erc721Tokens; // Needs to set operator
        uint256[] erc721TokenIds;
        IERC1155Upgradeable[] erc1155Tokens; // Needs to set operator
        uint256[][] erc1155TokenIds;
        uint256[][] erc1155TokenAmounts;
    }

    struct Room {
        address host;
        uint256 nonce;
        Offer idealOffer;
        mapping(address => Offer) offers;
    }

    struct DealRecord {
        address host;
        address counterparty;
        uint256 nonce;
        bytes32 roomId;
        Offer hostOffer;
        Offer counterpartyOffer;
    }

    mapping(bytes32 => Room) public rooms;
    mapping(bytes32 => DealRecord) public dealRecords;

    uint256 public constant MAX_UINT256 = 2**256 - 1;

    mapping(bytes32 => bool) public cannotUseKeccakComparison;

    modifier roomExists(bytes32 roomId) {
        if (rooms[roomId].host == address(0)) {
            revert ERoomDoesNotExist();
        }
        _;
    }

    modifier roomDoesNotExist(bytes32 roomId) {
        if (rooms[roomId].host != address(0)) {
            revert ERoomExists();
        }
        _;
    }

    modifier roomNotJoined(bytes32 roomId, address party) {
        if (!_isOfferEmpty(rooms[roomId].offers[party])) {
            revert ERoomAlreadyJoined();
        }
        _;
    }

    modifier roomAlreadyJoined(bytes32 roomId, address party) {
        if (_isOfferEmpty(rooms[roomId].offers[party])) {
            revert ERoomNotJoined();
        }
        _;
    }

    modifier offerNotExpired(bytes32 roomId, Offer memory offer) {
        if ((offer.offerNonce != rooms[roomId].nonce)) {
            revert EOfferExpired();
        }
        _;
    }

    modifier offerValid(Offer memory offer) {
        if (
            offer.erc20Tokens.length != offer.erc20TokenAmounts.length ||
            offer.erc721Tokens.length != offer.erc721TokenIds.length ||
            offer.erc1155Tokens.length != offer.erc1155TokenIds.length ||
            offer.erc1155Tokens.length != offer.erc1155TokenAmounts.length
        ) {
            revert EOfferInvalid();
        }
        _;
    }

    modifier offerNotEmpty(Offer memory offer) {
        if (_isOfferEmpty(offer)) revert EOfferEmpty();
        _;
    }

    modifier hostOnly(bytes32 roomId) {
        if (_msgSender() != rooms[roomId].host) {
            revert EActionUnauthorized();
        }
        _;
    }

    function createRoom(
        bytes32 roomId,
        Offer calldata hostOffer,
        Offer calldata idealOffer,
        string calldata metadata,
        bool hasAnyTokenIdFromCollectionPresent
    )
        external
        nonReentrant
        whenNotPaused
        roomDoesNotExist(roomId)
        offerValid(hostOffer)
        offerValid(idealOffer)
        offerNotEmpty(hostOffer)
        offerNotEmpty(idealOffer)
    {
        Room storage room = rooms[roomId];
        room.host = _msgSender();
        room.nonce = block.number;
        room.idealOffer = idealOffer;
        room.offers[_msgSender()] = hostOffer;
        room.offers[_msgSender()].offerNonce = block.number;
        cannotUseKeccakComparison[roomId] = hasAnyTokenIdFromCollectionPresent;
        emit RoomCreated(roomId, _msgSender(), metadata);
        emit OfferUpdated(roomId, _msgSender());
    }

    function joinRoom(bytes32 roomId, Offer calldata offer)
        external
        nonReentrant
        whenNotPaused
        roomExists(roomId)
        roomNotJoined(roomId, _msgSender())
        offerNotExpired(roomId, offer)
        offerValid(offer)
        offerNotEmpty(offer)
    {
        emit RoomJoined(roomId, _msgSender());
        _updateOffer(roomId, offer);
    }

    function exitRoom(bytes32 roomId) external nonReentrant whenNotPaused {
        delete rooms[roomId].offers[_msgSender()];
        emit RoomExited(roomId, _msgSender());
    }

    function closeRoom(bytes32 roomId)
        external
        nonReentrant
        whenNotPaused
        hostOnly(roomId)
    {
        _closeRoom(roomId);
    }

    function updateOffer(bytes32 roomId, Offer calldata offer)
        external
        nonReentrant
        whenNotPaused
        roomExists(roomId)
        roomAlreadyJoined(roomId, _msgSender())
        offerNotExpired(roomId, offer)
        offerValid(offer)
        offerNotEmpty(offer)
    {
        _updateOffer(roomId, offer);
    }

    // Approvals for ERC20, ERC721, and ERC1155 tokens
    // must be set to the Deal contract beforehand for
    // both host and counterparty.
    function swap(bytes32 roomId, address counterparty)
        external
        nonReentrant
        whenNotPaused
        hostOnly(roomId)
    {
        _swap(roomId, counterparty);
    }

    function getOffer(bytes32 roomId, address party)
        external
        view
        returns (Offer memory)
    {
        return rooms[roomId].offers[party];
    }

    function getRecordId(
        bytes32 roomId,
        uint256 nonce,
        uint256 blockNumber,
        address host,
        address counterparty
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(roomId, nonce, blockNumber, host, counterparty)
            );
    }

    function _closeRoom(bytes32 roomId) internal {
        delete rooms[roomId];
        delete cannotUseKeccakComparison[roomId];
        emit RoomClosed(roomId);
    }

    function _swap(bytes32 roomId, address counterparty) internal {
        _swapTokens(roomId, rooms[roomId].host, counterparty);
        _swapTokens(roomId, counterparty, rooms[roomId].host);
        _saveDealRecords(roomId, counterparty);
        _closeRoom(roomId);
    }

    function _swapTokens(
        bytes32 roomId,
        address from,
        address to
    ) internal {
        Room storage room = rooms[roomId];
        Offer memory offer = room.offers[from];
        if (room.nonce != offer.offerNonce) revert EOfferExpired();
        for (uint256 i = 0; i < offer.erc20Tokens.length; i++) {
            offer.erc20Tokens[i].safeTransferFrom(
                from,
                address(this),
                offer.erc20TokenAmounts[i]
            );
            offer.erc20Tokens[i].safeTransfer(to, offer.erc20TokenAmounts[i]);
        }
        for (uint256 i = 0; i < offer.erc721Tokens.length; i++) {
            offer.erc721Tokens[i].safeTransferFrom(
                from,
                to,
                offer.erc721TokenIds[i]
            );
        }
        for (uint256 i = 0; i < offer.erc1155Tokens.length; i++) {
            offer.erc1155Tokens[i].safeBatchTransferFrom(
                from,
                to,
                offer.erc1155TokenIds[i],
                offer.erc1155TokenAmounts[i],
                ""
            );
        }
    }

    function _saveDealRecords(bytes32 roomId, address counterparty) internal {
        address host = rooms[roomId].host;
        uint256 nonce = rooms[roomId].nonce;
        bytes32 recordId = getRecordId(
            roomId,
            nonce,
            block.number,
            host,
            counterparty
        );
        dealRecords[recordId] = DealRecord({
            host: host,
            counterparty: counterparty,
            nonce: nonce,
            roomId: roomId,
            hostOffer: rooms[roomId].offers[host],
            counterpartyOffer: rooms[roomId].offers[counterparty]
        });
        emit Swapped(recordId);
    }

    function _updateOffer(bytes32 roomId, Offer calldata offer) internal {
        rooms[roomId].offers[_msgSender()] = offer;
        emit OfferUpdated(roomId, _msgSender());
        if (_checkIfOfferMatchesIdealOffer(roomId, offer)) {
            if (
                _checkIfAllTokensApproved(offer, _msgSender()) &&
                _checkIfAllTokensApproved(
                    rooms[roomId].offers[rooms[roomId].host],
                    rooms[roomId].host
                )
            ) {
                _swap(roomId, _msgSender());
            }
        }
    }

    function _checkIfAllTokensApproved(Offer memory offer, address from)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < offer.erc20Tokens.length; i++) {
            if (
                offer.erc20Tokens[i].allowance(from, address(this)) <
                offer.erc20TokenAmounts[i]
            ) return false;
        }
        for (uint256 i = 0; i < offer.erc721Tokens.length; i++) {
            if (
                offer.erc721Tokens[i].getApproved(offer.erc721TokenIds[i]) !=
                address(this) &&
                !offer.erc721Tokens[i].isApprovedForAll(from, address(this))
            ) return false;
        }
        for (uint256 i = 0; i < offer.erc1155Tokens.length; i++) {
            if (!offer.erc1155Tokens[i].isApprovedForAll(from, address(this)))
                return false;
        }
        return true;
    }

    function _checkIfOfferMatchesIdealOffer(bytes32 roomId, Offer memory offer)
        internal
        view
        returns (bool)
    {
        Offer memory idealOffer = rooms[roomId].idealOffer;
        if (cannotUseKeccakComparison[roomId]) {
            if (
                keccak256(
                    abi.encode(
                        idealOffer.erc20Tokens,
                        idealOffer.erc20TokenAmounts
                    )
                ) !=
                keccak256(
                    abi.encode(offer.erc20Tokens, offer.erc20TokenAmounts)
                ) ||
                keccak256(
                    abi.encode(
                        idealOffer.erc721Tokens,
                        idealOffer.erc1155Tokens
                    )
                ) !=
                keccak256(abi.encode(offer.erc721Tokens, offer.erc1155Tokens))
            ) {
                return false;
            }
            for (uint256 i = 0; i < idealOffer.erc721Tokens.length; i++) {
                if (idealOffer.erc721TokenIds[i] == MAX_UINT256) {
                    continue;
                }
                if (idealOffer.erc721TokenIds[i] != offer.erc721TokenIds[i]) {
                    return false;
                }
            }
            for (uint256 i = 0; i < idealOffer.erc1155Tokens.length; i++) {
                for (
                    uint256 j = 0;
                    j < idealOffer.erc1155TokenIds[i].length;
                    j++
                ) {
                    if (
                        idealOffer.erc1155TokenAmounts[i][j] !=
                        offer.erc1155TokenAmounts[i][j]
                    ) {
                        return false;
                    }
                    if (idealOffer.erc1155TokenIds[i][j] == MAX_UINT256) {
                        continue;
                    }
                    if (
                        idealOffer.erc1155TokenIds[i][j] !=
                        offer.erc1155TokenIds[i][j]
                    ) {
                        return false;
                    }
                }
            }
            return true;
        } else {
            idealOffer.offerNonce = offer.offerNonce;
            return
                keccak256(abi.encode(offer)) ==
                keccak256(abi.encode(idealOffer));
        }
    }

    function _isOfferEmpty(Offer memory offer) internal pure returns (bool) {
        return
            offer.erc20Tokens.length == 0 &&
            offer.erc721Tokens.length == 0 &&
            offer.erc1155Tokens.length == 0;
    }
}