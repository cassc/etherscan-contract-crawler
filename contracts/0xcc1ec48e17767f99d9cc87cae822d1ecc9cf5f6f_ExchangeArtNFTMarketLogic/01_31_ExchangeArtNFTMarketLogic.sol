// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./mixins/shared/Constants.sol";
import "./mixins/IdGenerator.sol";
import "./mixins/BuyNowSellingAgreementProvider.sol";
import "./mixins/AuctionSellingAgreementProvider.sol";
import "./mixins/OfferSellingAgreementProvider.sol";

contract ExchangeArtNFTMarketLogic is
  Initializable,
  IdGenerator,
  ReentrancyGuardUpgradeable,
  BuyNowSellingAgreementProvider,
  OfferSellingAgreementProvider,
  AuctionSellingAgreementProvider
{
  address payable private immutable treasuryAddress =
    payable(0xB982539402A3453Dd38828203B6d84894915411a);
  Escrow private fallbackEscrow;

  constructor() {
    _disableInitializers();
  }

  /**
   * @dev See {Initializable-initialize}.
   * We mark this function with a special initializer modifier so it can only be called once.
   */
  function initialize() public initializer {
    fallbackEscrow = new Escrow();
    IdGenerator.__IdGenerator_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
  }

  /**
   * Function to withdraw the escrowed amount of a user, in case a standard transfer has failed.
   */
  function withdrawEscrowedAmount(address payable walletAddress) public {
    uint256 depositsOfUser = fallbackEscrow.depositsOf(walletAddress);
    if (depositsOfUser == 0) {
      revert EscrowWithdrawError__NoFundsToWithdraw(walletAddress);
    }
    fallbackEscrow.withdraw(walletAddress);
  }

  /**
   * We use the push payment pattern normally, but if the recipient is a contract address which cannot
   * accept Ethereum, we fallback to an escrow contract which will hold the funds until they are withdrawn.
   */
  function _pushPayments(
    address payable[] memory recipients,
    uint256[] memory amounts
  ) internal override(PaymentsAware) {
    for (uint256 i = 0; i < recipients.length; i++) {
      (bool success, ) = recipients[i].call{value: amounts[i], gas: 20_000}("");
      if (!success) {
        fallbackEscrow.deposit{value: amounts[i]}(recipients[i]);
      }
    }
  }

  /**
   * Internal function to retrieve the treasury address.
   */
  function _getTreasury()
    internal
    view
    virtual
    override(PaymentsAware)
    returns (address payable)
  {
    return treasuryAddress;
  }
}