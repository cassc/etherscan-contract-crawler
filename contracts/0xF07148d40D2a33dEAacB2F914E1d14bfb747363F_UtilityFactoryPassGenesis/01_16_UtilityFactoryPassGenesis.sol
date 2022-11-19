// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

import {ERC721A} from "./ERC721A.sol";

contract UtilityFactoryPassGenesis is Ownable, ERC721A, DefaultOperatorFilterer, ReentrancyGuard {

    bool publicSale = true;

    mapping(uint256 => TokenType) tokenType;
    mapping(uint256 => uint256) tokenActivationDate;
    mapping(uint256 => uint256) tokenEndValidityDate;

    enum TokenType {
        SILVER,
        GOLD
    }

    mapping(TokenType => uint16) typeSupply;
    mapping(TokenType => uint256) typeValidityDuration;
    mapping(TokenType => uint256) typePrice;
    mapping(TokenType => uint16) typeMinted;

    mapping(string => address) sponsorWallet; // Mapping code => ETH wallet
    mapping(string => uint256) nbSponsored; // Nb sponsored mints by an sponsor's address

    uint256 public constant MAX_FREE_MINT = 100;
    uint256 nbFreeMinted = 0;

    uint256 public constant SPONRORED_OFFER = 0.05 ether;

    constructor()
        ERC721A("Utility Factory Pass - Genesis", "UFPassGenesis", 10, 1000)
    {
        typeSupply[TokenType.SILVER] = 300;
        typeSupply[TokenType.GOLD] = 600;

        typePrice[TokenType.SILVER] = 0.35 ether;
        typePrice[TokenType.GOLD] = 0.95 ether;

        typeMinted[TokenType.SILVER] = 0;
        typeMinted[TokenType.GOLD] = 0;

        typeValidityDuration[TokenType.SILVER] = 92 * 24 * 3600; // 92 days
        typeValidityDuration[TokenType.GOLD] = 366 * 24 * 3600; // 366 days
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Sponsorship :
    //
    function addSponsor(string calldata code, address a) public onlyOwner {
        sponsorWallet[code] = a;
    }

    function removeSponsor(string calldata code) public onlyOwner {
        sponsorWallet[code] = address(0);
    }

    modifier checkSponsor(string calldata sponsorCode, TokenType passType) {
        //
        require(
            sponsorWallet[sponsorCode] != address(0),
            "Your sponsor is not recognized by UtilityFactory"
        );

        _;

        // Transfer commission after mint : Security warning ...
        if (sponsorWallet[sponsorCode] != address(0)) {
            nbSponsored[sponsorCode]++;
            uint256 rate = 15;
            if (
                nbSponsored[sponsorCode] > 19 && nbSponsored[sponsorCode] < 40
            ) {
                rate = 20;
            } else if (nbSponsored[sponsorCode] > 39) {
                rate = 25;
            }

            uint256 amount = typePrice[passType] - SPONRORED_OFFER;
            uint256 commission = (amount * rate) / 100;

            (bool success, ) = sponsorWallet[sponsorCode].call{
                value: commission
            }("");

            require(success, "Transfer failed.");
        }
    }

    //
    ////

    // Activation methods
    //
    function isValid(uint256 tokenId) public view returns (bool) {
        require(
            tokenEndValidityDate[tokenId] > 0,
            "This token is not active yet ;)"
        );
        return block.timestamp < tokenEndValidityDate[tokenId];
    }

    function activationDate(uint256 tokenId) public view returns (uint256) {
        return tokenActivationDate[tokenId];
    }

    function activate(uint256 tokenId) public {
        require(
            tokenActivationDate[tokenId] == 0,
            "This token is already activated ;) What a cheater!"
        );
        require(ownerOf(tokenId) == msg.sender, "You must be the owner to activate a pass ;)");
        tokenActivationDate[tokenId] = block.timestamp;
        tokenEndValidityDate[tokenId] =
            block.timestamp +
            typeValidityDuration[tokenType[tokenId]];
    }

    //
    ////////////

    // Mint methods
    //

    function mintSilver(uint256 quantity) external payable callerIsUser {
        require(
            typePrice[TokenType.SILVER] * quantity == msg.value,
            "Ether value sent is not correct"
        );
        _mint(TokenType.SILVER, quantity);
    }

    function mintGold(uint256 quantity) external payable callerIsUser {
        require(
            typePrice[TokenType.GOLD] * quantity == msg.value,
            "Ether value sent is not correct"
        );
        _mint(TokenType.GOLD, quantity);
    }

    function mintSilverSponsored(uint256 quantity, string calldata sponsorCode)
        external
        payable
        callerIsUser
        nonReentrant
        checkSponsor(sponsorCode, TokenType.SILVER)
    {
        require(
            (typePrice[TokenType.SILVER] - SPONRORED_OFFER) * quantity == msg.value,
            "Ether value sent is not correct"
        );
        _mint(TokenType.SILVER, quantity);
    }

    function mintGoldSponsored(uint256 quantity, string calldata sponsorCode)
        external
        payable
        callerIsUser
        nonReentrant
        checkSponsor(sponsorCode, TokenType.GOLD)
    {
        require(
            (typePrice[TokenType.GOLD] - SPONRORED_OFFER) * quantity == msg.value,
            "Ether value sent is not correct"
        );
        _mint(TokenType.GOLD, quantity);
    }

    function _mint(TokenType passType, uint256 quantity) internal {
        require(publicSale, "Public sale has not begun yet");
        require(
            typeSupply[passType] + quantity <= collectionSize,
            "Reached max supply"
        );
        require(quantity <= 10, "can not mint this many at a time");
        for (uint8 i = 0; i < quantity; i++) {
            tokenType[totalSupply() + i] = passType;
        }
        _safeMint(msg.sender, quantity);
    }

    function freeMint(uint256 quantity) external onlyOwner {
        require(nbFreeMinted < MAX_FREE_MINT, "Max free mints gone ...");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(quantity <= 10, "can not mint this many at a time");

        for (uint8 i = 0; i < quantity; i++) {
            tokenType[totalSupply() + i] = TokenType.GOLD;
        }
        nbFreeMinted += quantity;
        _safeMint(msg.sender, quantity);
    }

    // Accessor :
    function getTokenInfos(uint256 tokenId)
        public
        view
        returns (
            TokenType,
            uint256,
            uint256
        )
    {
        return (
            tokenType[tokenId],
            tokenActivationDate[tokenId],
            tokenEndValidityDate[tokenId]
        );
    }

    // metadata URI
    string private _baseTokenURI = "https://api.utilityfactory.xyz/metadata/";

    function setSaleState(bool state) external onlyOwner {
        publicSale = state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }


    // OpenSea Creator fees ...
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperator {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}