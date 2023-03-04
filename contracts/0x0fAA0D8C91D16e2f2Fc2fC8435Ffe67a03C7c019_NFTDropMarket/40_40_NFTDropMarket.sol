/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./mixins/shared/FETHNode.sol";
import "./mixins/shared/FoundationTreasuryNode.sol";
import "./mixins/shared/Gap9000.sol";
import "./mixins/shared/Gap500.sol";
import "./mixins/shared/MarketFees.sol";
import "./mixins/shared/MarketSharedCore.sol";
import "./mixins/shared/RouterContext.sol";
import "./mixins/shared/SendValueWithFallbackWithdraw.sol";
import "./mixins/shared/TxDeadline.sol";

import "./mixins/nftDropMarket/NFTDropMarketCore.sol";
import "./mixins/nftDropMarket/NFTDropMarketFixedPriceSale.sol";
import "./mixins/nftDropMarket/NFTDropMarketExhibition.sol";

error NFTDropMarket_NFT_Already_Minted();

/**
 * @title A market for minting NFTs with Foundation.
 * @author batu-inal & HardlyDifficult & philbirt & reggieag
 */
contract NFTDropMarket is
  TxDeadline,
  Initializable,
  FoundationTreasuryNode,
  Context,
  RouterContext,
  FETHNode,
  MarketSharedCore,
  NFTDropMarketCore,
  ReentrancyGuardUpgradeable,
  SendValueWithFallbackWithdraw,
  MarketFees,
  Gap500,
  Gap9000,
  NFTDropMarketExhibition,
  NFTDropMarketFixedPriceSale
{
  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param treasury The Foundation Treasury contract address.
   * @param feth The FETH ERC-20 token contract address.
   * @param royaltyRegistry The Royalty Registry contract address.
   * @param nftMarket The NFT Market contract address, containing exhibition definitions.
   * @param router The trusted router contract address.
   */
  constructor(
    address payable treasury,
    address feth,
    address royaltyRegistry,
    address nftMarket,
    address router
  )
    FoundationTreasuryNode(treasury)
    FETHNode(feth)
    MarketFees(
      /* protocolFeeInBasisPoints: */
      1500,
      royaltyRegistry,
      /* assumePrimarySale: */
      true
    )
    NFTDropMarketExhibition(nftMarket)
    RouterContext(router)
  {
    _disableInitializers();
  }

  /**
   * @notice Called once to configure the contract after the initial proxy deployment.
   * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
   */
  function initialize() external initializer {
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Returns address(0) if the NFT has already been sold, otherwise checks for a listing in this market.
   */
  function _getSellerOf(
    address nftContract,
    uint256 tokenId
  ) internal view override(MarketSharedCore, NFTDropMarketFixedPriceSale) returns (address payable seller) {
    // Check the current owner first in case it has been sold.
    try IERC721(nftContract).ownerOf(tokenId) returns (address owner) {
      if (owner != address(0)) {
        // If sold, return address(0) since that owner cannot sell via this market.
        return payable(address(0));
      }
    } catch {
      // Fall through
    }

    return super._getSellerOf(nftContract, tokenId);
  }

  /**
   * @inheritdoc NFTDropMarketFixedPriceSale
   */
  function _getProtocolFee(
    address nftContract
  ) internal view override(MarketFees, NFTDropMarketFixedPriceSale) returns (uint256 protocolFeeInBasisPoints) {
    protocolFeeInBasisPoints = super._getProtocolFee(nftContract);
  }

  /**
   * @inheritdoc MarketSharedCore
   * @dev Reverts if the NFT has already been sold, otherwise checks for a listing in this market.
   */
  function _getSellerOrOwnerOf(
    address nftContract,
    uint256 tokenId
  ) internal view override returns (address payable sellerOrOwner) {
    // Check the current owner first in case it has been sold.
    try IERC721(nftContract).ownerOf(tokenId) returns (address owner) {
      if (owner != address(0)) {
        // Once an NFT has been minted, it cannot be sold through this contract.
        revert NFTDropMarket_NFT_Already_Minted();
      }
    } catch {
      // Fall through
    }

    sellerOrOwner = super._getSellerOf(nftContract, tokenId);
  }

  /**
   * @inheritdoc RouterContext
   */
  function _msgSender() internal view override(Context, RouterContext) returns (address sender) {
    sender = super._msgSender();
  }
}