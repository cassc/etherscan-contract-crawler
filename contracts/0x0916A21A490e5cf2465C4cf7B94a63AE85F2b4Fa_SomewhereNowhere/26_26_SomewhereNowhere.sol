// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/common/ERC2981.sol';
import './erc721a/ERC721A.sol';
import './interfaces/ISomewhereNowhere.sol';
import './interfaces/ISomewhereNowhereMetadata.sol';
import './lib/OperatorFilter.sol';
import './lib/SignatureVerifier.sol';
import './lib/TokenSale.sol';

contract SomewhereNowhere is
    ISomewhereNowhere,
    ERC2981,
    ERC721A,
    OperatorFilter,
    SignatureVerifier,
    TokenSale
{
    address private _metadataContractAddress;

    constructor(
        address creatorAddress,
        address registryAddress,
        address registrySubscriptionAddress,
        address signingAddress
    )
        ERC721A('Somewhere Nowhere', 'HOOMAN')
        Ownable(_msgSender())
        SignatureVerifier(_getDomainSeparator())
        TokenSale(3333, 133)
    {
        setControllerAddress(_msgSender());
        setCreatorFeeInfo(creatorAddress, 500);
        setOperatorFilterRegistryAddress(registryAddress);
        if (registrySubscriptionAddress != address(0)) {
            registerAndSubscribe(registrySubscriptionAddress);
        }
        setSigningAddress(signingAddress);
    }

    modifier senderIsOrigin() {
        if (_msgSender() != tx.origin) revert SenderIsNotOrigin();
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        _;
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        ERC721A.approve(operator, tokenId);
    }

    function mintHooman(
        uint256 quantity,
        uint256 saleId,
        bytes calldata signature
    ) external senderIsOrigin signatureIsValid(signature, _getMessage(saleId)) {
        _mintSale(quantity, saleId);
        _safeMint(_msgSender(), quantity);
    }

    function mintReserve(address[] calldata addresses, uint256 quantity)
        external
        override
        onlyController
    {
        _mintReserve(addresses.length * quantity);
        for (uint256 i = 0; i < addresses.length; ++i) {
            _safeMint(addresses[i], quantity);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        ERC721A.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        ERC721A.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        ERC721A.setApprovalForAll(operator, approved);
    }

    function setCreatorFeeInfo(address receiver, uint96 feeBasisPoints)
        public
        override
        onlyController
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);

        emit CreatorFeeInfoUpdated(receiver, feeBasisPoints);
    }

    function setMetadataContractAddress(address metadataContractAddress)
        public
        override
        onlyController
    {
        _metadataContractAddress = metadataContractAddress;

        emit MetadataContractAddressUpdated(metadataContractAddress);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        ERC721A.transferFrom(from, to, tokenId);
    }

    function getMetadataContractAddress()
        public
        view
        override
        returns (address)
    {
        return _metadataContractAddress;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981, ERC721A, ISomewhereNowhere)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        tokenExists(tokenId)
        returns (string memory)
    {
        if (_metadataContractAddress == address(0))
            revert MetadataContractAddressIsZeroAddress();

        return
            ISomewhereNowhereMetadata(_metadataContractAddress).tokenURI(
                tokenId
            );
    }

    function _getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        'EIP712Domain('
                        'string name,'
                        'string version,'
                        'uint256 chainId,'
                        'address verifyingContract'
                        ')'
                    ),
                    keccak256(bytes('Somewhere Nowhere')),
                    keccak256(bytes('1')),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _getMessage(uint256 saleId) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256('SaleWallet(uint256 saleId,address wallet)'),
                    saleId,
                    _msgSender()
                )
            );
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}