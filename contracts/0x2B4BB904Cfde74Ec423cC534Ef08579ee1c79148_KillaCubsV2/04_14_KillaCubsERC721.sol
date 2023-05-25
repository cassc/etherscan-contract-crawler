// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./KillaCubsStorage.sol";

abstract contract KillaCubsERC721 is KillaCubsStorage {
    constructor(
        address bitsAddress,
        address gearAddress,
        address bearsAddress,
        address passesAddress,
        address kiltonAddress,
        address labsAddress,
        address superOwner
    )
        KillaCubsStorage(
            bitsAddress,
            gearAddress,
            bearsAddress,
            passesAddress,
            kiltonAddress,
            labsAddress,
            superOwner
        )
    {
        name = "KillaCubs";
        symbol = "KillaCubs";
        _setDefaultRoyalty(msg.sender, 500);
    }

    function _mint(address to, uint256 n, bool staked) internal {
        uint256 tokenId = 3334 + counters.batched;
        uint256 end = tokenId + n - 1;
        if (end > 8888) revert NotAllowed();

        Token storage token = tokens[tokenId];
        token.owner = to;

        counters.batched += uint16(n);
        wallets[to].batchedMints += uint16(n);

        if (staked) {
            incubator.add(to, tokenId, n);
            token.stakeTimestamp = uint32(block.timestamp);
            counters.stakes += uint16(n);
            wallets[to].stakes += uint16(n);

            while (tokenId <= end) {
                emit Transfer(address(0), to, tokenId);
                emit Transfer(to, address(this), tokenId);
                tokenId++;
            }
        } else {
            wallets[to].balance += uint16(n);
            while (tokenId <= end) {
                emit Transfer(address(0), to, tokenId);
                tokenId++;
            }
        }
    }

    function _mint(
        address to,
        uint256[] calldata tokenIds,
        bool staked
    ) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];

            Token storage token = tokens[id];

            if (id == 0) revert NotAllowed();
            if (token.owner != address(0)) revert NotAllowed();
            if (token.linkedPrev != 0) revert NotAllowed();

            token.owner = to;
            emit Transfer(address(0), to, id);

            if (staked) {
                emit Transfer(to, address(this), id);
                token.stakeTimestamp = uint32(block.timestamp);
            }

            if (i == 0) {
                token.owner = to;
            } else {
                token.linkedPrev = uint16(tokenIds[i - 1]);
                tokens[tokenIds[i - 1]].linkedNext = uint16(id);
            }
        }

        counters.linked += uint16(tokenIds.length);
        if (staked) {
            counters.stakes += uint16(tokenIds.length);
            wallets[to].stakes += uint16(tokenIds.length);
            incubator.add(to, tokenIds);
        } else {
            wallets[to].balance += uint16(tokenIds.length);
        }
        wallets[to].linkedMints += uint16(tokenIds.length);
    }

    function totalSupply() public view virtual returns (uint256) {
        return counters.linked + counters.batched;
    }

    function balanceOf(
        address owner
    ) external view virtual returns (uint256 balance) {
        if (owner == address(this)) return counters.stakes;
        return wallets[owner].balance;
    }

    function ownerOf(uint256 id) public view virtual returns (address) {
        Token memory token = resolveToken(id);
        if (token.stakeTimestamp != 0) return address(this);
        return token.owner;
    }

    function rightfulOwnerOf(
        uint256 tokenId
    ) public view virtual returns (address) {
        return resolveToken(tokenId).owner;
    }

    function resolveToken(uint256 id) public view returns (Token memory) {
        Token memory token = tokens[id];
        if (token.owner == address(0)) {
            Token memory temp = token;
            if (token.linkedPrev != 0) {
                do token = tokens[token.linkedPrev]; while (
                    token.owner == address(0)
                );
            } else if (id > 3333 && id <= 3333 + counters.batched) {
                do token = tokens[--id]; while (token.owner == address(0));
            } else {
                revert NonExistentToken();
            }

            token.bit = temp.bit;
            token.linkedNext = temp.linkedNext;
            token.linkedPrev = temp.linkedPrev;
        }
        return token;
    }

    function resolveTokens(
        uint256[] calldata ids
    ) public view returns (Token[] memory) {
        Token[] memory ret = new Token[](ids.length);
        bool skip = false;
        Token memory token;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            if (skip) skip = false;
            else token = resolveToken(id);

            ret[i] = token;

            uint256 nextId;
            if (token.linkedNext != 0) {
                nextId = token.linkedNext;
            } else if (id > 3333 && id < 3333 + counters.batched) {
                nextId = id + 1;
            } else {
                continue;
            }

            if (tokens[nextId].owner != address(0)) continue;
            if (i + 1 < ids.length && ids[i + 1] == nextId) {
                skip = true;
                token.bit = tokens[nextId].bit;
                token.linkedNext = tokens[nextId].linkedNext;
                token.linkedPrev = tokens[nextId].linkedPrev;
                continue;
            }
        }
        return ret;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);
        if (to.code.length != 0)
            if (!_checkOnERC721Received(from, to, id, data))
                revert TransferToNonERC721ReceiverImplementer();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);
        if (to.code.length != 0)
            if (!_checkOnERC721Received(from, to, id, ""))
                revert TransferToNonERC721ReceiverImplementer();
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual onlyAllowedOperator(from) {
        if (to == from) revert NotAllowed();
        if (to == address(0)) revert NotAllowed();

        Token memory token = resolveToken(id);

        if (token.stakeTimestamp > 0 || token.owner != from)
            revert NotAllowed();

        if (msg.sender != token.owner) {
            if (
                !operatorApprovals[token.owner][msg.sender] &&
                tokenApprovals[id] != msg.sender
            ) revert NotAllowed();
        }

        if (tokenApprovals[id] != address(0)) {
            delete tokenApprovals[id];
            emit Approval(from, address(0), id);
        }

        emit Transfer(token.owner, to, id);
        _bakeNextToken(token, id);

        token.owner = to;

        wallets[from].balance--;
        wallets[to].balance++;
        tokens[id] = token;
    }

    function _bakeNextToken(Token memory current, uint256 id) internal {
        uint256 nextId;
        if (current.linkedNext != 0) {
            nextId = current.linkedNext;
        } else if (id > 3333) {
            nextId = id + 1;
            if (nextId > 3333 + counters.batched) return;
        } else {
            return;
        }

        Token memory temp = tokens[nextId];
        if (temp.owner != address(0)) return;

        tokens[nextId] = current;

        tokens[nextId].linkedNext = temp.linkedNext;
        tokens[nextId].linkedPrev = temp.linkedPrev;
        tokens[nextId].bit = temp.bit;
    }

    function approve(
        address to,
        uint256 id
    ) public virtual onlyAllowedOperatorApproval(to) {
        address owner = ownerOf(id);
        if (msg.sender != owner) {
            if (!isApprovedForAll(owner, msg.sender)) {
                revert NotAllowed();
            }
        }

        tokenApprovals[id] = to;
        emit Approval(msg.sender, to, id);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual onlyAllowedOperatorApproval(operator) {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(
        uint256 id
    ) external view virtual returns (address operator) {
        return tokenApprovals[id];
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f || // ERC721Metadata;
            interfaceId == 0x4e2312e0 || // ERC1155Receiver
            interfaceId == 0x2a55205a; // ERC2981
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function calculateIncubationPhase(
        uint256 phase,
        uint256 ts,
        uint256 gen
    ) public view returns (uint256) {
        if (ts != 0) {
            phase += (block.timestamp - ts) / 1 weeks;
        }
        uint256 max = gen == 0
            ? initialIncubationLength
            : remixIncubationLength;
        if (phase > max) return max;
        return phase;
    }

    function getIncubationPhase(uint256 id) public view returns (uint256) {
        Token memory token = resolveToken(id);
        return
            calculateIncubationPhase(
                token.incubationPhase,
                token.stakeTimestamp,
                token.generation
            );
    }

    function getGeneration(uint256 id) public view returns (uint256) {
        if (laterGenerations[id] != 0) return laterGenerations[id];
        Token memory token = resolveToken(id);
        return token.generation;
    }
}