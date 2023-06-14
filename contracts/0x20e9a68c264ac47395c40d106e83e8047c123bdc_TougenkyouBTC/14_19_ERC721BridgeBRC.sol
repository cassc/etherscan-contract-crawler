// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract ERC721BridgeBRC is IERC721Receiver {
    event OperatorGranted(address indexed account, address indexed sender);
    event OperatorRevoked(address indexed account, address indexed sender);
    event TokenReceived(
        address indexed operator,
        address indexed from,
        uint256 tokenId
    );

    address public originalContract;
    address public bridgeContract;
    mapping(address => bool) private _operator;

    function _registOriginalContractAddress(address _contract) internal {
        originalContract = _contract;
    }

    function _registBridgeContractAddress(address _contract) internal {
        bridgeContract = _contract;
    }

    /**
     * @dev Returns `true` if this contract has original NFT. Regist Original contract to call this function.
     */
    function hasOriginalNFT(
        uint256 originalTokenId
    ) public view virtual returns (bool) {
        require(
            originalContract != address(0),
            "OriginalContract address is 0"
        );
        return
            IERC721(originalContract).ownerOf(originalTokenId) == address(this);
    }

    function _grantOperator(address account) internal virtual {
        _operator[account] = true;
        emit OperatorGranted(account, msg.sender);
    }

    function _revokeOperator(address account) internal virtual {
        _operator[account] = false;
        emit OperatorRevoked(account, msg.sender);
    }

    /**
     * @dev Returns `true` if `account` has been granted operator.
     */
    function hasOperator(address account) public view virtual returns (bool) {
        return _operator[account];
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Check safeTransfer is only Operator.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(hasOperator(operator), "token transfer need operator role");
        emit TokenReceived(operator, from, tokenId);
        return this.onERC721Received.selector;
    }
}