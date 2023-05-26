// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../libraries/DataStruct.sol';

interface ITokenizer is IERC721 {
  /**
   * @notice Emitted when a collateral service provider mints an empty asset bond token.
   * @param account The address of collateral service provider who minted
   * @param tokenId The id of minted token
   **/
  event EmptyAssetBondMinted(address indexed account, uint256 tokenId);

  /**
   * @notice Emitted when a collateral service provider mints an empty asset bond token.
   **/
  event AssetBondSettled(
    address indexed borrower,
    address indexed signer,
    uint256 tokenId,
    uint256 principal,
    uint256 couponRate,
    uint256 delinquencyRate,
    uint256 debtCeiling,
    uint256 maturityTimestamp,
    uint256 liquidationTimestamp,
    uint256 loanStartTimestamp,
    string ifpsHash
  );

  event AssetBondSigned(address indexed signer, uint256 tokenId, string signerOpinionHash);

  event AssetBondCollateralized(
    address indexed account,
    uint256 tokenId,
    uint256 borrowAmount,
    uint256 interestRate
  );

  event AssetBondReleased(address indexed borrower, uint256 tokenId);

  event AssetBondLiquidated(address indexed liquidator, uint256 tokenId);

  function mintAssetBond(address account, uint256 id) external;

  function collateralizeAssetBond(
    address collateralServiceProvider,
    uint256 tokenId,
    uint256 borrowAmount,
    uint256 borrowAPY
  ) external;

  function releaseAssetBond(address account, uint256 tokenId) external;

  function liquidateAssetBond(address account, uint256 tokenId) external;

  function getAssetBondIdData(uint256 tokenId)
    external
    view
    returns (DataStruct.AssetBondIdData memory);

  function getAssetBondData(uint256 tokenId)
    external
    view
    returns (DataStruct.AssetBondData memory);

  function getAssetBondDebtData(uint256 tokenId) external view returns (uint256, uint256);

  function getMinter(uint256 tokenId) external view returns (address);
}