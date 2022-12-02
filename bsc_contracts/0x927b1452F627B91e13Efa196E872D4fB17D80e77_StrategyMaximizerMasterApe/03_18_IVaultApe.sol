// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVaultApe {
    struct PoolInfo {
        IERC20 want; // Address of the want token.
        address strat; // Strategy address that will auto compound want tokens
    }

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256 shares);

    function poolLength() external view returns (uint256);

    function addPool(address _strat) external;

    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function deposit(
        uint256 _pid,
        uint256 _wantAmt,
        address _to
    ) external;

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(
        uint256 _pid,
        uint256 _wantAmt,
        address _to
    ) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function withdrawAll(uint256 _pid) external;

    function earnAll() external;

    function earnSome(uint256[] memory pids) external;

    function resetAllowances() external;

    function resetSingleAllowance(uint256 _pid) external;
}