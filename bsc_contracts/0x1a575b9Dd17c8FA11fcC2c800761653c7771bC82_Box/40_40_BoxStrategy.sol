// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../common/bases/StrategyOwnablePausableBaseUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Box is UUPSUpgradeable, StrategyOwnablePausableBaseUpgradeable {
    // solhint-disable-next-line const-name-snakecase
    string public constant trackingName = "box";
    // solhint-disable-next-line const-name-snakecase
    string public constant humanReadableName = "Box Strategy";
    // solhint-disable-next-line const-name-snakecase
    string public constant version = "1.0.0";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(StrategyArgs calldata strategyArgs)
        external
        initializer
    {
        __UUPSUpgradeable_init();
        __StrategyOwnablePausableBaseUpgradeable_init(strategyArgs);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _deposit(uint256 amount, NameValuePair[] calldata)
        internal
        virtual
        override
    {}

    function _withdraw(uint256 amount, NameValuePair[] calldata)
        internal
        virtual
        override
    {}

    function _reapReward(NameValuePair[] calldata) internal virtual override {}

    function _getAssetBalances()
        internal
        view
        virtual
        override
        returns (Balance[] memory assetBalances)
    {}

    function _getLiabilityBalances()
        internal
        view
        virtual
        override
        returns (Balance[] memory liabilityBalances)
    {}

    function _getAssetValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    )
        internal
        view
        virtual
        override
        returns (Valuation[] memory assetValuations)
    {}

    function _getLiabilityValuations(bool, bool)
        internal
        view
        virtual
        override
        returns (Valuation[] memory liabilityValuations)
    {}

    function getStargateLpBalance() public view returns (uint256) {}
}