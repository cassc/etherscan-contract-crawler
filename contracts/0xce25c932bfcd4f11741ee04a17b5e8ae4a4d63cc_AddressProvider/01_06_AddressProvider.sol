//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";

/// @title AddressProvider
/// @author leNFT
/// @notice This contract is responsible for storing and providing all the protocol contract addresses
// solhint-disable-next-line max-states-count
contract AddressProvider is OwnableUpgradeable, IAddressProvider {
    address private _lendingMarket;
    address private _feeDistributor;
    address private _swapRouter;
    address private _loanCenter;
    address private _nftOracle;
    address private _tokenOracle;
    address private _interestRate;
    address private _votingEscrow;
    address private _nativeToken;
    address private _nativeTokenVesting;
    address private _weth;
    address private _genesisNFT;
    address private _gaugeController;
    address private _tradingPoolFactory;
    address private _tradingPoolHelpers;
    address private _bribes;
    address private _liquidityPairMetadata;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function setLendingMarket(
        address lendingMarket
    ) external override onlyOwner {
        _lendingMarket = lendingMarket;
    }

    function getLendingMarket() external view override returns (address) {
        return _lendingMarket;
    }

    function setTradingPoolFactory(
        address tradingPoolFactory
    ) external override onlyOwner {
        _tradingPoolFactory = tradingPoolFactory;
    }

    function getTradingPoolFactory() external view override returns (address) {
        return _tradingPoolFactory;
    }

    function setTradingPoolHelpers(
        address tradingPoolHelpers
    ) external onlyOwner {
        _tradingPoolHelpers = tradingPoolHelpers;
    }

    function getTradingPoolHelpers() external view returns (address) {
        return _tradingPoolHelpers;
    }

    function setSwapRouter(address swapRouter) external override onlyOwner {
        _swapRouter = swapRouter;
    }

    function getSwapRouter() external view override returns (address) {
        return _swapRouter;
    }

    function setGaugeController(
        address gaugeController
    ) external override onlyOwner {
        _gaugeController = gaugeController;
    }

    function getGaugeController() external view override returns (address) {
        return _gaugeController;
    }

    function setVotingEscrow(address votingEscrow) external override onlyOwner {
        _votingEscrow = votingEscrow;
    }

    function getVotingEscrow() external view override returns (address) {
        return _votingEscrow;
    }

    function setNativeToken(address nativeToken) external override onlyOwner {
        _nativeToken = nativeToken;
    }

    function getNativeToken() external view override returns (address) {
        return _nativeToken;
    }

    function setNativeTokenVesting(
        address nativeTokenVesting
    ) external onlyOwner {
        _nativeTokenVesting = nativeTokenVesting;
    }

    function getNativeTokenVesting() external view override returns (address) {
        return _nativeTokenVesting;
    }

    function setFeeDistributor(
        address feeDistributor
    ) external override onlyOwner {
        _feeDistributor = feeDistributor;
    }

    function getFeeDistributor() external view override returns (address) {
        return _feeDistributor;
    }

    function setLoanCenter(address loanCenter) external override onlyOwner {
        _loanCenter = loanCenter;
    }

    function getLoanCenter() external view override returns (address) {
        return _loanCenter;
    }

    function setInterestRate(address interestRate) external override onlyOwner {
        _interestRate = interestRate;
    }

    function getInterestRate() external view override returns (address) {
        return _interestRate;
    }

    function setNFTOracle(address nftOracle) external override onlyOwner {
        _nftOracle = nftOracle;
    }

    function getNFTOracle() external view override returns (address) {
        return _nftOracle;
    }

    function setTokenOracle(address tokenOracle) external override onlyOwner {
        _tokenOracle = tokenOracle;
    }

    function getTokenOracle() external view override returns (address) {
        return _tokenOracle;
    }

    function setGenesisNFT(address genesisNFT) external override onlyOwner {
        _genesisNFT = genesisNFT;
    }

    function getGenesisNFT() external view override returns (address) {
        return _genesisNFT;
    }

    function setWETH(address weth) external override onlyOwner {
        _weth = weth;
    }

    function getWETH() external view override returns (address) {
        return _weth;
    }

    function setBribes(address bribes) external override onlyOwner {
        _bribes = bribes;
    }

    function getBribes() external view override returns (address) {
        return _bribes;
    }

    function setLiquidityPairMetadata(
        address liquidityPairMetadata
    ) external override onlyOwner {
        _liquidityPairMetadata = liquidityPairMetadata;
    }

    function getLiquidityPairMetadata()
        external
        view
        override
        returns (address)
    {
        return _liquidityPairMetadata;
    }
}