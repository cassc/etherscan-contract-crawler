// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITiny721.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CannotConfigureEmptyCriteria();
error CannotConfigureWithoutOutputItem();
error CannotConfigureWithoutPaymentToken();
error CannotRedeemForZeroItems();
error CannotRedeemCriteriaLengthMismatch();
error CannotRedeemItemAlreadyRedeemed();
error CannotRedeemUnownedItem();
error SweepingTransferFailed();


/**
  @title A contract for minting ERC-721 items given an ERC-20 token burn and
    ownership of some prerequisite ERC-721 items.
  @author 0xthrpw
  @author Tim Clancy

  This contract allows for the configuration of multiple redemption rounds. Each
  redemption round is configured with a set of ERC-721 item collection addresses
  in the `redemptionCriteria` mapping that any prospective redeemers must hold.

  Each redemption round is also configured with a redemption configuration per
  the `redemptionConfigs` mapping. This configuration allows a caller holding
  the required ERC-721 items to mint some amount `amountOut` of a new ERC-721
  `tokenOut` item in exchange for burning `price` amount of a `payingToken`
  ERC-20 token.

  Any ERC-721 collection being minted by this redeemer must grant minting
  permissions to this contract in some fashion. Users must also approve this
  contract to spend any requisite `payingToken` ERC-20 tokens on their behalf.

  April 27th, 2022.
*/
contract ImpostorsRedeemer721 is
  Ownable, ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /**
    A configurable address to transfer burned ERC-20 tokens to. The intent of
    specifying an address like this is to support burning otherwise unburnable
    ERC-20 tokens by transferring them to provably unrecoverable destinations,
    such as blackhole smart contracts.
  */
  address public immutable burnDestination;

  /**
    A mapping from a redemption round ID to an array of ERC-721 item collection
    addresses required to be held in fulfilling a redemption claim. In order to
    participate in a redemption round, a caller must hold a specific item from
    each of these required ERC-721 item collections.
  */
  mapping ( uint256 => address[] ) public redemptionCriteria;

  /**
    This struct is used when configuring a redemption round to specify a
    caller's required payment and the ERC-721 items they may be minted in
    return.

    @param price The amount of `payingToken` that a caller must pay for each set
      of items redeemed in this round.
    @param tokenOut The address of the ERC-721 item collection from which a
      caller will receive newly-minted items.
    @param payingToken The ERC-20 token of which `price` must be paid for each
      redemption.
    @param amountOut The number of new `tokenOut` ERC-721 items a caller will
      receive in return for fulfilling a claim.
  */
  struct RedemptionConfig {
    uint96 price;
    address tokenOut;
    address payingToken;
    uint96 amountOut;
  }

  /// A mapping from a redemption round ID to its configuration details.
  mapping ( uint256 => RedemptionConfig ) public redemptionConfigs;

  /**
    A triple mapping from a redemption round ID to an ERC-721 item collection
    address to the token ID of a specific item in the ERC-721 item collection.
    This mapping ensures that a specific item can only be used once in any given
    redemption round.
  */
  mapping (
    uint256 => mapping (
      address => mapping (
        uint256 => bool
      )
    )
  ) public redeemed;

  /**
    An event tracking a claim in a redemption round for some ERC-721 items.

    @param round The redemption round ID involved in the claim.
    @param caller The caller who triggered the claim.
    @param tokenIds The array of token IDs for specific items keyed against the
      matching `criteria` paramter.
  */
  event TokenRedemption (
    uint256 indexed round,
    address indexed caller,
    uint256[] tokenIds
  );

  /**
    An event tracking a configuration update for the details of a particular
    redemption round.

    @param round The redemption round ID with updated configuration.
    @param criteria The array of ERC-721 item collection addresses required for
      fulfilling a redemption claim in this round.
    @param configuration The updated `RedemptionConfig` configuration details
      for this round.
  */
  event ConfigUpdate (
    uint256 indexed round,
    address[] indexed criteria,
    RedemptionConfig indexed configuration
  );

  /**
    Construct a new item redeemer by specifying a destination for burnt tokens.

    @param _burnDestination An address where tokens received for fulfilling
      redemptions are sent.
  */
  constructor (
    address _burnDestination
  ) {
    burnDestination = _burnDestination;
  }

  /**
    Easily check the redemption status of multiple tokens of a single
    collection in a single round.

    @param _round The round to check for token redemption against.
    @param _collection The address of the specific item collection to check.
    @param _tokenIds An array of token IDs belonging to the collection
      `_collection` to check for redemption status.

    @return An array of boolean redemption status for each of the items being
      checked in `_tokenIds`.
  */
  function isRedeemed (
    uint256 _round,
    address _collection,
    uint256[] memory _tokenIds
  ) external view returns (bool[] memory) {
    bool[] memory redemptionStatus = new bool[](_tokenIds.length);
    for (uint256 i = 0; i < _tokenIds.length; i += 1) {
      redemptionStatus[i] = redeemed[_round][_collection][_tokenIds[i]];
    }
    return redemptionStatus;
  }

  /**
    Set the configuration details for a particular redemption round. A specific
    redemption round may be effectively disabled by setting the `amountOut`
    field of the given `RedemptionConfig` `_config` value to 0.

    @param _round The redemption round ID to configure.
    @param _criteria An array of ERC-721 item collection addresses to require
      holdings from when a caller attempts to redeem from the round of ID
      `_round`.
    @param _config The `RedemptionConfig` configuration data to use for setting
      new configuration details for the round of ID `_round`.
  */
  function setConfig (
    uint256 _round,
    address[] calldata _criteria,
    RedemptionConfig calldata _config
  ) external onlyOwner {

    /*
      Prevent a redemption round from being configured with no requisite ERC-721
      item collection holding criteria.
    */
    if (_criteria.length == 0) {
      revert CannotConfigureEmptyCriteria();
    }

    /*
      Perform input validation on the provided configuration details. A
      redemption round may not be configured with no ERC-721 item collection to
      mint as output.
    */
    if (_config.tokenOut == address(0)) {
      revert CannotConfigureWithoutOutputItem();
    }

    /*
      A redemption round may not be configured with no ERC-20 token address to
      attempt to enforce payment from.
    */
    if (_config.payingToken == address(0)) {
      revert CannotConfigureWithoutPaymentToken();
    }

    // Update the redemption criteria of this round.
    redemptionCriteria[_round] = _criteria;

    // Update the contents of the round configuration mapping.
    redemptionConfigs[_round] = RedemptionConfig({
      amountOut: _config.amountOut,
      price: _config.price,
      tokenOut: _config.tokenOut,
      payingToken: _config.payingToken
    });

    // Emit the configuration update event.
    emit ConfigUpdate(_round, _criteria, _config);
  }

  /**
    Allow a caller to redeem potentially multiple sets of criteria ERC-721 items
    in `_tokenIds` against the redemption round of ID `_round`.

    @param _round The ID of the redemption round to redeem against.
    @param _tokenIds An array of token IDs for the specific ERC-721 items keyed
      to the item collection criteria addresses for this round in
      the `redemptionCriteria` mapping.
  */
  function redeem (
    uint256 _round,
    uint256[][] memory _tokenIds
  ) external nonReentrant {
    address[] memory criteria = redemptionCriteria[_round];
    RedemptionConfig memory config = redemptionConfigs[_round];

    // Prevent a caller from redeeming from a round with zero output items.
    if (config.amountOut < 1) {
      revert CannotRedeemForZeroItems();
    }

    /*
      The caller may be attempting to redeem for multiple independent sets of
      items in this redemption round. Process each set of token IDs against the
      criteria addresses.
    */
    for (uint256 set = 0; set < _tokenIds.length; set += 1) {

      /*
        If the item set is not the same length as the criteria array, we have a
        mismatch and the set cannot possibly be fulfilled.
      */
      if (_tokenIds[set].length != criteria.length) {
        revert CannotRedeemCriteriaLengthMismatch();
      }

      /*
        Check each item in the set against each of the expected, required
        criteria collections.
      */
      for (uint256 i; i < criteria.length; i += 1) {

        // Verify that no item may be redeemed twice against a single round.
        if (redeemed[_round][criteria[i]][_tokenIds[set][i]]) {
          revert CannotRedeemItemAlreadyRedeemed();
        }

        /*
          Verify that the caller owns each of the items involved in the
          redemption claim.
        */
        if (ITiny721(criteria[i]).ownerOf(_tokenIds[set][i]) != _msgSender()) {
          revert CannotRedeemUnownedItem();
        }

        // Flag each item as redeemed against this round.
        redeemed[_round][criteria[i]][_tokenIds[set][i]] = true;
      }

      // Emit an event indicating which tokens were redeemed.
      emit TokenRedemption(_round, _msgSender(), _tokenIds[set]);
    }

    // If there is a non-zero redemption price, perform the required token burn.
    if (config.price > 0) {
      IERC20(config.payingToken).safeTransferFrom(
        _msgSender(),
        burnDestination,
        config.price * _tokenIds.length
      );
    }

    // Mint the caller their redeemed items.
    ITiny721(config.tokenOut).mint_Qgo(
      _msgSender(),
      config.amountOut * _tokenIds.length
    );
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