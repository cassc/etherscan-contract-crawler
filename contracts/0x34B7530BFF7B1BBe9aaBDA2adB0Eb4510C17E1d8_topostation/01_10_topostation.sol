//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MerkleWhitelist is Ownable {
  bytes32 public wl1WhitelistMerkleRoot = 0x628187298c9c8fbafcb3712be638de14a43fcd85f10e0600b457ab998e180daf;

  function _verifyWl1Sender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), wl1WhitelistMerkleRoot);
  }

  function _verify(bytes32[] memory proof, bytes32 addressHash, bytes32 whitelistMerkleRoot)
    internal
    pure
    returns (bool)
  {
    return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);
  }

  function _hash(address _address) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_address));
  }


  function setWl1WhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    wl1WhitelistMerkleRoot = merkleRoot;
  }


  /*
  MODIFIER
  */
 modifier onlyWl1Whitelist(bytes32[] memory proof) {
    require(_verifyWl1Sender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
 

}


contract topostation is Ownable, ERC721A, ReentrancyGuard,MerkleWhitelist {
     using SafeMath for uint256;
   
    uint256 public maxSupply = 2222;
    uint256 public AMOUNT = 333;

    uint256 public PRICE = 1 ether;

    uint256 public LIMIT = 5;

    bool _isActive = true;
    
    string public BASE_URI="https://data.awakenkakusei.net/metadata/";
    string public CONTRACT_URI ="https://data.awakenkakusei.net/api/contracturl.json";

    struct Info {
        uint256 all_amount;
        uint256 minted;
        uint256 price;
        uint256 start_time;
        uint256 numberMinted;
        uint256 limit;
        uint256 amount;
        bool isActive;
    }


    constructor() ERC721A("Topostation", "topostation") {
        _safeMint(msg.sender, 1);
    }  
    
    function info(address user) public view returns (Info memory) {
        return  Info(maxSupply,totalSupply(),PRICE,0,_numberMinted(user),LIMIT,AMOUNT,_isActive);
    }


    function mint(uint256 amount,bytes32[] memory proof) external payable onlyWl1Whitelist(proof){
        require(msg.sender == tx.origin, "Cannot mint from contract");
        require(_isActive, "must be active to mint tokens");
        require(amount > 0, "amount must be greater than 0");
        require(totalSupply().add(amount) <= AMOUNT, "Max supply for mint reached!");
        require(totalSupply().add(amount) <= maxSupply, "max supply would be exceeded");

        uint minted = _numberMinted(msg.sender);
        require(minted.add(amount) <= LIMIT, "max mint per wallet would be exceeded");
        
        require(msg.value >= PRICE * amount, "value not met");
        _safeMint(msg.sender, amount);
    }

   function withdraw() public onlyOwner nonReentrant {
        (bool succ, ) = payable(owner()).call{value: address(this).balance}('');
        require(succ, "transfer failed");
   }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }


    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json"));
    }

    function flipState(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function setPrice(uint256 price) public onlyOwner
    {
        PRICE = price;
    }

    function setAmount(uint256 amount) public onlyOwner
    {
        AMOUNT = amount;
    }

    function setLimit(uint256 limit) public onlyOwner
    {
        LIMIT = limit;
    }



}