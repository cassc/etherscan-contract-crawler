// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

/**
  * @title Liquid staking pool
  *
  * For the high-level description of the pool operation please refer to the paper.
  * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
  * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
  * only a small portion (buffer) of it.
  * It also mints new tokens for rewards generated at the ETH 2.0 side.
  */
interface IKiKiStaking {
    /**
     * @dev From IKiKiStaking interface, because "Interfaces cannot inherit".
     */
    function totalSupply() external view returns (uint256);
    function getTotalShares() external view returns (uint256);

    /**
      * @notice Stop pool routine operations
      */
    function stop() external;

    /**
      * @notice Resume pool routine operations
      */
    function resume() external;

    /**
      * @notice Stops accepting new Ether to the protocol
      *
      * @dev While accepting new Ether is stopped, calls to the `submit` function,
      * as well as to the default payable function, will revert.
      *
      * Emits `StakingPaused` event.
      */
    function pauseStaking() external;


    /**
      * @notice Resumes accepting new Ether to the protocol (if `pauseStaking` was called previously)
      * NB: Staking could be rate-limited by imposing a limit on the stake amount
      * at each moment in time, see `setStakingLimit()` and `removeStakingLimit()`
      *
      * @dev Preserves staking limit if it was set previously
      *
      * Emits `StakingResumed` event
      */
    function resumeStaking() external;

    /**
      * @notice Sets the staking rate limit
      *
      * @dev Reverts if:
      * - `_maxStakeLimit` == 0
      * - `_maxStakeLimit` >= 2^96
      * - `_maxStakeLimit` < `_stakeLimitIncreasePerBlock`
      * - `_maxStakeLimit` / `_stakeLimitIncreasePerBlock` >= 2^32 (only if `_stakeLimitIncreasePerBlock` != 0)
      *
      * Emits `StakingLimitSet` event
      *
      * @param _maxStakeLimit max stake limit value
      * @param _stakeLimitIncreasePerBlock stake limit increase per single block
      */
    function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external;

    /**
      * @notice Removes the staking rate limit
      *
      * Emits `StakingLimitRemoved` event
      */
    function removeStakingLimit() external;

    /**
      * @notice Check staking state: whether it's paused or not
      */
    function isStakingPaused() external view returns (bool);

    /**
      * @notice Returns how much Ether can be staked in the current block
      * @dev Special return values:
      * - 2^256 - 1 if staking is unlimited;
      * - 0 if staking is paused or if limit is exhausted.
      */
    function getCurrentStakeLimit() external view returns (uint256);


    event Stopped();
    event Resumed();

    event StakingPaused();
    event StakingResumed();
    event StakingLimitSet(uint256 maxStakeLimit, uint256 stakeLimitIncreasePerBlock);
    event StakingLimitRemoved();

    /**
      * @notice Set KiKiStaking protocol contracts (oracle, treasury, masterChef).
      * @param _oracle oracle contract
      * @param _treasury treasury contract
      * @param _masterChef masterChef contract
      */
    function setProtocolContracts(
        address _oracle,
        address _treasury,
        address _masterChef
    ) external;

    event ProtocolContractsSet(address oracle, address treasury, address _masterChef);

    /**
      * @notice Set fee rate to `_feeBasisPoints` basis points. The fees are accrued when oracles report staking results
      * @param _feeBasisPoints Fee rate, in basis points
      */
    function setFee(uint16 _feeBasisPoints) external;

    /**
      * @notice Returns staking rewards fee rate
      */
    function getFee() external view returns (uint16 feeBasisPoints);

    event FeeSet(uint16 feeBasisPoints);

    /**
      * @notice Set credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched to `_withdrawalCredentials`
      * @dev Note that setWithdrawalCredentials discards all unused signing keys as the signatures are invalidated.
      * @param _withdrawalCredentials hash of withdrawal multisignature key as accepted by
      *        the deposit_contract.deposit function
      */
    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    /**
      * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
      */
    function getWithdrawalCredentials() external view returns (bytes);


    event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);


    /**
      * @notice Ether on the ETH 2.0 side reported by the oracle
      * @param _beaconValidators Number of KiKiStaking's keys in the beacon state
      * @param _beaconBalance simmarized balance of KiKiStaking-controlled keys in wei
      */
    function handleOracleReport(uint256 _beaconValidators, uint256 _beaconBalance) external;



    // User functions

    /**
      * @notice Adds eth to the pool
      * @return kETH Amount of kETH generated
      */
    function submit(address _referral) external payable returns (uint256 kETH);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);

    // The `_amount` of ether was sent to the deposit_contract.deposit function.
    event Unbuffered(uint256 amount);

    event Stake(bytes pubkey);


    // Requested withdrawal of `etherAmount` to `pubkeyHash` on the ETH 2.0 side, `tokenAmount` burned by `sender`,
    // `sentFromBuffer` was sent on the current Ethereum side.
    event Withdrawal(address indexed sender, uint256 tokenAmount, uint256 sentFromBuffer,
                     bytes32 indexed pubkeyHash, uint256 etherAmount);

    /**
      * @notice Issues swap `_amount` kETH to ETH from liquidity pool, transfer to `to`.
      * @param _amount Amount of kETH to burn
      * @param to Recipient
      */
    function withdraw(uint256 _amount, address to) external;

    // Requested withdraw of `ethAmount`, `kETHAmount` burned by `sender`
    event Withdraw(address sender, address recipient, uint256 ETHOut, uint256 kETHIn);

    // Info functions

    /**
      * @notice Gets the amount of Ether controlled by the system
      */
    function getTotalPooledEther() external view returns (uint256);

    /**
      * @notice Gets the amount of Ether temporary buffered on this contract balance
      */
    function getBufferedEther() external view returns (uint256);

    /**
      * @notice Gets the amount of liquidity pooled ether
      */
    function getLiquidityPooledEther() external view returns (uint256);


    /**
      * @notice Gets the liquidity pool cap
      */
    function getLiquidityPoolCap() external view returns (uint256);

    // todo comment
    function setOracle(address _oracle) external;


    /**
      * @notice Returns the key values related to Beacon-side
      * @return depositedValidators - number of deposited validators
      * @return beaconValidators - number of KiKiStaking's validators visible in the Beacon state, reported by oracles
      * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of KiKiStaking validators)
      */
    function getBeaconStat() external view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance);

    function setLiquidityPoolPercent(uint16 points) external;
    function setLiquidityPoolFeePercent(uint16 minPoints, uint16 maxPoints) external;
    function getLiquidityPoolCapPercent() public view returns (uint16);
    function getLiquidityPoolFeePercent() public view returns (uint16, uint16);
    function getLiquidityPoolFeeByEtherAmount(uint256 etherAmount) public view returns (uint256);
    function getLiquidityPoolFeePointsByEtherAmount(uint256 etherAmount) public view returns (uint16);
}