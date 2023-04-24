// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@thirdweb-dev/contracts/base/ERC721SignatureMint.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/LazyMint.sol";
import "@thirdweb-dev/contracts/extension/BatchMintMetadata.sol";
import "@thirdweb-dev/contracts/extension/Royalty.sol";

import "@thirdweb-dev/contracts/extension/PlatformFee.sol";
import "@thirdweb-dev/contracts/extension/DefaultOperatorFilterer.sol";

contract Contract is
    Royalty,
    PlatformFee,
    BatchMintMetadata,
    LazyMint,
    PermissionsEnumerable,
    DefaultOperatorFilterer,
    ERC721SignatureMint
{
    mapping(address => uint256) private signatureMintedByWallet;
    address public ALLOWED_CONTRACT_ADDRESS_TO_BURN;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient,
        uint128 _platformFeeBps,
        address _platformFeeRecipient,
        address _allowedAddressToBurn
    )
        ERC721SignatureMint(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        ALLOWED_CONTRACT_ADDRESS_TO_BURN = _allowedAddressToBurn;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * Implementations
     */

    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override(ERC721SignatureMint) {
        if (_pricePerToken == 0) {
            return;
        }

        (
            address platformFeeRecipient,
            uint16 platformFeeBps
        ) = getPlatformFeeInfo();

        address saleRecipient = _primarySaleRecipient == address(0)
            ? primarySaleRecipient()
            : _primarySaleRecipient;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = 0;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert("!Price");
            }
        }

        CurrencyTransferLib.transferCurrency(
            _currency,
            _msgSender(),
            platformFeeRecipient,
            platformFees
        );
        CurrencyTransferLib.transferCurrency(
            _currency,
            _msgSender(),
            saleRecipient,
            totalPrice - platformFees
        );
    }

    function _canLazyMint() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal virtual returns (uint256 startTokenId) {
        startTokenId = _currentIndex;
        _safeMint(_to, _quantityBeingClaimed);
    }

    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    function nextTokenIdToMint()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return nextTokenIdToLazyMint;
    }

    /// @notice The tokenId assigned to the next new NFT to be claimed.
    function nextTokenIdToClaim() public view virtual returns (uint256) {
        return _currentIndex;
    }

    function _canSignMintRequest(
        address _signer
    ) internal view override returns (bool) {
        return _signer == owner() || hasRole(DEFAULT_ADMIN_ROLE, _signer);
    }

    function mintWithSignature(
        MintRequest calldata _req,
        bytes calldata _signature
    ) external payable override returns (address signer) {
        uint256 tokenIdToMint = _currentIndex;
        if (tokenIdToMint + _req.quantity > nextTokenIdToLazyMint) {
            revert("!Tokens");
        }

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        address receiver = _req.to;

        // Collect price
        _collectPriceOnClaim(
            _req.primarySaleRecipient,
            _req.quantity,
            _req.currency,
            _req.pricePerToken
        );

        // Set royalties, if applicable.
        if (_req.royaltyRecipient != address(0) && _req.royaltyBps != 0) {
            _setupRoyaltyInfoForToken(
                tokenIdToMint,
                _req.royaltyRecipient,
                _req.royaltyBps
            );
        }

        // Mint tokens.
        _safeMint(receiver, _req.quantity);

        signatureMintedByWallet[_req.to] =
            signatureMintedByWallet[_req.to] +
            _req.quantity;

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, _req);
    }

    function getSignatureMintedByWallet(
        address _address
    ) public view returns (uint256) {
        return signatureMintedByWallet[_address];
    }

    /**
     * Overriding the burn function to allow either the
     * token owner or the phase 3 contract to burn the token.
     */
    function burn(uint256 tokenId) public override {
        /**
         * Check if the address is the token owner
         * or is the whitelisted address ALLOWED_CONTRACT_ADDRESS_TO_BURN
         *
         */
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);
        address from = prevOwnership.addr;
        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender() ||
            ALLOWED_CONTRACT_ADDRESS_TO_BURN == _msgSender());
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        _burn(tokenId);
    }

    /**
     * allow multiple burns
     */
    function burnTokens(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }

    /**
     * update burn whitelisted address
     */

    function updateWhitelistedAddressToBurn(
        address _newAddress
    ) public onlyOwner {
        ALLOWED_CONTRACT_ADDRESS_TO_BURN = _newAddress;
    }
}