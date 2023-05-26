// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./KillaCubsERC721.sol";
import "../SuperOwnable.sol";

interface IKILLABITS {
    function detachUpgrade(uint256 token) external;

    function tokenUpgrade(uint256 token) external view returns (uint64);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IKILLAGEAR {
    function detokenize(
        address addr,
        uint256[] calldata types,
        uint256[] calldata amounts
    ) external;
}

abstract contract KillaCubsStaking is KillaCubsERC721, SuperOwnable {
    IKILLABITS public immutable bitsContract;
    IKILLAGEAR public immutable gearContract;

    event BitsAdded(uint256[] indexed tokens, uint16[] indexed bits);
    event BitRemoved(uint256 indexed token, uint16 indexed bit);
    event FastForwarded(uint256[] indexed tokens, uint256 indexed numberOfDays);

    mapping(uint256 => bool) public bitsUsed;

    uint256 public activeGeneration = 1;
    uint256 public initialIncubationLength = 8;
    uint256 public remixIncubationLength = 4;

    mapping(uint256 => uint256) public laterGenerations;

    constructor(
        address bitsAddress,
        address gearAddress,
        address superOwner
    ) KillaCubsERC721() SuperOwnable(superOwner) {
        bitsContract = IKILLABITS(bitsAddress);
        gearContract = IKILLAGEAR(gearAddress);
    }

    function stake(uint256[] calldata tokenIds) external {
        if (tokenIds.length == 0) return;

        Token memory token;
        bool skip;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (!skip) {
                token = resolveToken(tokenId);

                if (token.owner != msg.sender) revert NotAllowed();

                if (token.stakeTimestamp > 0) revert NotAllowed();

                tokens[tokenId] = token;
                tokens[tokenId].stakeTimestamp = uint32(block.timestamp);
            }

            emit Transfer(msg.sender, address(this), tokenId);

            skip = _lookAhead(tokenIds, i, token, true);
        }

        wallets[msg.sender].stakes += uint16(tokenIds.length);
        wallets[msg.sender].balance -= uint16(tokenIds.length);
        counters.stakes += uint16(tokenIds.length);
        incubator.add(msg.sender, tokenIds);
    }

    function unstake(uint256[] calldata tokenIds, bool finalized) external {
        if (tokenIds.length == 0) return;

        Token memory token;
        bool skip;
        bool setLaterGeneration;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (tokens[tokenId].bit > 0) {
                bitsContract.transferFrom(
                    address(this),
                    msg.sender,
                    tokens[tokenId].bit
                );
                if (finalized) bitsUsed[tokens[tokenId].bit] = true;
                emit BitRemoved(tokenId, tokens[tokenId].bit);
                tokens[tokenId].bit = 0;
            }

            if (!skip) {
                token = resolveToken(tokenId);
                setLaterGeneration = false;

                if (token.owner != msg.sender) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = _getIncubationPhase(token);

                tokens[tokenId] = token;
                tokens[tokenId].stakeTimestamp = 0;

                uint256 max = token.generation == 0
                    ? initialIncubationLength
                    : remixIncubationLength;

                if (phase >= max) {
                    if (!finalized) revert NotAllowed();
                    tokens[tokenId].incubationPhase = 0;
                    if (activeGeneration > 255) {
                        tokens[tokenId].generation = 255;
                        setLaterGeneration = true;
                    } else {
                        tokens[tokenId].generation = uint8(activeGeneration);
                    }
                } else {
                    if (finalized) revert NotAllowed();
                    tokens[tokenId].incubationPhase = uint8(phase);
                }
            }

            if (setLaterGeneration) {
                laterGenerations[tokenId] = activeGeneration;
            }

            emit Transfer(address(this), msg.sender, tokenId);

            skip = _lookAhead(tokenIds, i, token, true);
        }

