// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is a fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IERC721Manager } from '../interfaces/IERC721Manager.sol';
import { IERC721ManagerHelper } from '../interfaces/IERC721ManagerHelper.sol';
import { ICollectionProxy } from './ICollectionProxy.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract CollectionProxy is ICollectionProxy {
    address public collectionManagerProxy;

    address public collectionManagerHelperProxy;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(
            tx.origin == msg.sender,
            'CollectionProxy::senderOrigin: FORBIDDEN, not a direct call'
        );
        _;
    }

    function collectionManager() private view returns (address _collectionManager) {
        _collectionManager = address(
            IGovernedProxy_New(address(uint160(collectionManagerProxy))).implementation()
        );
    }

    function collectionManagerHelper() private view returns (address _collectionManagerHelper) {
        _collectionManagerHelper = address(
            IGovernedProxy_New(address(uint160(collectionManagerHelperProxy))).implementation()
        );
    }

    modifier requireManager() {
        require(
            msg.sender == collectionManager() || msg.sender == collectionManagerHelper(),
            'CollectionProxy::requireManager: FORBIDDEN, not CollectionManager or CollectionManagerHelper'
        );
        _;
    }

    /**
     * @dev ERC721 events
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Constructor (called by CollectionFactory at deployment)
    constructor(address _collectionManagerProxy, address _collectionManagerHelperProxy) public {
        collectionManagerProxy = _collectionManagerProxy;
        collectionManagerHelperProxy = _collectionManagerHelperProxy;
    }

    /**
     * @dev Event emitter functions (called by ERC721Manager)
     */
    function emitTransfer(address from, address to, uint256 tokenId) external requireManager {
        emit Transfer(from, to, tokenId);
    }

    function emitApproval(
        address owner,
        address approved,
        uint256 tokenId
    ) external requireManager {
        emit Approval(owner, approved, tokenId);
    }

    function emitApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external requireManager {
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev ERC165 supportsInterface function
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool returnValue) {
        return IERC721Manager(collectionManager()).supportsInterface(interfaceId);
    }

    /**
     * @dev ERC721 functions
     */
    function balanceOf(address user) external view returns (uint256) {
        return IERC721Manager(collectionManager()).balanceOf(address(this), user);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return IERC721Manager(collectionManager()).ownerOf(address(this), tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external {
        IERC721Manager(collectionManager()).safeTransferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId,
            _data
        );
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        IERC721Manager(collectionManager()).safeTransferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId,
            ''
        );
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        IERC721Manager(collectionManager()).transferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId
        );
    }

    function approve(address to, uint256 tokenId) external {
        IERC721Manager(collectionManager()).approve(address(this), msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return IERC721Manager(collectionManager()).getApproved(address(this), tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        IERC721Manager(collectionManager()).setApprovalForAll(
            address(this),
            msg.sender,
            operator,
            approved
        );
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return IERC721Manager(collectionManager()).isApprovedForAll(address(this), owner, operator);
    }

    /**
     * @dev ERC721Metadata functions
     */
    function name() external view returns (string memory) {
        return IERC721Manager(collectionManager()).name(address(this));
    }

    function symbol() external view returns (string memory) {
        return IERC721Manager(collectionManager()).symbol(address(this));
    }

    function baseURI() external view returns (string memory) {
        return IERC721Manager(collectionManager()).baseURI(address(this));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return IERC721Manager(collectionManager()).tokenURI(address(this), tokenId);
    }

    /**
     * @dev ERC721Enumerable functions
     */
    function totalSupply() external view returns (uint256) {
        return IERC721Manager(collectionManager()).totalSupply(address(this));
    }

    function tokenByIndex(uint256 index) external view returns (uint256 tokenId) {
        return IERC721Manager(collectionManager()).tokenByIndex(address(this), index);
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId) {
        return IERC721Manager(collectionManager()).tokenOfOwnerByIndex(address(this), owner, index);
    }

    /**
     * @dev safeMint function
     */
    function safeMint(address to, uint256 quantity, bool payWithWETH) external payable {
        IERC721ManagerHelper(collectionManagerHelper()).safeMint.value(msg.value)(
            address(this),
            msg.sender,
            to,
            quantity,
            payWithWETH
        );
    }

    /**
     * @dev ERC721Burnable burn function
     */
    function burn(uint256 tokenId) external {
        IERC721Manager(collectionManager()).burn(address(this), msg.sender, tokenId);
    }

    /**
     * @dev ERC721Ownable owner function
     */
    function owner() external view returns (address) {
        return IERC721Manager(collectionManager()).owner();
    }

    /**
     * @dev ERC2981 royaltyInfo function
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        return IERC721Manager(collectionManager()).royaltyInfo(address(this), tokenId, salePrice);
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function safeMint(address, address, address, uint256, bool) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function burn(address, address, uint256) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function approve(address, address, address, uint256) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function setApprovalForAll(address, address, address, bool) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function transferFrom(address, address, address, address, uint256) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function safeTransferFrom(
        address,
        address,
        address,
        address,
        uint256,
        bytes calldata
    ) external pure {
        revert('Good try');
    }

    // Proxy all other calls to CollectionManager.
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        address _collectionManager = collectionManager();

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let res := call(
                sub(gas(), 10000),
                _collectionManager,
                callvalue(),
                ptr,
                calldatasize(),
                0,
                0
            )
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize())

            switch res
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }
}