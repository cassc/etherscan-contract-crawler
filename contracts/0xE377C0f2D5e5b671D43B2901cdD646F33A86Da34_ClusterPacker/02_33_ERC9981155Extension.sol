// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ERC998TopDown.sol";
import "../interfaces/IERC998ERC1155TopDown.sol";

abstract contract ERC9981155Extension is ERC998TopDown, IERC998ERC1155TopDown, IERC1155Receiver {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal balances;

    function childBalance(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) external view override returns (uint256) {
        return balances[_tokenId][_childContract][_childTokenId];
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC998TopDown, IERC165)
        returns (bool)
    {
        return
            _interfaceId == type(IERC998ERC1155TopDown).interfaceId ||
            _interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    function safeTransferChild(
        uint256 _tokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId,
        uint256 _amount,
        bytes memory _data
    ) external override nonReentrant {
        _validateReceiver(_to);
        _validate1155ChildTransfer(_tokenId);
        _remove1155Child(_tokenId, _childContract, _childTokenId, _amount);
        if (_to == address(this)) {
            _validateAndReceive1155Child(msg.sender, _childContract, _childTokenId, _amount, _data);
        } else {
            IERC1155(_childContract).safeTransferFrom(address(this), _to, _childTokenId, _amount, _data);
            emit Transfer1155Child(_tokenId, _to, _childContract, _childTokenId, _amount);
        }
    }

    function safeBatchTransferChild(
        uint256 _tokenId,
        address _to,
        address _childContract,
        uint256[] memory _childTokenIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) external override nonReentrant {
        require(_childTokenIds.length == _amounts.length, "ids and amounts length mismatch");
        _validateReceiver(_to);

        _validate1155ChildTransfer(_tokenId);
        for (uint256 i = 0; i < _childTokenIds.length; ++i) {
            uint256 childTokenId = _childTokenIds[i];
            uint256 amount = _amounts[i];

            _remove1155Child(_tokenId, _childContract, childTokenId, amount);
            if (_to == address(this)) {
                _validateAndReceive1155Child(msg.sender, _childContract, childTokenId, amount, _data);
            }
        }

        if (_to != address(this)) {
            IERC1155(_childContract).safeBatchTransferFrom(address(this), _to, _childTokenIds, _amounts, _data);
            emit Transfer1155BatchChild(_tokenId, _to, _childContract, _childTokenIds, _amounts);
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        revert("external calls restricted");
    }

    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) external virtual override nonReentrant returns (bytes4) {
        require(_data.length == 32, "data must contain tokenId to transfer the child token to");
        uint256 _receiverTokenId = _parseTokenId(_data);

        for (uint256 i = 0; i < _ids.length; i++) {
            _receive1155Child(_receiverTokenId, msg.sender, _ids[i], _values[i]);
            emit Received1155Child(_from, _receiverTokenId, msg.sender, _ids[i], _values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function _validateAndReceive1155Child(
        address _from,
        address _childContract,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal virtual {
        require(_data.length == 32, "data must contain tokenId to transfer the child token to");

        uint256 _receiverTokenId = _parseTokenId(_data);
        _receive1155Child(_receiverTokenId, _childContract, _id, _amount);
        emit Received1155Child(_from, _receiverTokenId, _childContract, _id, _amount);
    }

    function _receive1155Child(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId,
        uint256 _amount
    ) internal virtual {
        require(_exists(_tokenId), "bundle tokenId does not exist");
        uint256 childTokensLength = childTokens[_tokenId][_childContract].length();
        if (childTokensLength == 0) {
            childContracts[_tokenId].add(_childContract);
        }
        childTokens[_tokenId][_childContract].add(_childTokenId);
        balances[_tokenId][_childContract][_childTokenId] += _amount;
    }

    function _validate1155ChildTransfer(uint256 _fromTokenId) internal virtual {
        _validateTransferSender(_fromTokenId);
    }

    function _remove1155Child(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId,
        uint256 _amount
    ) internal virtual {
        require(
            _amount != 0 && balances[_tokenId][_childContract][_childTokenId] >= _amount,
            "insufficient child balance for transfer"
        );
        balances[_tokenId][_childContract][_childTokenId] -= _amount;

        if (balances[_tokenId][_childContract][_childTokenId] == 0) {
            childTokens[_tokenId][_childContract].remove(_childTokenId);

            if (childTokens[_tokenId][_childContract].length() == 0) {
                childContracts[_tokenId].remove(_childContract);
            }
        }
    }
}