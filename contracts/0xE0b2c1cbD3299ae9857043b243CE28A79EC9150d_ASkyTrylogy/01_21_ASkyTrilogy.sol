//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./permission/Reciver.sol";
import "./interfaces/IControlMint.sol";
import "./interfaces/IPartitionsAndMetaStore.sol";
import "./interfaces/IEarlyMintersRoyalties.sol";

contract ASkyTrylogy is ERC721Enumerable, Ownable, Reciver, ReentrancyGuard, ERC2981 {
    using SafeMath for uint256;
    using Address for address;

    IControlMint private _controlMint;
    IPartitionsAndMetaStore private _partitionsAndMetaStore;
    IEarlyMintersRoyalties private _earlyMintersRoyalties;

    uint256 private prizeWeiWL = 0.15 ether;
    uint256 private prizeWeiPS = 0.3 ether;

    uint256 private idFreemint = 0;
    uint256 private idWhitelist = 100;
    uint256 private idPublicSales = 600;

    bool public activeMintFM = false;
    bool public activeMintWL = false;
    bool public activeMintPS = false;

    string private _contractURI;

    uint256 private TOKEN_TOTAL_AMOUNT = 10000;
    mapping(address => bool) private _specialPriceMinters;

    constructor(address reciver) ERC721("TEST", "TT") Reciver(reciver){}

    function setImplementsAddress(address controlMint, address partitionsAndMetaStore, address earlyMintersRoyalties) public onlyOwner{
        _controlMint = IControlMint(controlMint);
        _partitionsAndMetaStore = IPartitionsAndMetaStore(partitionsAndMetaStore);
        _earlyMintersRoyalties = IEarlyMintersRoyalties(payable(earlyMintersRoyalties));
    }

    function setContractURI(string memory contractURI_) public onlyOwner{
        _contractURI = contractURI_;
    }

    function activeMints(bool _activeFM, bool _activeWL, bool _activePS) public onlyOwner{
        activeMintFM = _activeFM;
        activeMintWL = _activeWL;
        activeMintPS = _activePS;
    }

    function contractURI() public view returns (string memory) {
        return string(_contractURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(_partitionsAndMetaStore.getMetadata(tokenId));
    }

    function mintFM(uint32 quantity) public returns(uint32){
        require(activeMintFM, "Freemint is desactivated");
        require(
            totalSupply() <= TOKEN_TOTAL_AMOUNT,
            "Error token limit has been reached"
        );

        require(
            idFreemint < 100,
            "Error freemint token limit has been reached"
        );

        require(
            quantity <= 5 && quantity > 0,
            "The quantity for mint is not correct"
        );

        uint32 numMaxMintFreemint = _controlMint.getAvailableMintForAddressFM(msg.sender);

        require(numMaxMintFreemint > 0, "No mint available for Freemint");

        uint32 quantityMint = 0;
        uint256 index = quantity <= numMaxMintFreemint ? quantity : numMaxMintFreemint;

        for (uint256 i = 0; i < index; i++) {
            if(totalSupply() + 1 <= TOKEN_TOTAL_AMOUNT && idFreemint + 1 <= 100){ 
                _controlMint.minterUseFreemint(msg.sender);
                idFreemint = idFreemint.add(1);
                _mint(idFreemint);
                quantityMint ++;
            }else{
                break;
            }   
        }

        return quantityMint;
    }

    function mintWL(uint64 quantity) public payable returns(uint32){
        require(activeMintWL, "Whitelist is desactivated");
        require(
            totalSupply() < TOKEN_TOTAL_AMOUNT,
            "Error token limit has been reached"
        );

        require(
            idWhitelist < 600,
            "Error whitelist token limit has been reached"
        );

        require(
            quantity <= 2 && quantity > 0,
            "The quantity for mint is not correct"
        );

        uint32 numMaxMintWhitelist = _controlMint.getAvailableMintForAddressWL(msg.sender);

        require(numMaxMintWhitelist >= quantity, "You have no mint available for whitelist");
        require(msg.value >= (prizeWeiWL * quantity), "No enough amount to mint"); 

        uint32 quantityMint = 0;
        uint256 index = quantity <= numMaxMintWhitelist ? quantity : numMaxMintWhitelist;

        for (uint256 i = 0; i < index; i++) {
            if(totalSupply() + 1 <= TOKEN_TOTAL_AMOUNT && idWhitelist + 1 <= 600){
                _controlMint.minterUseWhitelist(msg.sender);
                idWhitelist = idWhitelist.add(1);
                _mint(idWhitelist);
                quantityMint ++;
            }else{
                break;
            }   
        }

        return quantityMint;

    }

    function mintPS(uint64 quantity) public payable returns(uint32){
        require(activeMintPS, "Public sale is desactivated");
        require(
            totalSupply() < TOKEN_TOTAL_AMOUNT,
            "Error token limit has been reached"
        );
        require(
            idPublicSales < TOKEN_TOTAL_AMOUNT,
            "Error public sales token limit has been reached"
        );
        require(
            quantity <= 5 && quantity > 0,
            "The quantity for mint is not correct"
        );

        uint32 numMaxMintPublicsale = _controlMint.getAvailableMintForAddressPS(msg.sender);

        require(numMaxMintPublicsale >= quantity, "You have no mint available for public sale");
        require(msg.value >= (prizeWeiPS * quantity), "No enough amount to mint"); 

        uint32 quantityMint = 0;
        uint256 index = quantity <= numMaxMintPublicsale ? quantity : numMaxMintPublicsale;

        for (uint256 i = 0; i < index; i++) {
            if(totalSupply() + 1 <= TOKEN_TOTAL_AMOUNT && idPublicSales + 1 <= TOKEN_TOTAL_AMOUNT){
                idPublicSales = idPublicSales.add(1);
                _mint(idPublicSales);
                quantityMint ++;
            }else{
                break;
            }   
        }

        return quantityMint;
    }

    function _mint(uint256 newIdToken) private {

        _safeMint(msg.sender, newIdToken, msg.data);
        _earlyMintersRoyalties.setEarlyMinter(msg.sender, newIdToken);
        _partitionsAndMetaStore.checkClosePartition(newIdToken);
        _controlMint.addMintForAddress(msg.sender);
    }

    function setDataRoyalties(address receiver, uint96 feeNumerator) public onlyOwner{
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public nonReentrant onlyReciver {
        (bool hs, ) = payable(reciver()).call{
            value: (address(this).balance * 9500) / 10000
        }("");
        require(hs);
    }

    function withdrawAll() public nonReentrant onlyReciver {
        (bool hs, ) = payable(reciver()).call{value: address(this).balance}("");
        require(hs);
    }
}