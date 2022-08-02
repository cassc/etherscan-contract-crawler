/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol';

/// @custom:security-contact [email protected]
contract Sedition is Initializable, ERC721Upgradeable, AccessControlUpgradeable, EIP712Upgradeable {
  // It is still ok to define constant state variables in upgradeable contracts,
  // because the compiler does not reserve a storage slot for these variables
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant WITHDRAWER_ROLE = keccak256('WITHDRAWER_ROLE');

  // Mapping minter address to available ether to withdraw from contract
  mapping(address => uint256) private _withdrawableBalances;

  struct NFTVoucher {
    /// @notice The id of the token to be redeemed. Must be unique.
    uint256 tokenId;
    /// @notice The minimum price (in wei) required to be paid for this vaucher to be redeemed.
    uint256 minPrice;
    address redeemer;
    address issuer;
    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct.
    /// For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    /// @notice To prevent the implementation contract from being used, you should invoke the _disableInitializers function in the constructor to automatically lock it when it is deployed.
    /// Basically prevents initializing contract not via proxy since via proxy constructor is never run.
    _disableInitializers();
  }

  // Runs only once, after proxy is deployed it runs the initialize() by default.
  // Has to call parent initializers manually.
  function initialize() initializer public {
    __ERC721_init('Sedition', 'ART');
    __AccessControl_init();
    __EIP712_init('seditionart.com', '1');
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /// @notice Returns string that will be prepended to return of `tokenURI(tokenId)`
  function _baseURI() override internal pure virtual returns (string memory) {
    return "https://www.seditionart.com/nfts/";
  }

  /// @notice Returns string that will provide metadata for OpenSea
  function contractURI() public pure virtual returns (string memory) {
    return "https://www.seditionart.com/api/public/contracts/1";
  }

  /// @notice Transfers available withdrawable balance in the given account to the caller. Caller must have WITHDRAWER_ROLE.
  function withdrawFrom(address from) external virtual {
    require(
      hasRole(WITHDRAWER_ROLE, _msgSender()),
      'Sender is not a withdrawer'
    );

    // [CAUTION] casting msg.sender to a payable address is only safe
    // if ALL members of the minter role are payable addresses.
    address payable receiver = payable(_msgSender());

    uint256 amount = _withdrawableBalances[from];
    // zero account before transfer to prevent re-entrancy attack
    _withdrawableBalances[from] = 0;

    receiver.transfer(amount);
  }

  /// @notice Retuns the amount of Ether available to the caller to withdraw.
  function availableToWithdraw() external virtual view returns (uint256) {
    return _withdrawableBalances[_msgSender()];
  }

  /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
  /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
  function redeem(NFTVoucher calldata voucher)
    external
    payable
    returns (uint256)
  {
    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher);

    // make sure that the signer is authorized to mint NFTs
    require(hasRole(MINTER_ROLE, signer), 'Signature invalid');

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(msg.value >= voucher.minPrice, 'Insufficient funds to redeem');

    // make sure that the voucher redeemer matches sender
    require(_msgSender() == voucher.redeemer, 'Sender is not the redeemer');

    // first assign the token to the signer, to establish provenance on-chain
    _safeMint(voucher.issuer, voucher.tokenId);

    // transfer the token to the redeemer
    _transfer(voucher.issuer, voucher.redeemer, voucher.tokenId);

    // record payment to signer's withdrawal balance
    _withdrawableBalances[signer] += msg.value;

    return voucher.tokenId;
  }

  /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  /// @param voucher An NFTVoucher to hash.
  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256('NFTVoucher(uint256 tokenId,uint256 minPrice,address redeemer,address issuer)'),
            voucher.tokenId,
            voucher.minPrice,
            voucher.redeemer,
            voucher.issuer
          )
        )
      );
  }

  /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
  /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
  /// @param voucher An NFTVoucher describing an unminted NFT.
  function _verify(NFTVoucher calldata voucher)
    internal
    view
    returns (address)
  {
    bytes32 digest = _hash(voucher);
    return ECDSAUpgradeable.recover(digest, voucher.signature);
  }

  /// @notice Returns true if interface is supported by contract
  /// @param interfaceId hashed interface factory signature
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlUpgradeable, ERC721Upgradeable)
    returns (bool)
  {
    return
      ERC721Upgradeable.supportsInterface(interfaceId) ||
      AccessControlUpgradeable.supportsInterface(interfaceId);
  }

  /// @notice OpenSea identifies contract owner via owner() call
  /// usually this is implemented with Ownable interface, however
  /// we already use AccessControl so we don't need two.
  /// Hardcoding the account since it has minimal access, if the account
  /// gets lost it is still possible to approach OpenSea and ask to change
  /// the admin.
  function owner() external view virtual returns (address) {
    return 0x36274414d89B38d0292fb54E8767AF79f29FE00B;
  }
}