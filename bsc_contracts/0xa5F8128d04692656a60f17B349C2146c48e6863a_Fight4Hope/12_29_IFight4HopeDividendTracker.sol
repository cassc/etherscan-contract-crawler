// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./token/interfaces/IBEP20.sol";
import "./token/interfaces/IDividendPayingTokenInterface.sol";
import "./token/interfaces/IDividendPayingTokenOptionalInterface.sol";
import "./token/interfaces/IERC20TokenRecover.sol";

interface IFight4HopeDividendTracker is
    IBEP20,
    IDividendPayingTokenInterface,
    IDividendPayingTokenOptionalInterface,
    IERC20TokenRecover
{
    function lastProcessedIndex() external view returns (uint256);

    function excludedFromDividends(address account) external view returns (bool);

    function lastClaimTimes(address account) external view returns (uint256);

    function deployer() external view returns (address);

    function claimWait() external view returns (uint256);

    function minimumTokenBalanceForDividends() external view returns (uint256);

    event ExcludeFromDividends(address indexed account);
    event IncludedInDividends(address indexed account);

    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    function excludeFromDividends(address account) external;

    function includeInDividends(address account) external;

    function updateClaimWait(uint256 newClaimWait) external;

    function updateMinTokenBalance(uint256 minTokens) external;

    function getLastProcessedIndex() external view returns (uint256);

    function getNumberOfTokenHolders() external view returns (uint256);

    function getAccount(address _account)
        external
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        );

    function getAccountAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function ensureBalance(bool _process) external;

    function ensureBalanceForUsers(address payable[] memory accounts, bool _process) external;

    function ensureBalanceForUser(address payable account, bool _process) external;

    function setBalance(address payable account, uint256 newBalance) external;

    function process(uint256 gas)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function processAccount(address payable account, bool automatic) external returns (bool);
}