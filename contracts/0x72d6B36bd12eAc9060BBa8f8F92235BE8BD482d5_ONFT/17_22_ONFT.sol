// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ONFT721.sol";

contract ONFT is ONFT721, Pausable, ReentrancyGuard {
  using Strings for uint256;

  uint256 public currentMintId;
  uint256 public maximumSupply;
  string public contractURI;
  address public feeCollectorAddress;
  mapping(uint256 => uint16) public chainId;

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role.");
    _;
  }

  /// @notice Constructor for the ONFT
  /// @param _name the name of the token
  /// @param _symbol the token symbol
  /// @param _baseTokenURI the base URI for computing the tokenURI
  /// @param _layerZeroEndpoint handles message transmission across chains
  /// @param _feeCollectorAddress the address fee collector
  /// @param _maxSupply of the the nft
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI,
    address _layerZeroEndpoint,
    address _feeCollectorAddress,
    uint256 _maxSupply
  ) ONFT721(_name, _symbol, _layerZeroEndpoint) {
    setBaseURI(_baseTokenURI);
    contractURI = _baseTokenURI;
    feeCollectorAddress = _feeCollectorAddress;
    currentMintId = 0;
    maximumSupply = _maxSupply;
  }

  function mint(address to) external onlyMinter {
    require(currentMintId < maximumSupply, "Max supply reached.");
    _mint(to, currentMintId++);
  }

  function mintHonorary(address to, uint256 tokenId) external onlyMinter {
    _mint(to, tokenId);
  }

  function _beforeSend(
    address,
    uint16,
    bytes memory,
    uint256 _tokenId
  ) internal override whenNotPaused {
    _burn(_tokenId);
  }

  function pauseSendTokens(bool pause) external onlyOwner {
    pause ? _pause() : _unpause();
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return string(abi.encodePacked(_baseURI(), tokenId.toString()));
  }

  function tokenChainId(uint256 tokenId) public view returns (uint16) {
    return chainId[tokenId];
  }

  function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
    feeCollectorAddress = _feeCollectorAddress;
  }

  function setContractURI(string memory _contractURI) public onlyOwner {
    contractURI = _contractURI;
  }

  function totalSupply() public view virtual returns (uint256) {
    return currentMintId;
  }

  function maxSupply() public view virtual returns (uint256) {
    return maximumSupply;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maximumSupply = _maxSupply;
  }

  function setChainId(uint256 _tokenId, uint16 _chainId) public onlyOwner {
    _setChainId(_tokenId, _chainId);
  }

  //tokenIds and chainIds must be in matching order
  function setChainIds(uint256[] memory _tokenIds, uint16[] memory _chainIds)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _setChainId(_tokenIds[i], _chainIds[i]);
    }
  }

  function _setChainId(uint256 _tokenId, uint16 _chainId) internal {
    chainId[_tokenId] = _chainId;
  }
}