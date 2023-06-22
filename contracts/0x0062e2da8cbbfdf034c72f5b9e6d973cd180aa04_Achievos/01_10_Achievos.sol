// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import 'erc721a/contracts/ERC721A.sol';

abstract contract Ownable is Context {
    address private _owner;

    constructor() {
        _owner = _msgSender();
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract Achievos is ERC721A, Ownable {
  using Strings for uint256;

  uint256 public constant MAXSUPPLY = 10000;
  string public constant URISUFFIX = '.json';  

  string public uriPrefix = 'ipfs://QmXHJDdowxsTiCw3yziJ584N391u7iEUNqyZejP5Ty9nbb/'; 

  uint256 public cost = 20_000_000_000_000_000; // 0.02 ETH;  
  bool public paused = true;

  constructor() ERC721A("Achievos", "ACHVS") {
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= MAXSUPPLY, 'Max supply exceeded!');
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAXSUPPLY) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];
      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }
      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), URISUFFIX)) : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }  
}