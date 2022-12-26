pragma solidity ^0.8.0;

interface ITokenSaleCreator {
  struct TokenSaleItem {
    address token;
    uint256 tokensForSale;
    uint256 hardCap;
    uint256 softCap;
    uint256 presaleRate;
    bytes32 saleId;
    uint256 minContributionEther;
    uint256 maxContributionEther;
    uint256 saleStartTime;
    uint256 saleEndTime;
    bool interrupted;
    address proceedsTo;
    address admin;
    uint256 availableTokens;
    bool ended;
  }

  event TokenSaleItemCreated(
    bytes32 saleId,
    address token,
    uint256 tokensForSale,
    uint256 hardCap,
    uint256 softCap,
    uint256 presaleRate,
    uint256 minContributionEther,
    uint256 maxContributionEther,
    uint256 saleStartTime,
    uint256 saleEndTime,
    address proceedsTo,
    address admin
  );

  function initTokenSale(
    address token,
    uint256 tokensForSale,
    uint256 hardCap,
    uint256 softCap,
    uint256 presaleRate,
    uint256 minContributionEther,
    uint256 maxContributionEther,
    uint256 saleStartTime,
    uint256 daysToLast,
    address proceedsTo,
    address admin
  ) external payable returns (bytes32 saleId);

  function interruptTokenSale(bytes32 saleId) external;

  function allTokenSales(uint256) external view returns (bytes32);

  function feePercentage() external view returns (uint8);

  function balance(bytes32 saleId, address account) external view returns (uint256);

  function amountContributed(bytes32 saleId, address account) external view returns (uint256);
}