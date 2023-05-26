// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

interface IReverseResolver {
  function claim (address owner) external returns (bytes32);
}

interface IERC20 {
  function balanceOf (address account) external view returns (uint256);
  function transfer (address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
  function safeTransferFrom (address from, address to, uint256 tokenId ) external;
}

interface IDocumentationRepository {
  function doc (address contractAddress) external view returns (string memory name, string memory description, string memory details);
}

error MissingRole(bytes32 role, address operator);

abstract contract OwnableBase {
  bytes32 public constant ADMIN_ROLE = 0x00;
  mapping(bytes32 => mapping(address => bool)) internal roles; // role => operator => hasRole
  mapping(bytes32 => uint256) internal validSignatures; // message hash => expiration block height
  IDocumentationRepository public DocumentationRepository;

  event RoleChange (bytes32 indexed role, address indexed account, bool indexed isGranted, address sender);

  constructor (address documentationAddress) {
    roles[ADMIN_ROLE][msg.sender] = true;
    DocumentationRepository = IDocumentationRepository(documentationAddress);
  }

  function doc () public view returns (string memory name, string memory description, string memory details) {
    return DocumentationRepository.doc(address(this));
  }

  /**
   * @dev See {ERC1271-isValidSignature}.
   */
  function isValidSignature(bytes32 hash, bytes memory)
    external
    view
    returns (bytes4 magicValue)
  {
    if (validSignatures[hash] >= block.number) {
      return 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    } else {
      return 0xffffffff;
    }
  }

  /**
   * @dev Inspect whether a specific address has a specific role.
   */
  function hasRole (bytes32 role, address account) public view returns (bool) {
    return roles[role][account];
  }

  /* Modifiers */

  modifier onlyRole (bytes32 role) {
    if (roles[role][msg.sender] != true) revert MissingRole(role, msg.sender);
    _;
  }

  /* Administration */

  /**
   * @dev Allow current administrators to be able to grant/revoke admin role to other addresses.
   */
  function setAdmin (address account, bool isAdmin) public onlyRole(ADMIN_ROLE) {
    roles[ADMIN_ROLE][account] = isAdmin;
    emit RoleChange(ADMIN_ROLE, account, isAdmin, msg.sender);
  }

  /**
   * @dev Claim ENS reverse-resolver rights for this contract.
   * https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
   */
  function setReverseResolver (address registrar) public onlyRole(ADMIN_ROLE) {
    IReverseResolver(registrar).claim(msg.sender);
  }

  /**
   * @dev Update address for on-chain documentation lookup.
   */
  function setDocumentationRepository (address documentationAddress) public onlyRole(ADMIN_ROLE) {
    DocumentationRepository = IDocumentationRepository(documentationAddress);
  }

  /**
   * @dev Set a message as valid, to be queried by ERC1271 clients.
   */
  function markMessageSigned (bytes32 hash, uint256 expirationLength) public onlyRole(ADMIN_ROLE) {
    validSignatures[hash] = block.number + expirationLength;
  }

  /**
   * @dev Rescue ERC20 assets sent directly to this contract.
   */
  function withdrawForeignERC20 (address tokenContract) public onlyRole(ADMIN_ROLE) {
    IERC20 token = IERC20(tokenContract);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  /**
   * @dev Rescue ERC721 assets sent directly to this contract.
   */
  function withdrawForeignERC721 (address tokenContract, uint256 tokenId)
    public
    virtual
    onlyRole(ADMIN_ROLE)
  {
    IERC721(tokenContract).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId
    );
  }

  function withdrawEth () public onlyRole(ADMIN_ROLE) {
    payable(msg.sender).transfer(address(this).balance);
  }

}