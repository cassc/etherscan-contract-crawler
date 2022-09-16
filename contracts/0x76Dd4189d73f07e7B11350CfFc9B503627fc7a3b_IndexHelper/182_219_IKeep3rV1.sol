// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// solhint-disable func-name-mixedcase
interface IKeep3rV1 is IERC20, IERC20Metadata {
    // Structs
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    // Events
    event DelegateChanged(address indexed _delegator, address indexed _fromDelegate, address indexed _toDelegate);
    event DelegateVotesChanged(address indexed _delegate, uint256 _previousBalance, uint256 _newBalance);
    event SubmitJob(
        address indexed _job,
        address indexed _liquidity,
        address indexed _provider,
        uint256 _block,
        uint256 _credit
    );
    event ApplyCredit(
        address indexed _job,
        address indexed _liquidity,
        address indexed _provider,
        uint256 _block,
        uint256 _credit
    );
    event RemoveJob(
        address indexed _job,
        address indexed _liquidity,
        address indexed _provider,
        uint256 _block,
        uint256 _credit
    );
    event UnbondJob(
        address indexed _job,
        address indexed _liquidity,
        address indexed _provider,
        uint256 _block,
        uint256 _credit
    );
    event JobAdded(address indexed _job, uint256 _block, address _governance);
    event JobRemoved(address indexed _job, uint256 _block, address _governance);
    event KeeperWorked(
        address indexed _credit,
        address indexed _job,
        address indexed _keeper,
        uint256 _block,
        uint256 _amount
    );
    event KeeperBonding(address indexed _keeper, uint256 _block, uint256 _active, uint256 _bond);
    event KeeperBonded(address indexed _keeper, uint256 _block, uint256 _activated, uint256 _bond);
    event KeeperUnbonding(address indexed _keeper, uint256 _block, uint256 _deactive, uint256 _bond);
    event KeeperUnbound(address indexed _keeper, uint256 _block, uint256 _deactivated, uint256 _bond);
    event KeeperSlashed(address indexed _keeper, address indexed _slasher, uint256 _block, uint256 _slash);
    event KeeperDispute(address indexed _keeper, uint256 _block);
    event KeeperResolved(address indexed _keeper, uint256 _block);
    event TokenCreditAddition(
        address indexed _credit,
        address indexed _job,
        address indexed _creditor,
        uint256 _block,
        uint256 _amount
    );

    // Variables
    function KPRH() external returns (address);

    function delegates(address _delegator) external view returns (address);

    function checkpoints(address _account, uint32 _checkpoint) external view returns (Checkpoint memory);

    function numCheckpoints(address _account) external view returns (uint32);

    function DOMAIN_TYPEHASH() external returns (bytes32);

    function DOMAINSEPARATOR() external returns (bytes32);

    function DELEGATION_TYPEHASH() external returns (bytes32);

    function PERMIT_TYPEHASH() external returns (bytes32);

    function nonces(address _user) external view returns (uint256);

    function BOND() external returns (uint256);

    function UNBOND() external returns (uint256);

    function LIQUIDITYBOND() external returns (uint256);

    function FEE() external returns (uint256);

    function BASE() external returns (uint256);

    function ETH() external returns (address);

    function bondings(address _user, address _bonding) external view returns (uint256);

    function canWithdrawAfter(address _user, address _bonding) external view returns (uint256);

    function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256);

    function pendingbonds(address _keeper, address _bonding) external view returns (uint256);

    function bonds(address _keeper, address _bonding) external view returns (uint256);

    function votes(address _delegator) external view returns (uint256);

    function firstSeen(address _keeper) external view returns (uint256);

    function disputes(address _keeper) external view returns (bool);

    function lastJob(address _keeper) external view returns (uint256);

    function workCompleted(address _keeper) external view returns (uint256);

    function jobs(address _job) external view returns (bool);

    function credits(address _job, address _credit) external view returns (uint256);

    function liquidityProvided(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function liquidityUnbonding(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function liquidityAmountsUnbonding(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function jobProposalDelay(address _job) external view returns (uint256);

    function liquidityApplied(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function liquidityAmount(
        address _provider,
        address _liquidity,
        address _job
    ) external view returns (uint256);

    function keepers(address _keeper) external view returns (bool);

    function blacklist(address _keeper) external view returns (bool);

    function keeperList(uint256 _index) external view returns (address);

    function jobList(uint256 _index) external view returns (address);

    function governance() external returns (address);

    function pendingGovernance() external returns (address);

    function liquidityAccepted(address _liquidity) external view returns (bool);

    function liquidityPairs(uint256 _index) external view returns (address);

    // Methods
    function getCurrentVotes(address _account) external view returns (uint256);

    function addCreditETH(address _job) external payable;

    function addCredit(
        address _credit,
        address _job,
        uint256 _amount
    ) external;

    function addVotes(address _voter, uint256 _amount) external;

    function removeVotes(address _voter, uint256 _amount) external;

    function addKPRCredit(address _job, uint256 _amount) external;

    function approveLiquidity(address _liquidity) external;

    function revokeLiquidity(address _liquidity) external;

    function pairs() external view returns (address[] memory);

    function addLiquidityToJob(
        address _liquidity,
        address _job,
        uint256 _amount
    ) external;

    function applyCreditToJob(
        address _provider,
        address _liquidity,
        address _job
    ) external;

    function unbondLiquidityFromJob(
        address _liquidity,
        address _job,
        uint256 _amount
    ) external;

    function removeLiquidityFromJob(address _liquidity, address _job) external;

    function mint(uint256 _amount) external;

    function burn(uint256 _amount) external;

    function worked(address _keeper) external;

    function receipt(
        address _credit,
        address _keeper,
        uint256 _amount
    ) external;

    function receiptETH(address _keeper, uint256 _amount) external;

    function addJob(address _job) external;

    function getJobs() external view returns (address[] memory);

    function removeJob(address _job) external;

    function setKeep3rHelper(address _keep3rHelper) external;

    function setGovernance(address _governance) external;

    function acceptGovernance() external;

    function isKeeper(address _keeper) external returns (bool);

    function isMinKeeper(
        address _keeper,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age
    ) external returns (bool);

    function isBondedKeeper(
        address _keeper,
        address _bond,
        uint256 _minBond,
        uint256 _earned,
        uint256 _age
    ) external returns (bool);

    function bond(address _bonding, uint256 _amount) external;

    function getKeepers() external view returns (address[] memory);

    function activate(address _bonding) external;

    function unbond(address _bonding, uint256 _amount) external;

    function slash(
        address _bonded,
        address _keeper,
        uint256 _amount
    ) external;

    function withdraw(address _bonding) external;

    function dispute(address _keeper) external;

    function revoke(address _keeper) external;

    function resolve(address _keeper) external;

    function permit(
        address _owner,
        address _spender,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}