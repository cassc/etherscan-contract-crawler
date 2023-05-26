// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./EvolutionContract.sol";

contract TokenmonMinter is ERC721Enumerable, PaymentSplitter, Ownable {
  using Strings for uint256;

  IEvolutionContract evolutionContract;

  bool public _isMintingActive = false;
  bool public _isBaseUriSet = false;
  
  mapping(address => uint256) public admintsRemaining;
  uint256 public constant MAX_FIRST_EVO_SUPPLY = 10420; // This supply is for the first evolutions only, evolved tokens can exceed this

  uint256 public constant FIRST_EVO_PRICE = 0.069 ether;

  uint256 private _firstEvoTokenId = 0; // can't use totalSupply due to existence of burning
  uint256 private _secondEvoTokenId = MAX_FIRST_EVO_SUPPLY;

  string private _baseUri = "https://ipfs.io/ipfs/Qmd9RWBuj2AURbSDG19CMGamjh3ZHdcGxRmd9QWn8paxDp/";

  uint256 public REVEAL_TIMESTAMP = 1630339200;
  uint256 public offsetBlock;
  uint256 public offset;

  event Mint(address _to, uint256 _amount);
  event Evolve(address _to, uint256 _tokenId, uint256[3] _burnedTokens);

  constructor(address[] memory payees, uint256[] memory shares) ERC721("Tokenmon", "TM") PaymentSplitter(payees, shares) {
    for (uint i = 0; i < payees.length; i++) {
      admintsRemaining[payees[i]] = 10;
    }
  }

  function mint(uint256 amount) public payable {
    require(_isMintingActive, "TokenmonMinter: sale is not active");
    require(amount > 0, "TokenmonMinter: must mint more than 0");
    require(amount <= 20, "TokenmonMinter: must mint fewer than 20");
    require(_firstEvoTokenId < MAX_FIRST_EVO_SUPPLY, "TokenmonMinter: sale has ended");
    require(_firstEvoTokenId + amount <= MAX_FIRST_EVO_SUPPLY, "TokenmonMinter: exceeds max supply");
    require(amount * FIRST_EVO_PRICE == msg.value, "TokenmonMinter: must send correct ETH amount");

    for (uint i = 0; i < amount; i++) {
      _firstEvoTokenId = _firstEvoTokenId + 1;
      _mint(msg.sender, _firstEvoTokenId);
    }
    
    emit Mint(msg.sender, amount);

    if (offsetBlock == 0 && (totalSupply() == MAX_FIRST_EVO_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
        offsetBlock = block.number;
    }
  }

  function admint(uint256 amount) public {
    require(admintsRemaining[msg.sender] > 0, "TokenmontMinter: message sender has no admints remaining");
    require(admintsRemaining[msg.sender] - amount >= 0, "TokenmontMinter: exceeds number of admints remaining");
    require(amount > 0, "TokenmonMinter: must mint more than 0");
    require(_firstEvoTokenId < MAX_FIRST_EVO_SUPPLY, "TokenmonMinter: sale has ended");
    require(_firstEvoTokenId + amount <= MAX_FIRST_EVO_SUPPLY, "TokenmonMinter: exceeds max supply");

    for (uint i = 0; i < amount; i++) {
      _firstEvoTokenId = _firstEvoTokenId + 1;
      _mint(msg.sender, _firstEvoTokenId);
    }
    
    emit Mint(msg.sender, amount);

    if (offsetBlock == 0 && (totalSupply() == MAX_FIRST_EVO_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
        offsetBlock = block.number;
    }
  }

  function finalizeoffset() public {
    require(offset == 0, "TokenmonMinter: Starting index is already set");
    require(offsetBlock != 0, "TokenmonMinter: Starting index block must be set");
    
    offset = uint(blockhash(offsetBlock)) % MAX_FIRST_EVO_SUPPLY;
    if (block.number - offsetBlock > 255) {
        offset = uint(blockhash(block.number - 1)) % MAX_FIRST_EVO_SUPPLY;
    }

    if (offset == 0) {
        offset = 1;
    }
  }

  function toggleMinting() public onlyOwner {
    if (_firstEvoTokenId == 0) {
      REVEAL_TIMESTAMP = block.timestamp + 24 hours;
    }

    _isMintingActive = !_isMintingActive;
  }

  function setBaseURI(string memory baseUri) public onlyOwner {
    require(!_isBaseUriSet, "Base URI has already been set");

    _baseUri = baseUri;
    _isBaseUriSet = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseUri;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "TokenmonMinter: URI query for nonexistent token");

    if (tokenId > MAX_FIRST_EVO_SUPPLY) {
      return evolutionContract.tokenURI(tokenId);
    }

    string memory baseURI = _baseURI();
    if (offset == 0 || !_isBaseUriSet) {
      return baseURI;
    }

    uint256 index = ((tokenId + offset - 1) % MAX_FIRST_EVO_SUPPLY) + 1;
    return string(abi.encodePacked(baseURI, index.toString()));
  }
  
  function setEvolutionContractAddress(address _address) public onlyOwner {
    evolutionContract = IEvolutionContract(_address);
  }

  function evolve(uint256[3] memory _tokensToBurn) public payable {
    require(_isApprovedOrOwner(msg.sender, _tokensToBurn[0]) && _isApprovedOrOwner(msg.sender, _tokensToBurn[1]) && _isApprovedOrOwner(msg.sender, _tokensToBurn[2]), "TokenmonMinter: caller is not owner nor approved");
    require(evolutionContract.isEvolvingActive(), "TokenmonMinter: Evolving is not active right now");
    require(evolutionContract.isEvolutionValid(_tokensToBurn), "TokenmonMinter: Evolution is not valid");
    require(evolutionContract.getEvolutionPrice() == msg.value, "TokenmonMinter: must send correct ETH amount");
    
    _burn(_tokensToBurn[0]);
    _burn(_tokensToBurn[1]);
    _burn(_tokensToBurn[2]);
    
    _secondEvoTokenId + 1;
    _mint(msg.sender, _secondEvoTokenId);
    
    emit Evolve(msg.sender, _secondEvoTokenId, _tokensToBurn);
  }

  function withdraw(address _target) public onlyOwner {
    payable(_target).transfer(address(this).balance);
  }
}