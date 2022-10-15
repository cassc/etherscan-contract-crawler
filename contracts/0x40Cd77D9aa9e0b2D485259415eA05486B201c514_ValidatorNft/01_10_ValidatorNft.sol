// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721AQueryable.sol";
import "../interfaces/IAggregator.sol";

/** 
 * @title Validator Nft for Ethereum Network
 * @notice Each Validator Nft (vNFT) represents a validator node
 *         Apart from passive validator rewards, holders can leverage the liquidity of vNFT
 *         Integration of vNFT with other protocols is underway
 *         Holders of the nft also has full access to the underlying node & a exclusive dao (pfp coming)
 */
contract ValidatorNft is Ownable, ERC721AQueryable, ReentrancyGuard {
  address constant public OPENSEA_PROXY_ADDRESS = 0x1E0049783F008A0085193E00003D00cd54003c71;
  uint256 constant public MAX_SUPPLY = 6942069420;

  IAggregator private aggregator;
  mapping(bytes => bool) private validatorRecords;
  mapping(uint256 => address) private lastOwners;

  bytes[] public _validators;
  uint256[] public _gasHeights;
  uint256[] public _nodeCapital;
  uint256 public _activationDelay = 3600;

  bool private _isOpenSeaProxyActive = false;
  address private _aggregatorProxyAddress;

  event BaseURIChanged(string _before, string _after);
  event Transferred(address _to, uint256 _amount);
  event AggregatorChanged(address _before, address _after);
  event OpenSeaState(bool _isActive);

  modifier onlyAggregator() {
    require(_aggregatorProxyAddress == msg.sender, "Not allowed to mint/burn nft");
    _;
  }

  constructor() ERC721A("Validator Nft", "vNFT") {}

  /**
   * @notice Returns the aggregator's proxy address
   */
  function aggregatorProxyAddress() external view returns (address) {
    return _aggregatorProxyAddress;
  }

  /**
   * @notice Returns the validators that are active (may contain validator that are yet active on beacon chain)
   */
  function activeValidators() external view returns (bytes[] memory) {
    uint256 total = _nextTokenId();
    uint256 tokenIdsIdx;
    bytes[] memory validators = new bytes[](total);
    TokenOwnership memory ownership;

    for (uint256 i = _startTokenId(); i < total; ++i) {
        ownership = _ownershipAt(i);
        if (ownership.burned) { 
          continue;
        }

        validators[tokenIdsIdx++] = _validators[i];
    }

    return validators;
  }

  /**
   * @notice Checks if a validator exists
   * @param pubkey - A 48 bytes representing the validator's public key
   */
  function validatorExists(bytes calldata pubkey) external view returns (bool) {
    return validatorRecords[pubkey];
  }

  /**
   * @notice Finds the validator's public key of a nft
   * @param tokenId - tokenId of the validator nft
   */
  function validatorOf(uint256 tokenId) external view returns (bytes memory) {
    return _validators[tokenId];
  }

  /**
   * @notice Finds all the validator's public key of a particular address
   * @param owner - The particular address
   */
  function validatorsOfOwner(address owner) external view returns (bytes[] memory) {
    unchecked {
      //slither-disable-next-line uninitialized-local
      uint256 tokenIdsIdx;
      //slither-disable-next-line uninitialized-local
      address currOwnershipAddr;
      uint256 tokenIdsLength = balanceOf(owner);
      bytes[] memory tokenIds = new bytes[](tokenIdsLength);
      TokenOwnership memory ownership;
      for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
          ownership = _ownershipAt(i);
          if (ownership.burned) {
              continue;
          }
          if (ownership.addr != address(0)) {
              currOwnershipAddr = ownership.addr;
          }
          if (currOwnershipAddr == owner) {
              tokenIds[tokenIdsIdx++] = _validators[i];
          }
      }
      return tokenIds;
    }
  }

  /**
   * @notice Finds the tokenId of a validator
   * @dev Returns MAX_SUPPLY if not found
   * @param pubkey - A 48 bytes representing the validator's public key
   */
  function tokenOfValidator(bytes calldata pubkey) external view returns (uint256) {
    for (uint256 i = 0; i < _validators.length; i++) {
      if (keccak256(_validators[i]) == keccak256(pubkey) && _exists(i)) {
        return i;
      }
    }
    return MAX_SUPPLY;
  }

  /**
   * @notice Returns the gas height of the tokenId
   * @param tokenId - tokenId of the validator nft
   */
  function gasHeightOf(uint256 tokenId) external view returns (uint256) {
    require(_exists(tokenId), "Token does not exist");

    return _gasHeights[tokenId];
  }

  /**
   * @notice Returns the last owner before the nft is burned
   * @param tokenId - tokenId of the validator nft
   */
  function lastOwnerOf(uint256 tokenId) external view returns (address) {
    require(_ownershipAt(tokenId).burned, "Token not burned yet");
    
    return lastOwners[tokenId];
  }

  /**
   * @notice Mints a Validator nft (vNFT)
   * @param pubkey -  A 48 bytes representing the validator's public key
   * @param _to - The recipient of the nft
   */
  function whiteListMint(bytes calldata pubkey, address _to) external onlyAggregator {
    require(
      totalSupply() + 1 <= MAX_SUPPLY,
      "not enough remaining reserved for auction to support desired mint amount"
    );
    require(!validatorRecords[pubkey], "Pub key already in used");

    validatorRecords[pubkey] = true;
    _validators.push(pubkey);
    _gasHeights.push(block.number + _activationDelay);
    _nodeCapital.push(32 ether);
    _safeMint(_to, 1);
  }

  /**
   * @notice Burns a Validator nft (vNFT)
   * @param tokenId - tokenId of the validator nft
   */
  function whiteListBurn(uint256 tokenId) external onlyAggregator {
    lastOwners[tokenId] = ownerOf(tokenId);
    _nodeCapital[tokenId] = 0;
    _burn(tokenId);
  }

  /**
   * @notice Updates the capital value of a node as the node accrue validator rewards
   * @param tokenId - tokenId of the validator nft
   * @param value - The new cpaital value
   */
  function updateNodeCapital(uint256 tokenId, uint256 value) external onlyAggregator {
    if (value > _nodeCapital[tokenId]) {
        _nodeCapital[tokenId] = value;
    }
  }

  /**
   * @notice Returns the node capital value of a validator nft
   * @param tokenId - tokenId of the validator nft
   */
  function nodeCapitalOf(uint256 tokenId)  external view returns (uint256) {
    require(_exists(tokenId), "Token does not exist");

    return _nodeCapital[tokenId];
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    emit BaseURIChanged(_baseTokenURI, baseURI);
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external nonReentrant onlyOwner {
    emit Transferred(owner(), address(this).balance);
    payable(owner()).transfer(address(this).balance);
  }

  function setAggregator(address aggregatorProxyAddress_) external onlyOwner {
    require(aggregatorProxyAddress_ != address(0), "Aggregator address provided invalid");
    emit AggregatorChanged(_aggregatorProxyAddress, aggregatorProxyAddress_);
    _aggregatorProxyAddress = aggregatorProxyAddress_;
    aggregator = IAggregator(_aggregatorProxyAddress);
  }

  function setGasHeight(uint256 tokenId, uint256 value) external onlyAggregator {
    if (value > _gasHeights[tokenId]) {
      _gasHeights[tokenId] = value;
    }
  }

  function setActivationDelay(uint256 delay) external onlyOwner {
    _activationDelay = delay;
  }

  function numberMinted(address owner) external view returns (uint256) {
    return _numberMinted(owner);
  }

  function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override 
  {
    // no need to claim reward if user is minting nft
    if (from == address(0) || from == to) {
      return;
    }

    for (uint256 i = 0; i < quantity; i++) {
      aggregator.disperseRewards(startTokenId + i);
    }
  }

  ////////below is the new code//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  function isApprovedForAll(address owner, address operator)
      public
      view
      override
      returns (bool)
  {
      // Get a reference to OpenSea's proxy registry contract by instantiating
      // the contract using the already existing address.

      if (
          _isOpenSeaProxyActive &&
          OPENSEA_PROXY_ADDRESS == operator
      ) {
          return true;
      }
      if (operator == _aggregatorProxyAddress) {
          return true;
      }

      return super.isApprovedForAll(owner, operator);
  }

  // function to disable gasless listings for security in case
  // opensea ever shuts down or is compromised
  function setIsOpenSeaProxyActive(bool isOpenSeaProxyActive_)
      external
      onlyOwner
  {
    emit OpenSeaState(isOpenSeaProxyActive_);
    _isOpenSeaProxyActive = isOpenSeaProxyActive_;
  }
}