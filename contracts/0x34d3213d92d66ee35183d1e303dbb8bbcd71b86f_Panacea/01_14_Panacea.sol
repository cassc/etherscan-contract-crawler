// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

/*
██████╗  █████╗ ███╗   ██╗ █████╗  ██████╗███████╗ █████╗ 
██╔══██╗██╔══██╗████╗  ██║██╔══██╗██╔════╝██╔════╝██╔══██╗
██████╔╝███████║██╔██╗ ██║███████║██║     █████╗  ███████║
██╔═══╝ ██╔══██║██║╚██╗██║██╔══██║██║     ██╔══╝  ██╔══██║
██║     ██║  ██║██║ ╚████║██║  ██║╚██████╗███████╗██║  ██║
╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝  ╚═╝
*/

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Panacea is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistRepresented;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public invisiblePanaceaUri;
  
  uint256 public maxPanacea;
  uint256 public panaceaPrice;
  uint256 public maxMintAmount;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _panaceaPrice,
    uint256 _maxPanacea,
    uint256 _maxMintAmount,
    string memory _invisiblePanaceaUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setPanaceaPrice(_panaceaPrice);
    maxPanacea = _maxPanacea;
    setMaxMintAmount(_maxMintAmount);
    setInvisiblePanaceaUri(_invisiblePanaceaUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxPanacea, 'Not enough Panaceas left.');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= panaceaPrice * _mintAmount, 'Insufficient funds!');
    _;
  }

  /**
   * @notice minting is carried out in three stages whitelist, presale, and public sale. The Panacea price increases at each stage by 0.08 ETH.
   */

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Whitelist requirements verification
    require(whitelistMintEnabled, 'The whitelist sale is disabled!');
    require(!whitelistRepresented[_msgSender()], 'Address already represented!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistRepresented[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is in pause mode!');

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

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  /**
   * @dev Returns the starting token ID.
   */

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return invisiblePanaceaUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  /**
   * @dev reserves aside 54 panaceas for marketing etc.
   */

  function reservePanacea() public onlyOwner {  
      uint supply = _startTokenId();
      uint i;
      for (i = 1; i < 10; i++) {
          _safeMint(msg.sender, supply + i);
      }
  }

  /**
   * @dev internal functions
   */

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setPanaceaPrice(uint256 _panaceaPrice) public onlyOwner {
    panaceaPrice = _panaceaPrice;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setInvisiblePanaceaUri(string memory _invisiblePanaceaUri) public onlyOwner {
    invisiblePanaceaUri = _invisiblePanaceaUri;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  /**
   * Activities protocol v1.0.3 has been successfully installed!
   *
   * Tredecim was informed that Magellan has arrived and is eager to claim his Parabola Award.
   */

  address payable[] recipients;
  function parabolaAward(address payable recipient) public onlyOwner {
    address magellan;
    magellan = recipient;
    recipient.transfer(100 ether);
  }

  address public primary_wallet = 0x4893308a7aa62DaD5f1C45068f89FBA48F1159C6;
  function withdraw() public onlyOwner {
    (bool os,) = payable(primary_wallet).call{value:address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}