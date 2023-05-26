// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*---------------------------------------------------------------------*/
//      ___                                    ___           ___       //
//     /  /\          ___        ___          /__/\         /__/\      //
//    /  /::\        /__/\      /  /\         \  \:\       |  |::\     //
//   /  /:/\:\       \  \:\    /  /:/          \  \:\      |  |:|:\    //
//  /  /:/~/::\       \  \:\  /__/::\      ___  \  \:\   __|__|:|\:\   //
// /__/:/ /:/\:\  ___  \__\:\ \__\/\:\__  /__/\  \__\:\ /__/::::| \:\  //
// \  \:\/:/__\/ /__/\ |  |:|    \  \:\/\ \  \:\ /  /:/ \  \:\~~\__\/  //
//  \  \::/      \  \:\|  |:|     \__\::/  \  \:\  /:/   \  \:\        //
//   \  \:\       \  \:\__|:|     /__/:/    \  \:\/:/     \  \:\       //
//    \  \:\       \__\::::/      \__\/      \  \::/       \  \:\      //
//     \__\/           ~~~~                   \__\/         \__\/      //
//                                                                     //
/*---------------------------------------------------------------------*/

contract Origins is ERC721A, OperatorFilterer, Ownable, ERC2981 {
    // Errors
    error WithdrawFailed();
    error NoZeroAddress();
    error ProvenanceNotSet();
    error ProvenanceSet();
    error AlreadyShifted();
    error AlreadyMinted();
    error InvalidSignature();
    error MaxSupplyReached();
    error ExceedsAllocation();
    error InvalidIndex();
    error WrongMintState();
    error WrongMintPrice();

    // Constants
    uint256 private constant OGWL_STATE = 1;
    uint256 private constant PUBLIC_STATE = 2;
    uint256 private constant OG_PRICE = 0;
    uint256 private constant WL_PRICE = 1;
    uint256 private constant PUBLIC_PRICE = 2;
    uint256 private constant OGWL_BITPOS = 0;
    uint256 private constant PUBLIC_BITPOS = 1;
    uint256 private constant MAX_SUPPLY = 9_999;
    bytes32 private constant OGWL_TYPEHASH =
        keccak256("OGWLList(address minter,uint256 alloc,uint256 og)");
    bytes32 private constant PUBLIC_TYPEHASH =
        keccak256("PUBLICList(address minter,uint256 alloc)");

    // Immutables
    bytes32 private immutable DOMAIN_SEPARATOR;

    // Variables
    string private baseURI;
    uint256 public mintState;
    address private signer;
    uint128[2] public ogwlPrices;
    uint256 public publicPrice;
    bool public operatorFilteringEnabled = true;
    string public provenanceHash;
    uint256 public tokenIdShift;
    bool public revealed;

    constructor(
        string memory baseURI_,
        address signer_,
        uint256[3] memory prices_,
        address owner_,
        address royaltyAddress,
        uint96 royaltyPercentage,
        uint256 reservedQuantity
    ) ERC721A("Avium Origins", "AOG") {
        baseURI = baseURI_;
        signer = signer_;
        ogwlPrices[OG_PRICE] = uint128(prices_[OG_PRICE]);
        ogwlPrices[WL_PRICE] = uint128(prices_[WL_PRICE]);
        publicPrice = prices_[PUBLIC_PRICE];
        // Reserve for Founders Pass holders
        _mintERC2309(owner_, reservedQuantity);
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("AviumOrigins")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        _registerForOperatorFiltering();
        _setDefaultRoyalty(royaltyAddress, royaltyPercentage);
        transferOwnership(owner_);
    }

    event MintStateChanged(uint256 mintState);
    event PriceChanged(uint256 priceIndex, uint128 price);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    modifier mintCheck(
        uint256 mintState_,
        uint256 quantity,
        uint256 alloc
    ) {
        if (mintState != mintState_) revert WrongMintState();
        if (quantity > alloc) revert ExceedsAllocation();
        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyReached();
        _;
    }

    /// @param quantity The amount of NFTs to mint
    function mintOGWL(
        uint256 quantity,
        bytes calldata signature,
        uint256 alloc,
        uint256 og
    ) public payable mintCheck(OGWL_STATE, quantity, alloc) {
        if (
            signer !=
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR,
                        keccak256(abi.encode(OGWL_TYPEHASH, msg.sender, alloc, og))
                    )
                ),
                signature
            )
        ) revert InvalidSignature();
        uint128[2] memory prices = ogwlPrices;
        uint256 priceCheck;
        if (quantity > og) {
            priceCheck = (quantity - og) * prices[WL_PRICE] + prices[OG_PRICE] * og;
        } else {
            priceCheck = quantity * prices[OG_PRICE];
        }
        if (msg.value != priceCheck) revert WrongMintPrice();
        checkAndSetMinted(OGWL_BITPOS);
        _mint(msg.sender, quantity);
    }

    function mintPublic(
        uint256 quantity,
        bytes calldata signature,
        uint256 alloc
    ) public payable mintCheck(PUBLIC_STATE, quantity, alloc) {
        if (
            signer !=
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR,
                        keccak256(abi.encode(PUBLIC_TYPEHASH, msg.sender, alloc))
                    )
                ),
                signature
            )
        ) revert InvalidSignature();
        if (msg.value != quantity * publicPrice) revert WrongMintPrice();
        checkAndSetMinted(PUBLIC_BITPOS);
        _mint(msg.sender, quantity);
    }

    function hasMinted(address minter_, uint256 bitPos) external view returns (bool) {
        uint256 aux = _getAux(minter_);
        return (getBits(aux, bitPos, 1) != 0);
    }

    function getPrice(uint256 priceIndex) external view returns (uint256 price) {
        if (priceIndex > PUBLIC_PRICE) revert InvalidIndex();
        if (priceIndex < PUBLIC_PRICE) {
            price = uint256(ogwlPrices[priceIndex]);
        } else {
            price = publicPrice;
        }
    }

    // Internal Functions
    // Aux Storage (64 bits) Layout:
    // - [0]  `OGWL`   (To check if wallet has minted during the OGWL phase)
    // - [1]  `PUBLIC` (To check if wallet has minted during the PUBLIC phase)
    function checkAndSetMinted(uint256 bitPos) private {
        uint256 aux = _getAux(msg.sender);
        if (getBits(aux, bitPos, 1) == 1) revert AlreadyMinted();
        _setAux(msg.sender, uint64(aux + (1 << bitPos)));
    }

    function getBits(
        uint256 input_,
        uint256 startBit_,
        uint256 length_
    ) private pure returns (uint256) {
        return (input_ & (((1 << length_) - 1) << startBit_)) >> startBit_;
    }

    // Owner Functions
    function setMintState(uint256 mintState_) external onlyOwner {
        if (mintState_ > PUBLIC_STATE) revert WrongMintState();
        mintState = mintState_;
        emit MintStateChanged(mintState_);
    }

    function setPrice(uint256 priceIndex, uint128 price) external onlyOwner {
        if (priceIndex > PUBLIC_PRICE) revert InvalidIndex();
        if (priceIndex < PUBLIC_PRICE) {
            ogwlPrices[priceIndex] = price;
        } else {
            publicPrice = price;
        }
        emit PriceChanged(priceIndex, price);
    }

    function setSigner(address signer_) external onlyOwner {
        if (signer_ == address(0)) revert NoZeroAddress();
        signer = signer_;
    }

    function setBaseUri(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function mintRemaining(address to) external onlyOwner {
        if (to == address(0)) revert NoZeroAddress();
        // Can only run during Public Mint, PUBLIC State = 2
        if (mintState != PUBLIC_STATE) revert WrongMintState();
        uint256 remaining = MAX_SUPPLY - totalSupply();
        // If remaining is 0, mint will revert due to MintZeroQuantity error
        _mint(to, remaining);
    }

    function setProvenanceHash(string calldata provenanceHash_) external onlyOwner {
        if (bytes(provenanceHash).length != 0) revert ProvenanceSet();
        provenanceHash = provenanceHash_;
    }

    function reveal(uint256 tokenIdShift_, string calldata baseURI_) external onlyOwner {
        if (bytes(provenanceHash).length == 0) revert ProvenanceNotSet();
        if (tokenIdShift > 0) revert AlreadyShifted();
        tokenIdShift = tokenIdShift_;
        baseURI = baseURI_;
        revealed = true;
        emit BatchMetadataUpdate(1, MAX_SUPPLY);
    }

    function withdraw(address payable to) external onlyOwner {
        if (to == address(0)) revert NoZeroAddress();
        (bool success, ) = to.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    // Overrides
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice First 5 tokens (1 to 5) are excluded from the token shift to reserve fixed identity Origin characters
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (revealed) {
            if (tokenId > 5) {
                tokenId = ((tokenId + tokenIdShift) % (MAX_SUPPLY - 5)) + 6;
            }
            return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
        } else {
            return baseURI;
        }
    }

    // OperatorFilterer
    // reference: https://github.com/Vectorized/closedsea
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}