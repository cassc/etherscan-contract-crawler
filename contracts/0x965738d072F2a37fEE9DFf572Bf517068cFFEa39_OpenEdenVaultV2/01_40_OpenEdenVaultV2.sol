// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IBaseVault.sol";
import "../interfaces/IOpenEdenVault.sol";
import "../interfaces/IKycManager.sol";
import "../ChainlinkAccessor.sol";
import "../DoubleQueueModified.sol";

contract OpenEdenVaultV2 is
    ERC4626Upgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ChainlinkAccessor,
    AccessControl,
    IOpenEdenVault
{
    using MathUpgradeable for uint256;
    using DoubleQueueModified for DoubleQueueModified.BytesDeque;

    DoubleQueueModified.BytesDeque _withdrawalQueue;
    uint256 public _latestOffchainAsset;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 private constant BPSUNIT = 10000;

    uint256 public _minTxsFee;
    address public _oplServiceProvider;

    uint256 public _onchainFee;
    uint256 public _offchainFee;
    uint256 public _epoch;
    address public _treasury;

    IBaseVault public _baseVault;
    IKycManager public _kycManager;
    mapping(address => bool) public _firstDeposit;

    mapping(address => mapping(uint256 => uint256)) _depositAmount; // account => [epoch => depositAmount]
    mapping(address => mapping(uint256 => uint256)) _withdrawAmount; // account => [epoch => depositAmount]

    uint256 counter;

    modifier onlyAdminOrOperator() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                hasRole(OPERATOR_ROLE, _msgSender()),
            "permission denied"
        );
        _;
    }

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyCaller(address receiver) {
        require(_msgSender() == receiver, "receiver must be caller");
        _;
    }

    event FullFill(address _caller);

    function initialize(
        IERC20Upgradeable asset,
        address operator,
        address oplServiceProvider,
        address treasury,
        IBaseVault baseVault,
        IKycManager kycManager,
        address chainlinkToken,
        address chainlinkOracle,
        ChainlinkParameters memory chainlinkParams
    ) external initializer {
        __ERC4626_init(asset);
        __ERC20_init("OpenEden T-Bills", "TBILL");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, operator);

        _oplServiceProvider = oplServiceProvider;
        _treasury = treasury;
        _baseVault = baseVault;
        _kycManager = kycManager;

        super.init(chainlinkParams, chainlinkToken, chainlinkOracle);
        _setMinTxsFee(25 * 10 ** decimals()); // 25USDC
    }

    // pause trading on cut-off time
    function pause() external onlyAdmin {
        _pause();
    }

    // unpause after cut-off time
    function unpause() external onlyAdmin {
        _unpause();
    }

    // set address reveive service fee (only admin)
    function setOplServiceProvider(address opl) external onlyAdmin {
        _oplServiceProvider = opl;
        emit SetOplServiceProvider(opl);
    }

    // set address reveive service fee (only admin)
    function setTreasury(address newAddress) external onlyAdmin {
        _treasury = newAddress;
        emit UpdateTreasury(newAddress);
    }

    /**
     * @dev See {IERC4626-deposit}.
     */
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        override
        onlyCaller(receiver)
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        //! receiver equals to msg.sender, can be ensured by onlyCaller
        _kycManager.onlyKyc(receiver);
        _kycManager.onlyNotBanned(receiver);

        _validateDeposit(assets);
        bytes32 requestId = super._requestTotalOffchainAssets(
            receiver,
            assets,
            Action.DEPOSIT,
            decimals()
        );

        // !PLS NOTED: DEPOSIT WILL BE DONE IN FALLBACK FUNCTION : fulfill
        emit RequestDeposit(receiver, assets, requestId);
        return 0;
    }

    /**
     * @dev See {IERC4626-withdraw}.
     */
    function withdraw(
        uint256 shares,
        address receiver,
        address owner
    )
        public
        override
        onlyCaller(receiver)
        onlyCaller(owner)
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        //! receiver equals to msg.sender, can be ensured by onlyCaller
        _kycManager.onlyKyc(receiver);
        _kycManager.onlyNotBanned(receiver);

        _validateWithdraw(receiver, shares);
        bytes32 requestId = super._requestTotalOffchainAssets(
            receiver,
            shares,
            Action.WITHDRAW,
            decimals()
        );

        // !PLS NOTED: WITHDRAW WILL BE DONE IN FALLBACK FUNCTION : fulfill
        emit RequestWithdraw(receiver, shares, requestId);
        return 0;
    }

    /**
     * @dev See {IERC4626-mint}.
     */
    function mint(uint256, address) public pure override returns (uint256) {
        revert();
    }

    /**
     * @dev See {IERC4626-redeem}.
     */
    function redeem(
        uint256,
        address,
        address
    ) public pure override returns (uint256) {
        revert();
    }

    // called daily
    function requestUpdateEpoch() external onlyAdminOrOperator {
        bytes32 requestId = super._requestTotalOffchainAssets(
            _msgSender(),
            0,
            Action.EPOCH_UPDATE,
            decimals()
        );

        // !PLS NOTED: requestUpdateEpoch WILL BE DONE IN FALLBACK FUNCTION : fulfill
        emit RequestUpdateEpoch(msg.sender, requestId);
    }

    function processWithdrawalQueue() external onlyAdminOrOperator {
        require(!_withdrawalQueue.empty(), "queue is empty");

        bytes32 requestId = super._requestTotalOffchainAssets(
            _msgSender(),
            0,
            Action.WITHDRAW_QUEUE,
            decimals()
        );

        // !PLS NOTED: processWithdrawalQueue WILL BE DONE IN FALLBACK FUNCTION : fulfill
        emit RequestWithdrawalQueue(msg.sender, requestId);
    }

    function txsFee(uint256 assets) public view returns (uint256) {
        uint256 bpsTxsFee = (assets * _baseVault.getTransactionFee()) / BPSUNIT;
        return bpsTxsFee < _minTxsFee ? _minTxsFee : bpsTxsFee;
    }

    // @dev transfer underlying from vault to treasury
    function fundTBillPurchase(
        address underlying,
        uint256 assets
    ) external onlyAdmin {
        require(_treasury != address(0), "invalid treasury");
        require(assets <= totalAssets(), "insufficient amount");
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(underlying),
            _treasury,
            assets
        );
        emit FundTBillPurchase(_treasury, assets);
    }

    function _convertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0)
                ? _initialConvertToAssets(shares, rounding)
                : shares.mulDiv(assetsAvailable(), supply, rounding);
    }

    function _convertToShares(
        uint256 assets,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256 shares) {
        uint256 supply = totalSupply();

        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, assetsAvailable(), rounding);
    }

    function previewDepositCustomize(
        uint256 assets,
        uint256 totalOffchainAsset
    ) public view returns (uint256) {
        //based on _convertToShares
        uint256 supply = totalSupply();
        MathUpgradeable.Rounding rounding = MathUpgradeable.Rounding.Down;

        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(
                    supply,
                    totalOffchainAsset + onchainAssetsAvailable(),
                    rounding
                );
    }

    function previewRedeemCustomize(
        uint256 shares,
        uint256 totalOffchainAsset
    ) public view returns (uint256) {
        // based on _convertToAssets
        uint256 supply = totalSupply();
        MathUpgradeable.Rounding rounding = MathUpgradeable.Rounding.Down;
        return
            (supply == 0)
                ? _initialConvertToAssets(shares, rounding)
                : shares.mulDiv(
                    totalOffchainAsset + onchainAssetsAvailable(),
                    supply,
                    rounding
                );
    }

    function _validateDeposit(uint256 assets) internal view {
        /* gas saving by defining local variable*/
        address sender = _msgSender();

        (uint256 minDeposit, uint256 maxDeposit) = _baseVault
            .getMinMaxDeposit();
        uint256 firstDeposit = _baseVault.getFirstDeposit();

        require(assets <= _getAssetBalance(sender), "insufficient balance");
        require(assets >= minDeposit, "amount lt minimum deposit");
        if (!_firstDeposit[sender]) {
            require(assets >= firstDeposit, "amount lt minimum first deposit");
        }

        (
            uint256 depositAmt,
            uint256 withdrawAmt,
            uint256 gap
        ) = getUserEpochInfo(sender, _epoch);

        if (depositAmt >= withdrawAmt) {
            require(assets <= maxDeposit - gap, "deposit too much 1");
        } else {
            require(assets <= maxDeposit + gap, "deposit too much 2");
        }
    }

    function _processDeposit(
        address investor,
        uint256 assets,
        bytes32 requestId
    ) internal {
        uint256 txFee = txsFee(assets);
        uint256 actualAsset = assets - txFee;
        // console.log("actualAsset:", actualAsset);

        uint256 shares = previewDeposit(actualAsset);
        _deposit(investor, investor, actualAsset, shares);

        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(asset()),
            investor,
            _oplServiceProvider,
            txFee
        );
        if (!_firstDeposit[investor]) {
            _firstDeposit[investor] = true;
        }

        _depositAmount[investor][_epoch] += actualAsset;
        emit ProcessDeposit(
            investor,
            assets,
            shares,
            requestId,
            txFee,
            _oplServiceProvider
        );
    }

    function _processWithdraw(
        address investor,
        uint256 shares,
        bytes32 requestId
    ) internal {
        require(shares <= balanceOf(investor), "insuficient amount");
        uint256 currentFreeAssets = totalAssets();
        uint256 assets = previewRedeem(shares);

        uint256 actualShare = shares;
        uint256 actualAssets = assets;

        // !!asset insufficient
        if (actualAssets > currentFreeAssets) {
            actualAssets = currentFreeAssets;
            actualShare = previewWithdraw(actualAssets);
        }

        if (actualAssets > 0) {
            _withdraw(investor, investor, investor, actualAssets, actualShare);
        }

        // console.log("actualAssets :", actualAssets);
        // console.log("actualShare:", actualShare);

        if (shares > actualShare) {
            _updateQueueWithdrawal(investor, shares - actualShare, requestId);
        }

        _withdrawAmount[investor][_epoch] += assets;
        emit ProcessWithdraw(
            investor,
            assets,
            shares,
            requestId,
            currentFreeAssets,
            actualShare
        );
    }

    function _validateWithdraw(
        address sender,
        uint256 share
    ) internal view virtual {
        require(share <= balanceOf(sender), "withdraw more than balance");
        require(share > 0, "withdraw invalid amount");

        uint256 maxWithdraw = _baseVault.getMaxWithdraw();
        uint256 assets = previewRedeem(share);

        (
            uint256 depositAmt,
            uint256 withdrawAmt,
            uint256 gap
        ) = getUserEpochInfo(sender, _epoch);

        if (depositAmt >= withdrawAmt) {
            require(assets <= maxWithdraw + gap, "withdraw too much 1");
        } else {
            require(assets <= maxWithdraw - gap, "withdraw too much 2");
        }
    }

    function getUserEpochInfo(
        address user,
        uint256 epoch
    )
        public
        view
        returns (uint256 depositAmt, uint256 withdrawAmt, uint256 gap)
    {
        depositAmt = _depositAmount[user][epoch];
        withdrawAmt = _withdrawAmount[user][epoch];

        gap = depositAmt >= withdrawAmt
            ? depositAmt - withdrawAmt
            : withdrawAmt - depositAmt;

        return (depositAmt, withdrawAmt, gap);
    }

    function getWithdrawalQueueInfo(
        uint256 index
    ) external view returns (address investor, uint256 shares) {
        if (_withdrawalQueue.empty() || index > _withdrawalQueue.length() - 1) {
            return (address(0), 0);
        }

        bytes memory data = bytes(_withdrawalQueue.at(index));
        (investor, shares) = abi.decode(data, (address, uint256));
    }

    function getWithdrawalQueueLength() external view returns (uint256) {
        return _withdrawalQueue.length();
    }

    function setMinTxsFee(uint256 newValue) external onlyAdminOrOperator {
        _setMinTxsFee(newValue);
    }

    function _setMinTxsFee(uint256 newValue) internal {
        _minTxsFee = newValue;
        emit UpdateMinTxsFee(newValue);
    }

    /// @dev save invstor and shres in bytes whenever a user's withdraw operation is held
    /// @param investor withdraw user
    /// @param shares the amount of assets in shares
    /// @param requestId requestId in chainlinkAccessor
    function _updateQueueWithdrawal(
        address investor,
        uint256 shares,
        bytes32 requestId
    ) internal {
        bytes memory data = abi.encode(investor, shares);
        _withdrawalQueue.pushBack(data);
        _transfer(investor, address(this), shares);
        emit UpdateQueueWithdrawal(investor, shares, requestId);
    }

    function _processWithdrawalQueue(bytes32 requestId) internal {
        for (; !_withdrawalQueue.empty(); ) {
            bytes memory data = _withdrawalQueue.front();
            (address investor, uint256 shares) = abi.decode(
                data,
                (address, uint256)
            );

            uint256 assets = previewRedeem(shares);

            /* we allow users to drain this vault by design*/
            if (assets > totalAssets()) {
                return;
            }

            _withdrawalQueue.popFront();
            super._withdraw(
                address(this),
                investor,
                address(this),
                assets,
                shares
            );

            emit ProcessWithdrawalQueue(investor, assets, shares, requestId);
        }
    }

    function _updateEpochData(bytes32 requestId) internal {
        _epoch++;

        (uint256 onchainFeeRate, uint256 offchainFeeRate) = _baseVault
            .getOnchainAndOffChainServiceFeeRate();

        _onchainFee += _getServiceFee(onchainAssetsAvailable(), onchainFeeRate);
        _offchainFee += _getServiceFee(_latestOffchainAsset, offchainFeeRate);

        emit UpdateEpochData(_onchainFee, _offchainFee, _epoch, requestId);
    }

    function _getServiceFee(
        uint256 assets,
        uint256 rate
    ) internal pure returns (uint256 fee) {
        return (assets * rate) / (365 * BPSUNIT);
    }

    function claimOnchainServiceFee(uint256 amount) public onlyAdmin {
        require(_oplServiceProvider != address(0), "invalid opl address");

        _onchainFee -= amount;
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(asset()),
            _oplServiceProvider,
            amount
        );
        emit ClaimOnchainServiceFee(msg.sender, _oplServiceProvider, amount);
    }

    function claimOffchainServiceFee(uint256 amount) public onlyAdmin {
        require(_oplServiceProvider != address(0), "invalid opl address");

        _offchainFee -= amount;
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(asset()),
            _oplServiceProvider,
            amount
        );
        emit ClaimOffchainServiceFee(msg.sender, _oplServiceProvider, amount);
    }

    /*
     * @dev will be called during: transfer transferFrom mint burn
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal view override {
        /* _mint() or _burn() will set one of to address(0)
         *  no need to limit for these scenarios
         */
        if (from == address(0) || to == address(0)) {
            return;
        }

        _kycManager.onlyNotBanned(from);
        _kycManager.onlyNotBanned(to);

        if (_kycManager.isStrict()) {
            _kycManager.onlyKyc(from);
            _kycManager.onlyKyc(to);
        } else if (_kycManager.isUSKyc(from)) {
            _kycManager.onlyKyc(to);
        }
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }

    /**
     * function totalAssets(): return the amount of onchain assets, including claimable txfee.
     * function onchainAssetsAvailable(): return the amount of onchain assets (decduct the txfee).
     * function assetsAvailable(): return the amount of onchain + offchain (decduct the txfee).
     */

    function assetsAvailable() public view returns (uint256 assetAmt) {
        assetAmt = _latestOffchainAsset + onchainAssetsAvailable();
    }

    function onchainAssetsAvailable() public view returns (uint256 assetAmt) {
        assetAmt = totalAssets() - _onchainFee - _offchainFee;
    }

    function fulfill(
        bytes32 requestId,
        uint256 totalOffChainAssets
    ) external recordChainlinkFulfillment(requestId) {
        emit FullFill(msg.sender);
        // console.log("fulfill hit");
        // console.logBytes32(requestId);
        _latestOffchainAsset = totalOffChainAssets;

        (address investor, uint256 amount, Action action) = super
            .getRequestData(requestId);

        if (action == Action.DEPOSIT) {
            _processDeposit(investor, amount, requestId);
        } else if (action == Action.WITHDRAW) {
            _processWithdraw(investor, amount, requestId);
        } else if (action == Action.WITHDRAW_QUEUE) {
            _processWithdrawalQueue(requestId);
        } else if (action == Action.EPOCH_UPDATE) {
            _updateEpochData(requestId);
        }
        emit Fulfill(
            investor,
            requestId,
            totalOffChainAssets,
            amount,
            uint8(action)
        );
    }

    function _getAssetBalance(address addr) internal view returns (uint256) {
        return IERC20Upgradeable(asset()).balanceOf(addr);
    }

    /*//////////////////////////////////////////////////////////////
                 PART1: IMPLEMENTATION FOR CHAINKACCESSOR
    //////////////////////////////////////////////////////////////*/

    function setChainlinkOracleAddress(
        address newAddress
    ) external override onlyAdminOrOperator {
        super._setChainlinkOracleAddress(newAddress);
    }

    function setChainlinkFee(
        uint256 fee
    ) external override onlyAdminOrOperator {
        super._setChainlinkFee(fee);
    }

    function setChainlinkJobId(
        bytes32 jobId
    ) external override onlyAdminOrOperator {
        super._setChainlinkJobId(jobId);
    }

    function setChainlinkURLData(
        string memory url
    ) external override onlyAdminOrOperator {
        super._setChainlinkURLData(url);
    }

    function setPathToOffchainAssets(
        string memory path
    ) external override onlyAdminOrOperator {
        super._setPathToOffchainAssets(path);
    }

    function setPathToTotalOffchainAssetAtLastClose(
        string memory path
    ) external override onlyAdminOrOperator {
        super._setPathToTotalOffchainAssetAtLastClose(path);
    }

    function setCounter(uint256 newCounter) external {
        counter = newCounter;
    }

    function getCounter() external view returns (uint256) {
        return counter;
    }
}