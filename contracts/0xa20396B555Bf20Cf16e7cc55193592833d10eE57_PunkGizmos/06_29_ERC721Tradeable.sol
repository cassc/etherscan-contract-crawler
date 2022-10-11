// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";


import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
                                                                 
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Tradeable is ERC721Enumerable, ERC721Royalty, ContextMixin, NativeMetaTransaction, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  //Price is 0.0 ETH
  uint256 internal PRICE = 0;
  string public _contractURI;
  string internal _baseTokenURI;
  bool internal _isActive;
  string internal name_;
  string internal symbol_;
  uint256 internal MAX_FREE = 1;
  address proxyRegistryAddress;
  uint256 internal constant MAX_SUPPLY = 2000;
  uint256 internal constant MAX_PER_TX = 5;
  uint256 internal constant MAX_PER_WALLET = 10;
  mapping (string => bool) internal approvedAddresses;
  mapping (string => uint256) internal gizmoWeightsDict;
  bytes32 public merkleRoot = 0x90eae69f3e5f082fc54cf383ed75eb49fdb0b376d8422f6b0e593b1689037e22;
  Counters.Counter internal _nextTokenId;
     
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _nextTokenId.increment();
        _initializeEIP712(_name);
        name_ = _name;
        symbol_ = _symbol;
        gizmoWeightsDict['GizmoOne'] = 20000000000;
        gizmoWeightsDict['SnakeStatue'] = 1000000000;
        gizmoWeightsDict['Computer'] = 40000000000;
        gizmoWeightsDict['Skateboard'] = 20600000000;
        gizmoWeightsDict['Sneaker'] = 10000000000;
        gizmoWeightsDict['Ufo'] = 4900000000;
        gizmoWeightsDict['Cassete'] = 7000000000;
        gizmoWeightsDict['Phone'] = 16500000000;
        _setDefaultRoyalty(address(this), 750);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal override {
      _safeMint(to, tokenId, data);
    }

    function isWhitelisted(bytes32[] calldata _merkleProof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function updateMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
      merkleRoot = newMerkleRoot;
    }

    function updateRoyalties(address newAddress, uint96 bps) public onlyOwner {
      _setDefaultRoyalty(newAddress, bps);
    }

    event Received(address, uint);
    
    receive() external payable {
      emit Received(msg.sender, msg.value);
    }

    function name() public view virtual override(ERC721) returns (string memory) {
        return name_;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        //metadata
        string memory base = _baseTokenURI;
        return string.concat(
          string.concat(base, Strings.toString(id)),
          ".json");
    }

    function setFreePerWallet(uint256 amount) public onlyOwner {
      MAX_FREE = amount;
    }

    function setMintPriceInGWei(uint256 price) public onlyOwner {
      PRICE = price;
    }

    function symbol() public view virtual override(ERC721) returns (string memory) {
        return symbol_;
    }

    function mintPriceInWei() public view virtual returns (uint256) {
        return SafeMath.mul(PRICE, 1e9);
    }

    function maxFree() public view virtual returns (uint256) {
        return MAX_FREE;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721) {
      return super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
      return super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Royalty, ERC721Enumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
    }
    
}