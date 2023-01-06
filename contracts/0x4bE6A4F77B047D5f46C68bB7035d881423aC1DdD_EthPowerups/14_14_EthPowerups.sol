// SPDX-License-Identifier: MIT

/**
 *
 * ███████╗████████╗██╗  ██╗
 * ██╔════╝╚══██╔══╝██║  ██║
 * █████╗     ██║   ███████║
 * ██╔══╝     ██║   ██╔══██║
 * ███████╗   ██║   ██║  ██║
 * ╚══════╝   ╚═╝   ╚═╝  ╚═╝
 *
 * ███████╗ █████╗  █████╗ ████████╗ █████╗ ██████╗ ██╗   ██╗
 * ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗╚██╗ ██╔╝
 * █████╗  ███████║██║  ╚═╝   ██║   ██║  ██║██████╔╝ ╚████╔╝
 * ██╔══╝  ██╔══██║██║  ██╗   ██║   ██║  ██║██╔══██╗  ╚██╔╝
 * ██║     ██║  ██║╚█████╔╝   ██║   ╚█████╔╝██║  ██║   ██║
 * ╚═╝     ╚═╝  ╚═╝ ╚════╝    ╚═╝    ╚════╝ ╚═╝  ╚═╝   ╚═╝
 *
 */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IEthPowerups {
  function calcNftMultiplier(address _address) external view returns (uint);
}

interface IEthFactory {
  function getLastCreated(address _address) external view returns (uint);
}

contract EthPowerups is ERC721Enumerable, Ownable, IEthPowerups {
  using Strings for uint;

  constructor(string memory name, string memory symbol, string memory _baseTokenURI, address _factoryAddress) ERC721(name, symbol) {
    baseTokenURI = _baseTokenURI;
    IFactory = IEthFactory(_factoryAddress);
    factoryAddress = _factoryAddress;
  }

  /*|| === STATE VARIABLES === ||*/
  string public baseExtension = ".json";
  uint public cost = 0.1 ether;
  uint public maxSupply = 1000;
  uint public lastSupply = maxSupply;
  uint public maxMintAmount = 10;
  IEthFactory public IFactory;
  uint[1000] public remainingIds;
  uint[2] public nftTiers = [100, 300]; /// Tiers of NFTs, this should not change once NFTs are deployed
  uint[3] public nftMultiplier = [20, 15, 7]; /// Percent multipliers for each NFT tier
  uint public maxMultipliers = 2; /// How many NFTs can be applied to the multiplier at once
  bool public paused = true;
  string private baseTokenURI;
  address factoryAddress;

  /*|| === MAPPINGS === ||*/
  mapping(uint => address) public minters;
  mapping(uint => uint) private lastTransferred;

  /*|| === EXTERNAL FUNCTIONS === ||*/
  function setBaseURI(string memory baseURI) external onlyOwner {
    baseTokenURI = baseURI;
  }

  function setCost(uint _newCost) external onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint _newmaxMintAmount) external onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function pause(bool _state) external onlyOwner {
    paused = _state;
  }

  function setNftMultiplier(uint[3] memory _nftMultiplier) external onlyOwner {
    nftMultiplier = _nftMultiplier;
  }

  function setMaxMultipliers(uint _maxMultipliers) external onlyOwner {
    maxMultipliers = _maxMultipliers;
  }

  function mint(uint _mintAmount) external payable {
    // Checks
    require(!paused, "Minting has not started");
    require(_mintAmount > 0, "Minimum mint");
    require(_mintAmount <= maxMintAmount, "Maximum mint");
    require(lastSupply >= _mintAmount, "Max supply exceeded");
    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount, "Incorrect price");
    }
    for (uint i = 1; i <= _mintAmount; i++) {
      // Mint for caller
      lastTransferred[_randomMint(msg.sender)] = block.timestamp;
    }
    payable(factoryAddress).transfer(msg.value / 2);
  }

  /*|| === PUBLIC FUNCTIONS === ||*/
  function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
    lastTransferred[tokenId] = block.timestamp;
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(IERC721, ERC721) {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
    lastTransferred[tokenId] = block.timestamp;
    _safeTransfer(from, to, tokenId, data);
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
    require(success);
  }

  // Get Token List
  function getTokenIds(address _owner) public view returns (uint[] memory) {
    // Count owned Token
    uint ownerTokenCount = balanceOf(_owner);
    uint[] memory tokenIds = new uint[](ownerTokenCount);
    // Get ids of owned Token
    for (uint i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  // Return compiled Token URI
  function tokenURI(uint _id) public view virtual override returns (string memory) {
    require(_exists(_id), "RATS: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _id.toString(), baseExtension)) : "";
  }

  function getLastTransferred(uint id) public view returns (uint) {
    return lastTransferred[id];
  }

  function calcNftMultiplier(address _address) public view override returns (uint) {
    uint[] memory nfts = getTokenIds(_address);
    uint lastCreated = IFactory.getLastCreated(_address);
    uint multiplier;
    uint active;
    /// Calculate tier 1 nfts
    for (uint i = 0; i < nfts.length; i++) {
      if (active < 2) {
        if (nfts[i] <= nftTiers[0] && getLastTransferred(nfts[i]) < lastCreated) {
          multiplier += nftMultiplier[0];
          active++;
        }
      } else {
        return multiplier;
      }
    }
    /// Calculate tier 2 nfts
    for (uint i = 0; i < nfts.length; i++) {
      if (active < 2) {
        if (nfts[i] <= nftTiers[1] && getLastTransferred(nfts[i]) < lastCreated) {
          multiplier += nftMultiplier[1];
          active++;
        }
      } else {
        return multiplier;
      }
    }
    /// Calculate tier 3 nfts
    for (uint i = 0; i < nfts.length; i++) {
      if (active < 2 && getLastTransferred(nfts[i]) < lastCreated) {
        multiplier += nftMultiplier[2];
        active++;
      } else {
        return multiplier;
      }
    }

    return multiplier;
  }

  /*|| === INTERNAL FUNCTIONS === ||*/
  // Random mint
  function _randomMint(address _target) internal returns (uint) {
    // Get Random id to mint
    uint _index = _getRandom() % lastSupply;
    uint _realIndex = getValue(_index) + 1;
    // Reduce supply
    lastSupply--;
    // Replace used id by last
    remainingIds[_index] = getValue(lastSupply);
    // Mint
    _safeMint(_target, _realIndex);
    // Save Original minters
    minters[_realIndex] = msg.sender;
    return _realIndex;
  }

  // Get value from a remaining id node
  function getValue(uint _index) internal view returns (uint) {
    if (remainingIds[_index] != 0) return remainingIds[_index];
    else return _index;
  }

  // Create a random id for minting
  function _getRandom() internal view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, lastSupply)));
  }

  // URI Handling
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }
}