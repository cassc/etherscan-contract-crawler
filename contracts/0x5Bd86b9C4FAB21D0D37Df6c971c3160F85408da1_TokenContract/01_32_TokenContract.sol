// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@dlsl/dev-modules/libs/decimals/DecimalsConverter.sol";
import "@dlsl/dev-modules/utils/Globals.sol";

import "./interfaces/ITokenFactory.sol";
import "./interfaces/ITokenContract.sol";
import "./interfaces/IOwnable.sol";

contract TokenContract is
    ITokenContract,
    IOwnable,
    ERC721EnumerableUpgradeable,
    EIP712Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721Holder
{
    using DecimalsConverter for uint256;
    using SafeERC20 for IERC20Metadata;

    bytes32 internal constant _MINT_TYPEHASH =
        keccak256(
            "Mint(address paymentTokenAddress,uint256 paymentTokenPrice,uint256 discount,uint256 endTimestamp,bytes32 tokenURI)"
        );

    ITokenFactory public override tokenFactory;
    uint256 public override pricePerOneToken;

    uint256 internal _tokenId;
    string internal _tokenName;
    string internal _tokenSymbol;

    mapping(string => bool) public override existingTokenURIs;
    mapping(uint256 => string) internal _tokenURIs;

    // v1.0.0

    address public override voucherTokenContract;
    uint256 public override voucherTokensAmount;

    // v1.1.0

    uint256 public override minNFTFloorPrice;

    modifier onlyAdmin() {
        require(
            tokenFactory.isAdmin(msg.sender),
            "TokenContract: Only admin can call this function."
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "TokenContract: Only owner can call this function.");
        _;
    }

    function __TokenContract_init(TokenContractInitParams calldata initParams_)
        external
        override
        initializer
    {
        __ERC721_init(initParams_.tokenName, initParams_.tokenSymbol);
        __EIP712_init(initParams_.tokenName, "1");
        __Pausable_init();
        __ReentrancyGuard_init();

        tokenFactory = ITokenFactory(initParams_.tokenFactoryAddr);

        _updateTokenContractParams(
            initParams_.pricePerOneToken,
            initParams_.minNFTFloorPrice,
            initParams_.tokenName,
            initParams_.tokenSymbol
        );
        _updateVoucherParams(initParams_.voucherTokenContract, initParams_.voucherTokensAmount);
    }

    function updateTokenContractParams(
        uint256 newPrice_,
        uint256 newMinNFTFloorPrice_,
        string memory newTokenName_,
        string memory newTokenSymbol_
    ) external override onlyAdmin {
        _updateTokenContractParams(
            newPrice_,
            newMinNFTFloorPrice_,
            newTokenName_,
            newTokenSymbol_
        );
    }

    function updateVoucherParams(address newVoucherTokenContract_, uint256 newVoucherTokensAmount_)
        external
        override
        onlyAdmin
    {
        _updateVoucherParams(newVoucherTokenContract_, newVoucherTokensAmount_);
    }

    function updateAllParams(
        uint256 newPrice_,
        uint256 newMinNFTFloorPrice_,
        address newVoucherTokenContract_,
        uint256 newVoucherTokensAmount_,
        string memory newTokenName_,
        string memory newTokenSymbol_
    ) external override onlyAdmin {
        _updateTokenContractParams(
            newPrice_,
            newMinNFTFloorPrice_,
            newTokenName_,
            newTokenSymbol_
        );
        _updateVoucherParams(newVoucherTokenContract_, newVoucherTokensAmount_);
    }

    function pause() external override onlyAdmin {
        _pause();
    }

    function unpause() external override onlyAdmin {
        _unpause();
    }

    function withdrawPaidTokens(address tokenAddr_, address recipient_)
        external
        override
        onlyOwner
    {
        IERC20Metadata token_ = IERC20Metadata(tokenAddr_);
        bool isNativeCurrency_ = tokenAddr_ == address(0);

        uint256 amount_ = isNativeCurrency_
            ? address(this).balance
            : token_.balanceOf(address(this));

        require(amount_ > 0, "TokenContract: Nothing to withdraw.");

        if (isNativeCurrency_) {
            (bool success_, ) = recipient_.call{value: amount_}("");
            require(success_, "TokenContract: Failed to transfer native currecy.");
        } else {
            token_.safeTransfer(recipient_, amount_);

            amount_ = amount_.to18(token_.decimals());
        }

        emit PaidTokensWithdrawn(tokenAddr_, recipient_, amount_);
    }

    function mintToken(
        address paymentTokenAddress_,
        uint256 paymentTokenPrice_,
        uint256 discount_,
        uint256 endTimestamp_,
        string memory tokenURI_,
        bytes32 r_,
        bytes32 s_,
        uint8 v_
    ) external payable override whenNotPaused nonReentrant {
        _verifySignature(
            paymentTokenAddress_,
            paymentTokenPrice_,
            discount_,
            endTimestamp_,
            tokenURI_,
            r_,
            s_,
            v_
        );

        uint256 amountToPay_;

        if (paymentTokenPrice_ != 0 || paymentTokenAddress_ != address(0)) {
            if (paymentTokenAddress_ == address(0)) {
                amountToPay_ = _payWithETH(paymentTokenPrice_, discount_);
            } else {
                amountToPay_ = _payWithERC20(
                    IERC20Metadata(paymentTokenAddress_),
                    paymentTokenPrice_,
                    discount_
                );
            }
        }

        uint256 currentTokenId_ = _tokenId++;
        _mintToken(currentTokenId_, tokenURI_);

        emit SuccessfullyMinted(
            msg.sender,
            MintedTokenInfo(currentTokenId_, pricePerOneToken, tokenURI_),
            paymentTokenAddress_,
            amountToPay_,
            paymentTokenPrice_,
            discount_
        );
    }

    function mintTokenByNFT(
        address nftAddress_,
        uint256 nftFloorPrice_,
        uint256 tokenId_,
        uint256 endTimestamp_,
        string memory tokenURI_,
        bytes32 r_,
        bytes32 s_,
        uint8 v_
    ) external override whenNotPaused nonReentrant {
        _verifySignature(
            nftAddress_,
            nftFloorPrice_,
            0, // Discount is zero for NFT by NFT option
            endTimestamp_,
            tokenURI_,
            r_,
            s_,
            v_
        );

        _payWithNFT(IERC721Upgradeable(nftAddress_), nftFloorPrice_, tokenId_);

        uint256 currentTokenId_ = _tokenId++;
        _mintToken(currentTokenId_, tokenURI_);

        emit SuccessfullyMintedByNFT(
            msg.sender,
            MintedTokenInfo(currentTokenId_, minNFTFloorPrice, tokenURI_),
            nftAddress_,
            tokenId_,
            nftFloorPrice_
        );
    }

    function getUserTokenIDs(address userAddr_)
        external
        view
        override
        returns (uint256[] memory tokenIDs_)
    {
        uint256 _tokensCount = balanceOf(userAddr_);

        tokenIDs_ = new uint256[](_tokensCount);

        for (uint256 i; i < _tokensCount; i++) {
            tokenIDs_[i] = tokenOfOwnerByIndex(userAddr_, i);
        }
    }

    function owner() public view override returns (address) {
        return IOwnable(address(tokenFactory)).owner();
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "TokenContract: URI query for nonexistent token.");

        string memory baseURI_ = _baseURI();

        return
            bytes(baseURI_).length > 0
                ? string(
                    abi.encodePacked(tokenFactory.baseTokenContractsURI(), _tokenURIs[tokenId_])
                )
                : "";
    }

    function name() public view override returns (string memory) {
        return _tokenName;
    }

    function symbol() public view override returns (string memory) {
        return _tokenSymbol;
    }

    function _updateTokenContractParams(
        uint256 newPrice_,
        uint256 newMinNFTFloorPrice_,
        string memory newTokenName_,
        string memory newTokenSymbol_
    ) internal {
        pricePerOneToken = newPrice_;
        minNFTFloorPrice = newMinNFTFloorPrice_;

        _tokenName = newTokenName_;
        _tokenSymbol = newTokenSymbol_;

        emit TokenContractParamsUpdated(
            newPrice_,
            newMinNFTFloorPrice_,
            newTokenName_,
            newTokenSymbol_
        );
    }

    function _updateVoucherParams(
        address newVoucherTokenContract_,
        uint256 newVoucherTokensAmount_
    ) internal {
        voucherTokenContract = newVoucherTokenContract_;
        voucherTokensAmount = newVoucherTokensAmount_;

        emit VoucherParamsUpdated(newVoucherTokenContract_, newVoucherTokensAmount_);
    }

    function _payWithERC20(
        IERC20Metadata tokenAddr_,
        uint256 tokenPrice_,
        uint256 discount_
    ) internal returns (uint256) {
        require(msg.value == 0, "TokenContract: Currency amount must be a zero.");

        uint256 amountToPay_ = tokenPrice_ != 0
            ? _getAmountAfterDiscount((pricePerOneToken * DECIMAL) / tokenPrice_, discount_)
            : voucherTokensAmount;

        tokenAddr_.safeTransferFrom(
            msg.sender,
            address(this),
            amountToPay_.from18(tokenAddr_.decimals())
        );

        return amountToPay_;
    }

    function _payWithETH(uint256 ethPrice_, uint256 discount_) internal returns (uint256) {
        uint256 amountToPay_ = _getAmountAfterDiscount(
            (pricePerOneToken * DECIMAL) / ethPrice_,
            discount_
        );

        require(msg.value >= amountToPay_, "TokenContract: Invalid currency amount.");

        uint256 extraCurrencyAmount_ = msg.value - amountToPay_;

        if (extraCurrencyAmount_ > 0) {
            (bool success_, ) = msg.sender.call{value: extraCurrencyAmount_}("");
            require(success_, "TokenContract: Failed to return currency.");
        }

        return amountToPay_;
    }

    function _payWithNFT(
        IERC721Upgradeable nft_,
        uint256 nftFloorPrice_,
        uint256 tokenId_
    ) internal {
        require(
            nftFloorPrice_ >= minNFTFloorPrice,
            "TokenContract: NFT floor price is less than the minimal."
        );
        require(
            IERC721Upgradeable(nft_).ownerOf(tokenId_) == msg.sender,
            "TokenContract: Sender is not the owner."
        );

        nft_.safeTransferFrom(msg.sender, address(this), tokenId_);
    }

    function _mintToken(uint256 mintTokenId_, string memory tokenURI_) internal {
        _mint(msg.sender, mintTokenId_);

        _tokenURIs[mintTokenId_] = tokenURI_;
        existingTokenURIs[tokenURI_] = true;
    }

    function _verifySignature(
        address paymentTokenAddress_,
        uint256 paymentTokenPrice_,
        uint256 discount_,
        uint256 endTimestamp_,
        string memory tokenURI_,
        bytes32 r_,
        bytes32 s_,
        uint8 v_
    ) internal view {
        require(!existingTokenURIs[tokenURI_], "TokenContract: Token URI already exists.");

        bytes32 structHash_ = keccak256(
            abi.encode(
                _MINT_TYPEHASH,
                paymentTokenAddress_,
                paymentTokenPrice_,
                discount_,
                endTimestamp_,
                keccak256(abi.encodePacked(tokenURI_))
            )
        );

        address signer_ = ECDSA.recover(_hashTypedDataV4(structHash_), v_, r_, s_);

        require(tokenFactory.isAdmin(signer_), "TokenContract: Invalid signature.");
        require(block.timestamp <= endTimestamp_, "TokenContract: Signature expired.");
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenFactory.baseTokenContractsURI();
    }

    function _EIP712NameHash() internal view override returns (bytes32) {
        return keccak256(bytes(_tokenName));
    }

    function _getAmountAfterDiscount(uint256 amount_, uint256 discount_)
        internal
        pure
        returns (uint256)
    {
        return (amount_ * (PERCENTAGE_100 - discount_)) / PERCENTAGE_100;
    }
}