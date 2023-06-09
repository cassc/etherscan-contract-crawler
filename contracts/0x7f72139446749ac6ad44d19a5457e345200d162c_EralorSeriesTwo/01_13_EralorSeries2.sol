// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface FCContract {
    function balanceOf(address account, uint256 id) external view returns (uint256);
 }

 interface Series1Contract  {
    function balanceOf(address account) external view returns (uint256);
 }

contract EralorSeriesTwo is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    //CONST
    uint256 public constant S2_MAX = 500;
    uint256 public constant PURCHASE_LIMIT = 6;
    FCContract private _FCContract; 
    Series1Contract private _Series1Contract;
    string private _baseTokenURI = "https://eralorser2.s3.us-east-1.amazonaws.com/"; 
    bytes32 private _byoRoot;

    mapping(address => bool) private _hasBuilt;

    bool public isByoActive;
    bool public isPreSaleActive;
    bool public isPublicSaleActive;
    uint256 public GeneralPrice =  0.04 ether;
    uint256 public FCPrice = 0.025 ether;
    uint256 public DiscountedPrice = 0.03 ether;
    uint256 public totalSupply;
    

    constructor(
        address fcContract,
        address s1Contract
    ) ERC721("EralorSeries2", "ES2") {
        _FCContract = FCContract(fcContract);
        _Series1Contract = Series1Contract(s1Contract);
    }

//price
  function getPrice(uint256 quantity, address sender) public view returns (uint256) {
        
         if (_FCContract.balanceOf(sender, 0) > 0) {
           return FCPrice * quantity;
        } 
        if (quantity > 1 ){
            return DiscountedPrice * quantity;
        }
        return  GeneralPrice * quantity;

    }

     function setPrice(uint256 _newPrice) public onlyOwner {
          GeneralPrice = _newPrice;
      }

     function setDiscountPrice(uint256 _newPrice) public onlyOwner {
          DiscountedPrice = _newPrice;
      }

    function setFCPrice(uint256 _newPrice) public onlyOwner {
          FCPrice = _newPrice;
      }

    function setByoRoot(bytes32 merkleRoot) public onlyOwner {
        _byoRoot = merkleRoot;
    }

    function isAllowed(address sender, bytes32[] memory proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(proof, _byoRoot, leaf); 
    }

    function isSupporter(address sender) private view returns(bool) {
        return _FCContract.balanceOf(sender, 0) > 0 ||  _Series1Contract.balanceOf(sender) > 0;
    }

   function toggleIsActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleByoActive() external onlyOwner {
        isByoActive = !isByoActive;
    }

     function togglePreSaleActive() external onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }

     function withdraw() external onlyOwner { 
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    //minting
    function mintTokens(uint256 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 newTokenId = totalSupply + 1;
            _safeMint(msg.sender, newTokenId);
           totalSupply++; 
        }
    }

    function generalMintingRules(uint256 value, uint256 quantity) private view {
        require(msg.sender == tx.origin, "contracts can't mint");
        require(totalSupply + quantity <= S2_MAX, "this exceeds the public amount");
        require(value == getPrice(quantity, msg.sender), "wrong eth value");
    }

    function byoMint(bytes32[] calldata proof) external payable {
        require(isByoActive, "BYO is not active");
        require(!_hasBuilt[msg.sender], "Already minted BYO"); 
        require(isAllowed(msg.sender, proof), "Not on byo List");
        require(msg.value == 0.04 ether, "wrong eth value");
        mintTokens(1);
        _hasBuilt[msg.sender] = true;
    }

    function preSaleMint(uint256 numberOfTokens) external payable {
        require(isPreSaleActive, "Presale is not active");
        require(numberOfTokens <= PURCHASE_LIMIT,"Would exceed purchase limit");
        require(isSupporter(msg.sender), "Not allowed for Presale");
        generalMintingRules(msg.value, numberOfTokens);
        mintTokens(numberOfTokens);
    }

    function mint(uint256 numberOfTokens) external payable {
        require(isPublicSaleActive, "Public Sale is not active");
        require(numberOfTokens <= PURCHASE_LIMIT,"Would exceed purchase limit");
        generalMintingRules(msg.value, numberOfTokens);
        mintTokens(numberOfTokens);
    }

    function reserveTokens(uint256 quantity) public onlyOwner {
         require(totalSupply + quantity <= S2_MAX, "this exceed the public amount");
        mintTokens(quantity);
    }


// metaData
    function setBaseURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
    }

     function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString())); 
    }

  function walletOfOwner(address address_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        for (uint256 i = 1; i < S2_MAX; i++) {
            if (_exists(i)){
            if (address_ == ownerOf(i)) {
                _tokens[_index] = i;
                _index++;
            }}
        }

        return _tokens;
    }

}