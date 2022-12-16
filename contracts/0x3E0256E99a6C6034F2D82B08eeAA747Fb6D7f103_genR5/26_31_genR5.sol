//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RENRoyalties.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

import { GelatoRelayContext } from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";


contract genR5 is ERC721URIStorage, Ownable, EIP712, AccessControl
, RENRoyalties
, RevokableDefaultOperatorFilterer
, GelatoRelayContext
{

  uint256 constant MAX_SUPPLY = 1972;

  bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  string private constant SIGNING_DOMAIN = "genR5-mint-voucher";
  string private constant SIGNATURE_VERSION = "1";

  string private baseURI;
  string private _contractURI;

  uint256 private pendingWithdrawals;
  uint256 private minimumFundToKeep;

  bool private _gelatoActive;

  uint256 private maxByOwner;
  uint256 private totalMinted;

  constructor(
     uint256 bps
    )
    ERC721('genR5', 'genR5')
     RENRoyalties(bps)
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
      baseURI = "";
      _contractURI = "";
      _gelatoActive = true;
      maxByOwner = 1;
      totalMinted = 0;
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(WITHDRAWER_ROLE, _msgSender());
  }

  function setMaxByOwner(uint256 max) public onlyOwner {
      maxByOwner = max;
  }

  function setGelatoActive(bool active) public onlyOwner {
      _gelatoActive = active;
  }

  function setBaseURI(string memory _URI) public onlyOwner {
      baseURI = _URI;
  }

  function setContractURI(string memory _URI) public onlyOwner {
      _contractURI = _URI;
  }

  function contractURI() public view returns (string memory) {
        return _contractURI;
  }

  /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
  */
  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  //Setup Royalties
  function setupRoyalties(address addr, uint256 bps) public {
      require(msg.sender == owner(), "only owner can setupRoyalties");
      super.setRoyalties(addr, bps);
  }

  function mint(address to, uint256 tokenId, string memory _tokenURI) public
  {
      require(hasRole(MINTER_ROLE, msg.sender), "only minter can mint");
      require(totalMinted < MAX_SUPPLY, "MAX_SUPPLY reached");
      require(balanceOf(to) < maxByOwner, "maxByOwner reached");

      _mint(msg.sender, tokenId);
      _setTokenURI(tokenId, _tokenURI);
      totalMinted++;

      // transfer the token
      if (msg.sender != to)
          _transfer(msg.sender, to, tokenId);
  }

  /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
  struct NFTVoucher {
    /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
    uint256 tokenId;

    /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
    uint256 minPrice;

    /// @notice The metadata URI to associate with this token.
    string uri;

    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
  }


  /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
  /// @param redeemer The address of the account which will receive the NFT upon success.
  /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
  function redeem(address redeemer, NFTVoucher calldata voucher) public payable returns (uint256) {

    require(totalMinted < MAX_SUPPLY, "MAX_SUPPLY reached");
    require(balanceOf(redeemer) < maxByOwner, "maxByOwner reached");

    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher);

    // make sure that the signer is authorized to mint NFTs
    require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

    // first assign the token to the signer, to establish provenance on-chain
    _mint(signer, voucher.tokenId);
    _setTokenURI(voucher.tokenId, voucher.uri);
    totalMinted++;

    // transfer the token to the redeemer
    _transfer(signer, redeemer, voucher.tokenId);

    // record payment to withdrawal balance
    increasePendingWithdrawals(msg.value);

    return voucher.tokenId;
  }

  function redeemWithGelato(address redeemer, NFTVoucher calldata voucher) external payable onlyGelatoRelay returns (uint256) {
    require(_gelatoActive, "Gelato is not active");

    require(totalMinted < MAX_SUPPLY, "MAX_SUPPLY reached");
    require(balanceOf(redeemer) < maxByOwner, "maxByOwner reached");

    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher);

    // make sure that the signer is authorized to mint NFTs
    require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

    //Payment to gelato
    _transferRelayFee();

    _mint(signer, voucher.tokenId);
    _setTokenURI(voucher.tokenId, voucher.uri);
    _transfer(signer, redeemer, voucher.tokenId);
    totalMinted++;

    // record payment to withdrawal balance
    increasePendingWithdrawals(msg.value);

    return voucher.tokenId;
  }

  function increasePendingWithdrawals(uint256 val) internal {
    pendingWithdrawals += val;
  }

  function setMinimumFundToKeep(uint amount) public onlyOwner {
    minimumFundToKeep = amount;
  }

  //Default receive
  receive() external payable {
    //Check overflow
    require (pendingWithdrawals + msg.value > pendingWithdrawals, "too many ethers sent");
    pendingWithdrawals += msg.value;
  }

  /// @notice Transfers pending withdrawal balance to the caller. Reverts if the caller is not an authorized withdrawer.
  function withdraw(uint amount) public {
    require(hasRole(WITHDRAWER_ROLE, msg.sender), "Only authorized withdrawers can withdraw");
    require(amount <= pendingWithdrawals, "Too much amount to withdraw");
    if (msg.sender != owner())
      require(pendingWithdrawals - amount >= minimumFundToKeep, "Too much amount to withdraw to keep minimumFundToKeep");

    // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the withdrawer role are payable addresses.
    address payable receiver = payable(msg.sender);

    pendingWithdrawals -= amount;
    receiver.transfer(amount);
  }

  /// @notice Retuns the amount of Ether available to the caller to withdraw.
  function availableToWithdraw() public view returns (uint256) {
    //SIGNER-WITHDRAWERS-return pendingWithdrawals[msg.sender];
    return pendingWithdrawals;
  }

  /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher An NFTVoucher to hash.
  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
      voucher.tokenId,
      voucher.minPrice,
      keccak256(bytes(voucher.uri))
    )));
  }

  /// @notice Returns the chain id of the current blockchain.
  /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
  ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
        id := chainid()
    }
    return id;
  }

  /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
  /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
  /// @param voucher An NFTVoucher describing an unminted NFT.
  function _verify(NFTVoucher calldata voucher) internal view returns (address) {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721
  , RENRoyalties
  ) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId)
    || RENRoyalties.supportsInterface(interfaceId)
    ;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }

  function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
      return Ownable.owner();
  }
}