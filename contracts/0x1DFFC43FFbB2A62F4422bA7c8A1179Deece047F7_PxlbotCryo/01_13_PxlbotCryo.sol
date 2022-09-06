// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './Base64.sol';

contract PxlbotCryo is ERC721, Ownable, Pausable {
  using Base64 for *;
  using Strings for uint256;

  event Requested(address _contract, uint256 tokenId, uint256 requestId);
  event Fulfilled(address _contract, uint256 tokenId, uint256 requestId);

  mapping(address => mapping(uint256 => bool)) fulfilled;
  mapping(address => bool) public approved_contracts;
  mapping(uint256 => string) image_uris;
  address[] requests_contracts;
  uint256[] requests_tokens;
  uint256 public total_requests;
  uint256 public total_tokens;
  string baseURI;

  constructor() ERC721('PxlbotCryo', 'PXLBOTCRYO') {}

  function mint(address owner, string memory image_uri) public onlyOwner {
    total_tokens++;
    uint256 tokenId = total_tokens;
    _safeMint(owner, tokenId);
    image_uris[tokenId] = image_uri;
  }

  function burn(uint256 tokenId) public onlyOwner {
    delete image_uris[tokenId];
    _burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    string memory metadata = string(
      abi.encodePacked(
        '{"name": "Pxlbot Cryo #',
        tokenId.toString(),
        '", "description": "The robot uprising is smaller than you think.", ',
        '"image": "',
        _baseURI(),
        image_uris[tokenId],
        '"}'
      )
    );

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.base64(bytes(metadata))
        )
      );
  }

  function setBaseURI(string memory _base) external onlyOwner {
    baseURI = _base;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function request(address _contract, uint256 tokenId) external whenNotPaused {
    require(
      fulfilled[_contract][tokenId] == false,
      'This merge has already been generated.'
    );
    require(
      IERC721(_contract).ownerOf(tokenId) == _msgSender(),
      'Only token owner can call this function.'
    );
    require(
      approved_contracts[_contract] == true,
      'This contract is not approved'
    );
    requests_contracts.push(_contract);
    requests_tokens.push(tokenId);
    total_requests = requests_contracts.length;
    emit Requested(_contract, tokenId, requests_tokens.length - 1);
  }

  function getNextRequest()
    external
    view
    onlyOwner
    returns (address _contract, uint256 token_id)
  {
    require(total_requests > 0, 'No requests to process');
    return (requests_contracts[0], requests_tokens[0]);
  }

  function fulfill(uint256 request_id, string memory image_uri)
    external
    onlyOwner
  {
    require(request_id < requests_tokens.length, 'invalid request ID');
    uint256 tokenId = requests_tokens[request_id];
    address _contract = requests_contracts[request_id];
    mint(IERC721(_contract).ownerOf(tokenId), image_uri);
    //add to mapping
    fulfilled[requests_contracts[request_id]][
      requests_tokens[request_id]
    ] = true;
    //remove request from arrays
    requests_tokens[request_id] = requests_tokens[requests_tokens.length - 1];
    requests_tokens.pop();
    requests_contracts[request_id] = requests_contracts[
      requests_contracts.length - 1
    ];
    requests_contracts.pop();
    total_requests = requests_contracts.length;
    emit Fulfilled(_contract, tokenId, request_id);
  }

  function setApprovedContract(address _addr, bool approval)
    external
    onlyOwner
  {
    approved_contracts[_addr] = approval;
  }
}