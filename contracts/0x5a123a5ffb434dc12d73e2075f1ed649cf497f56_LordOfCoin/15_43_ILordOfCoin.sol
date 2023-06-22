// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ILordOfCoin {

    function marketOpenTime() external view returns (uint256);

    function dvd() external view returns (address);

    function sdvd() external view returns (address);

    function sdvdEthPairAddress() external view returns (address);

    function buy(uint256 musdAmount) external returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function buyTo(address recipient, uint256 musdAmount) external returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function buyFromETH() payable external returns (uint256 recipientDVD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function sell(uint256 dvdAmount) external returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function sellTo(address recipient, uint256 dvdAmount) external returns (uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function sellToETH(uint256 dvdAmount) external returns (uint256 returnedETH, uint256 returnedMUSD, uint256 marketTax, uint256 curveTax, uint256 taxedDVD);

    function claimDividend() external returns (uint256 net, uint256 fee);

    function claimDividendTo(address recipient) external returns (uint256 net, uint256 fee);

    function claimDividendETH() external returns (uint256 net, uint256 fee, uint256 receivedETH);

    function checkSnapshot() external;

    function releaseTreasury() external;

    function depositTradingProfit(uint256 amount) external;

}