// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/* 
 * 7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
 * 77      777  7777  77  7777  77  77737777  77777777        7777    777777    7777  7776777  777      77
 * 7  7777  77  777  777  7777  77  77777777  77777777777  777777  77  7777  77  777   777777  77  7777  7
 * 7  7777  77  77  7777  7777  77  77777777  77777777777  77777  7777  77  7777  77    77777  77  7777  7
 * 77  7177777  7  77777  7777  77  77777777  77777777777  77777  7777  77  7777  77  77  777  777  777777
 * 7777  77777     77877  7777  77  77777777  77777777777  77777  7777  77  7777  77  777  77  77777  7777
 * 777777  777  77  7777  7777  77  77777777  77777777777  77777  7777  77  7777  77  7777  7  7777577  77
 * 7  7777  77  777  777  7777  77  77777777  77777977777  77777  7777  77  7777  77  77777    77  7777  7
 * 7  7777  77  7777  77   77   77  77777777  77777777777  777777  77  7777  77  777  772777   77  7777  7
 * 77      777  7777  777      777        77        77777  7777777    777777    7777  7777777  777      77
 * 7777777777777777777777777777777777777777777777777777777777777777747777777777777777777777777777777777777
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ERC721A.sol";
import "./VerifySignature.sol";

error ExceedsMaxSupply();
error ExceedsMaxPerAddress();
error SignatureNotValid();
error SenderMustBeOrigin();
error WrongEtherAmountSent();
error TokenDoesNotExist();
error SaleNotOpen();
error ArraysDifferentLength();


contract Skulltoons is ERC721A, IERC2981, VerifySignature, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 7700;
    uint256 public constant AIRDROP_SUPPLY = 77;
    uint256 public ROYALTY_PERCENT = 7;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant PRICE_PER_NFT = .145 ether;
    address public constant THEODORU_ADDRESS = 0x9D20e79A853409Ec89aa37116d823dA8066743a8;

    enum ContractState { PAUSED, SKULL_GAME, PRESALE, PUBLIC, REVEALED }
    ContractState public currentState = ContractState.PAUSED;

    string private baseURI;
    string private baseURISuffix;

    address public royaltyAddress;

    constructor(string memory _base, string memory _suffix) 
        ERC721A("Skulltoons", "SKULL")
        VerifySignature("sk-v1", msg.sender)
    {
        baseURI = _base;
        baseURISuffix = _suffix;
        royaltyAddress = msg.sender;
    }

    function claim(uint256 quantity, uint256 maxMintAmount, bytes memory signature) external payable nonReentrant {
        if(currentState == ContractState.PAUSED || 
            currentState == ContractState.REVEALED) revert SaleNotOpen();
        if(getNFTPrice(quantity) != msg.value) revert WrongEtherAmountSent();
        if(totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();
        if(!_verify(msg.sender, maxMintAmount, signature)) revert SignatureNotValid();
        if(_numberMinted(msg.sender) + quantity > maxMintAmount) revert ExceedsMaxPerAddress();

        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable nonReentrant {
        if(currentState != ContractState.PUBLIC) revert SaleNotOpen();
        if(_numberMinted(msg.sender) + quantity > MAX_PER_WALLET) revert ExceedsMaxPerAddress();
        if(totalSupply() + quantity  > MAX_SUPPLY) revert ExceedsMaxSupply();
        if(getNFTPrice(quantity) != msg.value) revert WrongEtherAmountSent();

        _safeMint(msg.sender, quantity);
    }

    function getNFTPrice(uint256 quantity) public pure returns (uint256) {
        return PRICE_PER_NFT * quantity;
    }


    /****************************************\
    *             ADMIN FUNCTIONS            *
    \****************************************/

    function changeContractState(ContractState _state) external onlyOwner {
        currentState = _state;
        if(currentState == ContractState.SKULL_GAME) {
            MAX_SUPPLY = 51; // Supply for 1 airdrop and 50 for Skull Game
        } else {
            MAX_SUPPLY = 7700; // Max collection supply less airdrops
        }
    }

    function airdrop(address to, uint256 quantity) external onlyOwner {
        if(totalSupply() + quantity > AIRDROP_SUPPLY + MAX_SUPPLY) revert ExceedsMaxSupply();

        _safeMint(to, quantity);
    }

    function setBaseURI(string calldata _base, string calldata _suffix) external onlyOwner {
        baseURI = _base;
        baseURISuffix = _suffix;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(THEODORU_ADDRESS), address(this).balance/5);
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function setRoyalties(address _royaltyAddress, uint256 _royaltyPercent) public onlyOwner {
        royaltyAddress = _royaltyAddress;
        ROYALTY_PERCENT = _royaltyPercent;
    }


    /****************************************\
    *           OVERRIDES & EXTRAS           *
    \****************************************/

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        if(currentState != ContractState.REVEALED) {
            return string(abi.encodePacked(baseURI, "pre", baseURISuffix));
        }
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseURISuffix));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // EIP-2981: NFT Royalty Standard
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256 royaltyAmount) {
        if(!_exists(tokenId)) revert TokenDoesNotExist();
        royaltyAmount = ((salePrice / 100) * ROYALTY_PERCENT);
        return (royaltyAddress, royaltyAmount);
    }
}