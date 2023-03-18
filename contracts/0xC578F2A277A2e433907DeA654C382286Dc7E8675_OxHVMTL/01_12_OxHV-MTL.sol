// SPDX-License-Identifier: CC0
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract OxHVMTL is Ownable,ERC721A {
    
    string  public                  metadata_url;        
    
    uint256 public                  MAX_SUPPLY              = 10000;        
    uint256 public constant         MAX_PER_TX              = 20;   
    uint256 public constant         RESERVEDTEAM            = 555;
    uint256 public                  teamMinted              = 0;
    bool public                     isPaused                = false;
    uint256 public                  priceInWei              = 0.01 ether;        
    mapping(address => uint) public addressToMinted;
    uint256 public constant         FREE_MINTS              = 500;
    uint256 public constant         FREE_MINTS_PER_WALLET   = 5;

  constructor(string memory _tokenURI) 
    ERC721A("0xHV-MTL", "0xHV-MTL") {
        metadata_url = _tokenURI;
    }

    function freeMint (uint256 count) external payable {

        require(! isPaused , "Paused!");      
        require(msg.sender == tx.origin,"No smart contracts allowed!");   
        require(totalSupply() + count <= FREE_MINTS, "Not enough supply left!");           
        require(addressToMinted[_msgSender()]+count<=FREE_MINTS_PER_WALLET,"5 free mints per wallet!");    
         _safeMint(_msgSender(), count);
        addressToMinted[_msgSender()]+=count;            

    }

      function mint(uint256 count) external payable {        
        require(! isPaused , "Paused!");
        require(count <= MAX_PER_TX, "Exceeds max mint per transaction!");
        require(msg.sender == tx.origin,"No smart contracts allowed!");   
        require(totalSupply() + count <= MAX_SUPPLY, "Not enough supply left!");  
        require(count * priceInWei <= msg.value, "Incorrect ether value!");
            
        _safeMint(_msgSender(), count);
               
    }

    function comboMint(uint256 count) external payable{


require(! isPaused , "Paused!");
        require(count <= MAX_PER_TX, "Exceeds max mint per transaction!");
        require(msg.sender == tx.origin,"No smart contracts allowed!");   
        require(totalSupply() + count <= MAX_SUPPLY, "Not enough supply left!");  

        uint256 rebateCount = (totalSupply() + count <= FREE_MINTS) && (addressToMinted[_msgSender()] < FREE_MINTS_PER_WALLET) ? 
        (FREE_MINTS_PER_WALLET - addressToMinted[_msgSender()]) : 0;
        if (rebateCount>count)
        rebateCount=count;
        require( (count-rebateCount) * priceInWei <= msg.value, "Incorrect ether value!");
            
        _safeMint(_msgSender(), count);
        if (rebateCount!=0)
        addressToMinted[_msgSender()]+=rebateCount;            

    }


  function setPrice (uint256 newPrice) external onlyOwner {
      priceInWei = newPrice;
  }
  function setPaused (bool newIsPaused) external onlyOwner {
      isPaused= newIsPaused;
  }
  
    function setSupply (uint256 newSupply) external onlyOwner {
      MAX_SUPPLY = newSupply;
  }

  function setTokenURI(string memory _tokenURI) public onlyOwner {
        metadata_url = _tokenURI;
    }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist!");
        
        bytes memory strBytes = bytes(metadata_url);
        if( strBytes.length>0)
        return string(abi.encodePacked(metadata_url, Strings.toString(_tokenId)));
        else
        return "";
    }

    function reserveMint(uint256 count) external onlyOwner {
        require(teamMinted+count <= RESERVEDTEAM );
        teamMinted += count;
        _safeMint(_msgSender(),count);
    }
  

    function promoDrop(uint256 startID,address[] memory to) external onlyOwner 
    {        
        unchecked {
        for (uint256 n=startID;n<(startID+to.length);) {
        safeTransferFrom(_msgSender(),to[(n-startID)],n);
            ++n;
            }
        }
    }


    function withdraw(uint256 amount) external onlyOwner {
    require(amount<=address(this).balance);
    payable(_msgSender()).transfer(amount);     
    }


}