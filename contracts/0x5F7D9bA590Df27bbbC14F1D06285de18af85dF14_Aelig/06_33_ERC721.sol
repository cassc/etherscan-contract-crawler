// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721TokenReceiver.sol";
import "../libraries/AddressUtils.sol";
import "../libraries/Errors.sol";
import "../libraries/Constants.sol";


contract ERC721 is
    IERC721
{
    using AddressUtils for address;

    mapping (uint256 => address) internal idToOwner;
    mapping (uint256 => address) internal idToApproval;
    mapping (address => uint256) private ownerToNFTokenCount;
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    /**
        @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
        @param _tokenId ID of the NFT to validate.
    */
    modifier canOperate(
        uint256 _tokenId,
        address _operator
    )
    {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == _operator || ownerToOperators[tokenOwner][_operator],
            errors.NOT_OWNER_OR_OPERATOR
        );
        _;
    }

    /**
        @dev Guarantees that the msg.sender is allowed to transfer NFT (msg.sender is owner, or approved, or operator).
        @param _tokenId ID of the NFT to transfer.
    */
    modifier canTransfer(
        uint256 _tokenId
    )
    {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
            idToApproval[_tokenId] == msg.sender ||
            ownerToOperators[tokenOwner][msg.sender],
            errors.NOT_OWNER_APPROVED_OR_OPERATOR
        );
        _;
    }

    /**
        @dev Guarantees that _tokenId is a valid Token.
        @param _tokenId ID of the NFT to validate.
    */
    modifier validNFToken(
        uint256 _tokenId
    )
    {
        require(idToOwner[_tokenId] != address(0), errors.NOT_VALID_NFT);
        _;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        override
    {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        override
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        override
        canTransfer(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, errors.NOT_OWNER);
        require(_to != address(0), errors.ZERO_ADDRESS);

        _transfer(_to, _tokenId);
    }

    function approve(
        address _approved,
        uint256 _tokenId
    )
        external
        override
        canOperate(_tokenId, msg.sender)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner, errors.IS_OWNER);

        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
        override
    {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(
        address _owner
    )
        external
        override
        view
        returns (uint256)
    {
        require(_owner != address(0), errors.ZERO_ADDRESS);
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(
        uint256 _tokenId
    )
        external
        override
        view
        returns (address)
    {
        return _ownerOf(_tokenId);
    }

    function _ownerOf(
        uint256 _tokenId
    )
        internal
        view
        returns(address)
    {
        require(idToOwner[_tokenId] != address(0), errors.NOT_VALID_NFT);
        return idToOwner[_tokenId];
    }

    function getApproved(
        uint256 _tokenId
    )
        external
        override
        view
        validNFToken(_tokenId)
        returns (address)
    {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    )
        external
        override
        view
        returns (bool)
    {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(
        address _to,
        uint256 _tokenId
    )
        internal
        virtual
    {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function _mint(
        address _to,
        uint256 _tokenId
    )
        internal
        virtual
    {
        require(_to != address(0), errors.ZERO_ADDRESS);
        require(idToOwner[_tokenId] == address(0), errors.NFT_ALREADY_EXISTS);

        _addNFToken(_to, _tokenId);

        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(
        uint256 _tokenId
    )
        internal
        virtual
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        _clearApproval(_tokenId);
        _removeNFToken(tokenOwner, _tokenId);
        emit Transfer(tokenOwner, address(0), _tokenId);
    }

    function _removeNFToken(
        address _from,
        uint256 _tokenId
    )
        internal
        virtual
    {
        require(idToOwner[_tokenId] == _from, errors.NOT_OWNER);
        ownerToNFTokenCount[_from] -= 1;
        delete idToOwner[_tokenId];
    }

    function _addNFToken(
        address _to,
        uint256 _tokenId
    )
        internal
        virtual
    {
        require(idToOwner[_tokenId] == address(0), errors.NFT_ALREADY_EXISTS);

        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] += 1;
    }

    function _getOwnerNFTCount(
        address _owner
    )
        internal
        virtual
        view
        returns (uint256)
    {
        return ownerToNFTokenCount[_owner];
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        private
        canTransfer(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, errors.NOT_OWNER);
        require(_to != address(0), errors.ZERO_ADDRESS);

        _transfer(_to, _tokenId);

        if (_to.isContract())
        {
            bytes4 retval = IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == constants.MAGIC_ON_ERC721_RECEIVED, errors.NOT_ABLE_TO_RECEIVE_NFT);
        }
    }

    function _clearApproval(
        uint256 _tokenId
    )
        private
    {
        delete idToApproval[_tokenId];
    }

}