// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./StrategyBaseUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract StrategyOwnableBaseUpgradeable is
    OwnableUpgradeable,
    StrategyBaseUpgradeable
{
    uint256[8] private __gap;

    // solhint-disable-next-line
    function __StrategyOwnableBaseUpgradeable_init(
        StrategyArgs calldata strategyArgs
    ) internal onlyInitializing {
        __Ownable_init();
        __StrategyBaseUpgradeable_init(strategyArgs);
    }

    function setDepositFee(uint24 fee_, NameValuePair[] calldata params)
        public
        virtual
        onlyOwner
    {
        super._setDepositFee(fee_, params);
    }

    function setWithdrawalFee(uint24 fee_, NameValuePair[] calldata params)
        public
        virtual
        onlyOwner
    {
        super._setWithdrawalFee(fee_, params);
    }

    function setPerformanceFee(uint24 fee_, NameValuePair[] calldata params)
        public
        virtual
        onlyOwner
    {
        super._setPerformanceFee(fee_, params);
    }

    function setFeeReceiver(
        address feeReceiver_,
        NameValuePair[] calldata params
    ) public virtual onlyOwner {
        super._setFeeReceiver(feeReceiver_, params);
    }

    function setInvestmentToken(IInvestmentToken investmentToken)
        public
        virtual
        onlyOwner
    {
        super._setInvestmentToken(investmentToken);
    }

    function setTotalInvestmentLimit(uint256 totalInvestmentLimit)
        public
        virtual
        onlyOwner
    {
        super._setTotalInvestmentLimit(totalInvestmentLimit);
    }

    function setInvestmentLimitPerAddress(uint256 investmentLimitPerAddress)
        public
        virtual
        onlyOwner
    {
        super._setInvestmentLimitPerAddress(investmentLimitPerAddress);
    }

    function setPriceOracle(IPriceOracle priceOracle) public virtual onlyOwner {
        super._setPriceOracle(priceOracle);
    }

    function setSwapService(SwapServiceProvider provider, address router)
        public
        virtual
        onlyOwner
    {
        super._setSwapService(provider, router);
    }
}