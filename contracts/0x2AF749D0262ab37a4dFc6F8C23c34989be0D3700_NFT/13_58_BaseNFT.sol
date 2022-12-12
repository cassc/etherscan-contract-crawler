// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "../../BaseContract.sol";
import "./BaseNFTStorage.sol";
import "./IBaseNFT.sol";

// solhint-disable func-name-mixedcase
// solhint-disable ordering
contract BaseNFT is IBaseNFT, DefaultOperatorFiltererUpgradeable, ERC721Upgradeable, BaseContract, BaseNFTStorage {
    event BaseURIChanged(string baseUri);
    event CollectionURIChanged(string collectionUri);

    function __BaseNFTContract_init(
        address aclContract,
        string memory name,
        string memory symbol,
        string memory baseUri,
        string memory collectionUri
    ) internal onlyInitializing {
        __DefaultOperatorFilterer_init();
        __BaseContract_init(aclContract);
        __ERC721_init(name, symbol);
        __BaseNFTContract_init_unchained(baseUri, collectionUri);
    }

    function __BaseNFTContract_init_unchained(string memory baseUri, string memory collectionUri)
        internal
        onlyInitializing
    {
        _baseTokenURI = baseUri;
        _collectionURI = collectionUri;
    }

    function setBaseTokenURI(string calldata baseURI) external onlyOperator {
        _baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function setCollectionURI(string calldata collectionURI) external onlyOperator {
        _collectionURI = collectionURI;
        emit CollectionURIChanged(collectionURI);
    }

    function contractURI() external view returns (string memory) {
        // Named after openSea requirement, returns Collection metadata URI
        return _collectionURI;
    }

    function getBaseTokenURI() external view returns (string memory) {
        return _baseURI();
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // The following functions are overrides required by OpenSea
    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}