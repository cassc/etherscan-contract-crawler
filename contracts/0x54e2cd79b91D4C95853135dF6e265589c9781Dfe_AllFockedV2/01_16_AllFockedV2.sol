// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Algoz.sol";

contract AllFockedV2 is ERC721A, Ownable, ReentrancyGuard,Algoz {
  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public publicSupply = 4000; // supply open to all
  uint256 public reservedSupply = 1111; // supply reserved
  uint256 public maxMintAmountPerAddress = 1;
  bool paused = true;
  bool public revealed = false;
  
  constructor(
    string memory _hiddenMetadataUri,
    address _token_verifier, bool _verify_enabled, uint _proof_ttl
  ) ERC721A("AllFockedV2", "AF2") Algoz(_token_verifier, _verify_enabled, _proof_ttl) {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }
  
  modifier mintCompliance(uint256 _mintAmount) {
    require(balanceOf(msg.sender) + _mintAmount <= maxMintAmountPerAddress, "Max Mint amount reached");
    require(totalSupply() + _mintAmount <= publicSupply, "Max supply exceeded!");
    _;
  }

  // free mint with bot spam protection , visit https://allfocked.xyz to mint one
  function freemint(uint256 _mintAmount, bytes32 expiry_token, bytes32 auth_token, bytes calldata signature_token) public  mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    validate_token(expiry_token, auth_token, signature_token);
    _safeMint(msg.sender, _mintAmount);
  }
  
  // Admin mint for - able to mint both reserved & unreserved supply
  function mintForAddress(address _receiver,uint256 _mintAmount) public onlyOwner {
    require(_receiver != address(0),"Invalid address");
    require(totalSupply() + _mintAmount <= maxSupply(), "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  // starting tokenid
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // get the tokenURI of the 
   function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
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
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
        : "";
  }

  // Punishment for undercutters , who list below floor price - their token will get burned
  function getFocked(uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "Token does not exist");
    _burn(tokenId);
  }

  // revealed state
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  
  // set reserved supply 
  function setReservedSupply(uint256 _resSupply) public onlyOwner {
    reservedSupply = _resSupply;
  }

  
  // setter function to set max number of supply open for minting by public
  function setPublicSupply(uint256 _publicSupply) public onlyOwner {
    publicSupply = _publicSupply;
  }

  // set max mint per address
  function setMaxMintPerAddress(uint256 _maxMintAmountPerAddress) public onlyOwner {
    maxMintAmountPerAddress = _maxMintAmountPerAddress;
  }

  // set hidden metadata uri
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  // set base uri
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  // set uri suffix
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  // set paused state
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  // withdraw the value
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os,"Failed to withdraw");
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function maxSupply() public view returns(uint256){
    return reservedSupply + publicSupply;
  }

  function setAlgozVerification(bool _state) public {
    verify_enabled = _state;
  }
}