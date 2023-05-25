// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITiny721.sol";
import "../interfaces/staker/IFixedStaker.sol";
import "../libraries/EIP712.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CannotClaimInvalidSignature();
error CannotClaimAlreadyClaimed();
error SweepingTransferFailed();

/**
  @title The Impostors genesis season is over. Callers may claim pending BLOOD.
  @author Tim Clancy
  @author Rostislav Khlebnikov
  @author Liam Clancy
  @author 0xthrpw

  July 19th, 2022.
*/
contract ImpostorsStakerClaim is
  EIP712, Ownable, ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /// A constant hash of the claim operation's signature.
  bytes32 constant public CLAIM_TYPEHASH = keccak256(
    "claim(address _claimant,address _asset,uint256 _amount)"
  );

  /// The name of the vault.
  string public name;

  /// The address permitted to sign claim signatures.
  address public immutable signer;

  /// The address of the Impostors staker.
  address public immutable staker;

  /// The address of the Impostors items to unlock transfers for.
  address public immutable impostors;

  /// A mapping for whether or not a specific claimant has claimed.
  mapping ( address => bool ) public claimed;

  /**
    An event emitted when a claimant claims tokens.

    @param claimant The caller who claimed the tokens.
    @param asset The ERC-20 tokens being claimed.
    @param amount The amount of tokens claimed.
  */
  event Claimed (
    address indexed claimant,
    address indexed asset,
    uint256 amount
  );

  /**
    Construct a new vault by providing it a permissioned claim signer which may
    issue claims and claim amounts.

    @param _name The name of the vault used in EIP-712 domain separation.
    @param _signer The address permitted to sign claim signatures.
    @param _staker The address of the Impostors staker.
    @param _impostors The address of the Impostors items to unlock transfers on.
  */
  constructor (
    string memory _name,
    address _signer,
    address _staker,
    address _impostors
  ) EIP712(_name, "1") {
    name = _name;
    signer = _signer;
    staker = _staker;
    impostors = _impostors;
  }

  /**
    A private helper function to validate a signature supplied for token claims.
    This function constructs a digest and verifies that the signature signer was
    the authorized address we expect.

    @param _claimant The claimant attempting to claim tokens.
    @param _asset The address of the ERC-20 token being claimed.
    @param _amount The amount of tokens the claimant is trying to claim.
    @param _v The recovery byte of the signature.
    @param _r Half of the ECDSA signature pair.
    @param _s Half of the ECDSA signature pair.
  */
  function validClaim (
    address _claimant,
    address _asset,
    uint256 _amount,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) private view returns (bool) {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(
            CLAIM_TYPEHASH,
            _claimant,
            _asset,
            _amount
          )
        )
      )
    );

    // The claim is validated if it was signed by our authorized signer.
    return ecrecover(digest, _v, _r, _s) == signer;
  }

  /**
    Allow a caller to claim any of their available tokens if
      1. the claim is backed by a valid signature from the trusted `signer`.
      2. the vault has enough tokens to fulfill the claim.
      3. the user's items are unlocked.

    @param _asset The address of the ERC-20 token being claimed.
    @param _amount The amount of tokens that the caller is trying to claim.
    @param _v The recovery byte of the signature.
    @param _r Half of the ECDSA signature pair.
    @param _s Half of the ECDSA signature pair.
  */
  function claim (
    address _asset,
    uint256 _amount,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external nonReentrant {

    // Validate that the caller has not already claimed.
    if (claimed[_msgSender()]) {
      revert CannotClaimAlreadyClaimed();
    }

    // Validiate that the claim was provided by our trusted `signer`.
    bool validSignature = validClaim(
      _msgSender(),
      _asset,
      _amount,
      _v,
      _r,
      _s
    );
    if (!validSignature) {
      revert CannotClaimInvalidSignature();
    }

    // Mark the claim as fulfilled.
    claimed[_msgSender()] = true;

    /*
      Iterate through all pools in the staker to retrieve the caller's staked
      items.
    */
    for (uint256 poolId = 1; poolId < 5;) {
      (uint256[] memory flexStakedItems, ) = IFixedStaker(staker).getPosition(
        poolId,
        _msgSender()
      );

      // Unlock each item.
      for (uint256 i = 0; i < flexStakedItems.length;) {
        uint256 impostorId = flexStakedItems[i];
        ITiny721(impostors).lockTransfer(impostorId, false);

        // Increment.
        unchecked {
          ++i;
        }
      }

      // Increment.
      unchecked {
        ++poolId;
      }
    }

    // Transfer tokens to the claimant.
    IERC20(_asset).safeTransfer(
      _msgSender(),
      _amount
    );

    // Emit an event.
    emit Claimed(_msgSender(), _asset, _amount);
  }

  /**
    Allow the owner to sweep either Ether or a particular ERC-20 token from the
    contract and send it to another address. This allows the owner of the shop
    to withdraw their funds after the sale is completed.

    @param _token The token to sweep the balance from; if a zero address is sent
      then the contract's balance of Ether will be swept.
    @param _destination The address to send the swept tokens to.
    @param _amount The amount of token to sweep.
  */
  function sweep (
    address _token,
    address _destination,
    uint256 _amount
  ) external onlyOwner nonReentrant {

    // A zero address means we should attempt to sweep Ether.
    if (_token == address(0)) {
      (bool success, ) = payable(_destination).call{ value: _amount }("");
      if (!success) { revert SweepingTransferFailed(); }

    // Otherwise, we should try to sweep an ERC-20 token.
    } else {
      IERC20(_token).safeTransfer(_destination, _amount);
    }
  }
}