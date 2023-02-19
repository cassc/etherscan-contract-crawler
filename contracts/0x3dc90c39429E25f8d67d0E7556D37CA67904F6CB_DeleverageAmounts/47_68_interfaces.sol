//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFla {
    function flashLoan(
        address[] memory tokens_,
        uint256[] memory amts_,
        uint256 route,
        bytes calldata data_,
        bytes calldata instaData_
    ) external;
}

interface IVault {
    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);

    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external;

    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function withdrawalFee() external view returns (uint256);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}