// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DefinitelyHumanzDeployer is ERC721AQueryable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "https://www.definitelyhumanz.com/nft/json/";
  string public uriSuffix = ".json";
  string public _contractURI = "https://www.definitelyhumanz.com/nft/contract.json";
  string public hiddenMetadataUri;
  
  uint256 public maxSupply = 2222;
  uint256 public phaseSupply = 2222;

  bool public paused = true;
  bool public revealed = false;

  uint256 public whitelistPhase = 0;

  uint256 public whitelistCost = 25000000000000000;
  uint256 public publicCost = 25000000000000000;

  uint256 public walletLimit = 10;
  
  mapping (address => uint256) public alreadyMinted;
  uint256 public mintCounter = 0;

  bytes32 public merkleRoot = 0xc4feb302f2dd251c4797793711385060835192664b85e3e0118a2c819c6f1eb3;
  
  constructor() ERC721A("Definitely Humanz", "DHZ") {
    _startTokenId();
    setHiddenMetadataUri("https://www.definitelyhumanz.com/nft/hiddenMeta.json");
    setContractURI("https://www.definitelyhumanz.com/nft/contract.json");
  }

  function _startTokenId()
        internal
        pure
        override
        returns(uint256)
    {
        return 1;
    }

// RUNS BEFORE ALL MINT FUNCTIONS
  modifier mintCompliance (uint256 _mintAmount) 
  {
    require(!paused, "Minting is PAUSED!");
    require(mintCounter + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(mintCounter + _mintAmount <= phaseSupply, "Phase supply exceeded!");
    require(alreadyMinted[msg.sender] + _mintAmount <= walletLimit, "Max Mints Per Wallet Reached!");
    _;
  }

// ---------------! SETTERS !------------------

  function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner
  {
    merkleRoot = newMerkleRoot;
  }

  function setWhitelistMintCost(uint256 _mintCost) external onlyOwner
  {
      whitelistCost = _mintCost;
  }

  function setPublicMintCost(uint256 _mintCost) external onlyOwner
  {
      publicCost = _mintCost;
  }

  function setRevealed(bool _state) public onlyOwner 
  {
    revealed = _state;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner 
  {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner 
  {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner 
  {
    uriSuffix = _uriSuffix;
  }

  function setContractURI(string memory newContractURI) public onlyOwner 
  {
    _contractURI = newContractURI;
  }

  function setPaused(bool _state) public onlyOwner 
  {
    paused = _state;
  }

  function setWhitelistPhase(uint256 _state) public onlyOwner 
  {
    whitelistPhase = _state;
  }

  function setWalletLimit(uint256 _state) public onlyOwner
  {
    walletLimit = _state;
  }

  function setPhaseLimit(uint256 _state) public onlyOwner
  {
    phaseSupply = _state;
  }

// ---------------! GETTERS !----------------------

  function getWhitelistState() public view returns (uint256)
  {
    return whitelistPhase;
  }

  function getPausedState() public view returns (bool)
  {
    return paused;
  }

  function getTotalSupply() public view returns (uint256)
  {
    return totalSupply();
  }

  function getAlreadyMinted(address a) public view returns (uint256)
  {
    return alreadyMinted[a];
  }

// ---------------! MINT FUNCTIONS !-------------------

  function whitelistMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) external mintCompliance(_mintAmount) payable
  {
    require(whitelistPhase == 0, "Whitelist Sale Not Active");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Not on the Whitelist");
    require(msg.value >= _mintAmount * whitelistCost, "Insufficient funds!");
    require(_mintAmount > 0, "Invalid mint amount!");

    alreadyMinted[msg.sender] += _mintAmount;
    mintCounter += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  function publicMint(uint256 _mintAmount, address receiver) external mintCompliance(_mintAmount) payable
  {
    require(whitelistPhase == 1, "Public Sale Not Active");
    require(msg.value >= _mintAmount * publicCost, "Insufficient funds!");
    require(_mintAmount > 0, "Invalid mint amount!");

    alreadyMinted[msg.sender] += _mintAmount;
    mintCounter += _mintAmount;
    _safeMint(receiver, _mintAmount);
  }

// AIRDROP TO MULTIPLE ADDRESSES
  function mintForAddressMultiple(address[] calldata addresses, uint256[] calldata amount) public onlyOwner
  {
    for (uint256 i; i < addresses.length; i++)
    {
      require(mintCounter + amount[i] <= maxSupply, "Max supply exceeded!");
      mintCounter += amount[i];
      _safeMint(addresses[i], amount[i]);
    }
  }

// STANDARD BURN FUNCTION
    function burn(uint256 tokenId) public virtual 
    {
      require(msg.sender == ownerOf(tokenId), "Caller is not the token owner");
      _burn(tokenId);
    }

    function burnMultiple(uint256[] calldata ids) public virtual
    {
      for (uint256 i; i < ids.length; i++)
      {
        require(msg.sender == ownerOf(ids[i]), "Caller is not the token owner");
        _burn(ids[i]);
      }
    }

// ---------------! BASELINE FUNCTIONS !---------------

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override (ERC721A, IERC721A)
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), uriSuffix))
        : "";
  }

  function contractURI() 
  public 
  view 
  returns (string memory) 
  {
        return bytes(_contractURI).length > 0
          ? string(abi.encodePacked(_contractURI))
          : "";
  }

  function withdraw(uint256 amount) public onlyOwner 
  {
    payable(msg.sender).transfer(amount);
  }

  function withdrawAll() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}