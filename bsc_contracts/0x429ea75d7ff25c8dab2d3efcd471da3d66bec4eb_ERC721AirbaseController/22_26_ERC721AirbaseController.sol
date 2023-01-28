// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AirERC721.sol";
import "../../Ownable.sol";
import "../../Certificate.sol";
import "../../Datastructures.sol";
import "./IERC721AirbaseController.sol";

contract ERC721AirbaseController is
  IERC721AirbaseController,
  Pausable,
  Ownable,
  Certificate,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  struct Token {
    bool active;
    address owner;
    address creator;
  }

  mapping(address => Token) public tokens;
  mapping(bytes32 => uint256) public windowClaimed;
  mapping(bytes32 => bool) public hasClaimed;

  mapping(address => address[]) private _userTokens;
  Counters.Counter private _totalTokens;

  constructor(address _owner, address _ca)
    Ownable(_owner)
    Certificate(_ca)
    ReentrancyGuard()
  {}

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function totalTokens() external view returns (uint256) {
    return _totalTokens.current();
  }

  function totalUserTokens(address user) external view returns (uint256) {
    return _userTokens[user].length;
  }

  function getTokenInfo(address token) external view returns (Token memory) {
    return tokens[token];
  }

  function create(
    address _creator,
    string memory _name,
    string memory _symbol,
    string memory _tokenBaseURI,
    address _owner,
    bool _transferable,
    Datastructures.CertificateInfo calldata certificate
  ) external override whenNotPaused returns (address contractAddr) {
    uint256 nonce = _useNonce(_creator);

    bytes32 salt = keccak256(abi.encode(_creator, nonce));

    bytes memory bytecode = abi.encodePacked(
      type(AirERC721).creationCode,
      abi.encode(
        _name,
        _symbol,
        _tokenBaseURI,
        _owner,
        address(this),
        _transferable
      )
    );

    assembly {
      contractAddr := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    _validateCreate(contractAddr, certificate);

    Token storage token = tokens[contractAddr];

    token.active = true;
    token.owner = _owner;
    token.creator = _creator;

    _userTokens[_creator].push(contractAddr);

    _totalTokens.increment();

    emit TokenCreated(
      address(this),
      _creator,
      contractAddr,
      _name,
      _symbol,
      _tokenBaseURI,
      _owner,
      _transferable
    );
  }

  function claim(
    address user,
    bytes32 claimId,
    address token,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external override whenNotPaused nonReentrant {
    require(!hasClaimed[claimId], "Already claimed");
    require(
      amount <= (windowLimit - windowClaimed[window]),
      "ERC1155ABC:insufficient-fund"
    );

    uint256 nonce = _useNonce(user);

    bytes memory encodedMessgae = abi.encode(
      address(this),
      user,
      claimId,
      token,
      amount,
      window,
      windowLimit,
      certificate.deadline,
      nonce
    );
    _validateCertificate(encodedMessgae, certificate);

    windowClaimed[window] = windowClaimed[window].add(amount);
    hasClaimed[claimId] = true;

    AirERC721(token).mintBatch(user, amount);
    emit Claim(claimId, user, token, amount);
  }

  function claimBatch(
    address user,
    bytes32[] calldata claimIds,
    address token,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external override whenNotPaused nonReentrant {
    require(
      amount <= (windowLimit - windowClaimed[window]),
      "ERC20:insufficient-fund"
    );

    for (uint256 i = 0; i < claimIds.length; i++) {
      require(!hasClaimed[claimIds[i]], "Already claimed");
      hasClaimed[claimIds[i]] = true;
    }

    uint256 nonce = _useNonce(user);

    bytes memory encodedMessgae = abi.encode(
      address(this),
      user,
      claimIds,
      token,
      amount,
      window,
      windowLimit,
      certificate.deadline,
      nonce
    );
    _validateCertificate(encodedMessgae, certificate);

    AirERC721(token).mintBatch(user, amount);
    windowClaimed[window] = windowClaimed[window].add(amount);

    emit ClaimBatch(user, token, claimIds, amount);
  }

  function updateCA(address ca) external override onlyOwner {
    emit UpdateCA(certificationAuthority, ca);
    certificationAuthority = ca;
  }

  function _validateCreate(
    address contractAddress,
    Datastructures.CertificateInfo calldata certificate
  ) internal view {
    bytes memory encodedMessgae = abi.encode(
      address(this),
      contractAddress,
      certificate.deadline
    );

    _validateCertificate(encodedMessgae, certificate);
  }
}