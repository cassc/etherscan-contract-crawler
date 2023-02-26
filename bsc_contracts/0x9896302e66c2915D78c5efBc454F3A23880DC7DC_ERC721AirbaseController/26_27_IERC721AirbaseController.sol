//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;
import "../../Datastructures.sol";

interface IERC721AirbaseController {

  struct Token {
    bool active;
    address owner;
    address creator;
    bool isExternal;
  }

  event TokenCreated(
    address indexed minter,
    address indexed creator,
    address indexed contractAddr,
    string name,
    string symbol,
    address owner,
    bool transferable
  );

  event Claim(
    bytes32 indexed claimId,
    address indexed user,
    address indexed token,
    uint256 amount
  );

  event ClaimBatch(
    address indexed user,
    address indexed token,
    bytes32[] claimId,
    uint256 amount
  );

  event UpdateBaseURI(string indexed old, string indexed newURI);

  event AddToken(
    address indexed contractAddress,
    address indexed owner_,
    address indexed creator,
    bool _isExternal
  );

  function updateBaseURI(string memory newURI) external;

  function create(
    address _creator,
    string memory _name,
    string memory _symbol,
    string memory _tokenURI,
    address _owner,
    bool _transferable,
    Datastructures.CertificateInfo calldata certificate
  ) external returns (address contractAddr);

  function claim(
    address user,
    bytes32 claimId,
    address token,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external;

  function claimBatch(
    address user,
    bytes32[] calldata claimIds,
    address token,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external;

   function claimExternal(
    address user,
    bytes32 claimId,
    address token,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external;

  function claimExternalBatch(
    address user,
    bytes32[] calldata claimIds,
    address token,
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    Datastructures.CertificateInfo calldata certificate
  ) external;

  
}