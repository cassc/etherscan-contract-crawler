// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ========== Imports ==========
import "./access/AdminControl.sol";
import "solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RemixDaoToken is ERC1155, Pausable, ReentrancyGuard, AdminControl, Ownable {
  using Strings for uint256;

  uint256 constant TOKEN_ID = 1;
  uint256 public constant MAX_SUPPLY = 50000;
  address public constant DAO_MULTISIG = 0xCa52757875aBDFc1DDed370828DFc2bE2d4D53c4;

  // ========== Mutable Variables ==========

  string public baseURI;

  uint256 public totalMinted;
  uint256 public totalBurned;

  bytes32 public merkleRoot;
  uint256 public currentDrop;
  mapping(address => mapping(uint256 => uint256)) public amountsMinted;

  // ========== Constructor ==========

  constructor() {
    _pause();

    grantRole(DEFAULT_ADMIN_ROLE, DAO_MULTISIG);
    grantRole(ADMIN_ROLE, DAO_MULTISIG);

    renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  // ========== Claiming ==========

  function claimTokens(address _account, uint256 _quantity, bytes32[] calldata _proof) public whenNotPaused nonReentrant {
    require(verify(leaf(_account, _quantity), _proof), "Not permitted");
    require(totalMinted + _quantity <= MAX_SUPPLY, "Not enough tokens remaining");
    require(amountsMinted[_account][currentDrop] == 0, "Already claimed");

    amountsMinted[_account][currentDrop] += _quantity;

    totalMinted += _quantity;

    _mint(_account, TOKEN_ID, _quantity, "");
  }

  // ========== Public Methods ==========

  function totalTokenSupply() public view returns (uint256) {
    return totalMinted - totalBurned;
  }

  function totalSupply(uint256 _id) public view returns (uint256) {
    if (_id != TOKEN_ID) {
      return 0;
    }
    return totalMinted - totalBurned;
  }

  // ========== Burnable ==========

  function burn(address _account, uint256 _quantity) public virtual {
    require(
      _account == _msgSender() || isApprovedForAll[_account][_msgSender()],
      "ERC1155: caller is not owner nor approved"
    );

    _burn(_account, TOKEN_ID, _quantity);

    totalBurned += _quantity;
  }

  // ========== Admin ==========

  function ownerMint(address _to, uint256 _quantity) public onlyAdmin {
    require(totalMinted + _quantity <= MAX_SUPPLY, "Not enough tokens remaining");

    totalMinted += _quantity;

    _mint(_to, TOKEN_ID, _quantity, "");
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyAdmin {
    require(_merkleRoot.length > 0, "_merkleRoot is empty");
    merkleRoot = _merkleRoot;
  }

  function setBaseURI(string memory _baseURI) public onlyAdmin {
    baseURI = _baseURI;
  }

  function incrementCurrentDrop() public onlyAdmin {
    _pause();
    currentDrop++;
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  function withdraw() public onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function withdrawTokens(IERC20 token) public onlyOwner {
    require(address(token) != address(0));
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  // ============ Overrides ========

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AdminControl) returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId ||
           interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
           interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
           interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
  }

  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId == TOKEN_ID, "URI requested for invalid token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
  }

  // ============ Helpers ========

  function leaf(address _account, uint256 _amount) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_account, _amount));
  }

  function verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
    return MerkleProof.verify(_proof, merkleRoot, _leaf);
  }

  receive() external payable virtual {}
}