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

    event Deposit(
        uint256 indexed _pid,
        address indexed _sender,
        uint256 _amount
    );
    event Withdraw(
        uint256 indexed _pid,
        address indexed _sender,
        uint256 _shares
    );
    event Claim(address indexed _sender, uint256 _reward, ClaimOption _option);

    event BorrowForDeposit(
        uint256 indexed _pid,
        address _sender,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    );

    event RepayBorrow(address indexed _sender, bytes32 _lendingId);
    event Harvest(
        uint256 _rewards,
        uint256 _accRewardPerSharem,
        uint256 _totalShare
    );

    // event UpdateWithdrawalFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
    // event UpdatePlatformFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
    // event UpdateHarvestBountyPercentage(uint256 indexed _pid, uint256 _percentage);
    // event UpdatePlatform(address indexed _platform);
    event UpdateZap(address indexed _swap);
    event AddPool(
        uint256 indexed _pid,
        uint256 _lendingMarketPid,
        uint256 _convexPid,
        address _lpToken
    );
    event PausePoolDeposit(uint256 indexed _pid, bool _status);
    event PausePoolWithdraw(uint256 indexed _pid, bool _status);
    event AddLiquidity();

    // function pendingReward(uint256 _pid, address _account) external view returns (uint256);

    // function pendingRewardAll(address _account) external view returns (uint256);

    // function deposit(uint256 _pid, uint256 _amount) external returns (uint256);

    // function depositAll(uint256 _pid) external returns (uint256);

    // function withdrawAndClaim(
    //   uint256 _pid,
    //   uint256 _shares,
    //   uint256 _minOut,
    //   ClaimOption _option
    // ) external returns (uint256, uint256);

    // function withdrawAllAndClaim(
    //   uint256 _pid,
    //   uint256 _minOut,
    //   ClaimOption _option
    // ) external returns (uint256, uint256);

    // function claim(
    //   uint256 _pid,
    //   uint256 _minOut,
    //   ClaimOption _option
    // ) external returns (uint256);

    // function claimAll(uint256 _minOut, ClaimOption _option) external returns (uint256);

    // function harvest(
    //   uint256 _pid,
    //   address _recipient,
    //   uint256 _minimumOut
    // ) external returns (uint256);
}