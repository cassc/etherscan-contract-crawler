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

contract EralorSeriesOne is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    //CONST
    uint256 public constant S1_MAX = 1000;
    uint256 public claimable = 125;
    uint256 public constant PURCHASE_LIMIT = 3;
    FCContract public _FCContract; 
    string private _placeholderURI;
    string private _baseTokenURI;
    bytes32 private _byoRoot;
    bytes32 private _claimRoot;

    mapping(address => bool) private _hasBuilt;
    mapping(address => bool) private _hasClaimed;

    bool public isByoActive;
    bool public isPublicSaleActive;
    uint256 public price =  0.08 ether;
    uint256 public totalSupply;
    

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenUri,
        address fcContract
    ) ERC721(name, symbol) {
        _placeholderURI = baseTokenUri;
        _baseTokenURI = baseTokenUri;
        _FCContract = FCContract(fcContract);
    }

//price
  function getPrice(uint256 quantity, address sender) public view returns (uint256) {
        uint256 priceForThisMint = price *  quantity;
         if (_FCContract.balanceOf(sender, 0) > 0) {
            priceForThisMint = priceForThisMint /2;
        } 
        return priceForThisMint;
    }
     function setPrice(uint256 _newPrice) public onlyOwner {
          price = _newPrice;
      }

    function setByoRoot(bytes32 merkleRoot) public onlyOwner {
        _byoRoot = merkleRoot;
    }

      function setClaimRoot(bytes32 merkleRoot) public onlyOwner {
        _claimRoot = merkleRoot;
    }

    function setClaimable(uint256 newClaimable) public onlyOwner {
        claimable = newClaimable;
    }

    function isAllowed(address sender, bytes32[] memory proof, bytes32 root) public pure returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(proof, root, leaf); 
    }

   function toggleIsActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleByoActive() external onlyOwner {
        isByoActive = !isByoActive;
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
        require(totalSupply + quantity + claimable <= S1_MAX, "this exceeds the public amount");
        require(value == getPrice(quantity, msg.sender), "wrong eth value");
    }

    function byoMint(bytes32[] calldata proof) external {
        require(isByoActive, "BYO is not active");
        require(!_hasBuilt[msg.sender], "Already minted BYO");
        require(isAllowed(msg.sender, proof,_byoRoot), "Not on byo List");
        mintTokens(1);
        _hasBuilt[msg.sender] = true;
    }

    function mint(uint256 numberOfTokens) external payable {
        require(isPublicSaleActive, "Public Sale is not active");
        require(numberOfTokens <= PURCHASE_LIMIT,"Would exceed purchase limit");
        generalMintingRules(msg.value, numberOfTokens);
        mintTokens(numberOfTokens);
    }

    function claim(bytes32[] calldata proof) external {
        require(isPublicSaleActive, "public sale is not active");
        require(claimable > 0,"No more tokens left to claim");
        require(!_hasClaimed[msg.sender], "Already Claimed");
        require(isAllowed(msg.sender, proof, _claimRoot), "Not on claim List");
         mintTokens(1);
        _hasClaimed[msg.sender] = true;
        claimable--;
    }

    function reserveTokens(uint256 quantity) public onlyOwner {
         require(totalSupply + quantity <= S1_MAX, "this exceed the public amount");
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
        //todo: prerevealIMG   
    }

  function walletOfOwner(address address_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        for (uint256 i = 1; i < S1_MAX; i++) {
            if (_exists(i)){
            if (address_ == ownerOf(i)) {
                _tokens[_index] = i;
                _index++;
            }}
        }

        return _tokens;
    }

}