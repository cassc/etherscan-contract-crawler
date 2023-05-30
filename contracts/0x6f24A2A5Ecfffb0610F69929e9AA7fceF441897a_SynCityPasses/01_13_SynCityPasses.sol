// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: Francesco Sullo <[email protected]>
// Superpower Labs / Syn City
// Cryptography forked from Everdragons2(.com)'s code

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//import "hardhat/console.sol";

contract SynCityPasses is ERC721, Ownable {
  using Address for address;
  using ECDSA for bytes32;

  event ValidatorSet(address validator);
  event OperatorSet(address operator);
  event OperatorRevoked(address operator);
  event BaseURIUpdated();
  event BaseURIFrozen();

  uint256 public nextTokenId = 1;
  uint256 public maxTokenId = 888;
  uint256[] internal _remaining = [200, 200, 200, 200, 80];

  string private _baseTokenURI = "https://nft.syn.city/meta/SYNP/";
  bool public tokenURIHasBeenFrozen;

  using ECDSA for bytes32;
  using SafeMath for uint256;

  address public validator;
  mapping(address => bool) public operators;
  mapping(bytes32 => address) public usedCodes;

  modifier onlyOperator() {
    require(_msgSender() != address(0) && operators[_msgSender()], "forbidden");
    _;
  }

  address[] public team = [
    0x70f41fE744657DF9cC5BD317C58D3e7928e22E1B,
    0x16244cdFb0D364ac5c4B42Aa530497AA762E7bb3,
    0xe360cDb9B5348DB79CD630d0D1DE854b44638C64,
    0xE14615C5B0d4f262153343e1590f196DCd52164e,
    0x777eFBFd78D38Acd0753ef2eBe7cdA620C0f409a,
    0xca17b266C872aAa553d2fC2e13187EcE3e2Bc54a,
    0xE73B2AEB8A9f360FB16F7D8Df721B1b40076Aa5E,
    0x231540a54823De2EFC7631E40A5DD9dD2Ee965bc
  ];

  constructor(address _validator) ERC721("Syn City Genesis Passes", "SYNP") {
    setValidator(_validator);
    for (uint256 i = 0; i < team.length; i++) {
      _safeMint(team[i], nextTokenId++);
    }
  }

  function getRemaining(uint256 typeIndex) external view returns (uint256) {
    return _remaining[typeIndex];
  }

  function setValidator(address validator_) public onlyOwner {
    require(validator_ != address(0), "validator cannot be 0x0");
    validator = validator_;
    emit ValidatorSet(validator);
  }

  function setOperators(address[] memory _operators) public onlyOwner {
    for (uint256 j = 0; j < _operators.length; j++) {
      require(_operators[j] != address(0), "operator cannot be 0x0");
      operators[_operators[j]] = true;
      emit OperatorSet(_operators[j]);
    }
  }

  function revokeOperator(address operator_) external onlyOwner {
    delete operators[operator_];
    emit OperatorRevoked(operator_);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function updateBaseTokenURI(string memory uri) external onlyOwner {
    require(!tokenURIHasBeenFrozen, "token uri has been frozen");
    _baseTokenURI = uri;
    emit BaseURIUpdated();
  }

  function freezeBaseTokenURI() external onlyOwner {
    tokenURIHasBeenFrozen = true;
    emit BaseURIFrozen();
  }

  function contractURI() external view returns (string memory) {
    return _baseTokenURI;
  }

  function claimFreeToken(
    bytes32 authCode,
    uint256 typeIndex,
    bytes memory signature
  ) external {
    _mintToken(_msgSender(), authCode, typeIndex, signature);
  }

  function giveawayToken(
    address to,
    bytes32 authCode,
    bytes memory signature
  ) external onlyOperator {
    _mintToken(to, authCode, 4, signature);
  }

  function _mintToken(
    address to,
    bytes32 authCode,
    uint256 typeIndex,
    bytes memory signature
  ) internal {
    require(to != address(0), "invalid sender");
    require(usedCodes[authCode] == address(0), "authCode already used");
    require(balanceOf(to) == 0, "one pass per wallet");
    require(_remaining[typeIndex] > 0, "no more tokens for this season");
    require(_isSignedByValidator(encodeForSignature(to, authCode, typeIndex), signature), "invalid signature");
    require(nextTokenId <= maxTokenId, "distribution ended");
    usedCodes[authCode] = to;
    _remaining[typeIndex]--;
    _safeMint(to, nextTokenId++);
  }

  function _isSignedByValidator(bytes32 _hash, bytes memory _signature) private view returns (bool) {
    return validator != address(0) && validator == _hash.recover(_signature);
  }

  // this is called internally by _mintToken
  // and externally by the web3 app
  function encodeForSignature(
    address to,
    bytes32 authCode,
    uint256 typeIndex
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01", // EIP-191
          to,
          authCode,
          typeIndex
        )
      );
  }
}