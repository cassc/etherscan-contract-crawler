// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract SoccerPrince is ERC721A, Ownable{

    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public maxSupply = 6888;

    bool public open = true;

    uint256 public maxPerWallet = 2;

    uint256 public price = 0.00188 ether;
    
    string private _baseTokenURI = "https://www.soccerprince.club/img/metadata/";

    bytes32 public merkleRoot;


    constructor()ERC721A("SoccerPrince", "SP", 1000)
    {
    } 

    modifier eoaOnly() {
        require(tx.origin == msg.sender, "EOA Only");
        _;
    }


    function toggleOpen() external eoaOnly onlyOwner
    {
        open = !open;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external eoaOnly onlyOwner
    {
        merkleRoot = _merkleRoot;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external eoaOnly onlyOwner
    {
        maxPerWallet = _maxPerWallet;
    }

    function setPrice(uint256 _price) external eoaOnly onlyOwner
    {
        price = _price;
    }

    function mintTo(address _to,uint256 amount) public eoaOnly onlyOwner{

        require(totalSupply().add(amount) <= maxSupply,"Exceed max supply."); 

        _safeMint(_to, amount);
    }

    function mint(uint256 amount) public eoaOnly payable{

        require(open,"Not open.");

        require(numberMinted(msg.sender).add(amount) <= maxPerWallet, "Exceed max per wallet.");

        require(totalSupply().add(amount) <= maxSupply,"Exceed max supply."); 

        require(msg.value >= price.mul(amount),"Insufficient funds.");

        _safeMint(msg.sender, amount);
    }

    function wlMint(uint256 amount, bytes32[] calldata _merkleProof) public eoaOnly{

        require(open,"Not open.");

        require(numberMinted(msg.sender).add(amount) <= maxPerWallet, "Exceed max per wallet.");

        require(totalSupply().add(amount) <= maxSupply,"Exceed max supply.");   

        require(MerkleProof.verify(_merkleProof, merkleRoot , keccak256(abi.encodePacked(msg.sender))),"Invalid proof");

        _safeMint(msg.sender, amount);
    }


    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){

        string memory baseURI = _baseTokenURI;
        
        if(bytes(baseURI).length > 0){
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
        return "";
    }


    function withdrawETH() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

}