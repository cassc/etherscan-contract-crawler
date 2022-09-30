//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
//https://medium.com/@ItsCuzzo/using-merkle-trees-for-nft-whitelists-523b58ada3f9
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import './IPxlbot.sol';
import '../utils/Controllable.sol';
import '../utils/Payable.sol';

contract PxlbotCollectible is
  Pausable,
  ERC721AQueryable,
  Controllable,
  Payable
{
  using Strings for uint256;

  struct MintBatch {
    string name;
    uint256 price;
    uint16 max_tokens;
    uint8 faction_id;
    uint16 token_start;
  }

  mapping(uint8 => MintBatch) public batches;
  uint8 public current_batch = 0;
  uint256 public curr_token_price;
  uint16 public curr_batch_total;
  uint16 public curr_batch_max;
  string public curr_batch_name;
  uint8 public curr_batch_faction_id;
  //need to link tokens to batches for URI purposes
  mapping(uint8 => uint16) public faction_start;
  mapping(uint8 => uint16) public faction_end;
  //have to use this since we reveal in stages (batches)
  mapping(uint8 => string) batch_uris;
  mapping(uint8 => uint256) public batch_token_start;
  mapping(uint8 => uint256) public batch_token_end;

  //these will need to be reset by batch (if needed)
  mapping(uint8 => bool) public mint_list_enabled;
  mapping(uint8 => bytes32) merkle_roots;
  mapping(uint8 => uint8) public mint_list_limit;
  uint16 public limit_per_txn = 10;

  //how many tokens each addr has minted per batch (for mint list only)
  mapping(address => mapping(uint8 => uint256)) public mint_list_claimed;

  string[7] public factionNames = [
    'Terra',
    'Botborn',
    'Exterminators',
    'OVNI',
    'Veblen',
    'The BE',
    'The Uploaded'
  ];

  constructor() ERC721A('Pxlbots', 'PXLBOT') {
    faction_start[0] = uint16(_startTokenId());
    faction_end[0] = 3999;
    faction_start[1] = 4000;
    faction_end[1] = 6499;
    faction_start[2] = 6500;
    faction_end[2] = 7999;
    faction_start[3] = 8000;
    faction_end[3] = 8999;
    faction_start[4] = 900;
    faction_end[4] = 9499;
    faction_start[5] = 9500;
    faction_end[5] = 9999;

    batch_token_start[0] = uint16(_startTokenId());
    batch_token_end[0] = 1499;
    batch_token_start[1] = 1500;
    batch_token_end[1] = 3999;
    batch_token_start[2] = 4000;
    batch_token_end[2] = 6499;
    batch_token_start[3] = 6500;
    batch_token_end[3] = 7999;
    batch_token_start[4] = 8000;
    batch_token_end[4] = 8999;
    batch_token_start[5] = 9000;
    batch_token_end[5] = 9499;
    batch_token_start[6] = 9500;
    batch_token_end[6] = 9999;
  }

  function setBatch(
    uint8 index,
    string memory _name,
    uint256 _price,
    uint16 _token_start,
    uint16 _max_tokens,
    uint8 _faction_id
  ) external onlyController {
    MintBatch storage batch = batches[index];
    batch.name = _name;
    batch.price = _price;
    batch.max_tokens = _max_tokens;
    batch.faction_id = _faction_id;
    batch_token_start[index] = _token_start;
    //we subtract 1 since we started at 0
    batch_token_end[index] = _token_start + _max_tokens - 1;
  }

  function setBatchURI(uint8 batch_index, string memory _uri) external onlyController {
    batch_uris[batch_index] = _uri;
  }

  function setMerkleRoot(uint8 batch_id, bytes32 root) external onlyController {
    merkle_roots[batch_id] = root;
  }

  function setMintListLimit(uint8 batch_id, uint8 limit) external onlyController {
    mint_list_limit[batch_id] = limit;
  }

  function setLimitPerTxn(uint16 limit) external onlyController {
    limit_per_txn = limit;
  }

  function enableMintList(uint8 batch_id, bool _enabled) external onlyController {
    mint_list_enabled[batch_id] = _enabled;
  }

  function onMintList(uint8 batch_id, address addr, bytes32[] calldata proof) public view returns (bool) {
    return MerkleProof.verify(proof, merkle_roots[batch_id], keccak256((abi.encodePacked(addr))));
  }

  function setCurrentBatch(uint8 _index, bool reset) external onlyController {
    current_batch = _index;
    MintBatch storage batch = batches[current_batch];
    if (reset) {
      curr_batch_total = 0;
      curr_batch_max = batch.max_tokens;
      curr_token_price = batch.price;
      curr_batch_name = batch.name;
      curr_batch_faction_id = batch.faction_id;
    }
  }

  function mint(uint256 amount, address to) external payable whenNotPaused {
    require(
      curr_batch_max >= curr_batch_total + amount,
      'No more tokens allowed for this batch'
    );
    require(
      curr_token_price == 0 || msg.value >= curr_token_price,
      'Insufficient value sent'
    );
    require(!mint_list_enabled[current_batch], 'Unable to mint; please verify mint list status or try again later.');
    _mint(amount, to);
  }

  function mintFromList(bytes32[] calldata proof, uint256 amount, address to) external payable whenNotPaused {
    require(mint_list_enabled[current_batch], "Mint list disabled, please use normal mint function.");
    require(this.onMintList(current_batch, to, proof), 'Unable to mint; not on the mint list.');
    require(mint_list_claimed[to][current_batch] + amount <= mint_list_limit[current_batch], "Amount exceeds allowed tokens per wallet.");
    _mint(amount, to);
    mint_list_claimed[to][current_batch] += amount;
  }

  function _mint(uint256 amount, address to) internal {
    require(amount <= limit_per_txn, "Amount exceeds limit per transaction.");
    _safeMint(to, amount);
    curr_batch_total++;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 0;
  }

  /** ADMIN */

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
  {
    uint8 batch_index = 0;
    if (tokenId >= batch_token_start[1] && tokenId <= batch_token_end[1]) {
      batch_index = 1;
    }
    if (tokenId >= batch_token_start[2] && tokenId <= batch_token_end[2]) {
      batch_index = 2;
    }
    if (tokenId >= batch_token_start[3] && tokenId <= batch_token_end[3]) {
      batch_index = 3;
    }
    if (tokenId >= batch_token_start[4] && tokenId <= batch_token_end[4]) {
      batch_index = 4;
    }
    if (tokenId >= batch_token_start[5] && tokenId <= batch_token_end[5]) {
      batch_index = 5;
    }
    if (tokenId >= batch_token_start[6] && tokenId <= batch_token_end[6]) {
      batch_index = 6;
    }
    return
      string(abi.encodePacked(baseURI,batch_uris[batch_index],tokenId.toString()));
  }

  string baseURI;

  function setBaseURI(string memory _base) external onlyController {
    baseURI = _base;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // //todo: write test
  // function getFactionNames() external view returns (string[7] memory) {
  //   return factionNames;
  // }

  function factionForToken(uint256 tokenId) internal view returns (uint8) {
    if (tokenId >= faction_start[1] && tokenId < faction_end[1]) {
      return 1;
    }
    if (tokenId >= faction_start[2] && tokenId < faction_end[2]) {
      return 2;
    }
    if (tokenId >= faction_start[3] && tokenId < faction_end[3]) {
      return 3;
    }
    if (tokenId >= faction_start[4] && tokenId < faction_end[4]) {
      return 4;
    }
    if (tokenId >= faction_start[5] && tokenId < faction_end[5]) {
      return 5;
    }
    return 0;
  }

  // function setFactionStartEnd(uint8 faction_id, uint16 start, uint16 end) external onlyController {
  //   faction_start[faction_id] = start;
  //   faction_end[faction_id] = end;
  // }

  // function factionForId(uint256 tokenId) internal view returns (uint8) {
  //   return factions[tokenId];
  // }

  /** pausable */
  function pause() external onlyController {
    require(!paused(), 'Contract is already paused.');
    _pause();
  }
  function unpause() external onlyController {
    require(paused(), 'Contract is already unpaused.');
    _unpause();
  }
}