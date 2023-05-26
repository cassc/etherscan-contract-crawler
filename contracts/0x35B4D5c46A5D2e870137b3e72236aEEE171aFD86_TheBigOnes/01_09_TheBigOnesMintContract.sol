// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//████████╗██╗░░██╗███████╗  ██████╗░██╗░██████╗░  ░█████╗░███╗░░██╗███████╗░██████╗
//╚══██╔══╝██║░░██║██╔════╝  ██╔══██╗██║██╔════╝░  ██╔══██╗████╗░██║██╔════╝██╔════╝
//░░░██║░░░███████║█████╗░░  ██████╦╝██║██║░░██╗░  ██║░░██║██╔██╗██║█████╗░░╚█████╗░
//░░░██║░░░██╔══██║██╔══╝░░  ██╔══██╗██║██║░░╚██╗  ██║░░██║██║╚████║██╔══╝░░░╚═══██╗
//░░░██║░░░██║░░██║███████╗  ██████╦╝██║╚██████╔╝  ╚█████╔╝██║░╚███║███████╗██████╔╝
//░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═════╝░╚═╝░╚═════╝░  ░╚════╝░╚═╝░░╚══╝╚══════╝╚═════╝░

//WEBSITE: https://www.thebigonesociety.com

contract TheBigOnes is ERC721A, ERC721ABurnable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    constructor() ERC721A("THE BIG ONES", "TBO") {
        _signerAddress = 0xee80f7DC6da6B4f231FAB7751C4A033D9BAA162B;
    }
    string public baseURI = "https://storage.thebigonesociety.com/nft/prereveal/metadata/";
    
    uint public constant MAX_SUPPLY = 4444;
    uint public PRICE = 0.05 ether;
    uint public MAX_PER_MINT = 2;
    uint public MAX_PER_MINT_WL = 3;

    mapping(address => uint) public signatureUsed;
    address private _signerAddress;


    mapping(address => uint) public usedMinted;

    uint public WHITELIST_START_TIME = 1667566800;
    uint public PUBLIC_START_TIME = 1667588400;

    function getIsWhitelistMintStarted() public view returns(bool) {
        return block.timestamp >= WHITELIST_START_TIME;
    }

    function getIsPublicMintStarted() public view returns(bool) {
        return block.timestamp >= PUBLIC_START_TIME;
    }

    function getMaxSupply() public pure returns(uint) {
        return MAX_SUPPLY;
    }

    function getPrice() public view returns(uint) {
        return PRICE;
    }   
    
    function getTimestampPublic() public view returns(uint) {
        return PUBLIC_START_TIME;
    }

    function getTimestampWhitelist() public view returns(uint) {
        return WHITELIST_START_TIME;
    }

    function getMaxMintPublic() public view returns(uint) {
        return MAX_PER_MINT;
    } 
    
    function getMaxMintWhitelist() public view returns(uint) {
        return MAX_PER_MINT_WL;
    }

    function getTotalMinted() public view returns(uint) {
        return _totalMinted();
    }
    
    function getWalletMintWhitelistLeft(address _wallet) public view returns(uint) {
        return MAX_PER_MINT_WL - signatureUsed[_wallet];
    }

    function getWalletMintPublicLeft(address _wallet) public view returns(uint) {
        return MAX_PER_MINT - usedMinted[_wallet];
    }

    function setMaxMintPublic(uint _amount) public onlyOwner {
        MAX_PER_MINT = _amount;
    }

    function setMaxMintWhitelist(uint _amount) public onlyOwner {
        MAX_PER_MINT_WL = _amount;
    }

    function setPrice(uint _amount) public onlyOwner {
        PRICE = _amount;
    }

    function setBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }

    function setStartPublicMint(uint _newTime) public onlyOwner {
        PUBLIC_START_TIME = _newTime;
    }

    function setStartWhitelistMint(uint _newTime) public onlyOwner {
        WHITELIST_START_TIME = _newTime;
    }

    function setSignatureAddress(address _address) public onlyOwner {
        _signerAddress = _address;
    }
        
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "Token doesn't exist");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function verifyAddressSigner(bytes memory signature) private view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        return _signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function whitelistMint(uint _count, bytes memory signature) public payable {
        require(tx.origin == msg.sender, "Origin mismatch");
        require(getIsWhitelistMintStarted(), "Sale not started");
        require(signatureUsed[msg.sender] + _count <= MAX_PER_MINT_WL, "All mints of this signature has already been used.");
        require(_totalMinted() + _count < MAX_SUPPLY, "Minted out!");
        require(_count > 0 && _count <= MAX_PER_MINT_WL, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE * _count, "Not enough ether to purchase NFTs.");
        require(verifyAddressSigner(signature), "Invalid signature");
        
        _mintNFTs(_count);
        signatureUsed[msg.sender] += _count;
    }

    function mint(uint _count) external payable {
        require(tx.origin == msg.sender, "Origin mismatch");
        require(getIsPublicMintStarted(), "Sale not started");
        require(_totalMinted() + _count <= MAX_SUPPLY, "Minted out!");
        require(_count > 0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE * _count, "Not enough ether to purchase NFTs.");
        require(usedMinted[msg.sender] + _count <= MAX_PER_MINT, "Max mint on this wallet");

        _mintNFTs(_count);
        usedMinted[msg.sender] += _count;
    }

    function _mintNFTs(uint _count) private {
        _safeMint(msg.sender, _count);
    }

    function ownerMint(uint amount) public onlyOwner {
        require(_totalMinted() + amount < MAX_SUPPLY, "Minted out!");
        _safeMint(msg.sender,amount);
    }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

}