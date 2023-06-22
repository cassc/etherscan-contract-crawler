// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./KillaCubs/KillaCubsERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract KillaCubsStaker is KillaCubsERC721 {
    event BitsAddedFull(uint256[] tokens, uint16[] bits);
    event BitUsed(uint256 token, uint16 bit);
    event FastForwardedFull(uint256[] tokens, uint256 indexed numberOfDays);
    event Rushed(address owner, uint256[] tokens);
    event GearExtraction(address owner, uint256[] tokens, uint256[] weapons);

    constructor(
        address superOwner
    )
        KillaCubsERC721(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            superOwner
        )
    {}

    function stake(uint256[] calldata tokenIds) public {
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

    function unstake(uint256[] calldata tokenIds, bool finalized) public {
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
                if (finalized) {
                    bitsUsed[tokens[tokenId].bit] = true;
                    emit BitUsed(tokenId, tokens[tokenId].bit);
                } else {
                    emit BitRemoved(tokenId, tokens[tokenId].bit);
                }
                tokens[tokenId].bit = 0;
            }

            if (!skip) {
                token = resolveToken(tokenId);
                setLaterGeneration = false;

                if (token.owner != msg.sender) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = calculateIncubationPhase(
                    token.incubationPhase,
                    token.stakeTimestamp,
                    token.generation
                );

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
    ) public {
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
                token = resolveToken(tokenId);

                if (token.generation > 0) revert NotAllowed();
                if (token.owner != msg.sender) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = calculateIncubationPhase(
                    token.incubationPhase,
                    token.stakeTimestamp,
                    token.generation
                );

                if (phase >= initialIncubationLength) revert NotAllowed();
                if (phase > 0) {
                    tokens[tokenId] = token;
                    tokens[tokenId].stakeTimestamp = uint32(block.timestamp);
                    tokens[tokenId].incubationPhase = 0;
                    modified = true;
                } else {
                    modified = false;
                }
            }

            skip = _lookAhead(tokenIds, i, token, modified);
        }

        emit BitsAddedFull(tokenIds, bits);
    }

    function removeBits(uint256[] calldata tokenIds) public {
        uint16 n = uint16(tokenIds.length);
        for (uint256 i = 0; i < n; i++) {
            uint256 tokenId = tokenIds[i];
            Token memory token = resolveToken(tokenId);
            if (token.owner != msg.sender) revert NotAllowed();
            if (token.generation > 0) revert NotAllowed();

            uint256 phase = calculateIncubationPhase(
                token.incubationPhase,
                token.stakeTimestamp,
                token.generation
            );

            if (phase >= initialIncubationLength) {
                revert NotAllowed();
            } else {
                emit BitRemoved(tokenId, token.bit);
            }

            bitsContract.transferFrom(address(this), msg.sender, token.bit);
            tokens[tokenId].bit = 0;
        }
    }

    function extractGear(uint256[] calldata cubs) public {
        if (cubs.length == 0) revert NotAllowed();

        uint256[] memory weapons = new uint256[](cubs.length);

        bool[19] memory flags;

        for (uint256 i = 0; i < cubs.length; i++) {
            uint256 id = cubs[i];
            Token memory token = resolveToken(id);

            if (token.owner != msg.sender) revert NotAllowed();
            if (token.bit == 0) revert NotAllowed();

            uint256 phase = calculateIncubationPhase(
                token.incubationPhase,
                token.stakeTimestamp,
                token.generation
            );

            if (phase != 8) revert NotAllowed();

            uint256 weapon = bitsContract.tokenUpgrade(token.bit);
            bitsContract.detachUpgrade(token.bit);
            weapons[i] = weapon;
            flags[weapon - 175] = true;
        }

        for (uint256 i = 0; i < 19; i++) {
            if (!flags[i]) continue;
            uint256 id = i + 175;
            IERC1155 gear = IERC1155(address(gearContract));
            uint256 amount = gear.balanceOf(address(this), id);
            if (amount == 0) continue;
            gear.safeTransferFrom(
                address(this),
                0x000000000000000000000000000000000000dEaD,
                id,
                amount,
                ""
            );
        }

        emit GearExtraction(msg.sender, cubs, weapons);
    }

    function rush(uint256[] calldata tokenIds) external {
        if (tokenIds.length == 0) return;

        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 1;
        amounts[0] = tokenIds.length;

        IKILLAGEAR traits = IKILLAGEAR(externalStorage[0]);
        traits.detokenize(msg.sender, ids, amounts);

        Token memory token;
        bool skip;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (!skip) {
                token = resolveToken(tokenId);

                if (token.owner != msg.sender) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = calculateIncubationPhase(
                    token.incubationPhase,
                    token.stakeTimestamp,
                    token.generation
                );

                uint256 max = token.generation == 0
                    ? initialIncubationLength
                    : remixIncubationLength;

                if (phase >= max) revert NotAllowed();

                tokens[tokenId] = token;
                tokens[tokenId].incubationPhase = uint8(max);
            }

            skip = _lookAhead(tokenIds, i, token, true);
        }
        emit Rushed(msg.sender, tokenIds);
    }

    function fastForward(
        address owner,
        uint256[] calldata tokenIds,
        uint256 numberOfDays
    ) public {
        if (tokenIds.length == 0) return;
        if (numberOfDays == 0) return;

        Token memory token;
        bool skip;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (!skip) {
                token = resolveToken(tokenId);

                if (token.owner != owner) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = calculateIncubationPhase(
                    token.incubationPhase,
                    token.stakeTimestamp,
                    token.generation
                );

                uint256 max = token.generation == 0
                    ? initialIncubationLength
                    : remixIncubationLength;

                if (phase >= max) revert NotAllowed();

                tokens[tokenId] = token;
                tokens[tokenId].stakeTimestamp -= uint32(
                    numberOfDays * 24 * 3600
                );
            }

            skip = _lookAhead(tokenIds, i, token, true);
        }
        emit FastForwardedFull(tokenIds, numberOfDays);
    }

    function _lookAhead(
        uint256[] calldata tokenIds,
        uint256 index,
        Token memory current,
        bool modified
    ) public returns (bool sequential) {
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

    function configureStakingWindows(
        uint256 initialLength,
        uint256 remixLength
    ) public onlyOwner {
        initialIncubationLength = initialLength;
        remixIncubationLength = remixLength;
    }

    function setIncubator(address addr) public onlyOwner {
        incubator = IIncubator(addr);
    }

    function startNexGeneration() public onlyOwner {
        activeGeneration++;
    }

    function finalizeGeneration(
        uint256 gen,
        string calldata uri
    ) public onlyOwner {
        finalizedGeneration = gen;
        baseURIFinalized = uri;
    }
}