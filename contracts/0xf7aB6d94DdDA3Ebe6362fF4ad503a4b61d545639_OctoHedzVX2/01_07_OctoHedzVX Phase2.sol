// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;

import "./ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OctoHedzVX2 is Ownable, ERC721A, ReentrancyGuard {

    uint public MAX_VXOCTOS = 6047;
    bool public hasSaleStarted = false;
    bool public preSaleIsActive = false;
    string private _baseTokenURI;
    string private _baseContractURI;

    event TotalSupplyChanged(uint256 _val);
constructor(string memory baseTokenURI, string memory baseContractURI) ERC721A("OctoHedz VX2","OctoVX2")  {
        setBaseURI(baseTokenURI);
        _baseContractURI = baseContractURI;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, _toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
       return _baseContractURI;
    }

        function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }



// Modify Price Function
    uint256 public Price = 0.04 ether;
    function setPrice(uint256 _price) external onlyOwner {
        Price = _price;
    }



   
//Public Sale state
    function flipSaleState() public onlyOwner {
        hasSaleStarted = !hasSaleStarted;
    }
     


    function reserveAirdrop(uint256 numOctoHedz) public onlyOwner {

        require(hasSaleStarted == false, "Sale has already started");
        require(totalSupply() + numOctoHedz <= 100, "Exceeded airdrop supply");
        _safeMint(owner(), numOctoHedz);


    emit TotalSupplyChanged(totalSupply());

  }    

//NEW MINT FUNCTION
    function getOctoHedz(uint256 numOctoHedz) external payable {
        require(hasSaleStarted, "Sale must be active to mint OctoHedz");
        require(numOctoHedz < 9, "Amount of tokens exceeds transaction limit."); //Max 8 per txn
        require(totalSupply() + numOctoHedz <= MAX_VXOCTOS, "Amount exceeds supply.");
        require(Price * numOctoHedz == msg.value, "ETH sent not equal to cost.");
        _safeMint(msg.sender, numOctoHedz);
    emit TotalSupplyChanged(totalSupply());
  }  

//ALLOW LIST MINT

    mapping(address => uint256) public presaleWalletTracker;
    uint256 public presalePaidCounter = 0;

    uint256 public presalePrice = 0.03 ether;
    function setpresalePrice(uint256 _price) external onlyOwner {
        presalePrice = _price;
    }


    uint256 private _presalePaidLimit = 9; 
    function presalePaidLimit() external view returns (uint256) {
        return _presalePaidLimit;
    }
    function setPresalePaidLimit(uint256 presalePaidLimit_) external onlyOwner {
        _presalePaidLimit = presalePaidLimit_ + 1;
    }
  
    function setIsAllowListActive() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    bytes32 public merkleRoot;
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }


//Allow list function 
      function OctoHedzWL(uint256 numOctoHedz, bytes32[] memory proof) external payable nonReentrant {
        require(preSaleIsActive, "Pre Sale not active");
        require(presalePrice * numOctoHedz == msg.value, "Incorrect ETH amount");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)) ), "Invalid proof"); //ROOT 
        require(presaleWalletTracker[msg.sender] + numOctoHedz < _presalePaidLimit, "Exceeds presale limit");
        require(totalSupply() + numOctoHedz <= MAX_VXOCTOS, "Amount exceeds supply.");
        presaleWalletTracker[msg.sender] += numOctoHedz;
        presalePaidCounter += numOctoHedz;
        _safeMint(msg.sender, numOctoHedz);
    }  


   function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}