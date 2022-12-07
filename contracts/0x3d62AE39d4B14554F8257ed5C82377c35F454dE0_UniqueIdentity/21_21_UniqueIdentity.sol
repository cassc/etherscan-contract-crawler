// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "../../external/ERC1155PresetPauserUpgradeable.sol";
import "../../interfaces/IUniqueIdentity.sol";

/**
 * @title UniqueIdentity
 * @notice UniqueIdentity is an ERC1155-compliant contract for representing
 * the identity verification status of addresses.
 * @author Goldfinch
 */

contract UniqueIdentity is ERC1155PresetPauserUpgradeable, IUniqueIdentity {
  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

  uint256 public constant ID_TYPE_0 = 0; // non-US individual
  uint256 public constant ID_TYPE_1 = 1; // US accredited individual
  uint256 public constant ID_TYPE_2 = 2; // US non accredited individual
  uint256 public constant ID_TYPE_3 = 3; // US entity
  uint256 public constant ID_TYPE_4 = 4; // non-US entity
  uint256 public constant ID_TYPE_5 = 5;
  uint256 public constant ID_TYPE_6 = 6;
  uint256 public constant ID_TYPE_7 = 7;
  uint256 public constant ID_TYPE_8 = 8;
  uint256 public constant ID_TYPE_9 = 9;
  uint256 public constant ID_TYPE_10 = 10;

  uint256 public constant MINT_COST_PER_TOKEN = 830000 gwei;

  /// @dev We include a nonce in every hashed message, and increment the nonce as part of a
  /// state-changing operation, so as to prevent replay attacks, i.e. the reuse of a signature.
  mapping(address => uint256) public nonces;
  mapping(uint256 => bool) public supportedUIDTypes;

  function initialize(address owner, string memory uri) public initializer {
    require(owner != address(0), "Owner address cannot be empty");

    __ERC1155PresetPauser_init(owner, uri);
    __UniqueIdentity_init(owner);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __UniqueIdentity_init(address owner) internal initializer {
    __UniqueIdentity_init_unchained(owner);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __UniqueIdentity_init_unchained(address owner) internal initializer {
    _setupRole(SIGNER_ROLE, owner);
    _setRoleAdmin(SIGNER_ROLE, OWNER_ROLE);
  }

  function setSupportedUIDTypes(uint256[] calldata ids, bool[] calldata values) public onlyAdmin {
    require(ids.length == values.length, "accounts and ids length mismatch");
    for (uint256 i = 0; i < ids.length; ++i) {
      supportedUIDTypes[ids[i]] = values[i];
    }
  }

  /**
   * @dev Gets the token name.
   * @return string representing the token name
   */
  function name() public pure returns (string memory) {
    return "Unique Identity";
  }

  /**
   * @dev Gets the token symbol.
   * @return string representing the token symbol
   */
  function symbol() public pure returns (string memory) {
    return "UID";
  }

  function mint(
    uint256 id,
    uint256 expiresAt,
    bytes calldata signature
  )
    public
    payable
    override
    onlySigner(_msgSender(), id, expiresAt, signature)
    incrementNonce(_msgSender())
  {
    _mintTo(_msgSender(), id);
  }

  function mintTo(
    address recipient,
    uint256 id,
    uint256 expiresAt,
    bytes calldata signature
  )
    public
    payable
    override
    onlySignerMintTo(recipient, id, expiresAt, signature)
    incrementNonce(_msgSender())
  {
    require(balanceOf(_msgSender(), id) == 0, "msgSender already owns UID");
    _mintTo(recipient, id);
  }

  function _mintTo(address mintToAddress, uint256 id) private {
    require(msg.value >= MINT_COST_PER_TOKEN, "Token mint requires 0.00083 ETH");
    require(supportedUIDTypes[id] == true, "Token id not supported");
    require(balanceOf(mintToAddress, id) == 0, "Balance before mint must be 0");

    _mint(mintToAddress, id, 1, "");
  }

  function burn(
    address account,
    uint256 id,
    uint256 expiresAt,
    bytes calldata signature
  ) public override onlySigner(account, id, expiresAt, signature) incrementNonce(account) {
    _burn(account, id, 1);

    uint256 accountBalance = balanceOf(account, id);
    require(accountBalance == 0, "Balance after burn must be 0");
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155PresetPauserUpgradeable) {
    require(
      (from == address(0) && to != address(0)) || (from != address(0) && to == address(0)),
      "Only mint or burn transfers are allowed"
    );
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  modifier onlySigner(
    address account,
    uint256 id,
    uint256 expiresAt,
    bytes calldata signature
  ) {
    require(block.timestamp < expiresAt, "Signature has expired");

    bytes32 hash = keccak256(
      abi.encodePacked(account, id, expiresAt, address(this), nonces[account], block.chainid)
    );
    bytes32 ethSignedMessage = ECDSAUpgradeable.toEthSignedMessageHash(hash);
    require(
      hasRole(SIGNER_ROLE, ECDSAUpgradeable.recover(ethSignedMessage, signature)),
      "Invalid signer"
    );
    _;
  }

  modifier onlySignerMintTo(
    address mintToAddress,
    uint256 id,
    uint256 expiresAt,
    bytes calldata signature
  ) {
    require(block.timestamp < expiresAt, "Signature has expired");

    bytes32 hash = keccak256(
      abi.encodePacked(
        _msgSender(),
        mintToAddress,
        id,
        expiresAt,
        address(this),
        nonces[_msgSender()],
        block.chainid
      )
    );

    bytes32 ethSignedMessage = ECDSAUpgradeable.toEthSignedMessageHash(hash);
    require(
      hasRole(SIGNER_ROLE, ECDSAUpgradeable.recover(ethSignedMessage, signature)),
      "Invalid signer"
    );
    _;
  }

  modifier incrementNonce(address account) {
    nonces[account] += 1;
    _;
  }
}