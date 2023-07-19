// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface IVault {
    function admin() external view returns (address);

    function controller() external view returns (address);

    function timeLock() external view returns (address);

    function token() external view returns (address);

    function strategy() external view returns (address);

    function strategies(address _strategy) external view returns (bool);

    function reserveMin() external view returns (uint);

    function withdrawFee() external view returns (uint);

    function paused() external view returns (bool);

    function whitelist(address _addr) external view returns (bool);

    function setWhitelist(address _addr, bool _approve) external;

    function setAdmin(address _admin) external;

    function setController(address _controller) external;

    function setTimeLock(address _timeLock) external;

    function setPause(bool _paused) external;

    function setReserveMin(uint _reserveMin) external;

    function setWithdrawFee(uint _fee) external;

    /*
    @notice Returns the amount of token in the vault
    */
    function balanceInVault() external view returns (uint);

    /*
    @notice Returns the estimate amount of token in strategy
    @dev Output may vary depending on price of liquidity provider token
         where the underlying token is invested
    */
    function balanceInStrategy() external view returns (uint);

    /*
    @notice Returns amount of tokens invested strategy
    */
    function totalDebtInStrategy() external view returns (uint);

    /*
    @notice Returns the total amount of token in vault + total debt
    */
    function totalAssets() external view returns (uint);

    /*
    @notice Returns minimum amount of tokens that should be kept in vault for
            cheap withdraw
    @return Reserve amount
    */
    function minReserve() external view returns (uint);

    /*
    @notice Returns the amount of tokens available to be invested
    */
    function availableToInvest() external view returns (uint);

    /*
    @notice Approve strategy
    @param _strategy Address of strategy
    */
    function approveStrategy(address _strategy) external;

    /*
    @notice Revoke strategy
    @param _strategy Address of strategy
    */
    function revokeStrategy(address _strategy) external;

    /*
    @notice Set strategy
    @param _min Minimum undelying token current strategy must return. Prevents slippage
    */
    function setStrategy(address _strategy, uint _min) external;

    /*
    @notice Transfers token in vault to strategy
    */
    function invest() external;

    /*
    @notice Deposit undelying token into this vault
    @param _amount Amount of token to deposit
    */
    function deposit(uint _amount) external;

    /*
    @notice Calculate amount of token that can be withdrawn
    @param _shares Amount of shares
    @return Amount of token that can be withdrawn
    */
    function getExpectedReturn(uint _shares) external view returns (uint);

    /*
    @notice Withdraw token
    @param _shares Amount of shares to burn
    @param _min Minimum amount of token expected to return
    */
    function withdraw(uint _shares, uint _min) external;

    /*
    @notice Transfer token in vault to admin
    @param _token Address of token to transfer
    @dev _token must not be equal to vault token
    */
    function sweep(address _token) external;
}