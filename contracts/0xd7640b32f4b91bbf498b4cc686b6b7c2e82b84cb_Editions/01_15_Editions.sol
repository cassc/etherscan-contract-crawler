// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../../lib/Ownable.sol";
import {Pausable} from "../../lib/Pausable.sol";
import {Reentrancy} from "../../lib/Reentrancy.sol";
import {ERC721, IERC721, IERC165} from "../../lib/ERC721/ERC721.sol";
import {IERC721Metadata} from "../../lib/ERC721/interface/IERC721.sol";
import {IERC2309} from "../../lib/ERC2309/interface/IERC2309.sol";
import {IERC2981} from "../../lib/ERC2981/interface/IERC2981.sol";
import {IEditions, IEditionsEvents} from "./interface/IEditions.sol";

import {IRenderer} from "./interface/IRenderer.sol";

import {ITreasuryConfig} from "../../treasury/interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../../treasury/interface/IMirrorTreasury.sol";
import {IMirrorFeeConfig} from "../../fee-config/MirrorFeeConfig.sol";

import {Base64} from "../../lib/Base64.sol";

/**
 * @title Editions
 * @author MirrorXYZ
 */
contract Editions is
    Ownable,
    Pausable,
    Reentrancy,
    ERC721,
    IERC721Metadata,
    IERC2309,
    IERC2981,
    IEditions,
    IEditionsEvents
{
    // ============ Deployment ============

    /// @notice Address that deploys and initializes clones
    address public immutable override factory;

    // ============ Fee Configuration ============

    /// @notice Address for Mirror fee configuration.
    address public immutable override feeConfig;

    /// @notice Address for Mirror treasury configuration.
    address public immutable override treasuryConfig;

    // ============ ERC721 Metadata ============

    /// @notice Edition name
    string public override name;

    /// @notice Ediiton symbol
    string public override symbol;

    // ============ Edition Data ============

    /// @notice Edition description
    string public override description;

    /// @notice Last tokenId that was minted
    uint256 internal currentTokenId;

    /// @notice Edition contractURI
    string internal _contractURI;

    /// @notice Edition animationURI used for gifs or video
    string internal animationURI;

    /// @notice Edition contentURI
    string internal contentURI;

    /// @notice Edition price
    uint256 public override price;

    /// @notice Edition limit
    uint256 public override limit;

    // ============ Royalty Info (ERC2981) ============

    /// @notice Account that will receive royalties
    /// @dev set address(0) to avoid royalties
    address public override royaltyRecipient;

    /// @notice Royalty Basis Points
    uint256 public override royaltyBPS;

    // ============ Rendering ============

    /// @notice Rendering contract
    address public override renderer;

    // ============ Pre allocation ============

    /// @notice Allocation recipient (consecutive transfer)
    address internal allocationRecipient;

    /// @notice Allocation count (consecutive transfer)
    uint256 internal allocationCount;

    // ============ Constructor ============
    constructor(
        address factory_,
        address feeConfig_,
        address treasuryConfig_
    ) Ownable(address(0)) Pausable(false) {
        factory = factory_;
        feeConfig = feeConfig_;
        treasuryConfig = treasuryConfig_;
    }

    // ============ Initializing ============

    /// @notice Initialize metadata
    /// @param owner_ the clone owner
    /// @param name_ the name for the edition clone
    /// @param symbol_ the symbol for the edition clone
    /// @param description_ the description for the edition clone
    /// @param contentURI_ the contentURI for the edition clone
    /// @param animationURI_ the animationURI for the edition clone
    /// @param contractURI_ the contractURI for the edition clone
    /// @param edition_ the parameters for the edition sale
    /// @param paused_ the pause state for the edition sale
    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory contentURI_,
        string memory animationURI_,
        string memory contractURI_,
        Edition memory edition_,
        bool paused_
    ) external override {
        require(msg.sender == factory, "unauthorized caller");

        // store erc721 metadata
        name = name_;
        symbol = symbol_;

        // store edition data
        description = description_;
        contentURI = contentURI_;
        animationURI = animationURI_;
        _contractURI = contractURI_;
        price = edition_.price;
        limit = edition_.limit;

        // set pause status
        if (paused_) {
            _pause();
        }

        // store owner
        _setOwner(address(0), owner_);

        // set royalty defaults to owner and 10%
        royaltyRecipient = owner_;
        royaltyBPS = 1000;
    }

    // ============ Pause Methods ============

    /// @notice Unpause edition sale
    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @notice Pause edition sale
    function pause() external override onlyOwner {
        _pause();
    }

    // ============ Allocation ============

    /// @notice Allocates `count` editions to `recipient`
    /// @dev Throws if an edition has been purchased already or `count` exceeds limit
    /// @param recipient the account to receive tokens
    /// @param count the number of tokens to mint to `recipient`
    function allocate(address recipient, uint256 count)
        external
        override
        onlyOwner
    {
        // check that no purchases have happened and count does not exceed limit
        require(
            currentTokenId == 0 && (limit == 0 || count <= limit),
            "cannot allocate"
        );

        // set allocation recipient
        allocationRecipient = recipient;
        allocationCount = count;

        // update tokenId
        currentTokenId = count;

        // update balance
        _balances[recipient] = count;

        // emit transfer
        emit ConsecutiveTransfer(
            // fromTokenId
            1,
            // toTokenId
            count,
            // fromAddress
            address(0),
            // toAddress
            recipient
        );
    }

    /// @notice Finds the owner of a token
    /// @dev this method takes into account allocation
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address _owner = _owners[tokenId];

        // if there is not owner set,
        // and the tokenId is within the allocation count
        // the allocationRecipient owns it
        if (_owner == address(0) && tokenId > 0 && tokenId <= allocationCount) {
            return allocationRecipient;
        }

        require(_owner != address(0), "ERC721: query for nonexistent token");

        return _owner;
    }

    // ============ Purchase ============

    /// @notice Purchase an edition
    /// @dev throws if sale is paused or incorrect value is sent
    /// @param recipient the account to receive the edition
    function purchase(address recipient)
        external
        payable
        override
        whenNotPaused
        returns (uint256 tokenId)
    {
        require(msg.value == price, "incorrect value");

        return _purchase(recipient);
    }

    // ============ Minting ============

    /// @notice Mint an edition
    /// @dev throws if called by a non-owner
    /// @param recipient the account to receive the edition
    function mint(address recipient)
        external
        override
        onlyOwner
        returns (uint256 tokenId)
    {
        tokenId = _getTokenIdAndMint(recipient);
    }

    /// @notice Allows the owner to set a global limit on the total supply
    /// @dev throws if attempting to increase the limit
    function setLimit(uint256 newLimit) external override onlyOwner {
        // enforce that the limit should only ever decrease once set
        require(
            newLimit >= currentTokenId && (limit == 0 || newLimit < limit),
            "limit must be < than current limit"
        );

        // announce the change in limit
        emit EditionLimitSet(
            // oldLimit
            limit,
            // newLimit
            newLimit
        );

        // update the limit.
        limit = newLimit;
    }

    // ============ ERC2981 Methods ============

    /// @notice Called with the sale price to determine how much royalty
    //  is owed and to whom
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyRecipient;

        royaltyAmount = (_salePrice * royaltyBPS) / 10_000;
    }

    /// @param royaltyRecipient_ the address that will receive royalties
    /// @param royaltyBPS_ the royalty amount in basis points (bps)
    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyBPS_
    ) external override onlyOwner {
        require(
            royaltyBPS_ <= 10_000,
            "bps must be less than or equal to 10,000"
        );

        emit RoyaltyChange(
            // oldRoyaltyRecipient
            royaltyRecipient,
            // oldRoyaltyBPS
            royaltyBPS,
            // newRoyaltyRecipient
            royaltyRecipient_,
            // newRoyaltyBPS
            royaltyBPS_
        );

        royaltyRecipient = royaltyRecipient_;
        royaltyBPS = royaltyBPS_;
    }

    // ============ Rendering Methods ============

    /// @notice Set the renderer address
    /// @dev Throws if renderer is not the zero address
    function setRenderer(address renderer_) external override onlyOwner {
        require(renderer == address(0), "renderer already set");

        renderer = renderer_;

        emit RendererSet(
            // renderer
            renderer_
        );
    }

    /// @notice Get contract metadata
    /// @dev If a renderer is set, return the renderer's metadata
    function contractURI() external view override returns (string memory) {
        if (renderer != address(0)) {
            return IRenderer(renderer).contractURI();
        }

        return _contractURI;
    }

    /// @notice Get `tokenId` URI or data
    /// @dev If a renderer is set, call renderer's tokenURI
    /// @param tokenId The tokenId used to request data
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: query for nonexistent token");

        if (renderer != address(0)) {
            return IRenderer(renderer).tokenURI(tokenId);
        }

        bytes memory editionNumber;
        if (limit != 0) {
            editionNumber = abi.encodePacked("/", _toString(limit));
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        " ",
                        _toString(tokenId),
                        editionNumber,
                        '", "description": "',
                        string(description),
                        '", "animation_url": "',
                        string(animationURI),
                        '", "image": "',
                        string(contentURI),
                        '", "attributes":[{ "trait_type": "Serial", "value": ',
                        _toString(tokenId),
                        " }] }"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    // ============ Withdrawal ============

    /// @notice Set the price
    function setPrice(uint256 price_) external override onlyOwner {
        price = price_;

        emit PriceSet(
            // price
            price_
        );
    }

    function withdraw(uint16 feeBPS, address fundingRecipient)
        external
        onlyOwner
        nonReentrant
    {
        require(fundingRecipient != address(0), "must set fundingRecipient");

        _withdraw(feeBPS, fundingRecipient);
    }

    // ============ IERC165 Method ============

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    // ============ Internal Methods ============
    function _withdraw(uint16 feeBPS, address fundingRecipient) internal {
        // assert that the fee is valid
        require(IMirrorFeeConfig(feeConfig).isFeeValid(feeBPS), "invalid fee");

        // calculate the fee on the current balance, using the fee percentage
        uint256 fee = _feeAmount(address(this).balance, feeBPS);

        // if the fee is not zero, attempt to send it to the treasury
        if (fee != 0) {
            _sendEther(ITreasuryConfig(treasuryConfig).treasury(), fee);
        }

        // broadcast the withdrawal event – with balance and fee
        emit Withdrawal(
            // recipient
            fundingRecipient,
            // amount
            address(this).balance,
            // fee
            fee
        );

        // transfer the remaining balance to the fundingRecipient
        _sendEther(payable(fundingRecipient), address(this).balance);
    }

    function _sendEther(address payable recipient_, uint256 amount) internal {
        // ensure sufficient balance
        require(address(this).balance >= amount, "insufficient balance");
        // send the value
        (bool success, ) = recipient_.call{value: amount, gas: gasleft()}("");
        require(success, "recipient reverted");
    }

    function _feeAmount(uint256 amount, uint16 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / 10_000;
    }

    /// @dev ensure token has an owner, or token is within the allocation
    function _exists(uint256 tokenId) internal view override returns (bool) {
        return
            _owners[tokenId] != address(0) ||
            (tokenId > 0 && tokenId <= allocationCount);
    }

    /// @dev Mints token and emits purchase event
    function _purchase(address recipient) internal returns (uint256 tokenId) {
        // mint the token, get a tokenId
        tokenId = _getTokenIdAndMint(recipient);

        emit EditionPurchased(
            // tokenId
            tokenId,
            // nftRecipient
            recipient,
            // amountPaid
            msg.value
        );
    }

    /// @dev Mints and returns tokenId
    function _getTokenIdAndMint(address recipient)
        internal
        returns (uint256 tokenId)
    {
        // increment currentTokenId and store tokenId
        tokenId = ++currentTokenId;

        // check that there are still tokens available to purchase
        require(limit == 0 || tokenId < limit + 1, "sold out");

        // mint a new token for the recipient, using the `tokenId`.
        _mint(recipient, tokenId);
    }

    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}