        wallets[msg.sender].stakes -= uint16(tokenIds.length);
        wallets[msg.sender].balance += uint16(tokenIds.length);
        counters.stakes -= uint16(tokenIds.length);
        incubator.remove(msg.sender, tokenIds);
    }

    function addBits(
        uint256[] calldata tokenIds,
        uint16[] calldata bits
    ) external {
        if (tokenIds.length == 0) return;

        Token memory token;
        bool skip;
        bool modified;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (tokens[tokenId].bit > 0) revert NotAllowed();
            if (bitsUsed[bits[i]]) revert NotAllowed();
            tokens[tokenId].bit = bits[i];
            bitsContract.transferFrom(msg.sender, address(this), bits[i]);

            if (!skip) {
                modified = false;
                token = resolveToken(tokenId);

                if (token.generation > 0) revert NotAllowed();
                if (token.owner != msg.sender) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = _getIncubationPhase(token);

                if (phase >= initialIncubationLength) revert NotAllowed();
                if (phase > 1) {
                    tokens[tokenId] = token;
                    tokens[tokenId].stakeTimestamp = 0;
                    tokens[tokenId].incubationPhase = 0;
                    modified = true;
                }
            }

            skip = _lookAhead(tokenIds, i, token, modified);
        }

        emit BitsAdded(tokenIds, bits);
    }

    function removeBits(uint256[] calldata tokenIds) external {
        uint16 n = uint16(tokenIds.length);
        for (uint256 i = 0; i < n; i++) {
            uint256 tokenId = tokenIds[i];
            if (rightfulOwnerOf(tokenId) != msg.sender) revert NotAllowed();
            bitsContract.transferFrom(
                address(this),
                msg.sender,
                tokens[tokenId].bit
            );
            emit BitRemoved(tokenId, tokens[tokenId].bit);
            tokens[tokenId].bit = 0;
        }
    }

    function extractGear(uint256[] calldata cubs) external {
        if (cubs.length == 0) revert NotAllowed();

        uint256[] memory weapons = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        for (uint256 i = 0; i < cubs.length; i++) {
            uint256 id = cubs[i];
            Token memory token = resolveToken(id);

            if (token.owner != msg.sender) revert NotAllowed();
            if (token.bit == 0) revert NotAllowed();

            uint256 phase = _getIncubationPhase(token);

            if (phase != 8) revert NotAllowed();

            uint256 weapon = bitsContract.tokenUpgrade(token.bit);
            bitsContract.detachUpgrade(token.bit);

            weapons[0] = weapon;
            gearContract.detokenize(address(this), weapons, amounts);
        }
    }

    function fastForward(
        address owner,
        uint256[] calldata tokenIds,
        uint256 numberOfDays
    ) external onlyAuthority {
        if (tokenIds.length == 0) return;
        if (numberOfDays == 0) return;

        Token memory token;
        bool skip;

        bool modified;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (!skip) {
                token = resolveToken(tokenId);

                if (token.owner != owner) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = _getIncubationPhase(token);

                uint256 max = token.generation == 0
                    ? initialIncubationLength
                    : remixIncubationLength;

                if (phase >= max) revert NotAllowed();

                tokens[tokenId] = token;
                tokens[tokenId].stakeTimestamp -= uint32(
                    numberOfDays * 24 * 3600
                );
                modified = true;
            }

            skip = _lookAhead(tokenIds, i, token, modified);
        }
        emit FastForwarded(tokenIds, numberOfDays);
    }

    function _lookAhead(
        uint256[] calldata tokenIds,
        uint256 index,
        Token memory current,
        bool modified
    ) internal returns (bool sequential) {
        uint256 id = tokenIds[index];
        uint256 nextId;

        if (current.linkedNext != 0) {
            nextId = current.linkedNext;
        } else if (id > 3333 && id < 3333 + counters.batched) {
            nextId = id + 1;
        } else {
            return false;
        }

        if (tokens[nextId].owner != address(0)) return false;

        if (index + 1 < tokenIds.length && tokenIds[index + 1] == nextId)
            return true;

        if (modified) {
            Token memory temp = tokens[nextId];
            tokens[nextId] = current;
            tokens[nextId].bit = temp.bit;
            tokens[nextId].linkedNext = temp.linkedNext;
            tokens[nextId].linkedPrev = temp.linkedPrev;
        }

        return false;
    }

    function _getIncubationPhase(
        Token memory token
    ) internal view returns (uint256) {
        uint256 phase = token.incubationPhase;
        if (token.stakeTimestamp != 0) {
            phase += (block.timestamp - token.stakeTimestamp) / 1 weeks;
        }
        uint256 max = token.generation == 0
            ? initialIncubationLength
            : remixIncubationLength;
        if (phase > max) return max;
        return phase;
    }

    function getIncubationPhase(uint256 id) public view returns (uint256) {
        Token memory token = resolveToken(id);
        return _getIncubationPhase(token);
    }

    function getGeneration(uint256 id) public view returns (uint256) {
        if (laterGenerations[id] != 0) return laterGenerations[id];
        Token memory token = resolveToken(id);
        return token.generation;
    }
}