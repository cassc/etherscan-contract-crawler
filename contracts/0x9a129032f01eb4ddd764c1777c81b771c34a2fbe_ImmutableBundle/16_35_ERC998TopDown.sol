// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./utils/Ownable.sol";
import "./IERC998ERC721TopDown.sol";
import "./IERC998ERC721TopDownEnumerable.sol";

/**
 * @title ERC998TopDown
 * @author NFTfi
 * @dev ERC998ERC721 Top-Down Composable Non-Fungible Token.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-998.md
 * This implementation does not support children to be nested bundles, erc20 nor bottom-up
 */
abstract contract ERC998TopDown is
    ERC721Enumerable,
    IERC998ERC721TopDown,
    IERC998ERC721TopDownEnumerable,
    ReentrancyGuard,
    Ownable,
    Pausable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // return this.rootOwnerOf.selector ^ this.rootOwnerOfChild.selector ^
    //   this.tokenOwnerOf.selector ^ this.ownerOfChild.selector;
    bytes32 public constant ERC998_MAGIC_VALUE = 0xcd740db500000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant ERC998_MAGIC_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;

    uint256 public tokenCount = 0;

    // tokenId => child contract
    mapping(uint256 => EnumerableSet.AddressSet) internal childContracts;

    // tokenId => (child address => array of child tokens)
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal childTokens;

    // child address => childId => tokenId
    // this is used for ERC721 type tokens
    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;

    /**
     * @dev Stores the admin
     *
     * @param _admin address capable of pausing
     */
    constructor(address _admin) Ownable(_admin) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @notice Tells whether the ERC721 type child exists or not
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     * @return True if the child exists, false otherwise
     */
    function childExists(address _childContract, uint256 _childTokenId) external view virtual returns (bool) {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        return tokenId != 0;
    }

    /**
     * @notice Get the total number of child contracts with tokens that are owned by _tokenId
     * @param _tokenId The parent token of child tokens in child contracts
     * @return uint256 The total number of child contracts with tokens owned by _tokenId
     */
    function totalChildContracts(uint256 _tokenId) public view virtual override returns (uint256) {
        return childContracts[_tokenId].length();
    }

    /**
     * @notice Get child contract by tokenId and index
     * @param _tokenId The parent token of child tokens in child contract
     * @param _index The index position of the child contract
     * @return childContract The contract found at the _tokenId and index
     */
    function childContractByIndex(uint256 _tokenId, uint256 _index)
        external
        view
        virtual
        override
        returns (address childContract)
    {
        return childContracts[_tokenId].at(_index);
    }

    /**
     * @notice Get the total number of child tokens owned by tokenId that exist in a child contract
     * @param _tokenId The parent token of child tokens
     * @param _childContract The child contract containing the child tokens
     * @return uint256 The total number of child tokens found in child contract that are owned by _tokenId
     */
    function totalChildTokens(uint256 _tokenId, address _childContract) external view override returns (uint256) {
        return childTokens[_tokenId][_childContract].length();
    }

    /**
     * @notice Get child token owned by _tokenId, in child contract, at index position
     * @param _tokenId The parent token of the child token
     * @param _childContract The child contract of the child token
     * @param _index The index position of the child token
     * @return childTokenId The child tokenId for the parent token, child token and index
     */
    function childTokenByIndex(
        uint256 _tokenId,
        address _childContract,
        uint256 _index
    ) external view virtual override returns (uint256 childTokenId) {
        return childTokens[_tokenId][_childContract].at(_index);
    }

    /**
     * @notice Get the parent tokenId and its owner of a ERC721 child token
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     * @return parentTokenOwner The parent address of the parent token and ERC998 magic value
     * @return parentTokenId The parent tokenId of _childTokenId
     */
    function ownerOfChild(address _childContract, uint256 _childTokenId)
        external
        view
        virtual
        override
        returns (bytes32 parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId != 0, "child token does not exist");
        address parentTokenOwnerAddress = ownerOf(parentTokenId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            parentTokenOwner := or(ERC998_MAGIC_VALUE, parentTokenOwnerAddress)
        }
    }

    /**
     * @notice Get the root owner of tokenId
     * @param _tokenId The token to query for a root owner address
     * @return rootOwner The root owner at the top of tree of tokens and ERC998 magic value.
     */
    function rootOwnerOf(uint256 _tokenId) public view virtual override returns (bytes32 rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

    /**
     * @notice Get the root owner of a child token
     * @dev Returns the owner at the top of the tree of composables
     * Use Cases handled:
     * - Case 1: Token owner is this contract and token.
     * - Case 2: Token owner is other external top-down composable
     * - Case 3: Token owner is other contract
     * - Case 4: Token owner is user
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     * @return rootOwner The root owner at the top of tree of tokens and ERC998 magic value
     */
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId)
        public
        view
        virtual
        override
        returns (bytes32 rootOwner)
    {
        address rootOwnerAddress;
        if (_childContract != address(0)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(_childContract, _childTokenId);
        } else {
            rootOwnerAddress = ownerOf(_childTokenId);
        }

        if (rootOwnerAddress.isContract()) {
            try IERC998ERC721TopDown(rootOwnerAddress).rootOwnerOfChild(address(this), _childTokenId) returns (
                bytes32 returnedRootOwner
            ) {
                // Case 2: Token owner is other external top-down composable
                if (returnedRootOwner & ERC998_MAGIC_MASK == ERC998_MAGIC_VALUE) {
                    return returnedRootOwner;
                }
            } catch {
                // solhint-disable-previous-line no-empty-blocks
            }
        }

        // Case 3: Token owner is other contract
        // Or
        // Case 4: Token owner is user
        // solhint-disable-next-line no-inline-assembly
        assembly {
            rootOwner := or(ERC998_MAGIC_VALUE, rootOwnerAddress)
        }
        return rootOwner;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * The interface id 0x1efdf36a is added. The spec claims it to be the interface id of IERC998ERC721TopDown.
     * But it is not.
     * It is added anyway in case some contract checks it being compliant with the spec.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return
            _interfaceId == type(IERC998ERC721TopDown).interfaceId ||
            _interfaceId == type(IERC998ERC721TopDownEnumerable).interfaceId ||
            _interfaceId == 0x1efdf36a ||
            super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Mints a new bundle
     * @param _to The address that owns the new bundle
     * @return The id of the new bundle
     */
    function safeMint(address _to) public virtual whenNotPaused returns (uint256) {
        uint256 id = ++tokenCount;
        _safeMint(_to, id);

        return id;
    }

    /**
     * @notice Transfer child token from top-down composable to address
     * @param _fromTokenId The owning token to transfer from
     * @param _to The address that receives the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external virtual override nonReentrant {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        IERC721(_childContract).safeTransferFrom(address(this), _to, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    /**
     * @notice Transfer child token from top-down composable to address or other top-down composable
     * @param _fromTokenId The owning token to transfer from
     * @param _to The address that receives the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     * @param _data Additional data with no specified format
     */
    function safeTransferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) external virtual override nonReentrant {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        if (_to == address(this)) {
            _validateAndReceiveChild(msg.sender, _childContract, _childTokenId, _data);
        } else {
            IERC721(_childContract).safeTransferFrom(address(this), _to, _childTokenId, _data);
            emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
        }
    }

    /**
     * @dev Transfer child token from top-down composable to address
     * @param _fromTokenId The owning token to transfer from
     * @param _to The address that receives the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external virtual override nonReentrant {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        _oldNFTsTransfer(_to, _childContract, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    /**
     * @notice NOT SUPPORTED
     * Intended to transfer bottom-up composable child token from top-down composable to other ERC721 token.
     */
    function transferChildToParent(
        uint256,
        address,
        uint256,
        address,
        uint256,
        bytes memory
    ) external virtual override {
        revert("BOTTOM_UP_CHILD_NOT_SUPPORTED");
    }

    /**
     * @notice Transfer a child token from an ERC721 contract to a composable. Used for old tokens that does not
     * have a safeTransferFrom method like cryptokitties
     * @dev This contract has to be approved first in _childContract
     * @param _from The address that owns the child token.
     * @param _tokenId The token that becomes the parent owner
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the child token
     */
    function getChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) public virtual override whenNotPaused nonReentrant {
        require(_from == msg.sender, "_from should be msg.sender");
        _receiveChild(_from, _tokenId, _childContract, _childTokenId);
        IERC721(_childContract).transferFrom(_from, address(this), _childTokenId);
    }

    /**
     * @notice A token receives a child token
     * param The address that caused the transfer
     * @param _from The owner of the child token
     * @param _childTokenId The token that is being transferred to the parent
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     * @return the selector of this method
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _childTokenId,
        bytes calldata _data
    ) external virtual override whenNotPaused nonReentrant returns (bytes4) {
        _validateAndReceiveChild(_from, msg.sender, _childTokenId, _data);
        return this.onERC721Received.selector;
    }

    /**
     * @dev ERC721 implementation hook that is called before any token transfer. Prevents nested bundles
     * @param _from address of the current owner of the token
     * @param _to destination address
     * @param _tokenId id of the token to transfer
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        require(_to != address(this), "nested bundles not allowed");
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /**
     * @dev Validates the child transfer parameters and remove the child from the bundle
     * @param _fromTokenId The owning token to transfer from
     * @param _to The address that receives the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function _transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual {
        _validateReceiver(_to);
        _validateChildTransfer(_fromTokenId, _childContract, _childTokenId);
        _removeChild(_fromTokenId, _childContract, _childTokenId);
    }

    /**
     * @dev Validates the child transfer parameters
     * @param _fromTokenId The owning token to transfer from
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function _validateChildTransfer(
        uint256 _fromTokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId != 0, "_transferChild _childContract _childTokenId not found");
        require(tokenId == _fromTokenId, "ComposableTopDown: _transferChild wrong tokenId found");
        _validateTransferSender(tokenId);
    }

    /**
     * @dev Validates the receiver of a child transfer
     * @param _to The address that receives the child token
     */
    function _validateReceiver(address _to) internal virtual {
        require(_to != address(0), "child transfer to zero address");
    }

    /**
     * @dev Updates the state to remove a child
     * @param _tokenId The owning token to transfer from
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The tokenId of the token that is being transferred
     */
    function _removeChild(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual {
        // remove child token
        childTokens[_tokenId][_childContract].remove(_childTokenId);
        delete childTokenOwner[_childContract][_childTokenId];

        // remove contract
        if (childTokens[_tokenId][_childContract].length() == 0) {
            childContracts[_tokenId].remove(_childContract);
        }
    }

    /**
     * @dev Validates the data from a child transfer and receives it
     * @param _from The owner of the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     */
    function _validateAndReceiveChild(
        address _from,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) internal virtual {
        require(_data.length > 0, "data must contain tokenId to transfer the child token to");
        // convert up to 32 bytes of _data to uint256, owner nft tokenId passed as uint in bytes
        uint256 tokenId = _parseTokenId(_data);
        _receiveChild(_from, tokenId, _childContract, _childTokenId);
    }

    /**
     * @dev Update the state to receive a child
     * @param _from The owner of the child token
     * @param _tokenId The token receiving the child
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     */
    function _receiveChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual {
        require(_exists(_tokenId), "bundle tokenId does not exist");
        uint256 childTokensLength = childTokens[_tokenId][_childContract].length();
        if (childTokensLength == 0) {
            childContracts[_tokenId].add(_childContract);
        }
        childTokens[_tokenId][_childContract].add(_childTokenId);
        childTokenOwner[_childContract][_childTokenId] = _tokenId;
        emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
    }

    /**
     * @dev Returns the owner of a child
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     * @return parentTokenOwner The parent address of the parent token and ERC998 magic value
     * @return parentTokenId The parent tokenId of _childTokenId
     */
    function _ownerOfChild(address _childContract, uint256 _childTokenId)
        internal
        view
        virtual
        returns (address parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId != 0, "child token does not exist");
        return (ownerOf(parentTokenId), parentTokenId);
    }

    /**
     * @dev Convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     * @return tokenId the token Id encoded in the data
     */
    function _parseTokenId(bytes memory _data) internal pure virtual returns (uint256 tokenId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenId := mload(add(_data, 0x20))
        }
    }

    /**
     * @dev Transfers the NFT using method compatible with old token contracts
     * @param _to address of the receiver of the children
     * @param _childContract The contract address of the child token
     * @param _childTokenId The tokenId of the child
     */
    function _oldNFTsTransfer(
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) internal {
        // This is here to be compatible with cryptokitties and other old contracts that require being owner and
        // approved before transferring.
        // Does not work with current standard which does not allow approving self, so we must let it fail in that case.
        try IERC721(_childContract).approve(address(this), _childTokenId) {
            // solhint-disable-previous-line no-empty-blocks
        } catch {
            // solhint-disable-previous-line no-empty-blocks
        }

        IERC721(_childContract).transferFrom(address(this), _to, _childTokenId);
    }

    /**
     * @notice Validates that the sender is authorized to perform a child transfer
     * @param _fromTokenId The owning token to transfer from
     */
    function _validateTransferSender(uint256 _fromTokenId) internal virtual {
        address rootOwner = address(uint160(uint256(rootOwnerOf(_fromTokenId))));
        require(
            rootOwner == msg.sender ||
                getApproved(_fromTokenId) == msg.sender ||
                isApprovedForAll(rootOwner, msg.sender),
            "transferChild msg.sender not eligible"
        );
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - Only the owner can call this method.
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - Only the owner can call this method.
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}