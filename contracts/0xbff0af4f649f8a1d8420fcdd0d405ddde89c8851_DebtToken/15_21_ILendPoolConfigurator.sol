// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILendPoolConfigurator {
  struct ConfigReserveInput {
    address asset;
    uint256 reserveFactor;
  }

  struct ConfigNftInput {
    address asset;
    uint256 tokenId;
    uint256 baseLTV;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 redeemDuration;
    uint256 auctionDuration;
    uint256 redeemFine;
    uint256 redeemThreshold;
    uint256 minBidFine;
    uint256 maxSupply;
    uint256 maxTokenId;
  }

  struct ConfigNftAsCollateralInput {
    address asset;
    uint256 nftTokenId;
    uint256 newPrice;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 redeemThreshold;
    uint256 liquidationBonus;
    uint256 redeemDuration;
    uint256 auctionDuration;
    uint256 redeemFine;
    uint256 minBidFine;
  }

  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param uToken The address of the associated uToken contract
   * @param debtToken The address of the associated debtToken contract
   * @param interestRateAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed uToken,
    address debtToken,
    address interestRateAddress
  );

  /**
   * @dev Emitted when borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingEnabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when a reserve is activated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveActivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is deactivated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDeactivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is frozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveFrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve is unfrozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated
   * @param asset The address of the underlying asset of the reserve
   * @param factor The new reserve factor
   **/
  event ReserveFactorChanged(address indexed asset, uint256 factor);

  /**
   * @dev Emitted when the reserve decimals are updated
   * @param asset The address of the underlying asset of the reserve
   * @param decimals The new decimals
   **/
  event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

  /**
   * @dev Emitted when a reserve interest strategy contract is updated
   * @param asset The address of the underlying asset of the reserve
   * @param strategy The new address of the interest strategy contract
   **/
  event ReserveInterestRateChanged(address indexed asset, address strategy);

  /**
   * @dev Emitted when a nft is initialized.
   * @param asset The address of the underlying asset of the nft
   * @param uNft The address of the associated uNFT contract
   **/
  event NftInitialized(address indexed asset, address indexed uNft);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified NFT are updated.
   * @param asset The address of the underlying asset of the NFT
   * @param tokenId token ID
   * @param ltv The loan to value of the asset when used as NFT
   * @param liquidationThreshold The threshold at which loans using this asset as NFT will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event NftConfigurationChanged(
    address indexed asset,
    uint256 indexed tokenId,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when a NFT is activated
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftActivated(address indexed asset);

  /**
   * @dev Emitted when a NFT is deactivated
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftDeactivated(address indexed asset);

  /**
   * @dev Emitted when a NFT token is activated
   * @param asset The address of the underlying asset of the NFT
   * @param nftTokenId The token id of the underlying asset of the NFT
   **/
  event NftTokenActivated(address indexed asset, uint256 indexed nftTokenId);

  /**
   * @dev Emitted when a NFT token is deactivated
   * @param asset The address of the underlying asset of the NFT
   * @param nftTokenId The token id of the underlying asset of the NFT
   **/
  event NftTokenDeactivated(address indexed asset, uint256 indexed nftTokenId);

  /**
   * @dev Emitted when a NFT is frozen
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftFrozen(address indexed asset);

  /**
   * @dev Emitted when a NFT is unfrozen
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a NFT is frozen
   * @param asset The address of the underlying asset of the NFT
   * @param nftTokenId The token id of the underlying asset of the NFT
   **/
  event NftTokenFrozen(address indexed asset, uint256 indexed nftTokenId);

  /**
   * @dev Emitted when a NFT is unfrozen
   * @param asset The address of the underlying asset of the NFT
   * @param nftTokenId The token id of the underlying asset of the NFT
   **/
  event NftTokenUnfrozen(address indexed asset, uint256 indexed nftTokenId);

  /**
   * @dev Emitted when a redeem duration is updated
   * @param asset The address of the underlying asset of the NFT
   * @param tokenId token ID
   * @param redeemDuration The new redeem duration
   * @param auctionDuration The new redeem duration
   * @param redeemFine The new redeem fine
   **/
  event NftAuctionChanged(
    address indexed asset,
    uint256 indexed tokenId,
    uint256 redeemDuration,
    uint256 auctionDuration,
    uint256 redeemFine
  );
  /**
   * @dev Emitted when a redeem threshold is modified
   * @param asset The address of the underlying asset of the NFT
   * @param tokenId token ID
   * @param redeemThreshold The new redeem threshold
   **/
  event NftRedeemThresholdChanged(address indexed asset, uint256 indexed tokenId, uint256 redeemThreshold);
  /**
   * @dev Emitted when a min bid fine is modified
   * @param asset The address of the underlying asset of the NFT
   * @param tokenId token ID
   * @param minBidFine The new min bid fine
   **/
  event NftMinBidFineChanged(address indexed asset, uint256 indexed tokenId, uint256 minBidFine);
  /**
   * @dev Emitted when an asset's max supply and max token Id is modified
   * @param asset The address of the underlying asset of the NFT
   * @param maxSupply The new max supply
   * @param maxTokenId The new max token Id
   **/
  event NftMaxSupplyAndTokenIdChanged(address indexed asset, uint256 maxSupply, uint256 maxTokenId);

  /**
   * @dev Emitted when an uToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The uToken proxy address
   * @param implementation The new uToken implementation
   **/
  event UTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  /**
   * @dev Emitted when the implementation of a debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The debt token proxy address
   * @param implementation The new debtToken implementation
   **/
  event DebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  /**
   * @dev Emitted when the lend pool rescuer is updated
   * @param rescuer the new rescuer address
   **/
  event RescuerUpdated(address indexed rescuer);
}