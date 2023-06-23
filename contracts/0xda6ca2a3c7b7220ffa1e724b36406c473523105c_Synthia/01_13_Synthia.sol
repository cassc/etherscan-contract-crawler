// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//                           ,,
//                        ,,@@@@%/,
//                      ,%@@@@@@@@@(
//                      @@@@@@@@@@@@*
//                    *(@@@@@@@@@@@@@*
//                    #@@@@@@@@@@@@@@@*,
//                  ,*@@@@@@@@@@@@@@@@@,
//                  *#@@@@@@@@@@@@@@@@@%
//                     ,@@@@@@@@@@@&(/
//                      @@(,@@@@@,(@@
//                  #&@@@@@@@,@/@@@@@@@@@##
//               /@@@@@#@@@@@@@@@@@@@@@@@@@%,
//              .&@@@@@@@@@@%@@@(@@@@@@@@(#@&
//               @@@@%(/&/@@@%@@@@@@@@@#*@&&&
//               %%%&&&@@@@@@@@@@@@@@@&& %%##
//              ,*,  %&&@@@@@@@@@@@@@&&   .,/
//              %&&&/  &@@@@@@@@@@@@@    %&%&#
//              &&&&    @@@@@@@@@@#@@    ,&&&&
//             %&&&&  ,*@@@@@@@@@@@#/,    &%&&(
//             ((##*,,,,,@@@@@@@@@(@,,,   (#((/
//            %#((/*&&&@@@@@@@@@@#@@@&(,,  *(((
//            &&&,&&&@,*@@@@@@@@@@@,,@@%,   (&&#
//           /,&&@@@@@@@@/@@@@@@@@*@@@@,,,,&%/@%
//       ,,&@@@@@@@@@@@/,((&@@@@@@@@@@,@@@@@@@@&&&&.
//   ,@*(@@@&@@&@@,@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@%
//  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
//  *@@@@@@@@@@@@@@@&@@@@%,,     *@@@@@@@@@@@@@@@@@@@(%
//
//  DRP x Pellar 2022
//  SYN_001 - Synthia Project

contract Synthia is Ownable, ERC721Enumerable {
  bool public revealed;
  bool public salesActive;
  uint16 public teamClaimed;

  uint16 public constant TEAM_SUPPLY = 27;
  uint16 public constant PUBLIC_SUPPLY = 333;
  uint16 public constant MAX_SUPPLY = 360;
  uint16 public constant MAX_PER_WALLET = 2;
  uint16 public totalClaimed;
  uint16 public boundary = 333;

  uint256 public constant MINT_PRICE = 0.2 ether;

  uint256 public foundersSalesStart = 1668207600;
  uint256 public foundersSalesEnd = 1668294000;
  uint256 public whitelistSalesStart = 1668466800;
  uint256 public publicSalesStart = 1668553200;

  address public verifier = 0x046c2c915d899D550471d0a7b4d0FaCF79Cde290;
  string public baseURI = "ipfs://QmdqX8gHvs6kZNvKSE3UprbFto2kUy8ZfNMe172oh6z3YZ/";
  string public preRevealURI = "ipfs://QmdijATCq4N45xCqCj3xwExJhtJagoBPg5HiXdzvNQERkf";

  mapping(uint16 => uint16) public randoms;
  mapping(uint16 => string) public uri;
  mapping(address => uint16) public nClaimed;

  constructor() ERC721("SYNTHIA", "SYNTHIA") {}

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Token doesn't exist");

    if (!revealed) {
      return preRevealURI;
    }

    if (bytes(uri[uint16(_tokenId)]).length > 0) {
      return uri[uint16(_tokenId)];
    }

    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
  }

  function eligibleClaim(
    uint16 _maxAmount,
    address _account,
    bytes memory _signature,
    uint16 _amount
  ) public view returns (bool) {
    bytes32 message = keccak256(abi.encodePacked("synthia-drp", _maxAmount, _account));
    return validSignature(message, _signature) && nClaimed[_account] + _amount <= _maxAmount;
  }

  // founders and WL the same
  function whitelistMint(
    uint16 _maxAmount,
    bytes calldata _signature,
    uint16 _amount
  ) external payable {
    require(tx.origin == msg.sender, "Not allowed");
    // whitelist eligiblity (founders + regular WL)
    require((block.timestamp >= whitelistSalesStart && block.timestamp < publicSalesStart) || (block.timestamp >= foundersSalesStart && block.timestamp <= foundersSalesEnd), "Sales inactive");
    require(totalClaimed + _amount <= PUBLIC_SUPPLY, "Exceed max");
    require(eligibleClaim(_maxAmount, msg.sender, _signature, _amount), "Ineligible");
    require(msg.value >= MINT_PRICE * _amount, "Insufficient ETH");

    for (uint16 i = 0; i < _amount; i++) {
      _mintRandomToken(msg.sender);
    }
    totalClaimed += _amount;
    nClaimed[msg.sender] += _amount;
  }

  function mint(uint16 _amount) external payable {
    require(tx.origin == msg.sender, "Not allowed");
    require(publicSalesStart <= block.timestamp, "Sales inactive");
    require(totalClaimed + _amount <= PUBLIC_SUPPLY, "Exceed max");
    require(nClaimed[msg.sender] + _amount <= MAX_PER_WALLET, "Already claimed max");
    require(msg.value >= MINT_PRICE * _amount, "Insufficient ETH");

    for (uint16 i = 0; i < _amount; i++) {
      _mintRandomToken(msg.sender);
    }
    totalClaimed += _amount;
    nClaimed[msg.sender] += _amount;
  }

  function teamClaim(uint16 _amount) external onlyOwner {
    require(teamClaimed + _amount <= MAX_SUPPLY - PUBLIC_SUPPLY, "Already claimed");
    // sequential for team claim tokens
    for (uint16 i = 0; i < _amount; i++) {
      _safeMint(msg.sender, PUBLIC_SUPPLY + teamClaimed + i);
    }
    teamClaimed += _amount;
  }

  function setWhitelistSalesStart(uint256 startTime) external onlyOwner {
    whitelistSalesStart = startTime;
  }

  // also wl end
  function setPublicSalesStart(uint256 startTime) external onlyOwner {
    publicSalesStart = startTime;
  }

  function setFoundersSalesPeriod(uint256 startTime, uint256 endTime) external onlyOwner {
    foundersSalesStart = startTime;
    foundersSalesEnd = endTime;
  }

  function toggleRevealState(bool _state) external onlyOwner {
    revealed = _state;
  }

  function setBaseURI(string calldata _uri) external onlyOwner {
    baseURI = _uri;
  }

  function setPreRevealURI(string calldata _uri) external onlyOwner {
    preRevealURI = _uri;
  }

  function setTokensURI(uint16[] calldata _tokenIds, string[] calldata _uris) external onlyOwner {
    require(_tokenIds.length == _uris.length, "Input mismatch");
    for (uint256 i; i < _tokenIds.length; i++) {
      uri[_tokenIds[i]] = _uris[i];
    }
  }

  function setVerifier(address _account) external onlyOwner {
    verifier = _account;
  }

  // withdraw
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /* Internal */
  function _mintRandomToken(address _to) internal {
    uint16 index = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _to, totalSupply(), address(this)))) % boundary) + 1; // 1 -> 88
    uint16 tokenId = randoms[index] > 0 ? randoms[index] - 1 : index - 1;
    randoms[index] = randoms[boundary] > 0 ? randoms[boundary] : boundary;
    boundary -= 1;
    _safeMint(_to, tokenId);
  }

  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  function validSignature(bytes32 _message, bytes memory _signature) public view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == verifier;
  }
}