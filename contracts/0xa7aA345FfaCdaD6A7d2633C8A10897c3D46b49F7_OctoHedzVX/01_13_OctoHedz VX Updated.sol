// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


interface iINKz {
    function balanceOf(address address_) external view returns (uint); 
    function transferFrom(address from_, address to_, uint amount) external returns (bool);
    function burn(address from_, uint amount) external;
}

abstract contract OCTOHEDZ {

  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
  function tokensOfOwner(address owner) external virtual view returns (uint256[] memory tokens);
}

abstract contract OCTOHEDZV2 {

  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
  function tokensOfOwner(address owner) external virtual view returns (uint256[] memory tokens);
}

contract OctoHedzVX is Ownable, ERC721Enumerable {

    OCTOHEDZ private octohedz;
    address private octohedzContract = 0x6E5a65B5f9Dd7b1b08Ff212E210DCd642DE0db8B;  //Mainnet
   


    OCTOHEDZV2 private octohedzv2;
    address private octohedzv2Contract = 0x6da4c631C6AD8bFd9D7845Fd093541BEBecE2f96; //Mainnet
     

   

    mapping(address => uint8) private _allowList;

    constructor(string memory baseTokenURI, string memory baseContractURI) ERC721("OctoHedz VX", "OctoHedzVX") {
        setBaseURI(baseTokenURI);
        _baseContractURI = baseContractURI;
        octohedz = OCTOHEDZ(octohedzContract);
        octohedzv2= OCTOHEDZV2(octohedzv2Contract);
    }

    

    //limits
    uint public MAX_OCTOHEDZVX = 11111;         //max token
    uint internal PUB_OCTOHEDZVX = 6072;        //max public mint
    uint internal GEN_OCTOHEDZVX = 888;         //max gen
    uint internal REL_OCTOHEDZVX = 4000;        //max reloaded
    

    uint internal genstartingtoken = 0;         //Genesis
    uint internal corstartingtoken = 889;       //Corrupted 
    uint internal relstartingtoken = 1039;      //Reloaded 1038
    uint internal pubstartingtoken = 5039;      //Public


    uint public GEN_OCTOHEDZVX_Minted = 0; 
    uint public REL_OCTOHEDZVX_Minted = 0;   
    uint public PUB_OCTOHEDZVX_Minted = 0;
    uint public AIR_OCTOHEDZVX_Minted = 0;     




    mapping(uint256 => uint256) public mintedIDs;
    mapping(uint256 => uint256) public ReladedmintedIDs;

    
    //Variables
    uint256 public _price = 0.08 ether;
    uint256 public mintPriceINKz = 300 ether;

    bool public preSaleIsActive = false;
    bool public hasSaleStarted = false;
    string private _baseTokenURI;
    string private _baseContractURI;
    // bool public inkzMintEnabled= true;
    //uint256 public totalVxMinted = 0;

   // INKz Interactions
    address public INKzAddress;
    iINKz public INKz;
    function setINKz(address address_) external onlyOwner { 
        INKzAddress = address_;
        INKz = iINKz(address_);
    }
    
    
    // function setINKzMintStatus(bool bool_) external onlyOwner {
    //     inkzMintEnabled = bool_;
    // }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
       return _baseContractURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function flipSaleState() public onlyOwner {
        hasSaleStarted = !hasSaleStarted;
    }
    
        event Mint (address indexed to_, uint tokenId_);
        modifier onlySender {
        require(msg.sender == tx.origin, "No smart contracts allowed!");
        _;
    }
     
    //     modifier inkzMint {
    //     require(inkzMintEnabled, "Minting with INKz is not available yet!");
    //     _;
    // } 

    function setIsAllowListActive() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }
     function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }


    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

   
    function getGenAvailableIDs() public view returns (uint256[] memory) {
        uint256[] memory GenavailableIDs = new uint256[](GEN_OCTOHEDZVX);
        for (uint256 i = 0; i < GEN_OCTOHEDZVX; i++) {
           if (mintedIDs[i] != 1){
              GenavailableIDs[i] = i;
           } else {
              GenavailableIDs[i] = GEN_OCTOHEDZVX; 
           }
          
        }
        return GenavailableIDs;
    }

     
    function getRelAvailableIDs() public view returns (uint256[] memory) {
        uint256[] memory RelavailableIDs = new uint256[](REL_OCTOHEDZVX);
        for (uint256 i = 0; i < REL_OCTOHEDZVX; i++) {
           if (mintedIDs[i] != 1){
              RelavailableIDs[i] = i;
           } else {
              RelavailableIDs[i] = REL_OCTOHEDZVX; 
           }
          
        }
        return RelavailableIDs;
    }

    function Price() public view returns (uint256) {
        require(totalSupply() < MAX_OCTOHEDZVX, "Invasion has ended");  
        return _price;
    }

    


    function reserveAirdrop(uint256 numOctoHedz) public onlyOwner {
        //uint currentSupply = totalSupply();
        uint256 CorVX = corstartingtoken + AIR_OCTOHEDZVX_Minted;
        require(totalSupply() + numOctoHedz <= 150, "Exceeded airdrop supply");
        require(hasSaleStarted == false, "Sale has already started");
        uint256 index;
        // Reserved for airdrops and giveaways
        for (index = 0; index < numOctoHedz; index++) {
            _safeMint(owner(),  CorVX + index);
            AIR_OCTOHEDZVX_Minted++;
        }
    }
           

    //setup genesis to mint using token
    function mintGen(uint256 _tokenId) public {
    uint genesis = mintedIDs[_tokenId];
    require(octohedz.ownerOf(_tokenId) == msg.sender, "Must own the specific OctoHedz");
    require(genesis == 0, "tokens already used");
    require(_tokenId <= corstartingtoken , "Must be Genesis");
    require(totalSupply()<= MAX_OCTOHEDZVX, "Exceeds Total Supply");    
    require(INKz.balanceOf(msg.sender) >= mintPriceINKz, "You do not have enough INKz!");
    INKz.burn(msg.sender, mintPriceINKz); 
    mintedIDs[_tokenId] += 1;
    _safeMint(msg.sender, _tokenId+1);
    GEN_OCTOHEDZVX_Minted++;

    }

    //setup reloaded to mint using token
    
    function mintRel(uint256 tokenId1, uint256 tokenId2) public  {

    uint reloaded1 = ReladedmintedIDs[tokenId1];
    uint reloaded2 = ReladedmintedIDs[tokenId2];
    require(tokenId1 != tokenId2, "Same token");
    require(octohedzv2.ownerOf(tokenId1) == msg.sender && octohedzv2.ownerOf(tokenId2) == msg.sender , "Not token owner");   
     require (reloaded1 == 0 && reloaded2 == 0, "tokens already used");
    ReladedmintedIDs[tokenId1] += 1;
    ReladedmintedIDs[tokenId2] += 1;
    require(totalSupply()<= MAX_OCTOHEDZVX, "Exceeds Total Supply");
    require(INKz.balanceOf(msg.sender) >= mintPriceINKz, "You do not have enough INKz!");
    INKz.burn(msg.sender, mintPriceINKz); 
    
    uint256 RelVX = relstartingtoken + REL_OCTOHEDZVX_Minted;
    _safeMint(msg.sender, RelVX);
    REL_OCTOHEDZVX_Minted++;

    }
   

  
  
   //Public MINT Function
   function getOctoHedz(uint256 numOctoHedz) public payable {

        require(hasSaleStarted, "Sale must be active to mint OctoHedz");
        uint256 PubVX = pubstartingtoken + PUB_OCTOHEDZVX_Minted;
        require(numOctoHedz > 0, "need to mint at least 1");
        require(numOctoHedz <= 2, "max mint amount per session exceeded");
        require(msg.value >= _price * numOctoHedz, "insufficient funds");
        require(PUB_OCTOHEDZVX_Minted + numOctoHedz <= PUB_OCTOHEDZVX, "request exceeds max mint count"); 
        require(totalSupply()<= MAX_OCTOHEDZVX, "Exceeds Total Supply");
        require(numOctoHedz + balanceOf(msg.sender) <= 200, "Can't have more than 200 OctoHedz per wallet");
        for (uint256 i = 0; i < numOctoHedz; i++) {
        _safeMint(msg.sender, PubVX + i);
        PUB_OCTOHEDZVX_Minted++;
        }
    }

    function OctoHedzWL(uint8 numOctoHedz) public payable {
 
        uint256 PubVX = pubstartingtoken + PUB_OCTOHEDZVX_Minted;
        require(preSaleIsActive, "Pre Sale not active");
        require(numOctoHedz <= _allowList[msg.sender], "Exceeded max available per wallet");
        require(msg.value >= _price * numOctoHedz, "insufficient funds");
        require(PUB_OCTOHEDZVX_Minted + numOctoHedz <= PUB_OCTOHEDZVX, "request exceeds max mint count");
        _allowList[msg.sender] -= numOctoHedz;
        for (uint256 i = 0; i < numOctoHedz; i++) {
        _safeMint(msg.sender, PubVX + i);
        PUB_OCTOHEDZVX_Minted++;
        }
    }



   function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function claimableVX(address _user) public view returns (uint[] memory) {
         uint[] memory octoz = OCTOHEDZ(octohedzContract).tokensOfOwner(_user);

         uint arrayOctozLength = octoz.length;
         uint x=0;
         for (uint i=0; i<arrayOctozLength; i++) {
              uint256 id = octoz[i];
              if (mintedIDs[id]==0) {
                  x++;
              }
         }
         uint[] memory octozAvailable = new uint[](x);
         x=0;
         for (uint i=0; i<arrayOctozLength; i++) {
              if (mintedIDs[octoz[i]]==0) {
                  octozAvailable[x]=octoz[i];
                  x++;
              }
         }
         return octozAvailable;
    }

    function unusedReloaded(address _user) public view returns (uint[] memory) {
         uint[] memory octoz = OCTOHEDZV2(octohedzv2Contract).tokensOfOwner(_user);

         uint arrayOctozLength = octoz.length;
         uint x=0;
         for (uint i=0; i<arrayOctozLength; i++) {
              uint256 id = octoz[i];
              if (ReladedmintedIDs[id]==0) {
                  x++;
              }
         }
         uint[] memory octozUnused = new uint[](x);
         x=0;
         for (uint i=0; i<arrayOctozLength; i++) {
              if (ReladedmintedIDs[octoz[i]]==0) {
                  octozUnused[x]=octoz[i];
                  x++;
              }
         }
         return octozUnused;
    }

    function checkIfVXClaimed(uint id) public view returns (uint) {
         return mintedIDs[id];
    }
    function checkIfReloadedUsed(uint id) public view returns (uint) {
         return ReladedmintedIDs[id];
    }

}