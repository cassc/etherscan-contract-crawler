pragma solidity ^0.8.18;

import "./mason/utils/Administrable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC2981.sol";

error CannotDecreaseMaxSupply();
error CannotIncreaseMaxSupply();
error CannotMintMoreThanMaxSupply();
error RoyaltiesTooHigh();
error TokenIdIsDisabled();

contract FloorPack is
    DefaultOperatorFilterer,
    ERC1155,
    ERC1155Supply,
    ERC2981Base,
    Administrable
{
    // Used to enforce max supply constraints on a token. Note that by
    // default, maxSupply is 0, which means that there is unlimited supply.
    struct TokenConfig {
        uint64 maxSupply;
        bool isDisabled;
    }

    RoyaltyInfo private _royalties;

    string public name;
    string public symbol;

    string public contractMetadataUri;

    mapping(uint256 => TokenConfig) public tokenConfigs;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        string memory _contractMetadataUri
    ) ERC1155(_uri) {
        _setRoyaltyInfo(msg.sender, 500); // 5%

        _setURI(_uri);
        _setContractURI(_contractMetadataUri);

        name = _name;
        symbol = _symbol;
    }

    // ***********************
    // * Token Management
    // ***********************

    function setTokenConfig(
        uint256 tokenId,
        TokenConfig memory newConfig
    ) external onlyOperatorsAndOwner {
        _setTokenConfig(tokenId, newConfig);
    }

    function _setTokenConfig(
        uint256 tokenId,
        TokenConfig memory newConfig
    ) internal {
        TokenConfig memory currentConfig = tokenConfigs[tokenId];

        if (
            currentConfig.maxSupply != 0 &&
            newConfig.maxSupply > currentConfig.maxSupply
        ) revert CannotIncreaseMaxSupply();
        if (newConfig.maxSupply < totalSupply(tokenId))
            revert CannotDecreaseMaxSupply();

        tokenConfigs[tokenId] = newConfig;
    }

    // ***********************
    // * Metadata Management
    // ***********************

    // Sets the base URI of the tokens. We rely on the substitution mechanism
    // so that we can use the same URI for all tokens.
    // Expected format is https://server.com/directory/{id}.json
    function setURI(string memory uri) public onlyOperatorsAndOwner {
        _setURI(uri);
    }

    // This defines contract-level metadata (that can be overridden by marketplace
    // configuration).
    function contractURI() public view returns (string memory) {
        return contractMetadataUri;
    }

    function setContractURI(
        string memory _contractMetadataUri
    ) public onlyOperatorsAndOwner {
        _setContractURI(_contractMetadataUri);
    }

    function _setContractURI(string memory _contractMetadataUri) internal {
        contractMetadataUri = _contractMetadataUri;
    }

    // ***********************
    // * Token Distribution
    // ***********************

    function batchAirdrop(
        uint256 tokenId,
        address[] memory recipients
    ) external onlyOperatorsAndOwner {
        TokenConfig memory config = tokenConfigs[tokenId];

        if (config.isDisabled) revert TokenIdIsDisabled();
        if (
            config.maxSupply != 0 &&
            config.maxSupply - totalSupply(tokenId) < recipients.length
        ) revert CannotMintMoreThanMaxSupply();

        for (uint256 i = 0; i < recipients.length; ) {
            _mint(recipients[i], tokenId, 1, "");
            unchecked {
                ++i;
            }
        }
    }

    function airdropSingle(
        uint256 tokenId,
        address to
    ) external onlyOperatorsAndOwner {
        TokenConfig memory config = tokenConfigs[tokenId];

        if (config.isDisabled) revert TokenIdIsDisabled();
        if (config.maxSupply != 0 && config.maxSupply == totalSupply(tokenId))
            revert CannotMintMoreThanMaxSupply();

        _mint(to, tokenId, 1, "");
    }

    mapping(uint256 => uint256) private _tokenCounts;

    function airdropBatch(
        uint256[] memory tokenIds,
        address to
    ) external onlyOperatorsAndOwner {
        mapping(uint256 => uint256) storage localCounts = _tokenCounts;

        uint256[] memory amounts = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            TokenConfig memory config = tokenConfigs[tokenId];

            localCounts[tokenId] += 1;

            if (config.isDisabled) revert TokenIdIsDisabled();
            if (
                config.maxSupply != 0 &&
                config.maxSupply < totalSupply(tokenId) + localCounts[tokenId]
            ) revert CannotMintMoreThanMaxSupply();

            amounts[i] = 1;
            unchecked {
                ++i;
            }
        }
        _mintBatch(to, tokenIds, amounts, "");
    }

    // ***********************
    // * Boilerplate
    // ***********************

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155, ERC2981Base, AccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(ERC2981Base).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ***********************
    // * Royalties
    // ***********************

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (_salePrice * royalties.amount) / 10000;
    }

    function setRoyalties(
        address recipient,
        uint256 value
    ) external onlyOperatorsAndOwner {
        _setRoyaltyInfo(recipient, value);
    }

    function _setRoyaltyInfo(address recipient, uint256 value) internal {
        if (value >= 10000) revert RoyaltiesTooHigh();

        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC1155) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}