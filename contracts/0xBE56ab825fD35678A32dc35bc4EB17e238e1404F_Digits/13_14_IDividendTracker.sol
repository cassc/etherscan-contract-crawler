// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IDividendTracker {
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event ExcludeFromDividends(address indexed account, bool excluded);
    event Claim(address indexed account, uint256 amount);
    event Compound(address indexed account, uint256 amount, uint256 tokens);

    function distributeDividends(uint256 daiDividends) external;

    function excludeFromDividends(address account, bool excluded) external;

    function setBalance(address account, uint256 newBalance) external;

    function totalSupply() external view returns (uint256);

    function isExcludedFromDividends(address account)
        external
        view
        returns (bool);

    function processAccount(address account) external returns (bool);

    function compoundAccount(address account) external returns (bool);

    function withdrawableDividendOf(address account)
        external
        view
        returns (uint256);

    function withdrawnDividendOf(address account)
        external
        view
        returns (uint256);

    function accumulativeDividendOf(address account)
        external
        view
        returns (uint256);

    function getAccountInfo(address account)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getLastClaimTime(address account) external view returns (uint256);
}