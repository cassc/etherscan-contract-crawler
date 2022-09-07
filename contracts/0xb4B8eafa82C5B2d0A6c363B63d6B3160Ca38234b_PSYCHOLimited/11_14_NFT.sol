// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../interfaces/IErrors.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Receiver.sol";

/**
 * @dev Implementation of the ERC721 standard
 */
contract NFT is
    IERC721,
    IErrors {

    // Mapping token ID to owner address
    mapping(uint256 => address) private _tokenOwner;

    // Mapping address to total tokens owned
    mapping(address => uint256) private _ownerBalance;

    // Mapping token ID to approved spender address
    mapping(uint256 => address) private _tokenApproval;

    // Mapping address to approved operator
    mapping(address => mapping(
        address => bool
    )) private _operatorApproval;

    // Mapping token ID to meta struct
    mapping(uint256 => Meta) private _tokenMeta;

    // Current token ID variable
    uint256 private _currentIdCount;

    // Reentrancy guard variable
    bool private _reentrant;

    // Meta struct
    struct Meta { 
        uint256 mood;
        uint256 grade;
    }
    Meta meta;

    /**
     * @dev Constructs reentrancy status
     */
    constructor() {
        _reentrant = false;
    }

    /**
     * @dev Pseudo number operations
     */
    function _x(
    ) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty
                )
            )
    );}

    function _y(
    ) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(block.difficulty)
            )
    );}

    function _z(
    ) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(block.timestamp)
            )
    );}

    function _t(
        uint256 _nonce
    ) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    _x(),
                    _y(),
                    _nonce)
                )
    ) % 21;}

    function _g(
        uint256 _nonce
    ) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    _z(),
                    _t(_nonce * 33),
                    _nonce)
                )
    ) % 6;}

    /**
     * @dev Reentrancy guard
     */
    modifier guard() {
        if (_reentrant == true) {
            revert NonReentrant();
        }
        _reentrant = true;
        _;
        _reentrant = false;
    }

    /**
     * @dev Loop function for genesis
     */
    function _loop(
        address _to
    ) private {
        _currentIdCount += 1;
        _tokenMeta[_currentIdCount] =
            Meta(_t(_currentIdCount),
            _g(_currentIdCount));
        _tokenOwner[_currentIdCount] = _to;
        emit Transfer(
            address(0),
            _to,
            _currentIdCount
        );
    }

    /**
     * @dev Token genesis
     */
    function _genesis(
        address _to,
        uint256 _quantity
    ) internal {
        if (_to == address(0)) {
            revert TransferToZeroAddress();
        }
        _ownerBalance[_to] += _quantity;
        for (uint256 i=0; i < _quantity; i++) {
            _loop(_to);
        }
    }

    /**
     * @dev Generates avatars
     */
    function _generate(
        address _to,
        uint256 _quantity
    ) internal {
        if (tx.origin != msg.sender) {
            revert TxOriginNonSender();
        }
        _genesis(
            _to,
            _quantity
        );
    }

    /**
     * @dev Returns meta struct for token ID
     */
    function _meta(
        uint256 _tokenId
    ) internal view returns (Meta memory) {
        return _tokenMeta[_tokenId];
    }

    /**
     * @dev Returns `true` if token ID exists
     */
    function _exists(
        uint256 _tokenId
    ) internal view virtual returns (bool) {
        return _tokenOwner[_tokenId] != address(0);
    }

    /**
     * @dev Returns total supply
     */
    function totalSupply(
    ) public view returns (uint256) {
        return (_currentIdCount);
    }

    /**
     * @dev Returns owner balance
     */
    function balanceOf(
        address _owner
    ) public view override(
        IERC721
    ) returns (uint256) {
        return _ownerBalance[_owner];
    }

    /**
     * @dev Returns owner of token ID
     */
    function ownerOf(
        uint256 _tokenId
    ) public view override(
        IERC721
    ) returns (address) {
        return _tokenOwner[_tokenId];
    }

    /**
     * @dev Safe {_transfer}
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(
        IERC721
    ) {
        safeTransferFrom(
            _from,
            _to,
            _tokenId,
            ""
        );
    }

    /**
     * @dev Safe {_transfer} overload
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override(
        IERC721
    ) {
        if (!_isApprovedOrOwner(
            msg.sender,
            _tokenId
        )) {
            revert NonApprovedNonOwner();
        }
        _transfer(
            _from,
            _to,
            _tokenId
        );
        _onERC721Received(
            _from,
            _to,
            _tokenId,
            _data
        );
    }

    /**
     * @dev {_transfer} if approved or owner
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(
        IERC721
    ) {
        if (!_isApprovedOrOwner(
            msg.sender,
            _tokenId
        )) {
            revert NonApprovedNonOwner();
        }
        _transfer(
            _from,
            _to,
            _tokenId
        );
    }

    /**
     * @dev Approves address for spending tokens
     */
    function approve(
        address _approved,
        uint256 _tokenId
    ) public override(
        IERC721
    ) {
        require(
            _tokenOwner[_tokenId] == msg.sender
        );
        _tokenApproval[_tokenId] = _approved;
        emit Approval(
            msg.sender,
            _approved,
            _tokenId
        );
    }

    /**
     * @dev Sets approved for all operator
     */
    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public override(
        IERC721
    ) {
        if (msg.sender == _operator) {
            revert ApproveOwnerAsOperator();
        }
        _operatorApproval[msg.sender][_operator] =
            _approved;
        emit ApprovalForAll(
            msg.sender,
            _operator,
            _approved
        );
    }

    /**
     * @dev Returns approved spender
     */
    function getApproved(
        uint256 _tokenId
    ) public view override(
        IERC721
    ) returns (address) {
        return _tokenApproval[_tokenId];
    }

    /**
     * @dev Returns `true` if operator
     * is approved to spend owner tokens
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override(
        IERC721
    ) returns (bool) {
        return _operatorApproval[_owner][_operator];
    }

    /**
     * @dev Bool for whether spender is allowed
     */
    function _isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    ) internal view virtual returns (bool) {
        address tokenOwner = ownerOf(_tokenId);
        return (
            _spender == tokenOwner ||
            isApprovedForAll(
                tokenOwner,
                _spender
            ) ||
            getApproved(_tokenId) == _spender
        );
    }

    /**
     * @dev Transfers token and emits event
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        if (ownerOf(_tokenId) != _from) {
            revert TransferFromNonOwner();
        }
        if (_to == address(0)) {
            revert TransferToZeroAddress();
        }
        delete _tokenApproval[_tokenId];
        _ownerBalance[_from] -= 1;
        _ownerBalance[_to] += 1;
        _tokenOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev ERC721 receiver
     */
    function _onERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            ) returns (bytes4 retval) {
                return retval ==
                    IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}