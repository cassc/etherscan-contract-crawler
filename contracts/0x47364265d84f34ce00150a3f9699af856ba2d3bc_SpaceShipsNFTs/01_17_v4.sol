// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract SpaceShipsNFTs is ERC721, ERC2981, Ownable {

  using Strings for uint256;
  address constant private _DogelonTokenContract = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
  string private _BaseURI = "";
  string private _BluePrintURI = "";
  address private Owner; 
  bool private MintingEnabled;
  uint private OneDayInBlockHeight = 7150;
  uint256 private TotalShipCount;  
  mapping (uint256 => uint8) private ShipClass;
  mapping (uint256 => uint)  private ReadyAtBlockHeight;
  mapping (address => bool)  private Whitelisted;

    struct NewClass{
      uint256 DOGELONPrice;
      uint24 MaxMintSupply;
      uint24 CurrentSupply;
      uint BuildDaysInBlockHeight;
    }
    NewClass[] private Classes; 

    function initializeClasses() private {
      NewClass memory MyNewClass;  
      Classes.push(MyNewClass);
    }
  
    constructor() ERC721("DOGELONSPACESHIPS", "ELONSHIP") {
      Owner = msg.sender;
	    MintingEnabled = false;
      initializeClasses();
      _setDefaultRoyalty(Owner, 1000);
    }
 
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
      return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function setRoyalty(address _Receiver, uint96 _RoyaltyPercentageInBasePoints) external onlyOwner {
      _setDefaultRoyalty(_Receiver, _RoyaltyPercentageInBasePoints);
    }

    function tokenURI(uint256 tokenId) override public virtual view returns (string memory) {
      _requireMinted(tokenId);       
      if (block.number > ReadyAtBlockHeight[tokenId]) {
        return string(abi.encodePacked(_BaseURI, tokenId.toString(), ".json"));
      }
      return string(abi.encodePacked(_BluePrintURI, tokenId.toString(), ".json"));
    }

    function addNewClass(uint256 _DOGELONPrice, 
                         uint24 _MaxMintSupply,  
                         uint _BuildDays) public onlyOwner { 
      NewClass memory MyNewClass;
      MyNewClass.DOGELONPrice           = _DOGELONPrice;
      MyNewClass.MaxMintSupply          = _MaxMintSupply;
      MyNewClass.BuildDaysInBlockHeight = _BuildDays * OneDayInBlockHeight;
      Classes.push(MyNewClass);
    }
    
    function addNewClasses(uint256[] memory _ClassesData) public onlyOwner {
      for (uint I = 0; I < _ClassesData.length; I++) {
        uint Res = I % 3;
        if (Res == 0) {
          addNewClass(_ClassesData[I], uint24(_ClassesData[I + 1]), uint(_ClassesData[I + 2]));  
        }       
      }
    }
    
    function setClassPrice(uint _Class, uint256 _Price) public onlyOwner {
      Classes[_Class].DOGELONPrice = _Price;
    }

    function getClasses() public view returns (NewClass[] memory) {
      return Classes;
    }

    function setBaseURI(string memory _NewURI) external onlyOwner {
      _BaseURI = _NewURI;
    }

    function setBluePrintURI(string memory _NewURI) external onlyOwner {
      _BluePrintURI = _NewURI;
    }

    function withdrawETH () external onlyOwner {
      payable(Owner).transfer(address(this).balance);  
    }

    function rescueTokens (address _TokenAddress, uint256 _Amount) external onlyOwner {
      IERC20(_TokenAddress).transfer(Owner, _Amount);
    }

    function setMintState (bool _State) external onlyOwner {
      MintingEnabled = _State;
    }
    
    function totalSupply() public view returns (uint256) {    
      return(TotalShipCount);             
    }

    function getClassByTokenID(uint256 _TokenID) public view returns (uint8) {   
      return( ShipClass[_TokenID] );             
    }

    function getNewShipsSinceID(uint256 ShipID) public view returns (string memory) {
      _requireMinted(ShipID); 
      if (ShipID == TotalShipCount) {
        return("");
      }
      string memory Json = "[";
      uint256 I = ShipID;     
      while (I <= TotalShipCount) {                  
        string memory TempJson = string(abi.encodePacked('{"ShipID":"', I.toString(),'","ClassID":"',Strings.toString(ShipClass[I]),'","Owner":"',Strings.toHexString(_ownerOf(I)),'"}')); 
        if (keccak256(abi.encodePacked(Json)) == keccak256(abi.encodePacked("["))) {
          Json = string(abi.encodePacked(Json, TempJson));
        } else {
          Json = string(abi.encodePacked(Json, ",", TempJson));
        }
        I++;
      }
      Json = string(abi.encodePacked(Json, "]"));
      return(Json);
    }

    function setExternalContractWhitelist(address _Contract, bool _State) external onlyOwner {
      Whitelisted[_Contract] = _State;
    }

    function changeClassMaxSupply(uint8 _Class, uint8 _NewMaxMintSupply) external onlyOwner {
      unchecked {
        Classes[_Class].MaxMintSupply = _NewMaxMintSupply;
      }
    }

    function whitelisted_contract_mint(address _NewTokenOwner, uint8 _Class) external {
      require(_Class < Classes.length, "Class Not Found!");
      require(Whitelisted[msg.sender] || msg.sender == Owner, "Only Whitelisted Contracts Can Use This Mint Method!"); 
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;          
      }
      uint256 _TokenID = TotalShipCount;     
      _safeMint(_NewTokenOwner, _TokenID);
      ShipClass[_TokenID] = _Class;
      ReadyAtBlockHeight[_TokenID] = block.number;
    }

    function mint_Using_DOGELON(uint8 _Class) external payable {
      require(MintingEnabled, "Minting Is Locked!");
      require(_Class < Classes.length, "Class Not Found!");
      require(Classes[_Class].CurrentSupply < Classes[_Class].MaxMintSupply, "Mint Limit For This Class reached!");   
      IERC20(_DogelonTokenContract).transferFrom(msg.sender, Owner, Classes[_Class].DOGELONPrice);      
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;          
      }
      uint256 _TokenID = TotalShipCount;     
      _safeMint(msg.sender, _TokenID);
      ShipClass[_TokenID] = _Class;
      ReadyAtBlockHeight[_TokenID] = block.number + Classes[_Class].BuildDaysInBlockHeight;
    }
	
}