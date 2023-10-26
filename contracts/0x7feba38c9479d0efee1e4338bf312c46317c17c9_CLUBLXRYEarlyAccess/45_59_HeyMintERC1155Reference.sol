// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title HeyMint ERC1155 Function Reference
 * @author HeyMint Launchpad (https://join.heymint.xyz)
 * @notice This is a function reference contract for Etherscan reference purposes only.
 * This contract includes all the functions from multiple implementation contracts.
 */
contract HeyMintERC1155Reference {
    struct BaseConfig {
        uint24 projectId;
        bool enforceRoyalties;
        uint16 royaltyBps;
        bool heyMintFeeActive;
        address presaleSignerAddress;
        string uriBase;
    }

    struct TokenConfig {
        uint16 tokenId;
        uint16 maxSupply;
        bool publicSaleActive;
        uint32 publicPrice;
        uint8 publicMintsAllowedPerAddress;
        bool usePublicSaleTimes;
        uint32 publicSaleStartTime;
        uint32 publicSaleEndTime;
        bool presaleActive;
        uint32 presalePrice;
        uint16 presaleMaxSupply;
        uint8 presaleMintsAllowedPerAddress;
        string tokenUri;
        bool usePresaleTimes;
        uint32 presaleStartTime;
        uint32 presaleEndTime;
        address freeClaimContractAddress;
        uint16 mintsPerFreeClaim;
        bool freeClaimActive;
        uint32 burnPayment;
        uint16 mintsPerBurn;
        bool burnClaimActive;
        bool soulbindingActive;
        uint32 refundEndsAt;
        uint32 refundPrice;
    }

    struct AdvancedConfig {
        address royaltyPayoutAddress;
        uint16[] payoutBasisPoints;
        address[] payoutAddresses;
        bool payoutAddressesFrozen;
        address[] creditCardMintAddresses;
        bool soulbindAdminTransfersPermanentlyDisabled;
        address soulboundAdminAddress;
        address refundAddress;
    }

    struct BurnToken {
        address contractAddress;
        uint8 tokenType;
        uint8 tokensPerBurn;
        uint16 tokenId;
    }

    function CORI_SUBSCRIPTION_ADDRESS() external view returns (address) {}

    function DOMAIN_SEPARATOR() external view returns (bytes32) {}

    function EMPTY_SUBSCRIPTION_ADDRESS() external view returns (address) {}

    function balanceOf(
        address owner,
        uint256 id
    ) external view returns (uint256) {}

    function balanceOfBatch(
        address[] memory owners,
        uint256[] memory ids
    ) external view returns (uint256[] memory balances) {}

    function defaultHeymintFeePerToken() external view returns (uint256) {}

    function heymintFeePerToken() external view returns (uint256) {}

    function heymintPayoutAddress() external view returns (address) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        BaseConfig memory _config,
        TokenConfig[] memory _tokenConfig
    ) external {}

    function isApprovedForAll(
        address operator,
        address owner
    ) external view returns (bool) {}

    function isOperatorFilterRegistryRevoked() external view returns (bool) {}

    function name() external view returns (string memory) {}

    function nonces(address owner) external view returns (uint256) {}

    function owner() external view returns (address) {}

    function pause() external {}

    function permanentlyDisableTokenMinting(uint16 _tokenId) external {}

    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) external {}

    function revokeOperatorFilterRegistry() external {}

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address, uint256) {}

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {}

    function setApprovalForAll(address operator, bool approved) external {}

    function setRoyaltyBasisPoints(uint16 _royaltyBps) external {}

    function setRoyaltyPayoutAddress(address _royaltyPayoutAddress) external {}

    function supportsInterface(
        bytes4 interfaceId
    ) external view returns (bool) {}

    function symbol() external view returns (string memory) {}

    function transferOwnership(address newOwner) external {}

    function unpause() external {}

    function uri(uint256 _id) external view returns (string memory) {}

    function anyTokenRefundGuaranteeActive() external view returns (bool) {}

    function heymintAdminAddress() external view returns (address) {}

    function mintToken(uint16 _tokenId, uint16 _numTokens) external payable {}

    function publicPriceInWei(
        uint16 _tokenId
    ) external view returns (uint256) {}

    function refundGuaranteeActive(
        uint16 _tokenId
    ) external view returns (bool) {}

    function setHeymintFeePerToken(uint256 _heymintFeePerToken) external {}

    function setTokenMaxSupply(uint16 _tokenId, uint16 _maxSupply) external {}

    function setTokenPublicMintsAllowedPerAddress(
        uint16 _tokenId,
        uint8 _mintsAllowed
    ) external {}

    function setTokenPublicPrice(
        uint16 _tokenId,
        uint32 _publicPrice
    ) external {}

    function setTokenPublicSaleEndTime(
        uint16 _tokenId,
        uint32 _publicSaleEndTime
    ) external {}

    function setTokenPublicSaleStartTime(
        uint16 _tokenId,
        uint32 _publicSaleStartTime
    ) external {}

    function setTokenPublicSaleState(
        uint16 _tokenId,
        bool _saleActiveState
    ) external {}

    function setTokenUsePublicSaleTimes(
        uint16 _tokenId,
        bool _usePublicSaleTimes
    ) external {}

    function tokenPublicSaleTimeIsActive(
        uint16 _tokenId
    ) external view returns (bool) {}

    function updatePayoutAddressesAndBasisPoints(
        address[] memory _payoutAddresses,
        uint16[] memory _payoutBasisPoints
    ) external {}

    function withdraw() external {}

    function presaleMint(
        bytes32 _messageHash,
        bytes memory _signature,
        uint16 _tokenId,
        uint16 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable {}

    function presalePriceInWei(
        uint16 _tokenId
    ) external view returns (uint256) {}

    function setPresaleSignerAddress(address _presaleSignerAddress) external {}

    function setTokenPresaleEndTime(
        uint16 _tokenId,
        uint32 _presaleEndTime
    ) external {}

    function setTokenPresaleMaxSupply(
        uint16 _tokenId,
        uint16 _maxSupply
    ) external {}

    function setTokenPresaleMintsAllowedPerAddress(
        uint16 _tokenId,
        uint8 _mintsAllowed
    ) external {}

    function setTokenPresalePrice(
        uint16 _tokenId,
        uint32 _presalePrice
    ) external {}

    function setTokenPresaleStartTime(
        uint16 _tokenId,
        uint32 _presaleStartTime
    ) external {}

    function setTokenPresaleState(
        uint16 _tokenId,
        bool _presaleActiveState
    ) external {}

    function setTokenUsePresaleTimes(
        uint16 _tokenId,
        bool _usePresaleTimes
    ) external {}

    function tokenPresaleTimeIsActive(
        uint16 _tokenId
    ) external view returns (bool) {}

    function getSettings()
        external
        view
        returns (
            BaseConfig memory,
            AdvancedConfig memory,
            bool,
            uint16[] memory
        )
    {}

    function getTokenSettings(
        uint16 tokenId
    ) external view returns (TokenConfig memory, BurnToken[] memory) {}

    function setGlobalUri(string memory _newTokenURI) external {}

    function setTokenUri(
        uint16 _tokenId,
        string memory _newTokenURI
    ) external {}

    function updateBaseConfig(BaseConfig memory _baseConfig) external {}

    function updateAdvancedConfig(
        AdvancedConfig memory _advancedConfig
    ) external {}

    function updateFullConfig(
        BaseConfig memory _baseConfig,
        TokenConfig[] memory _tokenConfigs,
        AdvancedConfig memory _advancedConfig,
        BurnToken[][] memory _burnTokens
    ) external {}

    function upsertToken(TokenConfig memory _tokenConfig) external {}

    function creditCardMint(
        uint16 _tokenId,
        uint16 _numTokens,
        address _to
    ) external payable {}

    function getDefaultCreditCardMintAddresses()
        external
        pure
        returns (address[5] memory)
    {}

    function giftTokens(
        uint16 _tokenId,
        address[] memory _receivers,
        uint256[] memory _mintNumber
    ) external payable {}

    function setCreditCardMintAddresses(
        address[] memory _creditCardMintAddresses
    ) external {}

    function burnAddress() external view returns (address) {}

    function burnPaymentInWei(
        uint16 _tokenId
    ) external view returns (uint256) {}

    function burnToMint(
        uint16 _tokenId,
        address[] memory _contracts,
        uint256[][] memory _tokenIdsToBurn,
        uint16 _tokensToMint
    ) external payable {}

    function disableSoulbindAdminTransfersPermanently() external {}

    function increaseRefundEndsAt(
        uint16 _tokenId,
        uint32 _newRefundEndsAt
    ) external {}

    function refund(uint16 _tokenId, uint256 _numTokens) external {}

    function refundPriceInWei(
        uint16 _tokenId
    ) external view returns (uint256) {}

    function setBurnClaimState(
        uint16 _tokenId,
        bool _burnClaimActive
    ) external {}

    function setRefundAddress(address _refundAddress) external {}

    function setSoulbindingState(
        uint16 _tokenId,
        bool _soulbindingActive
    ) external {}

    function setSoulboundAdminAddress(address _adminAddress) external {}

    function soulboundAdminTransfer(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _amount
    ) external {}

    function updateBurnTokens(
        uint16[] calldata _tokenIds,
        BurnToken[][] calldata _burnConfigs
    ) external {}

    function updateMintsPerBurn(
        uint16 _tokenId,
        uint8 _mintsPerBurn
    ) external {}

    function updatePaymentPerBurn(
        uint16 _tokenId,
        uint32 _burnPayment
    ) external {}

    function checkFreeClaimEligibility(
        uint16 _tokenId,
        uint256[] memory _claimTokenIds
    ) external view returns (bool[] memory) {}

    function freeClaim(
        uint16 _tokenId,
        uint256[] memory _claimTokenIds
    ) external payable {}

    function setFreeClaimContractAddress(
        uint16 _tokenId,
        address _freeClaimContractAddress
    ) external {}

    function setFreeClaimState(
        uint16 _tokenId,
        bool _freeClaimActive
    ) external {}

    function updateMintsPerFreeClaim(
        uint16 _tokenId,
        uint8 _mintsPerFreeClaim
    ) external {}

    function freezePayoutAddresses() external {}

    function freezeTokenMetadata(uint16 _tokenId) external {}

    function freezeAllMetadata() external {}

    function totalSupply(uint16 _tokenId) external view returns (uint16) {}

    function tokensMintedByAddress(
        address _address,
        uint16 _tokenId
    ) external view returns (uint16) {}

    function tokenURI(uint256 _tokenId) external view returns (string memory) {}

    function setTokenIds(uint16[] calldata _tokenIds) external {}
}