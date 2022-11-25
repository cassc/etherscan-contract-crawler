// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./interfaces/IMellowMultiVaultRouter.sol";
import "./interfaces/IERC20RootVault.sol";
import "./storages/MellowMultiVaultRouterStorage.sol";
import "./libraries/SafeTransferLib.sol";
import "./libraries/FullMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MellowMultiVaultRouter is
    IMellowMultiVaultRouter,
    MellowMultiVaultRouterStorage,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeTransferLib for IERC20Minimal;
    using SafeTransferLib for IWETH;

    uint256 constant WEIGHT_SUM = 100;

    // -------------------  INITIALIZER  -------------------

    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // To authorize the owner to upgrade the contract we implement _authorizeUpgrade with the onlyOwner modifier.
    // ref: https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        IWETH weth_,
        IERC20Minimal token_,
        IERC20RootVault[] memory vaults_
    ) external override initializer {
        require(vaults_.length > 0, "empty vaults");

        _weth = weth_;
        _token = token_;

        for (uint256 i = 0; i < vaults_.length; i++) {
            _addVault(vaults_[i]);
        }

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // -------------------  GETTERS -------------------

    function weth() external view override returns (IWETH) {
        return _weth;
    }

    function token() external view override returns (IERC20Minimal) {
        return _token;
    }

    function getBatchedDeposits(uint256 index)
        external
        view
        override
        returns (BatchedDeposit[] memory)
    {
        if (index >= _vaults.length) {
            BatchedDeposit[] memory emptyDeposits = new BatchedDeposit[](0);
            return emptyDeposits;
        }

        BatchedDeposits storage batchedDeposits = _batchedDeposits[index];

        uint256 activeDeposits = batchedDeposits.size - batchedDeposits.current;
        BatchedDeposit[] memory deposits = new BatchedDeposit[](activeDeposits);

        for (uint256 i = 0; i < activeDeposits; i++) {
            deposits[i] = batchedDeposits.batch[i + batchedDeposits.current];
        }

        return deposits;
    }

    function getLPTokenBalances(address owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_vaults.length);

        for (uint256 i = 0; i < _vaults.length; i++) {
            balances[i] = _managedLpTokens[owner][i];
        }

        return balances;
    }

    function getVaults()
        external
        view
        override
        returns (IERC20RootVault[] memory)
    {
        return _vaults;
    }

    function isVaultDeprecated(uint256 index) external view override returns(bool) {
        return _isVaultDeprecated[index];
    }

    // -------------------  CHECKS  -------------------

    function validWeights(uint256[] memory weights)
        public
        view
        override
        returns (bool)
    {
        if (weights.length != _vaults.length) {
            return false;
        }

        uint256 sum = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            if (_isVaultDeprecated[i] && weights[i] > 0) {
                return false;
            }
            sum += weights[i];
        }

        return sum == WEIGHT_SUM;
    }

    // -------------------  INTERNAL  -------------------

    function _addVault(IERC20RootVault vault_) internal {
        for (uint256 i = 0; i < _vaults.length; i++) {
            require(
                _batchedDeposits[i].current == _batchedDeposits[i].size,
                "batch non-empty"
            );
        }

        address[] memory vaultTokens = vault_.vaultTokens();
        require(
            vaultTokens.length == 1 && vaultTokens[0] == address(_token),
            "invalid vault"
        );

        _vaults.push(vault_);
        _token.safeIncreaseAllowanceTo(address(vault_), type(uint256).max);
    }

    function _trackDeposit(
        address author,
        uint256 amount,
        uint256[] memory weights
    ) internal {
        require(validWeights(weights), "invalid weights");

        for (uint256 i = 0; i < _vaults.length; i++) {
            uint256 weightedAmount = FullMath.mulDiv(
                amount,
                weights[i],
                WEIGHT_SUM
            );

            if (weightedAmount > 0) {
                BatchedDeposit memory instance = BatchedDeposit({
                    author: author,
                    amount: weightedAmount
                });

                _batchedDeposits[i].batch[_batchedDeposits[i].size] = instance;
                _batchedDeposits[i].size += 1;
            }
        }
    }

    // -------------------  SETTERS  -------------------

    function addVault(IERC20RootVault vault_) external override onlyOwner {
        _addVault(vault_);
    }

    function deprecateVault(uint256 index) external override onlyOwner {
        require(index < _vaults.length, "invalid index");
        require(!_isVaultDeprecated[index], "already deprecated");
        require(
            _batchedDeposits[index].current == _batchedDeposits[index].size,
            "batch non-empty"
        );

        _isVaultDeprecated[index] = true;
    }

    function reactivateVault(uint256 index) external override onlyOwner {
        require(index < _vaults.length, "invalid index");
        require(_isVaultDeprecated[index], "already active");
        require(
            _batchedDeposits[index].current == _batchedDeposits[index].size,
            "batch non-empty"
        );
        
        _isVaultDeprecated[index] = false;
    }

    // -------------------  DEPOSITS  -------------------

    function depositEth(uint256[] memory weights) public payable override {
        require(address(_token) == address(_weth), "only ETH vaults");
        require(msg.value > 0, "only deposit");

        // 1. Wrap the ETH into WETH
        uint256 ethPassed = msg.value;
        _weth.deposit{value: ethPassed}();

        // 2. Track the deposit
        _trackDeposit(msg.sender, ethPassed, weights);
    }

    function depositErc20(uint256 amount, uint256[] memory weights)
        public
        override
    {
        require(amount > 0, "only deposit");

        // 1. Send the funds from the user to the router
        IERC20Minimal(_token).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        // 2. Track the deposit
        _trackDeposit(msg.sender, amount, weights);
    }

    // -------------------  BATCH PUSH  -------------------

    function submitBatch(uint256 index, uint256 batchSize) external override {
        BatchedDeposits storage batchedDeposits = _batchedDeposits[index];
        IERC20RootVault vault = _vaults[index];

        uint256 remainingDeposits = batchedDeposits.size -
            batchedDeposits.current;

        // 1. Get the full size if batch size is 0 or more than neccessary
        if (batchSize == 0 || batchSize > remainingDeposits) {
            batchSize = remainingDeposits;
        }

        // 2. Set the local variables
        BatchedDeposit[] memory deposits = new BatchedDeposit[](batchSize);

        // 3. Get the target deposits and aggregate the funds to push
        uint256 fundsToPush = 0;
        for (uint256 i = 0; i < batchSize; i += 1) {
            deposits[i] = batchedDeposits.batch[i + batchedDeposits.current];

            fundsToPush += deposits[i].amount;
        }

        if (fundsToPush > 0) {
            // 4. Distribute the funds to the vaults according to their weights
            uint256 deltaLpTokens = vault.balanceOf(address(this));

            uint256[] memory tokenAmounts = new uint256[](1);
            tokenAmounts[0] = fundsToPush;

            // Deposit to Mellow
            vault.deposit(tokenAmounts, 0, "");

            // Track the delta lp tokens
            deltaLpTokens = vault.balanceOf(address(this)) - deltaLpTokens;

            // 5. Calculate and manage how many LP tokens each user gets
            for (
                uint256 batchIndex = 0;
                batchIndex < batchSize;
                batchIndex += 1
            ) {
                uint256 share = FullMath.mulDiv(
                    deltaLpTokens,
                    deposits[batchIndex].amount,
                    fundsToPush
                );

                _managedLpTokens[deposits[batchIndex].author][index] += share;
            }
        }

        // 6. Advance the iterator
        batchedDeposits.current += batchSize;
    }

    // -------------------  WITHDRAWALS  -------------------

    function claimLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions
    ) external override {
        require(index < _vaults.length, "invalid index");

        uint256 balance = _managedLpTokens[msg.sender][index];

        uint256 deltaLpTokens = _vaults[index].balanceOf(address(this));
        _vaults[index].withdraw(
            msg.sender,
            balance,
            minTokenAmounts,
            vaultsOptions
        );

        deltaLpTokens = deltaLpTokens - _vaults[index].balanceOf(address(this));
        _managedLpTokens[msg.sender][index] -= deltaLpTokens;
    }

    function rolloverLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions,
        uint256[] memory weights
    ) external override {
        require(index < _vaults.length, "invalid index");

        uint256 balance = _managedLpTokens[msg.sender][index];
        uint256 deltaLpTokens = _vaults[index].balanceOf(address(this));

        uint256[] memory actualTokenAmounts = _vaults[index].withdraw(
            address(this),
            balance,
            minTokenAmounts,
            vaultsOptions
        );

        deltaLpTokens = deltaLpTokens - _vaults[index].balanceOf(address(this));
        _managedLpTokens[msg.sender][index] -= deltaLpTokens;

        _trackDeposit(msg.sender, actualTokenAmounts[0], weights);
    }
}