// SPDX-License-Identifier: MIT
// Creator: [email protected]

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IBoundERC721Receiver {
    function onBoundERC721Received(
        address operator,
        address to,
        uint256 boundTokenId,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Burnable {
    function burn(uint256 tokenId) external;

    function removeSlave(uint256 tokenId) external;
}

// @dev The implementation is to bind the NFT (master) and its airdrop NFT (slave).
// The airdrop NFT cannot be transferred or sold separately.
// The slave nfts will be transferred or sold with the master nft.
abstract contract ERC721Attachable is Ownable, ERC721 {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct BoundToken {
        address collection;
        uint256 tokenId;
    }

    // slave tokenId => master token
    mapping(uint256 => BoundToken) public slaveTokens;
    // master tokenId => slave token
    mapping(uint256 => BoundToken[]) private _masterTokens;
    // collection => tokenId => index
    mapping(address => mapping(uint256 => uint256)) private _slaveTokenIndex;

    EnumerableSet.AddressSet private _slaveCollections;

    // Grant the specified address the permission to transfer slave nft for airdrop NFT deposit into the game contract.
    EnumerableSet.AddressSet private _transferApprovals;

    event CollectionRemoved(address indexed collection);
    event CollectionAdded(address indexed collection);

    event TransferApprove(address indexed operator);
    event TransferDisapprove(address indexed operator);

    function allSlaveTokenLength(uint256 tokenId) public view returns (uint256) {
        return _masterTokens[tokenId].length;
    }

    function addCollection(address collection) external onlyOwner {
        require(!_slaveCollections.contains(collection), "ERC721Attachable: collection already slave");
        _slaveCollections.add(collection);

        emit CollectionAdded(collection);
    }

    function removeCollection(address collection) external onlyOwner {
        require(_slaveCollections.contains(collection), "ERC721Attachable: collection not slave");
        _slaveCollections.remove(collection);

        emit CollectionRemoved(collection);
    }

    function isSlaveCollection(address collection) public view returns (bool) {
        return _slaveCollections.contains(collection);
    }

    function addTransferApproval(address operator) external onlyOwner {
        require(!_transferApprovals.contains(operator), "ERC721Attachable: already approved");
        _transferApprovals.add(operator);

        emit TransferApprove(operator);
    }

    function removeTransferApproval(address operator) external onlyOwner {
        require(_transferApprovals.contains(operator), "ERC721Attachable: not approved");
        _transferApprovals.remove(operator);

        emit TransferDisapprove(operator);
    }

    function isTransferApproval(address operator) public view returns (bool) {
        return _transferApprovals.contains(operator);
    }

    function isSlaveToken(uint256 tokenId) public view returns (bool) {
        return slaveTokens[tokenId].collection != address(0);
    }

    function masterOf(uint256 tokenId) public view returns (address) {
        require(isSlaveToken(tokenId), "ERC721Attachable: not slave token");

        return slaveTokens[tokenId].collection;
    }

    function slaveTokenByIndex(uint256 tokenId, uint256 index) public view returns (BoundToken memory) {
        require(index < _masterTokens[tokenId].length, "ERC721Attachable: tokenId index out of bounds");
        return _masterTokens[tokenId][index];
    }

    function _slaveMint(
        address to,
        uint256 tokenId,
        address collection,
        uint256 masterTokenId
    ) internal virtual {
        BoundToken storage at = slaveTokens[tokenId];
        at.collection = collection;
        at.tokenId = masterTokenId;

        require(
            _checkOnBoundERC721Received(collection, to, tokenId, masterTokenId, ""),
            "ERC721Attachable: transfer to non BoundERC721Receiver implementer"
        );

        _mint(to, tokenId);
    }

    function _removeSlave(uint256 tokenId) internal virtual {
        require(isSlaveToken(tokenId), "ERC721Attachable: not slave token");

        BoundToken storage at = slaveTokens[tokenId];
        require(
            _checkOnBoundERC721Received(at.collection, address(0), tokenId, at.tokenId, ""),
            "ERC721Attachable: transfer to non BoundERC721Receiver implementer"
        );

        delete slaveTokens[tokenId];
    }

    function _removeMaster(uint256 tokenId) internal virtual {
        require(allSlaveTokenLength(tokenId) > 0, "ERC721Attachable: no slave token");

        uint256 slaveNum = allSlaveTokenLength(tokenId);
        for (uint256 i = 0; i < slaveNum; i++) {
            IERC721Burnable(_masterTokens[tokenId][i].collection).removeSlave(_masterTokens[tokenId][i].tokenId);
        }
        delete _masterTokens[tokenId];
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        BoundToken storage at = slaveTokens[tokenId];
        if (at.collection != address(0)) {
            require(
                _checkOnBoundERC721Received(at.collection, address(0), tokenId, at.tokenId, ""),
                "ERC721Attachable: transfer to non BoundERC721Receiver implementer"
            );

            delete slaveTokens[tokenId];
        }

        uint256 slaveNum = allSlaveTokenLength(tokenId);
        if (slaveNum > 0) {
            for (uint256 i = 0; i < slaveNum; i++) {
                IERC721Burnable(_masterTokens[tokenId][i].collection).burn(_masterTokens[tokenId][i].tokenId);
            }
            delete _masterTokens[tokenId];
        }
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (slaveTokens[tokenId].collection != address(0)) {
            if (msg.sender == slaveTokens[tokenId].collection) {
                _transfer(from, to, tokenId);
            } else {
                require(_transferApprovals.contains(msg.sender), "ERC721Attachable: slave token transfer not allowed");
                super.transferFrom(from, to, tokenId);
            }
        } else {
            super.transferFrom(from, to, tokenId);

            for (uint256 i = 0; i < _masterTokens[tokenId].length; i++) {
                IERC721(_masterTokens[tokenId][i].collection).transferFrom(from, to, _masterTokens[tokenId][i].tokenId);
            }
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        if (slaveTokens[tokenId].collection != address(0)) {
            if (msg.sender == slaveTokens[tokenId].collection) {
                _safeTransfer(from, to, tokenId, data);
            } else {
                require(_transferApprovals.contains(msg.sender), "ERC721Attachable: slave token transfer not allowed");
                super.safeTransferFrom(from, to, tokenId, data);
            }
        } else {
            super.safeTransferFrom(from, to, tokenId, data);

            for (uint256 i = 0; i < _masterTokens[tokenId].length; i++) {
                IERC721(_masterTokens[tokenId][i].collection).safeTransferFrom(
                    from,
                    to,
                    _masterTokens[tokenId][i].tokenId,
                    data
                );
            }
        }
    }

    function onBoundERC721Received(
        address, /*operator*/
        address to,
        uint256 boundTokenId,
        uint256 tokenId,
        bytes calldata /*data*/
    ) external returns (bytes4) {
        require(isSlaveCollection(msg.sender), "ERC721Attachable: slave to non boundERC721 receiver");

        if (to != address(0)) {
            require(ownerOf(tokenId) == to, "ERC721Attachable: slave to incorrect owner");

            _slaveTokenIndex[msg.sender][boundTokenId] = _masterTokens[tokenId].length;

            _masterTokens[tokenId].push(BoundToken(msg.sender, boundTokenId));
        } else {
            _removeTokenFromMasterTokens(tokenId, msg.sender, boundTokenId);
        }

        return this.onBoundERC721Received.selector;
    }

    function _checkOnBoundERC721Received(
        address from,
        address to,
        uint256 tokenId,
        uint256 masterTokenId,
        bytes memory _data
    ) private returns (bool) {
        try IBoundERC721Receiver(from).onBoundERC721Received(msg.sender, to, tokenId, masterTokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == IBoundERC721Receiver.onBoundERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721Attachable: transfer to non BoundERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function _removeTokenFromMasterTokens(
        uint256 tokenId,
        address collection,
        uint256 boundTokenId
    ) private {
        uint256 lastTokenIndex = _masterTokens[tokenId].length - 1;
        uint256 tokenIndex = _slaveTokenIndex[collection][boundTokenId];

        BoundToken storage bToken = _masterTokens[tokenId][lastTokenIndex];
        _masterTokens[tokenId][tokenIndex] = BoundToken(bToken.collection, bToken.tokenId);
        _slaveTokenIndex[bToken.collection][bToken.tokenId] = tokenIndex;

        delete _slaveTokenIndex[collection][boundTokenId];
        _masterTokens[tokenId].pop();
    }
}