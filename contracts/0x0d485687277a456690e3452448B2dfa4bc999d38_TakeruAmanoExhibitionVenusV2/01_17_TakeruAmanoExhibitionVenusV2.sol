// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract TakeruAmanoExhibitionVenusV2 is 
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable, 
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable {
    
    using StringsUpgradeable for uint256;
    
    string internal tokenName;
    string internal tokenSymbol;
    uint256 public maxSupply;

    string public uriPrefix;
    string public uriSuffix;
    string internal royaltyURI; 

    uint96 internal royaltyFee;
    address royaltyAddress;
    
    bool public paused;

    struct RoyaltyInfo {
      address recipient;
      uint96 amount;
    }

    event Royalty(uint256 tokenId, address royaltyAddress, uint256 value);

    mapping(uint256 => RoyaltyInfo) internal _royalties;
   
    bytes32 internal constant ADMIN = keccak256("ADMIN");
    bytes32 internal constant MINTER = keccak256("MINTER");
    bytes32 internal constant PAUSE = keccak256("PAUSE");
    

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply
    ) initializer public {
        __ERC721_init(
            tokenName = _tokenName,
            tokenSymbol = _tokenSymbol
        );
        __ERC721Enumerable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(MINTER, msg.sender);
        _grantRole(PAUSE, msg.sender);
        maxSupply = _maxSupply;
    }

    function minter(address _to, uint256 tokenId) public {
    require(hasRole(MINTER, msg.sender), "Only admin and minter can use this function");
    require(!paused, "The contract is paused!");
    require(tokenId <= maxSupply, "cannot mint more than maxSupply");
    _safeMint(_to, tokenId);
  }

  function bulkMint(address[] memory _to, uint256[] memory _id) public {
    require(hasRole(ADMIN, msg.sender), "Only admin can use this function");
    require(!paused, "The contract is paused!");
    require(_to.length == _id.length, "Receivers and IDs are different length");
    for (uint256 i = 0; i < _to.length; i++) {
      _safeMint(_to[i], _id[i]);
    }
  }

  
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setUriPrefix(string memory _uriPrefix) public onlyRole(ADMIN) {
    uriPrefix = _uriPrefix;
    
  }

  function setUriSuffix(string memory _uriSuffix) public onlyRole(ADMIN) {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyRole(ADMIN) {
    paused = _state;
  }

  function withdraw() public nonReentrant onlyRole(ADMIN){
    require(hasRole(ADMIN, msg.sender), "Only admin can use this function");
    (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      override(ERC721EnumerableUpgradeable)
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
      returns (bool)
  {
      return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
  }

  function setURIRoyalty(string memory _uri)external onlyRole(ADMIN){
    royaltyURI = _uri;
  }

  function showURIRoyalty()public view returns(string memory){
      return royaltyURI;
  }

  // Royalty information

  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view returns(address receiver, uint256 _royaltyFee) {
    RoyaltyInfo memory royalties = _royalties[_tokenId];
    receiver = royalties.recipient;
    _royaltyFee = calculateRoyalties(_salePrice);
  }


  function changeRoyaltyFee(uint96 _royaltyFee) public onlyRole(ADMIN) {
    royaltyFee = _royaltyFee;
  }

  function setRoyaltyAddress(address _royaltyAddress) public onlyRole(ADMIN){
      royaltyAddress = _royaltyAddress;
  }


  function calculateRoyalties(uint256 _salePrice) view internal returns(uint256) {
    return (_salePrice / 10000) * royaltyFee;
  }

  function showRoyaltyInfo() external view returns(address, uint96) {
    return (royaltyAddress, royaltyFee);
  }


  function _setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 fee
  ) internal {
    fee = royaltyFee;
    require(fee <= 10000);
    require(receiver != address(0));
    _royalties[tokenId] = RoyaltyInfo(receiver, fee);
    emit Royalty(tokenId, receiver, uint256(fee));
  }
}