// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../ext-contracts/@openzeppelin/contracts/access/Ownable.sol";
import "../../ext-contracts/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../../ext-contracts/operator-filter-registry/DefaultOperatorFilterer.sol";
import "../v1/money/RoyaltyReceiver.sol";
import "../v1/token/LimitedNFT.sol";
import "../v1/access/PausableTopic.sol";

abstract contract UnfetteredBaseToken is
    ERC721URIStorage,
    PausableTopic,
    RoyaltyReceiver,
    LimitedNFT,
    DefaultOperatorFilterer,
    Ownable
{
    string public _baseUri;
    string public _defaultMetadataURI;

    constructor(
        address accountOwner,
        string memory name,
        string memory symbol,
        string memory defaultMetadataURI,
        uint96 numerator,
        IERC20[] memory paymentTokens,
        uint256 maxSupply,
        uint256 maxMintCountForPerAddress
    )
        ERC721(name, symbol)
        RoyaltyReceiver(accountOwner, numerator, paymentTokens)
        LimitedNFT(maxSupply, maxMintCountForPerAddress)
    {
        _defaultMetadataURI = defaultMetadataURI;
    }

    function setPaused(uint8 topic, bool paused) public onlyOwner {
        _pausableTopics[topic] = paused;
    }

    function setAccountOwner(address accountOwner) public onlyOwner {
        _setAccountOwner(accountOwner);
    }

    function addRemovePaymentToken(
        IERC20 paymentToken,
        bool remove
    ) public onlyOwner {
        _addRemovePaymentToken(paymentToken, remove);
    }

    function withdraw() external onlyAccountOwner {
        _withdraw();
    }

    function _mint(
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, LimitedNFT) whenNotPaused(MintPauseTopicID) {
        LimitedNFT._mint(to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseUri = uri;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory uri = ERC721URIStorage.tokenURI(tokenId);
        if (bytes(uri).length > 0)
            return uri;
        
        return _defaultMetadataURI;
    }

    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) public onlyOwner {
        ERC721URIStorage._setTokenURI(tokenId, _tokenURI);
    }

    function setMaxMintCountForPerAddress(
        uint256 max
    ) public virtual onlyOwner {
        _maxMintCountForPerAddress = max;
    }

    function setOperatorFiltering(bool enabled) public onlyOwner {
        _operatorFiltering = enabled;
    }

    function registerOperatorFilter(
        address registry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) public onlyOwner {
        _registerOperatorFilter(
            registry,
            subscriptionOrRegistrantToCopy,
            subscribe
        );
    }

    function unregisterOperatorFilter(address registry) public onlyOwner {
        _unregisterOperatorFilter(registry);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        ERC721.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        ERC721.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        // if operation is not mint and paused for transfer operations
        if (from != address(0) && isPaused(TransferPauseTopicID))
            revert TopicPaused();

        ERC721Enumerable._beforeTokenTransfer(
            from,
            to,
            firstTokenId,
            batchSize
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _burn(
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenId);
    }
}

uint8 constant MintPauseTopicID = 1;
uint8 constant TransferPauseTopicID = 2;