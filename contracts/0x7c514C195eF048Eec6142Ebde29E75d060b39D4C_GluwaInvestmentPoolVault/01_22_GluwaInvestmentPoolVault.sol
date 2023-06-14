// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol';

import './libs/GluwaInvestmentModel.sol';
import './abstracts/SignerNonce.sol';
import './abstracts/VaultControl.sol';
import './abstracts/GluwaInvestment.sol';

contract GluwaInvestmentPoolVault is SignerNonce, EIP712Upgradeable, VaultControl, GluwaInvestment {
    bytes32 private constant _CREATEACCOUNT_TYPEHASH =
        keccak256('createAccountBySig(address account,uint256 amount,bytes32 identityHash,bytes32 poolHash,uint256 gluwaNonce)');

    bytes32 private constant _CREATEBALANCE_TYPEHASH = keccak256('createBalanceBySig(address account,uint256 amount,bytes32 poolHash,uint256 gluwaNonce)');

    function initialize(address adminAccount, address token) external initializer {
        _VaultControl_Init(adminAccount);
        _GluwaInvestment_init(token);
    }

    event Withdraw(address indexed beneficiary, uint256 amount);
    event Invest(address indexed recipient, uint256 amount);

    /**
     * @dev allow to get version for EIP712 domain dynamically. We do not need to init EIP712 anymore
     *
     */
    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes(version()));
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain based on token name. We do not need to init EIP712 anymore
     *
     */
    function _EIP712NameHash() internal pure override returns (bytes32) {
        return keccak256(bytes(name()));
    }

    function version() public pure returns (string memory) {
        return '2.0.0';
    }

    function name() public pure returns (string memory) {
        return 'Gluwa-Investor-DAO';
    }

    function updateRewardSettings(
        address rewardToken,
        uint16 rewardOnPrincipal,
        uint16 rewardOnInterest
    ) external onlyOperator returns (bool) {
        _updateRewardSettings(rewardToken, rewardOnPrincipal, rewardOnInterest);
        return true;
    }

    function setAccountState(bytes32 accountHash, GluwaInvestmentModel.AccountState state) external onlyController returns (bool) {
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        require(account.startingDate > 0, 'GluwaInvestmentPoolVault: Invalid hash');
        account.state = state;
        return true;
    }

    function invest(address recipient, uint256 amount) external onlyOperator returns (bool) {
        require(recipient != address(0), 'GluwaInvestmentPoolVault: Recipient address for investment must be defined');
        require(_token.balanceOf(address(this)) >= amount, 'GluwaInvestmentPoolVault: the investment amount must be lower than the contract balance');
        _token.transfer(recipient, amount);
        emit Invest(recipient, amount);
        return true;
    }

    /// @dev The controller creates an account for users, the user need to pay fee for that.
    function createAccount(
        address account,
        uint256 amount,
        uint256 fee,
        bytes32 identityHash,
        bytes32 poolHash
    )
        external
        virtual
        onlyController
        returns (
            bool,
            bytes32,
            bytes32
        )
    {
        return _createAccount(account, amount, fee, uint64(block.timestamp), identityHash, poolHash);
    }

    /// @dev The controller can sign to allow anyone to create an account. The sender will pay for gas
    function createAccountBySig(
        address account,
        uint256 amount,
        bytes32 identityHash,
        bytes32 poolHash,
        uint256 gluwaNonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        virtual
        returns (
            bool,
            bytes32,
            bytes32
        )
    {
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_CREATEACCOUNT_TYPEHASH, account, amount, identityHash, poolHash, gluwaNonce))),
            v,
            r,
            s
        );
        require(isController(signer), 'GluwaInvestment: Unauthorized access');
        _useNonce(signer, gluwaNonce);
        return _createAccount(account, amount, 0, uint64(block.timestamp), identityHash, poolHash);
    }

    /// @dev The controller creates a balance for users, the user need to pay fee for that.
    function createBalance(
        address account,
        uint256 amount,
        uint256 fee,
        bytes32 poolHash
    ) external virtual onlyController returns (bool, bytes32) {
        return (true, _createBalance(account, amount, fee, poolHash));
    }

    /// @dev The controller can sign to allow anyone to create a balance. The sender will pay for gas
    function createBalanceBySig(
        address account,
        uint256 amount,
        bytes32 poolHash,
        uint256 gluwaNonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (bool, bytes32) {
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_CREATEBALANCE_TYPEHASH, account, amount, poolHash, gluwaNonce))),
            v,
            r,
            s
        );
        require(isController(signer), 'GluwaInvestment: Unauthorized access');
        _useNonce(signer, gluwaNonce);
        return (true, _createBalance(account, amount, 0, poolHash));
    }

    function withdrawUnstartedBalances(bytes32[] calldata balanceHashList) external returns (bool) {
        uint256 totalWithdrawal = _withdrawUnstartedBalances(balanceHashList, _msgSender(), 0);
        _token.transfer(_msgSender(), totalWithdrawal);
        emit Withdraw(_msgSender(), totalWithdrawal);
        return true;
    }

    function withdrawUnstartedBalancesFor(
        bytes32[] calldata balanceHashList,
        address account,
        uint256 fee
    ) external onlyController returns (bool) {
        uint256 totalWithdrawal = _withdrawUnstartedBalances(balanceHashList, account, fee);
        _token.transfer(account, totalWithdrawal);
        emit Withdraw(account, totalWithdrawal);
        return true;
    }

    function withdrawUnclaimedMatureBalances(
        bytes32[] calldata balanceHashList,
        address account,
        address recipient,
        uint256 fee
    ) external onlyAdmin {
        require(_token.transfer(recipient, _withdrawBalances(balanceHashList, account, fee)), 'GluwaInvestment: Unable to send amount to withdraw balance');
    }

    function withdrawBalancesFor(
        bytes32[] calldata balanceHashList,
        address ownerAddress,
        uint256 fee
    ) external onlyController returns (bool) {
        require(
            _token.transfer(ownerAddress, _withdrawBalances(balanceHashList, ownerAddress, fee)),
            'GluwaInvestment: Unable to send amount to withdraw balance'
        );
        return true;
    }

    function withdrawBalances(bytes32[] calldata balanceHashList) external returns (bool) {
        require(
            _token.transfer(_msgSender(), _withdrawBalances(balanceHashList, _msgSender(), 0)),
            'GluwaInvestment: Unable to send amount to withdraw balance'
        );
        return true;
    }

    function _withdrawBalances(
        bytes32[] calldata balanceHashList,
        address ownerAddress,
        uint256 fee
    ) internal override(GluwaInvestment) returns (uint256) {
        uint256 totalWithdrawableAmount = super._withdrawBalances(balanceHashList, ownerAddress, fee);
        require(totalWithdrawableAmount > 0, 'GluwaInvestmentPoolVault: No balance is withdrawable');
        emit Withdraw(ownerAddress, totalWithdrawableAmount);
        return totalWithdrawableAmount;
    }

    function createPool(
        uint32 interestRate,
        uint32 tenor,
        uint64 openDate,
        uint64 closeDate,
        uint64 startDate,
        uint128 minimumRaise,
        uint256 maximumRaise
    ) external onlyOperator returns (bytes32) {
        return _createPool(interestRate, tenor, openDate, closeDate, startDate, minimumRaise, maximumRaise);
    }

    function addPoolRepayment(
        address source,
        bytes32 poolHash,
        uint256 amount
    ) external onlyOperator returns (bool) {
        GluwaInvestmentModel.Pool storage pool = _poolStorage[poolHash];

        require(
            amount + pool.totalRepayment <= _calculateTotalExpectedPoolWithdrawal(pool.interestRate, pool.tenor, pool.totalDeposit),
            'GluwaInvestment: Repayment exceeds total expected withdrawal amount'
        );

        require(_token.transferFrom(source, address(this), amount), 'GluwaInvestment: Unable to send for pool repayment');

        unchecked {
            pool.totalRepayment += amount;
        }

        return true;
    }

    function lockPool(bytes32 poolHash) external onlyOperator {
        _lockPool(poolHash);
    }

    function unlockPool(bytes32 poolHash) external onlyOperator {
        _unlockPool(poolHash);
    }

    function cancelPool(bytes32 poolHash) external onlyOperator {
        _cancelPool(poolHash);
    }

    function getAvailableWithdrawalAmount(bytes32 balanceHash) external view returns (uint256) {
        return _getAvailableWithdrawalAmount(balanceHash);
    }

    function getUserBalanceList(address account) external view onlyController returns (uint64[] memory) {
        return _getUserBalanceList(account);
    }

    function getUnstartedBalances(address owner) external view returns (GluwaInvestmentModel.Balance[] memory) {
        require(owner == _msgSender() || isController(_msgSender()), 'GluwaInvestment: Unauthorized access to the balance details');
        return _getUnstartedBalanceList(owner);
    }

    function getMatureBalances(address owner) external view returns (GluwaInvestmentModel.Balance[] memory) {
        require(owner == _msgSender() || isController(_msgSender()), 'GluwaInvestment: Unauthorized access to the balance details');
        return _getMatureBalanceList(owner);
    }

    function getBalance(bytes32 balanceHash)
        external
        view
        returns (
            uint64,
            bytes32,
            bytes32,
            address,
            uint32,
            uint32,
            uint256,
            uint256,
            uint256,
            uint64,
            uint64,
            GluwaInvestmentModel.BalanceState
        )
    {
        GluwaInvestmentModel.Balance storage balance = _balanceStorage[balanceHash];
        require(balance.owner == _msgSender() || isController(_msgSender()), 'GluwaInvestment: Unauthorized access to the balance details');
        GluwaInvestmentModel.BalanceState balanceState = _getBalanceState(balanceHash);
        GluwaInvestmentModel.Pool storage pool = _poolStorage[balance.poolHash];

        return (
            balance.idx,
            balance.accountHash,
            balance.poolHash,
            balance.owner,
            pool.interestRate,
            INTEREST_DENOMINATOR,
            _calculateYield(pool.interestRate, pool.tenor, balance.principal),
            balance.totalWithdrawal,
            balance.principal,
            pool.startingDate,
            pool.startingDate + pool.tenor,
            balanceState
        );
    }

    function getUserAccount(bytes32 accountHash)
        external
        view
        onlyController
        returns (
            uint64,
            uint256,
            uint256,
            GluwaInvestmentModel.AccountState,
            bytes32
        )
    {
        GluwaInvestmentModel.Account storage account = _accountStorage[accountHash];
        return (account.idx, account.totalDeposit, account.startingDate, account.state, account.securityReferenceHash);
    }

    function getAccountFor(address account)
        external
        view
        onlyController
        returns (
            uint64,
            address,
            uint256,
            uint256,
            GluwaInvestmentModel.AccountState,
            bytes32
        )
    {
        return _getAccountFor(account);
    }

    function getAccountHashByIdx(uint64 idx) external view onlyController returns (bytes32) {
        return _getAccountHashByIdx(idx);
    }

    function getBalanceHashByIdx(uint64 idx) external view onlyController returns (bytes32) {
        return _getBalanceHashByIdx(idx);
    }

    uint256[50] private __gap;
}