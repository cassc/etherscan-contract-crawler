// SPDX-License-Identifier: MIT
/*  
   
   █▀▀▄	 ▐▌▀▀   ██   ██   ▐▌
   █   ▌ ▐▌▀▀  ▐▌ ▀▌▀ ▐▌  ▐▌
   █▄▄▀	 ▐▌▄▄  ▐▌  ▀  ▐▌  ▐▌

    DemiVerse Studio - DemiHumanNFTs / 2021 
*/

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

abstract contract BAYCFriend {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

abstract contract MAYCFriend {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

abstract contract CoolCatsFriend {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract DemiHuman is ERC721, ERC721Enumerable, Ownable {
    
  using SafeMath for uint256;
  using Strings for uint256;

  BAYCFriend private bayc;
  MAYCFriend private mayc;  
  CoolCatsFriend private cool;
  
  bool private _isPreSaleD1Active = false;
  bool private _isPreSaleD2Active = false;
  bool private _isPublicSaleActive = false;
  
  uint256 public offsetIndex = 0;
  uint256 public revealTimeStamp = block.timestamp + (86400 * 12); 
  uint256 public constant PRICE = .08 ether;
  uint256 public constant MAX_SUPPLY = 10000;

  string private _baseURIExtended;
  string private _preRevealURI;

  address private s1 = 0x819A899c0325342CD471A485c1196d182F85860D ;
  address private s2 = 0x295fF892A2B5941ED26Ff8a10FEcF90554092719 ;
  address private s3 = 0xFF626Ae456Cd4296E54C096f8BEa3a2Ed1439243 ;
  address private s4 = 0x1A336Ac6B4e75933AA8e179E9917871b6297d85f ;

  mapping(address => bool) private _allowList; 
  mapping(address => bool) private _blackList;
  
  modifier onlyShareHolders() {
        require(msg.sender == s1 || msg.sender == s2 || msg.sender == s3 || msg.sender == s4);
        _;
    }

  modifier onlyRealUser() {
    require(msg.sender == tx.origin, "Oops. Something went wrong !");
    _;
  }
  
  event PreSaleD1_Started();
  event PreSaleD1_Stopped();
  event PreSaleD2_Started();
  event PreSaleD2_Stopped();
  event PublicSale_Started();
  event PublicSale_Stopped();
  event TokenMinted(uint256 supply);

  constructor(address dependentContractAddress1, address dependentContractAddress2, address dependentContractAddress3) 
  ERC721('DemiHuman', 'DEMI') {
      bayc = BAYCFriend(dependentContractAddress1);
      mayc = MAYCFriend(dependentContractAddress2);
      cool = CoolCatsFriend(dependentContractAddress3);
  }

  function addToAllowList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _allowList[addresses[i]] = true;
    }
  }

  function removeFromAllowList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _allowList[addresses[i]] = false;
    }
  }
  
  function onAllowList(address addr) external view returns (bool) {
    return _allowList[addr];
  }
  
  function startPreSaleD1() public onlyOwner {
    _isPreSaleD1Active = true;
    emit PreSaleD1_Started();
  }

  function pausePreSaleD1() public onlyOwner {
    _isPreSaleD1Active = false;
    emit PreSaleD1_Stopped();
  }

  function isPreSaleD1Active() public view returns (bool) {
    return _isPreSaleD1Active;
  }
  
  function startPreSaleD2() public onlyOwner {
    _isPreSaleD2Active = true;
    emit PreSaleD2_Started();
  }

  function pausePreSaleD2() public onlyOwner {
    _isPreSaleD2Active = false;
    emit PreSaleD2_Stopped();
  }

  function isPreSaleD2Active() public view returns (bool) {
    return _isPreSaleD2Active;
  }

  function startPublicSale() public onlyOwner {
    _isPublicSaleActive = true;
    emit PublicSale_Started();
  }

  function pausePublicSale() public onlyOwner {
    _isPublicSaleActive = false;
    emit PublicSale_Stopped();
  }

  function isPublicSaleActive() public view returns (bool) {
    return _isPublicSaleActive;
  }
  

  function withdraw() public onlyShareHolders {
    uint256 _each = address(this).balance / 4;
    require(payable(s1).send(_each), "Send Failed");
    require(payable(s2).send(_each), "Send Failed");
    require(payable(s3).send(_each), "Send Failed");
    require(payable(s4).send(_each), "Send Failed");
  }
  
  function getTotalSupply() public view returns (uint256) {
    return totalSupply();
  }

  function getTokenByOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function mint_presaled1(uint8 NUM_TOKENS_MINT) public payable onlyRealUser {
    require(_isPreSaleD1Active, "Sales is not active");
    require(totalSupply().add(NUM_TOKENS_MINT) <= 9612, "Exceeding max supply");
    require(_allowList[msg.sender], "You are not in the allowList");
    require(NUM_TOKENS_MINT <= 2, "You can not mint over 2 at a time");
    require(NUM_TOKENS_MINT > 0, "At least one should be minted");
    require(PRICE*NUM_TOKENS_MINT <= msg.value, "Not enough ether sent");
    _allowList[msg.sender] = false ;
    _mint(NUM_TOKENS_MINT, msg.sender);
    emit TokenMinted(totalSupply());
  }
  
  function mint_presaled2(uint8 NUM_TOKENS_MINT) public payable onlyRealUser {
    require(_isPreSaleD2Active, "Sales is not active");
    require(totalSupply().add(NUM_TOKENS_MINT) <= 9612, "Exceeding max supply");
    require(_blackList[msg.sender] == false, "You have already minted"); 
    uint bayc_balance = bayc.balanceOf(msg.sender);
    uint mayc_balance = mayc.balanceOf(msg.sender);
    uint cool_balance = cool.balanceOf(msg.sender);
    require(bayc_balance > 0 || mayc_balance > 0 || cool_balance > 0, "You must hold at least one BAYC/MAYC/CoolCats");
    require(NUM_TOKENS_MINT <= 2, "You can not mint over 2 at a time");
    require(NUM_TOKENS_MINT > 0, "At least one should be minted");
    require(PRICE*NUM_TOKENS_MINT <= msg.value, "Not enough ether sent");
    _blackList[msg.sender] = true;
    _mint(NUM_TOKENS_MINT, msg.sender);
    emit TokenMinted(totalSupply());
  }
  
  function mint_public(uint8 NUM_TOKENS_MINT) public payable onlyRealUser {
    require(_isPublicSaleActive, "Sales is not active");
    require(totalSupply().add(NUM_TOKENS_MINT) <= 9612, "Exceeding max supply");
    require(NUM_TOKENS_MINT <= 10, "You can not mint over 10 at a time");
    require(NUM_TOKENS_MINT > 0, "At least one should be minted");
    require(PRICE*NUM_TOKENS_MINT <= msg.value, "Not enough ether sent");
    _mint(NUM_TOKENS_MINT, msg.sender);
    emit TokenMinted(totalSupply());
  }
  
  function reserve(uint256 num) public onlyOwner {
    require(totalSupply().add(num) <= MAX_SUPPLY, "Exceeding max supply");
    _mint(num, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function airdrop(uint256 num, address recipient) public onlyOwner {
    require(totalSupply().add(num) <= MAX_SUPPLY, "Exceeding max supply");
    _mint(num, recipient);
    emit TokenMinted(totalSupply());
  }
  
  function airdropToMany(address[] memory recipients) external onlyOwner {
    require(totalSupply().add(recipients.length) <= MAX_SUPPLY, "Exceeding max supply");
    for (uint256 i = 0; i < recipients.length; i++) {
      airdrop(1, recipients[i]);
    }
  }

  function _mint(uint256 num, address recipient) internal {
    uint256 supply = totalSupply();
    for (uint256 i = 0; i < num; i++) {
      _safeMint(recipient, supply + i);
    }
  }

  function setRevealTimestamp(uint256 newRevealTimeStamp) external onlyOwner {
    revealTimeStamp = newRevealTimeStamp;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseURIExtended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function setPreRevealURI(string memory preRevealURI) external onlyOwner {
    _preRevealURI = preRevealURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    if (totalSupply() >= MAX_SUPPLY || block.timestamp >= revealTimeStamp) {
      if (tokenId < MAX_SUPPLY) {
        uint256 offsetId = tokenId.add(MAX_SUPPLY.sub(offsetIndex)).mod(MAX_SUPPLY);
        return string(abi.encodePacked(_baseURI(), offsetId.toString(), ".json"));
      } } 
      else {
      return _preRevealURI;
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}