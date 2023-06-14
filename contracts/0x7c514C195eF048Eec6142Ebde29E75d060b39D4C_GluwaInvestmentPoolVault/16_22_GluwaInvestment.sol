// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './IERC20MintUpgradeable.sol';

import '../libs/GluwaInvestmentModel.sol';
import '../libs/HashMapIndex.sol';
import '../libs/Uint64ArrayUtil.sol';

error AccountIsLocked();

contract GluwaInvestment is ContextUpgradeable {
    using HashMapIndex for HashMapIndex.HashMapping;
    using Uint64ArrayUtil for uint64[];

    uint32 public constant INTEREST_DENOMINATOR = 100_000_000;

    /// @dev The supported token which can be deposited to an account.
    IERC20Upgradeable internal _token;

    /// @dev The reward token which will be sent to users upon balance maturity.
    IERC20MintUpgradeable private _rewardToken;

    uint16 private _rewardOnPrincipal;
    uint16 private _rewardOnInterest;

    HashMapIndex.HashMapping private _poolIndex;
    HashMapIndex.HashMapping private _accountIndex;
    HashMapIndex.HashMapping private _balanceIndex;

    mapping(address => bytes32) private _addressAccountMapping;
    mapping(address => uint64[]) private _addressBalanceMapping;
    mapping(bytes32 => bool) private _usedIdentityHash;
    mapping(bytes32 => uint8) private _poolManualState;

    mapping(bytes32 => bool) internal _balancePrematureClosed;
    mapping(bytes32 => GluwaInvestmentModel.Pool) internal _poolStorage;
    mapping(bytes32 => GluwaInvestmentModel.Account) internal _accountStorage;
    mapping(bytes32 => GluwaInvestmentModel.Balance) internal _balanceStorage;

    event LogPool(bytes32 indexed poolHash);

    event LogAccount(bytes32 indexed accountHash, address indexed owner);

    event LogBalance(bytes32 indexed balanceHash, address indexed owner, uint256 deposit, uint256 fee);

    function _GluwaInvestment_init(address tokenAddress) internal onlyInitializing {
        _token = IERC20Upgradeable(tokenAddress);
    }

    function _updateRewardSettings(
        address rewardToken,
        uint16 rewardOnPrincipal,
        uint16 rewardOnInterest
    ) internal {
        _rewardToken = IERC20MintUpgradeable(rewardToken);
        _rewardOnPrincipal = rewardOnPrincipal;
        _rewardOnInterest = rewardOnInterest;
    }

    function _getAvailableWithdrawalAmount(bytes32 balanceHash) internal view returns (uint256) {
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        GluwaInvestmentModel.Pool storage pool = _poolStorage[balance.poolHash];
        return _calculateAvailableWithdrawalAmount(balance, pool);
    }

    function _getBalanceState(bytes32 balanceHash) internal view returns (GluwaInvestmentModel.BalanceState) {
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        GluwaInvestmentModel.Pool storage pool = _poolStorage[balance.poolHash];
        unchecked {
            if (
                _balancePrematureClosed[balanceHash] ||
                balance.totalWithdrawal == balance.principal + _calculateYield(pool.interestRate, pool.tenor, balance.principal)
            ) {
                return GluwaInvestmentModel.BalanceState.Closed;
            }

            /// @dev pool is mature implies balance is mature but the other direction is not correct as pool can be locked
            if (pool.startingDate + pool.tenor <= block.timestamp) {
                return GluwaInvestmentModel.BalanceState.Mature;
            }

            /// @dev it implies pool.startingDate + pool.tenor > block.timestamp based on the previous if
            if (pool.startingDate <= block.timestamp) {
                return GluwaInvestmentModel.BalanceState.Active;
            }
        }
        return GluwaInvestmentModel.BalanceState.Pending;
    }

    function _getPoolState(bytes32 poolHash) internal view returns (GluwaInvestmentModel.PoolState) {
        unchecked {
            if (_poolManualState[poolHash] > 0) {
                return GluwaInvestmentModel.PoolState(_poolManualState[poolHash]);
            }

            GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];

            if (pool.openingDate > block.timestamp) {
                return GluwaInvestmentModel.PoolState.Scheduled;
            }

            if (pool.minimumRaise > pool.totalDeposit && block.timestamp >= pool.closingDate) {
                return GluwaInvestmentModel.PoolState.Rejected;
            }

            /// @dev pool is mature implies balance is mature but the other direction is not correct as pool can be locked
            if (pool.startingDate + pool.tenor <= block.timestamp) {
                return GluwaInvestmentModel.PoolState.Mature;
            }

            /// @dev it implies pool.startingDate + pool.tenor > block.timestamp based on the previous if
            if (pool.closingDate <= block.timestamp) {
                return GluwaInvestmentModel.PoolState.Closed;
            }

            /// @dev since pool.closingDate > pool.openingDate, therfore this condition implies currentTime < pool.closingDate
            if (pool.openingDate <= block.timestamp) {
                return GluwaInvestmentModel.PoolState.Open;
            }
        }

        return GluwaInvestmentModel.PoolState.Pending;
    }

    /// @dev as it is for a read function, we still return the list of balances when the account is locked so that we can help users to plan for fund retrieval
    function _getUnstartedBalanceList(address owner) internal view returns (GluwaInvestmentModel.Balance[] memory) {
        uint64[] storage balanceIds = _addressBalanceMapping[owner];
        GluwaInvestmentModel.Balance[] memory balanceList = new GluwaInvestmentModel.Balance[](balanceIds.length);
        GluwaInvestmentModel.Balance memory temp;
        GluwaInvestmentModel.PoolState poolStateTemp;
        for (uint256 i; i < balanceIds.length; ) {
            temp = _balanceStorage[_balanceIndex.get(balanceIds[i])];
            poolStateTemp = _getPoolState(temp.poolHash);
            if (
                (poolStateTemp == GluwaInvestmentModel.PoolState.Rejected || poolStateTemp == GluwaInvestmentModel.PoolState.Canceled) &&
                !_balancePrematureClosed[_balanceIndex.get(balanceIds[i])]
            ) {
                balanceList[i] = temp;
            }
            unchecked {
                ++i;
            }
        }
        return balanceList;
    }

    /// @dev as it is for a read function, we still return the list of balances when the account is locked so that we can help users to plan for fund retrieval
    function _getMatureBalanceList(address owner) internal view returns (GluwaInvestmentModel.Balance[] memory) {
        uint64[] storage balanceIds = _addressBalanceMapping[owner];
        GluwaInvestmentModel.Balance[] memory balanceList = new GluwaInvestmentModel.Balance[](balanceIds.length);
        GluwaInvestmentModel.Balance memory temp;
        for (uint256 i; i < balanceIds.length; ) {
            temp = _balanceStorage[_balanceIndex.get(balanceIds[i])];
            if (
                _getBalanceState(_balanceIndex.get(balanceIds[i])) == GluwaInvestmentModel.BalanceState.Mature &&
                _getPoolState(temp.poolHash) == GluwaInvestmentModel.PoolState.Mature
            ) {
                balanceList[i] = temp;
            }
            unchecked {
                ++i;
            }
        }
        return balanceList;
    }

    function getPool(bytes32 poolHash) external view returns (GluwaInvestmentModel.Pool memory, GluwaInvestmentModel.PoolState) {
        return (_poolStorage[poolHash], _getPoolState(poolHash));
    }

    function getAccount()
        external
        view
        returns (
            uint64,
            address,
            uint256,
            uint256,
            GluwaInvestmentModel.AccountState,
            bytes32
        )
    {
        return _getAccountFor(_msgSender());
    }

    function _getUserBalanceList(address account) internal view returns (uint64[] memory) {
        return _addressBalanceMapping[account];
    }

    function _getAccountHashByIdx(uint64 idx) internal view returns (bytes32) {
        return _accountIndex.get(idx);
    }

    function _getBalanceHashByIdx(uint64 idx) internal view returns (bytes32) {
        return _balanceIndex.get(idx);
    }

    function _getAccountFor(address owner)
        internal
        view
        returns (
            uint64,
            address,
            uint256,
            uint256,
            GluwaInvestmentModel.AccountState,
            bytes32
        )
    {
        bytes32 accountHash = _addressAccountMapping[owner];
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        return (account.idx, owner, account.totalDeposit, account.startingDate, account.state, account.securityReferenceHash);
    }

    function _createAccount(
        address owner,
        uint256 initialDeposit,
        uint256 fee,
        uint64 startDate,
        bytes32 identityHash,
        bytes32 poolHash
    )
        internal
        returns (
            bool,
            bytes32,
            bytes32
        )
    {
        require(owner != address(0), 'GluwaInvestment: Account owner address must be defined');

        /// @dev ensure one address only have one account by using account hash (returned by addressAccountMapping[account]) to check
        if (_addressAccountMapping[owner] != 0x0) {
            require(_accountStorage[_addressAccountMapping[owner]].startingDate == 0, 'GluwaInvestment: Each address should have only 1 account only');
        }

        require(_usedIdentityHash[identityHash] == false, 'GluwaInvestment: Identity hash is already used');

        bytes32 accountHash = keccak256(abi.encodePacked('Account', identityHash, owner));

        /// @dev Add the account to the data storage
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        unchecked {
            account.idx = _accountIndex.nextIdx;
            account.startingDate = startDate;
            /// @dev set the account's initial status
            account.state = GluwaInvestmentModel.AccountState.Active;
            account.securityReferenceHash = identityHash;

            _addressAccountMapping[owner] = accountHash;
            _usedIdentityHash[identityHash] = true;
        }
        _accountIndex.add(accountHash);

        emit LogAccount(accountHash, owner);

        return (true, accountHash, _createBalance(owner, initialDeposit, fee, poolHash));
    }

    function _createPool(
        uint32 interestRate,
        uint32 tenor,
        uint64 openDate,
        uint64 closeDate,
        uint64 startDate,
        uint128 minimumRaise,
        uint256 maximumRaise
    ) internal returns (bytes32) {
        require(openDate < closeDate && closeDate < startDate && minimumRaise < maximumRaise, 'GluwaInvestment: Invalid argument value(s)');

        bytes32 poolHash = keccak256(abi.encodePacked(_poolIndex.nextIdx, openDate, closeDate, startDate, interestRate, tenor, minimumRaise, maximumRaise));

        /// @dev Add the pool to the data storage
        GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];
        unchecked {
            pool.idx = _poolIndex.nextIdx;
            pool.interestRate = interestRate;
            pool.tenor = tenor;
            pool.openingDate = openDate;
            pool.closingDate = closeDate;
            pool.startingDate = startDate;
            pool.minimumRaise = minimumRaise;
            pool.maximumRaise = maximumRaise;
        }
        _poolIndex.add(poolHash);

        emit LogPool(poolHash);

        return poolHash;
    }

    function _unlockPool(bytes32 poolHash) internal {
        require(_getPoolState(poolHash) == GluwaInvestmentModel.PoolState.Locked, 'GluwaInvestment: Pool is not locked');
        _poolManualState[poolHash] = 0;
    }

    function _lockPool(bytes32 poolHash) internal {
        require(_poolManualState[poolHash] == 0, 'GluwaInvestment: Cannot lock pool');
        _poolManualState[poolHash] = uint8(GluwaInvestmentModel.PoolState.Locked);
    }

    function _cancelPool(bytes32 poolHash) internal {
        require(_poolStorage[poolHash].startingDate > block.timestamp, 'GluwaInvestment: Cannot cancel the pool');
        _poolManualState[poolHash] = uint8(GluwaInvestmentModel.PoolState.Canceled);
    }

    function _createBalance(
        address owner,
        uint256 deposit,
        uint256 fee,
        bytes32 poolHash
    ) internal returns (bytes32) {
        require(deposit > 0, 'GluwaInvestment: Deposit must be > 0');

        GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];

        require(
            pool.totalDeposit + deposit <= pool.maximumRaise && _getPoolState(poolHash) == GluwaInvestmentModel.PoolState.Open,
            'GluwaInvestment: the pool does not allow more deposit'
        );

        bytes32 balanceHash = keccak256(abi.encodePacked(_balanceIndex.nextIdx, 'Balance', address(this), owner));

        bytes32 hashOfReferenceAccount = _addressAccountMapping[owner];

        require(
            _accountStorage[hashOfReferenceAccount].state == GluwaInvestmentModel.AccountState.Active,
            "GluwaInvestment: The user's account must be active to create more balance"
        );

        require(_token.transferFrom(owner, address(this), deposit + fee), 'GluwaInvestment: Unable to send amount to create balance');

        /// @dev Add the balance to the data storage
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        unchecked {
            balance.idx = _balanceIndex.nextIdx;
            balance.owner = owner;
            balance.principal = deposit;
            balance.accountHash = hashOfReferenceAccount;
            balance.poolHash = poolHash;
            _accountStorage[hashOfReferenceAccount].totalDeposit += deposit;
            pool.totalDeposit += deposit;
        }
        _addressBalanceMapping[owner].add(_balanceIndex.nextIdx);
        _balanceIndex.add(balanceHash);

        _rewardToken.mint(owner, _calculateReward(_rewardOnPrincipal, deposit));

        emit LogBalance(balanceHash, owner, deposit, fee);

        return balanceHash;
    }

    function _withdrawBalances(
        bytes32[] calldata balanceHashList,
        address ownerAddress_,
        uint256 fee
    ) internal virtual returns (uint256 totalWithdrawalAmount) {
        uint256 rewardAmount;
        for (uint256 i; i < balanceHashList.length; ) {
            GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHashList[i]];
            require(balance.owner == ownerAddress_, 'GluwaInvestment: The balance is not owned by the owner');
            unchecked {
                (uint256 totalWithdrawalAmount_, uint256 rewardAmount_) = _withdrawBalance(balance);
                totalWithdrawalAmount += totalWithdrawalAmount_;
                rewardAmount += rewardAmount_;
                ++i;
            }
        }
        unchecked {
            require(totalWithdrawalAmount >= fee, 'GluwaInvestment: The withdrawal amount must be greater than 0');
            totalWithdrawalAmount -= fee;
        }
        if (rewardAmount > 0) _rewardToken.mint(ownerAddress_, rewardAmount);
    }

    function _withdrawUnstartedBalances(
        bytes32[] calldata balanceHashList,
        address ownerAddress_,
        uint256 fee
    ) internal virtual returns (uint256 totalWithdrawalAmount) {
        GluwaInvestmentModel.Account storage account = _accountStorage[_addressAccountMapping[ownerAddress_]];
        if (account.state == GluwaInvestmentModel.AccountState.Locked) {
            revert AccountIsLocked();
        }
        GluwaInvestmentModel.PoolState poolStateTemp;
        for (uint256 i; i < balanceHashList.length; ) {
            GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHashList[i]];
            poolStateTemp = _getPoolState(balance.poolHash);

            require(
                (poolStateTemp == GluwaInvestmentModel.PoolState.Rejected || poolStateTemp == GluwaInvestmentModel.PoolState.Canceled) &&
                    balance.owner == ownerAddress_ &&
                    !_balancePrematureClosed[balanceHashList[i]],
                'GluwaInvestmentPoolVault: Unable to withdraw the balance'
            );
            unchecked {
                _balancePrematureClosed[balanceHashList[i]] = true;
                balance.totalWithdrawal = balance.principal;
                account.totalDeposit -= balance.principal;
                totalWithdrawalAmount += balance.principal;
                ++i;
            }
        }
        totalWithdrawalAmount -= fee;
    }

    function _withdrawBalance(GluwaInvestmentModel.Balance storage balance) private returns (uint256 withdrawalAmount, uint256 rewardAmount) {
        GluwaInvestmentModel.Account storage account = _accountStorage[balance.accountHash];
        if (account.state == GluwaInvestmentModel.AccountState.Locked) {
            revert AccountIsLocked();
        }
        require(_getPoolState(balance.poolHash) != GluwaInvestmentModel.PoolState.Locked,
            'GluwaInvestment: The balance is not avaiable to withdraw'
        );
        GluwaInvestmentModel.Pool storage pool = _poolStorage[balance.poolHash];
        withdrawalAmount = _calculateAvailableWithdrawalAmount(balance, pool);

        unchecked {
            /// @dev Reduce total deposit for the holding account
            if (balance.principal >= balance.totalWithdrawal) {
                if (withdrawalAmount + balance.totalWithdrawal <= balance.principal) {
                    account.totalDeposit -= withdrawalAmount;
                } else {
                    account.totalDeposit -= (balance.principal - balance.totalWithdrawal);
                }
            }

            /// @dev we only give reward when the pool repayment enough to cover more than pricipal amount
            if (_rewardToken != IERC20MintUpgradeable(address(0)) && withdrawalAmount + balance.totalWithdrawal > balance.principal) {
                if (balance.totalWithdrawal <= balance.principal) {
                    rewardAmount = _calculateReward(_rewardOnInterest, withdrawalAmount + balance.totalWithdrawal - balance.principal);
                } else {
                    rewardAmount = _calculateReward(_rewardOnInterest, withdrawalAmount);
                }
            }

            balance.totalWithdrawal += withdrawalAmount;
        }
    }

    /**
     * @return all the contract's settings;.
     */
    function settings()
        external
        view
        returns (
            uint32,
            IERC20Upgradeable,
            IERC20MintUpgradeable,
            uint16,
            uint16
        )
    {
        return (INTEREST_DENOMINATOR, _token, _rewardToken, _rewardOnPrincipal, _rewardOnInterest);
    }

    function _calculateAvailableWithdrawalAmount(GluwaInvestmentModel.Balance memory balance, GluwaInvestmentModel.Pool memory pool) private pure returns (uint256 withdrawalAmount) {
        withdrawalAmount = ((balance.principal + _calculateYield(pool.interestRate, pool.tenor, balance.principal)) * pool.totalRepayment) /
            _calculateTotalExpectedPoolWithdrawal(pool.interestRate, pool.tenor, pool.totalDeposit) -
            balance.totalWithdrawal;
    }

    /// @dev calculate yield for given amount based on term and interest rate.
    function _calculateYield(
        uint32 interestRate,
        uint32 tenor,
        uint256 amount
    ) internal pure returns (uint256) {
        return (amount * uint256(interestRate) * uint256(tenor)) / (uint256(INTEREST_DENOMINATOR) * 365 days);
    }

    /// @dev calculate the total withdrawal amount for a pool
    function _calculateTotalExpectedPoolWithdrawal(
        uint32 interestRate,
        uint32 tenor,
        uint256 poolTotalDeposit
    ) internal pure returns (uint256) {
        return poolTotalDeposit + _calculateYield(interestRate, tenor, poolTotalDeposit);
    }

    /// @dev calculate the reward
    function _calculateReward(uint256 rewardRate, uint256 amount) private pure returns (uint256) {
        return (amount * rewardRate) / 10_000;
    }

    uint256[50] private __gap;
}