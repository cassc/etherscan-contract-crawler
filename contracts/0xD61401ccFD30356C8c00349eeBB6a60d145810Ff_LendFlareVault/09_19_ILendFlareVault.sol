// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ILendFlareVault {
    enum ClaimOption {
        None,
        Claim,
        ClaimAsCvxCRV,
        ClaimAsCRV,
        ClaimAsCVX,
        ClaimAsETH
    }

    event Deposit(uint256 indexed _pid, address indexed _sender, uint256 _amount);
    event Withdraw(uint256 indexed _pid, address indexed _sender, uint256 _shares);
    event Claim(address indexed _sender, uint256 _reward, ClaimOption _option);
    event BorrowForDeposit(uint256 indexed _pid, bytes32 _lendingId, address _sender, uint256 _token0, uint256 _borrowBlock, uint256 _supportPid);
    event RepayBorrow(address indexed _sender, bytes32 _lendingId);
    event Harvest(uint256 _rewards, uint256 _accRewardPerSharem, uint256 _totalShare);
    event UpdateZap(address indexed _swap);
    event AddPool(uint256 indexed _pid, uint256 _lendingMarketPid, uint256 _convexPid, address _lpToken);
    event PausePoolDeposit(uint256 indexed _pid, bool _status);
    event PausePoolWithdraw(uint256 indexed _pid, bool _status);
    event AddLiquidity(uint256 _pid, address _underlyToken, address _lpToken, uint256 _tokens);
    event Liquidate(bytes32 _lendingId, uint256 _extraErc20Amount);
}