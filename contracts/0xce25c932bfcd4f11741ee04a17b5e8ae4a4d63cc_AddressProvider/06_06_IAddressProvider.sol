//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface IAddressProvider {
    function setLendingMarket(address market) external;

    function getLendingMarket() external view returns (address);

    function setTradingPoolFactory(address tradingPoolFactory) external;

    function getTradingPoolFactory() external view returns (address);

    function setSwapRouter(address swapRouter) external;

    function getSwapRouter() external view returns (address);

    function setGaugeController(address gaugeController) external;

    function getGaugeController() external view returns (address);

    function setLoanCenter(address loancenter) external;

    function getLoanCenter() external view returns (address);

    function setVotingEscrow(address nativeTokenVault) external;

    function getVotingEscrow() external view returns (address);

    function setNativeToken(address nativeToken) external;

    function getNativeToken() external view returns (address);

    function getNativeTokenVesting() external view returns (address);

    function setInterestRate(address interestRate) external;

    function getInterestRate() external view returns (address);

    function setNFTOracle(address nftOracle) external;

    function getNFTOracle() external view returns (address);

    function setTokenOracle(address tokenOracle) external;

    function getTokenOracle() external view returns (address);

    function setFeeDistributor(address feeDistributor) external;

    function getFeeDistributor() external view returns (address);

    function setGenesisNFT(address genesisNFT) external;

    function getGenesisNFT() external view returns (address);

    function setWETH(address weth) external;

    function getWETH() external view returns (address);

    function setBribes(address bribes) external;

    function getBribes() external view returns (address);

    function setLiquidityPairMetadata(address liquidityPairMetadata) external;

    function getLiquidityPairMetadata() external view returns (address);
}