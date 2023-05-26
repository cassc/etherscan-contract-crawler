// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libraries/EIP712.sol";
import "./interfaces/IYAYOMintable.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CannotMintExpiredSignature ();
error CannotMintInvalidSignature ();
error MintArrayLengthMismatch ();
error SignerCannotBeZero ();

/**
  @custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
  @title A contract which accepts signatures from a trusted signer to mint an
    ERC-721 item.
  @author Tim Clancy <tim-clancy.eth>
  @author cheb <evmcheb.eth>

  This token contract allows for the implementation of off-chain systems that
  mint items to callers using entirely off-chain data.

  @custom:date May 24th, 2023
*/
contract SignatureMint is EIP712, Ownable, ReentrancyGuard {

  /**
    A constant hash of the mint operation's signature.
  
    @dev _minter The address of the minter for the signed-for item. This must
      be the address of the caller.
    @dev _expiry The expiry time after which this signature cannot execute.
    @dev _tokenId The ID of the specific token being minted.
  */
  bytes32 public constant MINT_TYPEHASH = keccak256(
    "mint(address _minter,uint256 _expiry,uint256 _tokenId)"
  );

  /// The name of this minter.
  string public name;

  /// The address permitted to sign claim signatures.
  address public signer;

  /// The address of the YAYO contract to mint new items into.
  address public immutable yayo;

  /**
    An event emitted when a caller mints a new item.

    @param caller The caller who claimed the tokens.
    @param id The ID of the specific item within the ERC-721 `item` contract.
  */
  event Minted (
    address indexed caller,
    uint256 id
  );

  /**
    Construct a new minter by providing it a permissioned claim signer which may
    issue claims and claim amounts, and the item to mint in.

    @param _name The name of the minter, used in EIP-712 domain separation.
    @param _signer The address permitted to sign claim signatures.
    @param _yayo The address of the YAYO NFT contract that items are minted into.
  */
  constructor (
    string memory _name,
    address _signer,
    address _yayo
  ) EIP712 (_name, "1") {
    if (_signer == address(0)) { revert SignerCannotBeZero(); }
    name = _name;
    signer = _signer;
    yayo = _yayo;
  }

  /**
    A private helper function to validate a signature supplied for item mints.
    This function constructs a digest and verifies that the signature signer was
    the authorized address we expect.

    @param _minter The address of the minter for the signed-for item. This must
      be the address of the caller.
    @param _expiry The expiry time after which this signature cannot execute.
    @param _tokenId The specific ID of the item to mint.
    @param _v The recovery byte of the signature.
    @param _r Half of the ECDSA signature pair.
    @param _s Half of the ECDSA signature pair.
  */
  function validMint (
    address _minter,
    uint256 _expiry,
    uint256 _tokenId,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) private view returns (bool) {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(MINT_TYPEHASH, _minter, _expiry, _tokenId)
        )
      )
    );

    // The claim is validated if it was signed by our authorized signer.
    return ecrecover(digest, _v, _r, _s) == signer;
  }

  /**
    Allow a caller to mint a new item if
      1. the mint is backed by a valid signature from the trusted `signer`.
      2. the signature is not expired.

    @param _minter The address of the minter for the signed-for item. This does
      not have to be the address of the caller, allowing for meta-transaction
      style minting.
    @param _expiry The expiry time after which this signature cannot execute.
    @param _tokenId The specific ID of the item to mint.
    @param _v The recovery byte of the signature.
    @param _r Half of the ECDSA signature pair.
    @param _s Half of the ECDSA signature pair.
  */
  function _mint (
    address _minter,
    uint256 _expiry,
    uint256 _tokenId,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) internal nonReentrant {

    // Validate the expiration time.
    if (_expiry < block.timestamp) { revert CannotMintExpiredSignature(); }

    // Validiate that the claim was provided by our trusted `signer`.
    bool validSignature = validMint(_minter, _expiry, _tokenId, _v, _r, _s);
    if (!validSignature) {
      revert CannotMintInvalidSignature();
    }

    // Mint the new item.
    IYAYOMintable yayoContract = IYAYOMintable(yayo);
    yayoContract.mint(_minter, _tokenId);

    // Emit an event.
    emit Minted(_minter, _tokenId);
  }

  /**
    Allow a caller to mint any new items in an array if, for each item
      1. the mint is backed by a valid signature from the trusted `signer`.
      2. the signature is not expired.

    @param _minters Addresses of the minters for the signed-for item. This
      does not have to be the address of the caller, allowing for
      meta-transaction style minting.
    @param _expiries The expiry times after which a signature cannot execute.
    @param _tokenIds The specific IDs of the items to mint.
    @param _v The recovery bytes of the signature.
    @param _r Halves of the ECDSA signature pair.
    @param _s Halves of the ECDSA signature pair.
  */
  function mint (
    address[] memory _minters,
    uint256[] memory _expiries,
    uint256[] memory _tokenIds,
    uint8[] memory _v,
    bytes32[] memory _r,
    bytes32[] memory _s
  ) external {
    if (
      _minters.length != _expiries.length || 
      _minters.length != _tokenIds.length || 
      _minters.length != _v.length ||
      _minters.length != _r.length ||
      _minters.length != _s.length
    ) {
      revert MintArrayLengthMismatch();
    }

    // Mint each item.
    for (uint256 i = 0; i < _minters.length; i++) {
      _mint(_minters[i], _expiries[i], _tokenIds[i], _v[i], _r[i], _s[i]);
    }
  }

  /**
    An administrative function to change the signer address. This may be used to
    rotate the signer address routinely or in the event of a key compromise.
    The zero address is used to disable the signer entirely.

    @param _newSigner The address of the new address permitted to sign claim
      signatures.
  */
  function setSigner (
    address _newSigner
  ) external onlyOwner {
    if (_newSigner == address(0)) {
      revert SignerCannotBeZero();
    }
    signer = _newSigner;
  }
}