// SPDX-License-Identifier: MIT
//
//                                               .-.    __
//                                              |   |  /\ \
//                                              |   |  \_\/      __        .-.
//     ___ ___ _    _      _  _ ___ _____       |___|        __ /\ \      /:::\
//    | _ \_ _| |  | |    | \| | __|_   _|      |:::|       / /\\_\/     /::::/
//    |  _/| || |__| |__  | .` | _|  | |        |:::|       \/_/        / `-:/
//    |_| |___|____|____| |_|\_|_|   |_|        ':::'__   _____ _____  /    /
//                                                  / /\ /     |:::::\ \   /
//                                                  \/_/ \     |:::::/  `"`
//                                                        `"""""""""`
//
// @creator:  Pill NFT  
// @author:   @roxaxis     twitter.com/roxaxis
// @author:   @batuhankok  twitter.com/batuhankok

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PillNFT is ERC721, Ownable {

  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;
  mapping (address => uint) pillCountOfPillians;

  bytes32 constant merkleRoot = 0xa81682d80bb19f95b0f54b6763d7a4f3cbe9964f7d37527abde729429d34180b;
  address public constant proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

  string public uriPrefix = "https://api.pillnft.com/m/";
  string public uriSuffix = "";
  
  uint256 constant cost = 0.088 ether;
  uint256 constant maxSupply = 10001;
  uint256 constant maxMintAmountPerTx = 11;
  uint256 constant maxMintAmountPerWallet = 11;

  bool public isWhitelistMintActive = false;
  bool public isPublicMintActive = false;

  constructor() ERC721("PillNFT", "PILL") {}

  modifier onlyOrigin () {
    require(msg.sender == tx.origin, "Chef cannot be fooled so easily!");
    _;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function takePill(uint256 _mintAmount) external payable mintCompliance(_mintAmount) onlyOrigin {
    require(isPublicMintActive, "Public mint is not active!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(pillCountOfPillians[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Exceeds mint amount per wallet!");
    
    pillCountOfPillians[msg.sender] += _mintAmount;

    _mintLoop(msg.sender, _mintAmount);
  }

  function takePillEarly(uint256 _mintAmount, bytes32[] calldata proof) external payable mintCompliance(_mintAmount) onlyOrigin {
    require(isWhitelistMintActive, "Whitelist mint is not active!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(pillCountOfPillians[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Exceeds mint amount per wallet!");
    require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not whitelisted!");

    pillCountOfPillians[msg.sender] += _mintAmount;

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function communityMint(uint256 _mintAmount) external onlyOwner {
    _mintLoop(msg.sender, _mintAmount);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Non-existent Pill token given!");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function pillsOfPillian(address _owner) external view returns(uint256[] memory ) {
      uint256 pillCount = balanceOf(_owner);
      if (pillCount == 0) {
          return new uint256[](0);
      } else {
          uint256[] memory result = new uint256[](pillCount);
          uint256 index = 0;
          for (uint256 tokenId = 1; tokenId <= supply.current(); tokenId++) {
              if (index == pillCount) break;
              if (ownerOf(tokenId) == _owner) {
                  result[index] = tokenId;
                  index++;
              }
          }
          return result;
      }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function totalSupply() external view returns (uint256) {
    return supply.current();
  }

  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) external onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setIsWhitelistMintActive(bool _state) external onlyOwner {
    isWhitelistMintActive = _state;
  }

  function setIsPublicMintActive(bool _state) external onlyOwner {
    isPublicMintActive = _state;
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);

    _withdraw(payable(0xC13109635A71D00A8701F1607105B3ca476dFE39), (balance * 80) / 1000);
    _withdraw(payable(0x2dC9f6De709bc0EF0dd503443c1c2c96D71141D0), (balance * 80) / 1000);
    _withdraw(payable(0x1CEB9f132Ba2d667031A99AeC7A0D6C4f0a2a430), (balance * 80) / 1000);
    _withdraw(payable(0x9cb9D3e9dD18c4f21C27857b3183c252555CD182), (balance * 80) / 1000);
    _withdraw(payable(0x4Bc5808d524B8B34E7F4f1B60c361362557BdC70), (balance * 80) / 1000);
    _withdraw(payable(0x4682B0B6f1E68487C6FEBBA11687e696638B4a0c), (balance * 40) / 1000);
    _withdraw(payable(0x503103Abc0441539c4e5b19A5AC50aF40E01aF1b), (balance * 40) / 1000);
    _withdraw(payable(0xf037F020777BF024a4Ea3b7529cf09519d4f7965), (balance * 30) / 1000);
    _withdraw(payable(0xEe85b397633338618f6a5d486FDE314898d22B28), (balance * 30) / 1000);
    _withdraw(payable(0x450B42fE4Bc9b779b04c37B82348a144b9D9e019), (balance * 20) / 1000);
    _withdraw(payable(0x88cEBA6B8a9053ca760193ab0E6460878cD43CED), (balance * 10) / 1000);
    _withdraw(payable(0x98E52E827d55726eE4660436D5C16F6cfadD5c11), (balance * 10) / 1000);
    _withdraw(payable(0xD5b31E583f975db893Ff39955087F1Db38C52870), (balance * 5) / 1000);
    _withdraw(payable(0x80c5cd94390d40C95a20a82613EC6F568b91919E), (balance * 30) / 1000);
    _withdraw(payable(0xDc48bb8985A4f81c87bC121346118D3460181bB0), (balance * 120) / 1000);
    _withdraw(payable(0xC2850cee70Aba6d3e65de89B12941d04842Ed860), (balance * 265) / 1000);
      
    _withdraw(owner(), address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }
}