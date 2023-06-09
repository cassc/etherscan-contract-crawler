// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Spy Signals Agent
/// @author MilkyTaste#8662 @MilkyTasteEth https://milkytaste.xyz

/// https://spysignals.io/

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721Ao.sol";
import "./Payable.sol";

contract SpySignalsAgent is ERC721Ao, Payable {
    using Strings for uint256;
    using ECDSA for bytes32;

    // Token values incremented for gas efficiency
    uint256 private maxSalePlusOne = 2223;
    uint256 private constant MAX_RESERVED_PLUS_ONE = 51;
    uint256 private constant MAX_PRESALE_PLUS_ONE = 4;
    uint256 private constant MAX_PER_TRANS_PLUS_ONE = 4;

    uint256 private reserveClaimed = 0;
    uint256 private tokenPublicPrice = 0.2 ether;
    uint256 private tokenPresalePrice = 0.15 ether;

    enum SaleState {
        OFF,
        PRESALE,
        PUBLIC
    }
    SaleState public saleState = SaleState.OFF;

    address public presaleSigner;
    mapping(address => uint256) public presaleClaimed;

    string public baseURI;

    constructor() ERC721Ao("SpySignals", "AGENT") Payable() {}

    //
    // Minting
    //

    /**
     * Mint tokens
     */
    function mintPublic(uint256 numTokens) external payable {
        require(msg.sender == tx.origin, "SpySignalsAgent: No bots");
        require(saleState == SaleState.PUBLIC, "SpySignalsAgent: Public sale is not active");
        require((totalSupply() + numTokens) < maxSalePlusOne, "SpySignalsAgent: Purchase exceeds available tokens");
        require(numTokens < MAX_PER_TRANS_PLUS_ONE, "SpySignalsAgent: Exceeds tokens per transaction");
        require((tokenPublicPrice * numTokens) == msg.value, "SpySignalsAgent: Ether value sent is not correct");
        _safeMint(msg.sender, numTokens);
    }

    /**
     * Mint presale.
     * @notice Do not mint from contract. Requires a signature
     * @param numTokens Number of tokens to mint
     * @param signature Server signature
     */
    function mintPresale(uint256 numTokens, bytes memory signature) external payable {
        require(saleState == SaleState.PRESALE, "SpySignalsAgent: Presale is not active");
        require((totalSupply() + numTokens) < maxSalePlusOne, "SpySignalsAgent: Purchase exceeds available tokens");
        require(
            (presaleClaimed[msg.sender] + numTokens) < MAX_PRESALE_PLUS_ONE,
            "SpySignalsAgent: Exceeds presale allowance"
        );
        require((tokenPresalePrice * numTokens) == msg.value, "SpySignalsAgent: Ether value sent is not correct");
        require(
            _verify(abi.encodePacked(msg.sender), signature, presaleSigner),
            "SpySignalsAgent: Signature not valid"
        );
        presaleClaimed[msg.sender] += numTokens;
        _safeMint(msg.sender, numTokens);
    }

    /**
     * Mints reserved tokens.
     */
    function mintReserved(uint256 numTokens, address mintTo) external onlyOwner {
        require((totalSupply() + numTokens) < maxSalePlusOne, "SpySignalsAgent: Purchase exceeds available tokens");
        require((reserveClaimed + numTokens) < MAX_RESERVED_PLUS_ONE, "SpySignalsAgent: Reservation exceeded");
        reserveClaimed += numTokens;
        _safeMint(mintTo, numTokens);
    }

    //
    // Admin
    //

    /**
     * Set sale state
     * @param saleState_ 0: OFF, 1: PRESALE, 2: PUBLIC
     */
    function setSaleState(SaleState saleState_) external onlyOwner {
        saleState = saleState_;
    }

    /**
     * Update token prices
     * @param tokenPresalePrice_ New presale price
     * @param tokenPublicPrice_ New public price
     */
    function setTokenPrices(uint256 tokenPresalePrice_, uint256 tokenPublicPrice_) external onlyOwner {
        tokenPresalePrice = tokenPresalePrice_;
        tokenPublicPrice = tokenPublicPrice_;
    }

    /**
     * Update maximum number of tokens for sale
     */
    function setMaxSale(uint256 maxSale) external onlyOwner {
        require(maxSale + 1 < maxSalePlusOne, "SpySignalsAgent: Can only reduce supply");
        maxSalePlusOne = maxSale + 1;
    }

    /**
     * Update the presale signer address
     */
    function setPresaleSigner(address presaleSigner_) external onlyOwner {
        presaleSigner = presaleSigner_;
    }

    /**
     * Sets base URI
     * @dev Only use this method after sell out as it will leak unminted token data.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    /**
     * Return sale info.
     * @param addr The address to check for presaleClaimed
     * @return [maxSale, totalSupply, saleState, reserveClaimed, presaleClaimed, tokenPresalePrice, tokenPublicPrice]
     * saleClaims[0]: maxSale (total available tokens)
     * saleClaims[1]: totalSupply (total minted)
     * saleClaims[2]: saleState (state of the sale)
     * saleClaims[3]: reserveClaimed (claimed by team)
     * saleClaims[4]: presaleClaimed (presale tokens claimed by given address)
     * saleClaims[5]: tokenPresalePrice
     * saleClaims[6]: tokenPublicPrice
     */
    function saleInfo(address addr) public view virtual returns (uint256[7] memory) {
        return [
            maxSalePlusOne - 1,
            totalSupply(),
            uint256(saleState),
            reserveClaimed,
            presaleClaimed[addr],
            tokenPresalePrice,
            tokenPublicPrice
        ];
    }

    /**
     * Verify a signature
     * @param data The signature data
     * @param signature The signature to verify
     * @param account The signer account
     */
    function _verify(
        bytes memory data,
        bytes memory signature,
        address account
    ) public pure returns (bool) {
        return keccak256(data).toEthSignedMessageHash().recover(signature) == account;
    }
}