// SPDX-License-Identifier: MIT

/*

@@@@@@   @     @   @         @  @@@@@@  @        @  @       @  @ @ @ @ @   @@@@@@@
@    @   @     @   @  @   @  @  @    @  @        @  @ @     @  @           @
@@@@@@   @     @   @    @    @  @@@@@@  @        @  @   @   @  @   @ @ @   @@@@@@@
@@       @     @   @         @  @@      @        @  @     @ @  @       @         @
@@       @@@@@@@   @         @  @@      @@@@@@@  @  @       @  @ @ @ @ @   @@@@@@@

*/

pragma solidity ^0.8.4;

import "../lib/openzeppelin/contracts/access/Ownable.sol";
import "../lib/openzeppelin/contracts/utils/Strings.sol";
import "../lib/openzeppelin/contracts/utils/Address.sol";
import "../lib/openzeppelin/contracts/token/common/ERC2981.sol";
import "../lib/openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract Pumplings is ERC721A, Ownable, ERC2981 {
    uint256 public cost = 10000000000000000; // 0.01 eth for second mint
    uint256 public maxSupply = 5000;
    uint256 public perWalletMaxAmount = 2;
    uint256 public teamMintAmount = 50;

    string public baseURI = "";

    bool public publicSaleIsActive;
    bool public preSaleIsActive;
    bool public isRevealed;

    bytes32 public root;

    mapping(address => bool) private _presaleList; // for FE it should return result as function
    mapping(address => bool) public alreadyMinted; // for FE it should return result as function
    mapping(address => uint256) private amount; // for FE it should return result as function

    constructor(bytes32 merkleroot
    ) ERC721A("PUMPLINGS", "PMP") {
        _setDefaultRoyalty(address(this), 750); // 7.5% royalties
        root = merkleroot;
    }

    function setMerkleRoot(bytes32 merkleroot) onlyOwner public{
        root = merkleroot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = (_newBaseURI);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setRoyalties(address recipient, uint96 value) external onlyOwner {
        require(recipient == address(0), "Invalid address");

        _setDefaultRoyalty(recipient, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function teamMint() public onlyOwner{
        _safeMint(msg.sender, teamMintAmount);
    }

    function wlMint(uint256 _amount, bytes32[] memory proof) public payable {
        require(preSaleIsActive, "Whitelist sale is not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verify(leaf, proof), 'User is not on the whitelist');
        uint256 supply = totalSupply();

        require(_amount > 0, "Amount cannot lower than 1");
        require(_amount <= perWalletMaxAmount, "Per wallet can mint max 2 NFT");
        require(supply + _amount <= maxSupply, "Exceed max supply");
        require( amount[msg.sender] + _amount <= perWalletMaxAmount, "Too many tokens");
        !alreadyMinted[msg.sender]
                ? require(cost * (_amount - 1) <= msg.value, "Ether value sent is not correct")
                : require(cost * (_amount) <= msg.value, "Ether value sent is not correct");

        amount[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
        alreadyMinted[msg.sender] = true;
    }

    function mint(uint256 _amount) external payable {
            require(publicSaleIsActive, "Public sale is not active");
            uint256 supply = totalSupply();
            require(_amount > 0, "Total number of mints cannot be 0");
            require(_amount <= 2, "Total number of mints cannot exceed 2");
            require(amount[msg.sender] + _amount <= perWalletMaxAmount,"You can only mint 2 in total");
            require(supply + _amount <= maxSupply, "Purchase would exceed max supply of Tokens");

            //Check msg.value
            amount[msg.sender] == 0
                 ? require(cost * (_amount - 1) <= msg.value, "Ether value sent is not correct")
                 : require(cost * (_amount) <= msg.value, "Ether value sent is not correct");


            amount[msg.sender] += _amount;
            _safeMint(msg.sender, _amount);
            alreadyMinted[msg.sender] = true;
    }

    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = true;
        }
    }

    function removeFromPresaleList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = false;
        }
    }

    function onPreSaleList(address addr) external view returns (bool) {
        return _presaleList[addr];
    }

    function userAlreadyMinted(address addr) external view returns (bool){
        return alreadyMinted[addr];
    }

    function mintedNFTNumber(address addr) external view returns (uint256){
        return amount[addr];
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
        require(os);
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool){
        return MerkleProof.verify(proof, root, leaf);
    }

    function togglePublicSale() external onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }

        function togglePreSale() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory){
            require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
            string memory currentBaseURI = _baseURI();

            if(isRevealed == false){
                return "ipfs://QmZGdjFvaoCTdnbT3N2897wUDw1Ms6gJG6N8RbWqgGp8bD/hidden.json";
            }

            return
              bytes(currentBaseURI).length > 0
                 ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json"))
                 : "";
        }
}