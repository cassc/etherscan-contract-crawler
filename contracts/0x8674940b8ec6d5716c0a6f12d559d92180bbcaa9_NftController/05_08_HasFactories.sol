// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

abstract contract HasFactories {
    mapping(address => bool) _factories;

    modifier onlyFactory() {
        require(_factories[msg.sender], "only for factories");
        _;
    }

    function setFactories(
        address[] calldata addresses,
        bool isFactoryValue
    ) external {
        require(
            canFactoriesChange(msg.sender),
            "account can not set factories"
        );
        for (uint256 i = 0; i < addresses.length; ++i) {
            _factories[addresses[i]] = isFactoryValue;
        }
    }

    function isFactory(address addr) external view returns (bool) {
        return _factories[addr];
    }

    function canFactoriesChange(
        address account
    ) internal view virtual returns (bool);
}