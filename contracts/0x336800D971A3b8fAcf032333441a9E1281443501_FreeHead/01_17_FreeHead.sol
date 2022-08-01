// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract FreeHead is ERC721ABurnable, ERC721AQueryable, Ownable{
  using Strings for uint256;

  bytes32 public merkleRoot;
  string public headLocation;
  string public hiddenMetadata;
  bool public isRevealed;
  bool public whitelistMintEnabled;
  bool public burnEnabled;
  bool public burnMintEnabled;

  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public burntHeadClaimed;

  uint256 public constant maxSupply = 6000;
  uint256 public constant maxMintAmountPerTx = 2;



  constructor(string memory _hiddenMetadata) ERC721A("HuemanHead", "HEADZ") {
    hiddenMetadata = _hiddenMetadata;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public mintCompliance(_mintAmount){
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function burnMint() public {
    require(burnMintEnabled, "This minting is not enabled");
    require(_numberBurned(_msgSender()) >= 15);
    require(!burntHeadClaimed[_msgSender()], "Address already claimed a burnt head.");

    burntHeadClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), 1);
  }
 
  function setHeadLocation(string memory _location) public onlyOwner {
    headLocation = _location;
  }

  function setPlaceHolderURI(string memory _URI) public onlyOwner {
    hiddenMetadata = _URI;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setBurnEnabled(bool _state) public onlyOwner {
    burnEnabled = _state;
  }


  function setRevealed(bool _state) public onlyOwner {
    isRevealed = _state;
  }

  function setBurnMintEnabled(bool _state) public onlyOwner {
    burnMintEnabled = _state;
  }




  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (isRevealed == false) {
      return hiddenMetadata;
    }

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return headLocation;
  }
   function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  
  function burn(uint256 tokenId) public virtual override {
    require(burnEnabled, "Burning is not enabled!");
    _burn(tokenId, true);
  }

  function burnedByAddress(address _user) public view returns(uint256){
        return _numberBurned(_user);
    }
}