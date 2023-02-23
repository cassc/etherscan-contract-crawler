// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interfaces/IStoreNFT.sol";
import "./Initialize.sol";
import "./Signature.sol";
import "./ExternalContracts.sol";

// @author: miinded.com

abstract contract StoreNFT is IStoreNFT, Initialize, Signature, ExternalContracts, ReentrancyGuard, ERC1155Receiver, IERC721Receiver {

    function init(address _multiSigContract, address[] memory _externalContracts) public onlyOwner isNotInitialized {
        MultiSigProxy._setMultiSigContract(_multiSigContract);

        for (uint256 i = 0; i < _externalContracts.length; i++) {
            ExternalContracts._setExternalContract(_externalContracts[i], true);
        }
    }

    // Transfer

    function Transfer(address _collection, uint256 _id, uint256 _count, uint256 _signatureId, bytes memory _signature)
    external signedUnique(_canTransfer(_collection, _id, _count, _signatureId), _signatureId, _signature) nonReentrant {
        _transfer(_msgSender(), _collection, _id, _count);
    }

    function TransferByAdmin(address _to, address _collection, uint256 _id, uint256 _count) external onlyOwnerOrAdmins nonReentrant {
        _transfer(_to, _collection, _id, _count);
    }

    function TransferExternal(address _to, address _collection, uint256 _id, uint256 _count) external override externalContract nonReentrant {
        _transfer(_to, _collection, _id, _count);
    }

    // Transfer Batch

    function TransferBatch(address _collection, uint256[] memory _ids, uint256[] memory _counts, uint256 _signatureId, bytes memory _signature)
    external signedUnique(_canTransferBatch(_collection, _ids, _counts, _signatureId), _signatureId, _signature) nonReentrant {
        require(_ids.length == _counts.length, "StoreNFT: length mismatch");

        _transferBatch(_msgSender(), _collection, _ids, _counts);
    }

    function TransferBatchByAdmin(address _to, address _collection, uint256[] memory _ids, uint256[] memory _counts) external onlyOwnerOrAdmins nonReentrant {
        require(_ids.length == _counts.length, "StoreNFT: length mismatch");

        _transferBatch(_to, _collection, _ids, _counts);
    }

    function TransferBatchExternal(address _to, address _collection, uint256[] memory _ids, uint256[] memory _counts) external override externalContract nonReentrant {
        require(_ids.length == _counts.length, "StoreNFT: length mismatch");

        _transferBatch(_to, _collection, _ids, _counts);
    }

    // internals

    function _transfer(address _to, address _collection, uint256 _id, uint256 _count) internal {
        if (isERC721(_collection)) {
            _transfer721(_collection, _to, _id);
        } else if (isERC1155(_collection)) {
            _transfer1155(_collection, _to, _id, _count);
        } else {
            revert("StoreNFT: Not a ERC721 or ERC1155 token");
        }
    }

    function _transferBatch(address _to, address _collection,  uint256[] memory _ids, uint256[] memory _counts) internal {
        if (isERC721(_collection)) {
            for (uint256 i = 0; i < _ids.length; i++) {
                _transfer721(_collection, _to, _ids[i]);
            }
        } else if (isERC1155(_collection)) {
            _transferBatch1155(_collection, _to, _ids, _counts);
        } else {
            revert("StoreNFT: Not a ERC721 or ERC1155 token");
        }
    }

    function _transfer721(address _collection, address _to, uint256 _tokenId) internal {
        IERC721(_collection).safeTransferFrom(address(this), _to, _tokenId);
    }

    function _transfer1155(address _collection, address _to, uint256 _id, uint256 _count) internal {
        IERC1155(_collection).safeTransferFrom(address(this), _to, _id, _count, "");
    }

    function _transferBatch1155(address _collection, address _to, uint256[] memory _ids, uint256[] memory _counts) internal {
        IERC1155(_collection).safeBatchTransferFrom(address(this), _to, _ids, _counts, "");
    }

    function isERC721(address _collection) public view returns (bool) {
        return ERC165Checker.supportsInterface(_collection, type(IERC721).interfaceId);
    }

    function isERC1155(address _collection) public view returns (bool) {
        return ERC165Checker.supportsInterface(_collection, type(IERC1155).interfaceId);
    }

    function _canTransfer(address _collection, uint256 _id, uint256 _count, uint256 _signatureId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_msgSender(), _collection, _id, _count, _signatureId, HASH_SIGN));
    }

    function _canTransferBatch(address _collection, uint256[] memory _ids, uint256[] memory _counts, uint256 _signatureId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_msgSender(), _collection, _ids, _counts, _signatureId, HASH_SIGN));
    }

    // external

    function balanceOf(address _collection) external view override returns (uint256) {
        return IERC721(_collection).balanceOf(address(this));
    }

    function balanceOf(address _collection, uint256 _id) external view override returns (uint256) {
        return IERC1155(_collection).balanceOf(address(this), _id);
    }

    // Received

    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external override pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}