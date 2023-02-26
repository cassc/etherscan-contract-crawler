// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AirERC721.sol";
import "../../Ownable.sol";
import "../../Core.sol";
import "../../Datastructures.sol";
import "./IERC721AirbaseController.sol";
import "../../AirAddress.sol";
import "../../Claimable.sol";

contract ERC721AirbaseController is
  IERC721AirbaseController,
  Core,
  Claimable,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  using AirAddress for address;

  mapping(address => Token) public tokens;
  string public baseURI;

  Counters.Counter private _totalTokens;

  constructor(
    address owner_,
    address _ca,
    string memory _baseURI
  ) Core(owner_, _ca) ReentrancyGuard() {
    baseURI = _baseURI;
  }

  function totalTokens() external view returns (uint256) {
    return _totalTokens.current();
  }

  function getTokenInfo(address token) external view returns (Token memory) {
    return tokens[token];
  }

  function addToken(
    address contractAddress,
    address owner_,
    address creator,
    bool _isExternal
  ) external onlyOwner {
    require(
      contractAddress != address(0),
      "ERC721ABC:invalid-contract-address"
    );

    Token storage token = tokens[contractAddress];

    token.active = true;
    token.owner = owner_;
    token.creator = creator;
    token.isExternal = _isExternal;

    _totalTokens.increment();
    emit AddToken(contractAddress, owner_, creator, _isExternal);
  }

  function create(
    address _creator,
    string memory name_,
    string memory symbol_,
    string memory tokenURI_,
    address owner_,
    bool _transferable,
    Datastructures.CertificateInfo calldata certificate
  ) external override whenNotPaused returns (address contractAddr) {
    uint256 nonce = _useNonce(_creator);

    bytes32 salt = keccak256(abi.encode(_creator, nonce));

    bytes memory bytecode = abi.encodePacked(
      type(AirERC721).creationCode,
      abi.encode(name_, symbol_, tokenURI_, address(this), _transferable)
    );

    assembly {
      contractAddr := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    _validateCreate(owner_, contractAddr, certificate);
    AirERC721 airToken = AirERC721(contractAddr);
    if (bytes(tokenURI_).length == 0) {
      airToken.setBaseURI(
        string(
          abi.encodePacked(baseURI, "0x", contractAddr.toAsciiString(), "/")
        )
      );
    }

    airToken.transferOwnership(owner_);

    Token storage token = tokens[contractAddr];

    token.active = true;
    token.owner = owner_;
    token.creator = _creator;

    _totalTokens.increment();

    emit TokenCreated(
      address(this),
      _creator,
      contractAddr,
      name_,
      symbol_,
      owner_,
      _transferable
    );
  }

  function claim(
    address user,
    bytes32 claimId,
    address tokenAddr,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external override whenNotPaused nonReentrant {
    Token storage token = tokens[tokenAddr];
    require(!token.isExternal, "ERC721ABC:use-claim-external");
    require(token.active, "ERC721ABC:inactive-token");

    _updateClaim(amount, window, windowLimit, claimId);

    uint256 nonce = _useNonce(user);

    bytes memory encodedMessage = abi.encode(
      user,
      claimId,
      tokenAddr,
      amount,
      window,
      windowLimit,
      certificate.deadline,
      nonce,
      _thisHash()
    );
    _validateCertificate(encodedMessage, certificate);

    AirERC721(tokenAddr).mintBatch(user, amount);
    emit Claim(claimId, user, tokenAddr, amount);
  }

  function claimBatch(
    address user,
    bytes32[] calldata claimIds,
    address tokenAddr,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external override whenNotPaused nonReentrant {
    Token storage token = tokens[tokenAddr];
    require(!token.isExternal, "ERC721ABC:use-claim-external-batch");
    require(token.active, "ERC721ABC:inactive-token");

    _updateBatchClaim(amount, window, windowLimit, claimIds);

    uint256 nonce = _useNonce(user);

    bytes memory encodedMessage = abi.encode(
      user,
      claimIds,
      tokenAddr,
      amount,
      window,
      windowLimit,
      certificate.deadline,
      nonce,
      _thisHash()
    );
    _validateCertificate(encodedMessage, certificate);

    AirERC721(tokenAddr).mintBatch(user, amount);

    emit ClaimBatch(user, tokenAddr, claimIds, amount);
  }

  function claimExternal(
    address user,
    bytes32 claimId,
    address tokenAddr,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external override whenNotPaused nonReentrant {
    Token storage token = tokens[tokenAddr];
    require(token.isExternal, "ERC721ABC:use-claim");
    require(token.active, "ERC721ABC:inactive-token");

    _updateClaim(amount, window, windowLimit, claimId);

    uint256 nonce = _useNonce(user);

    bytes memory encodedMessgae = abi.encode(
      user,
      claimId,
      tokenAddr,
      amount,
      window,
      windowLimit,
      certificate.deadline,
      nonce,
      _thisHash()
    );
    _validateCertificate(encodedMessgae, certificate);
    _mintExternalBatch(tokenAddr, user, amount);

    emit Claim(claimId, user, tokenAddr, amount);
  }

  function claimExternalBatch(
    address user,
    bytes32[] calldata claimIds,
    address tokenAddr,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external override whenNotPaused nonReentrant {
    Token storage token = tokens[tokenAddr];
    require(token.isExternal, "ERC721ABC:use-claim-batch");
    require(token.active, "ERC721ABC:inactive-token");

    _updateBatchClaim(amount, window, windowLimit, claimIds);

    uint256 nonce = _useNonce(user);

    bytes memory encodedMessgae = abi.encode(
      user,
      claimIds,
      tokenAddr,
      amount,
      window,
      windowLimit,
      certificate.deadline,
      nonce,
      _thisHash()
    );
    _validateCertificate(encodedMessgae, certificate);
   _mintExternalBatch(tokenAddr, user, amount);

    emit ClaimBatch(user, tokenAddr, claimIds, amount);
  }

  function updateBaseURI(string memory newURI) external override onlyOwner {
    emit UpdateBaseURI(baseURI, newURI);
    baseURI = newURI;
  }

  function _mintExternalBatch(
    address tokenAddr,
    address user,
    uint256 amount
  ) internal {
    for (uint256 i = 0; i < amount; i++) {
      AirERC721(tokenAddr).mint(user);
    }
  }

  function _validateCreate(
    address owner_,
    address contractAddress,
    Datastructures.CertificateInfo calldata certificate
  ) internal view {
    bytes memory encodedMessage = abi.encode(
      owner_,
      contractAddress,
      certificate.deadline,
      _thisHash()
    );

    _validateCertificate(encodedMessage, certificate);
  }
}