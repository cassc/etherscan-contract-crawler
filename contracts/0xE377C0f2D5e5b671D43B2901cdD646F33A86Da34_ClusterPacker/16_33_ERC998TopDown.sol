// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IERC998ERC721TopDown.sol";
import "../interfaces/IERC998ERC721TopDownEnumerable.sol";

abstract contract ERC998TopDown is
    ERC721Enumerable,
    IERC998ERC721TopDown,
    IERC998ERC721TopDownEnumerable,
    ReentrancyGuard
{
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ERC998_MAGIC_VALUE = 0xcd740db500000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant ERC998_MAGIC_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;

    uint256 public tokenCount = 0;

    mapping(uint256 => EnumerableSet.AddressSet) internal childContracts;

    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal childTokens;

    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;

    function childExists(address _childContract, uint256 _childTokenId) external view virtual returns (bool) {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        return tokenId != 0;
    }

    function totalChildContracts(uint256 _tokenId) external view virtual override returns (uint256) {
        return childContracts[_tokenId].length();
    }

    function childContractByIndex(uint256 _tokenId, uint256 _index)
        external
        view
        virtual
        override
        returns (address childContract)
    {
        return childContracts[_tokenId].at(_index);
    }

    function totalChildTokens(uint256 _tokenId, address _childContract) external view override returns (uint256) {
        return childTokens[_tokenId][_childContract].length();
    }

    function childTokenByIndex(
        uint256 _tokenId,
        address _childContract,
        uint256 _index
    ) external view virtual override returns (uint256 childTokenId) {
        return childTokens[_tokenId][_childContract].at(_index);
    }

    function ownerOfChild(address _childContract, uint256 _childTokenId)
        external
        view
        virtual
        override
        returns (bytes32 parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId != 0, "owner of child not found");
        address parentTokenOwnerAddress = ownerOf(parentTokenId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            parentTokenOwner := or(ERC998_MAGIC_VALUE, parentTokenOwnerAddress)
        }
    }

    function rootOwnerOf(uint256 _tokenId) public view virtual override returns (bytes32 rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

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
                if (returnedRootOwner & ERC998_MAGIC_MASK == ERC998_MAGIC_VALUE) {
                    return returnedRootOwner;
                }
            } catch {
                // solhint-disable-previous-line no-empty-blocks
            }
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            rootOwner := or(ERC998_MAGIC_VALUE, rootOwnerAddress)
        }
        return rootOwner;
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return
            _interfaceId == type(IERC998ERC721TopDown).interfaceId ||
            _interfaceId == type(IERC998ERC721TopDownEnumerable).interfaceId ||
            _interfaceId == 0x1efdf36a ||
            super.supportsInterface(_interfaceId);
    }

    function _safeMint(address _to) internal returns (uint256) {
        uint256 id = ++tokenCount;
        _safeMint(_to, id);

        return id;
    }

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

    function transferChildToParent(
        uint256,
        address,
        uint256,
        address,
        uint256,
        bytes memory
    ) external pure override {
        revert("BOTTOM_UP_CHILD_NOT_SUPPORTED");
    }

    function getChild(
        address,
        uint256,
        address,
        uint256
    ) external pure override {
        revert("external calls restricted");
    }

    function _getChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual nonReentrant {
        _receiveChild(_from, _tokenId, _childContract, _childTokenId);
        IERC721(_childContract).transferFrom(_from, address(this), _childTokenId);
    }

    function onERC721Received(
        address,
        address _from,
        uint256 _childTokenId,
        bytes calldata _data
    ) external virtual override nonReentrant returns (bytes4) {
        _validateAndReceiveChild(_from, msg.sender, _childTokenId, _data);
        return this.onERC721Received.selector;
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        require(_to != address(this), "nested bundles not allowed");
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

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

    function _validateReceiver(address _to) internal virtual {
        require(_to != address(0), "child transfer to zero address");
    }

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

    function _ownerOfChild(address _childContract, uint256 _childTokenId)
        internal
        view
        virtual
        returns (address parentTokenOwner, uint256 parentTokenId)
    {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId != 0, "owner of child not found");
        return (ownerOf(parentTokenId), parentTokenId);
    }

    function _parseTokenId(bytes memory _data) internal pure virtual returns (uint256 tokenId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenId := mload(add(_data, 0x20))
        }
    }

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

    function _validateTransferSender(uint256 _fromTokenId) internal virtual {
        address rootOwner = address(uint160(uint256(rootOwnerOf(_fromTokenId))));
        require(
            rootOwner == msg.sender ||
                getApproved(_fromTokenId) == msg.sender ||
                isApprovedForAll(rootOwner, msg.sender),
            "transferChild msg.sender not eligible"
        );
    }
}