// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";


contract SG is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using SafeMath for uint256;
  using ECDSA for bytes32;
  event PermanentURI(string _value, uint256 indexed _id);

  bool public onlyWhitelisted = true;
  bool public onlyEternalHolders = false;
  bool public paused = false;
  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public SoulsOnSell = 1; 
  uint256 public SoulsOnWhitelist = 1198; 
  uint256 public MAX_Souls = 17839;
  uint256 public token_id = 0;
  uint256 public maxMintAmount = 2;
  address public adminAddress = 0xBe59449af04D4cAF3f5E455ecEC4626b76629163;


  constructor( ) ERC721("Soul Genesis", "SOULS") {
    baseURI = "https://www.soulgenesis.art/api/json/metadatass/"; 

  }

 
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }



    function teamMint( address  user, uint numberOfTokens) public payable onlyOwner{
        require(!paused, "the contract is paused");
        require(totalSupply().add(numberOfTokens) <= MAX_Souls, "Purchase would exceed max supply of Souls");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() <= MAX_Souls) {
                _safeMint(user, mintIndex);
                token_id++;
            }
        }
    }


     function Sale(uint numberOfTokens) public payable nonReentrant {
       require(!onlyWhitelisted, "Sale is paused");
        require(numberOfTokens < SoulsOnSell, "Purchase would exceed max supply");
        require(!paused, "Sale must be active to mint Souls");
        require(totalSupply().add(numberOfTokens) < MAX_Souls, "Purchase would exceed max supply of Souls");
        require(msg.value >= cost * numberOfTokens, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_Souls) {
                _safeMint(msg.sender, mintIndex);
                token_id++;
            }
        }
    }


  function walletHoldsEternal(address _wallet) public view returns (bool) {
     address contractt = 0x399EB70fBf34fa796B9186736a291B4b90Be51Db;   
    return IERC721(contractt).balanceOf(_wallet) > 0;
  }


 
  function verifiedAddress(bytes memory signature) public view returns(bool){
    bytes32 sender = keccak256(abi.encodePacked(msg.sender));
    bytes32 message = ECDSA.toEthSignedMessageHash(sender);
    address signer = ECDSA.recover(message, signature);
    return signer==adminAddress;
  }
  



  function Presale(uint8 numberOfTokens,  bytes memory signature) public payable nonReentrant {
        require(!paused, "the contract is paused");
        require(onlyWhitelisted, "Presale is over, use regular mint");
        uint256 totalTokensOwned = balanceOf(msg.sender);
        require(totalTokensOwned + numberOfTokens < maxMintAmount, "Can only mint 1 token at a wallet");
        require(totalSupply().add(numberOfTokens) < SoulsOnWhitelist, "Purchase would exceed max supply of Souls");
        require(totalSupply().add(numberOfTokens) < MAX_Souls, "Purchase would exceed max supply of Souls");
        if(onlyEternalHolders){
          require(walletHoldsEternal(msg.sender), "No Ethernals on wallet");
        }else{
          require(verifiedAddress(signature), "Sign not verified");
        }
        require(msg.value >= cost * numberOfTokens, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_Souls) {
                _safeMint(msg.sender, mintIndex);
                token_id++;
            }
        }
    }


 

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

 

  function getState() public view returns(bool state) {
    return paused;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setSoulsOnSell(uint256 _newSouls) public onlyOwner {
    SoulsOnSell = _newSouls;
  }

  function setWhitelistSoulsOnSell(uint256 _newSouls) public onlyOwner {
    SoulsOnWhitelist = _newSouls;
  }

  function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setAdminAddress(address _address) public onlyOwner {
    adminAddress = _address;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function setOnlyEternalHolders(bool _state) public onlyOwner {
    onlyEternalHolders = _state;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }


  function pause(bool _state) public onlyOwner {
        paused = _state;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }


  function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
  }
  

    address a1 = 0x66a7E85fC3bbacF0A9D0f81B9F5Bd080BE599D82; 

    address a2 = 0x91C744fa5D176e8c8c2243a952b75De90A5186bc; 

    address a3 = 0xE0D80FC054BC859b74546477344b152941902CB6; 

    address a4 = 0xae87B3506C1F48259705BA64DcB662Ed047575Bb; 
     
 
  function withdraw() public payable onlyOwner {

       uint256 _sender1 = address(this).balance * 23/100;
       uint256 _sender2 = address(this).balance * 24/100;
       uint256 _sender3 = address(this).balance * 23/100;
       uint256 _sender4 = address(this).balance * 30/100;

        require(payable(a1).send(_sender1));
        require(payable(a2).send(_sender2));
        require(payable(a3).send(_sender3));
        require(payable(a4).send(_sender4));
  }
}