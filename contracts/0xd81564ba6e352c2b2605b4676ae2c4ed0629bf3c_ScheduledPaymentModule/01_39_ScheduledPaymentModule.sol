// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IExchange.sol";
import "./utils/BokkyPooBahsDateTimeLibrary.sol";
import "./utils/Decimal.sol";

contract ScheduledPaymentModule is Module {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using SafeMathUpgradeable for uint256;

    event ScheduledPaymentModuleSetup(
        address indexed initiator,
        address indexed owner,
        address indexed avatar,
        address[] avatarOwners,
        address target,
        address config,
        address exchange,
        address moduleAddress
    );
    event PaymentScheduled(bytes32 spHash);
    event ScheduledPaymentCancelled(bytes32 spHash);
    event ScheduledPaymentExecuted(bytes32 spHash);
    event ConfigSet(address config);

    error AlreadyScheduled(bytes32 spHash);
    error UnknownHash(bytes32 spHash);
    error InvalidPeriod(bytes32 spHash);
    error ExceedMaxGasPrice(bytes32 spHash);
    error PaymentExecutionFailed(bytes32 spHash);
    error OutOfGas(bytes32 spHash, uint256 gasUsed);
    error GasEstimation(uint256 gas);

    struct Fee {
        Decimal.D256 fixedUSD;
        Decimal.D256 percentage;
    }

    bytes4 public constant TRANSFER =
        bytes4(keccak256("transfer(address,uint256)"));

    address public config;
    address public exchange;
    EnumerableSetUpgradeable.Bytes32Set private spHashes;
    //Mapping RSP hash to last paid at
    mapping(bytes32 => uint256) public lastPaidAt;

    modifier onlyAvatar() {
        require(msg.sender == avatar, "caller is not the right avatar");
        _;
    }

    modifier onlyCrank() {
        require(
            msg.sender == IConfig(config).crankAddress(),
            "caller is not a crank"
        );
        _;
    }

    constructor(
        address _owner,
        address _avatar,
        address[] memory _avatarOwners,
        address _target,
        address _config,
        address _exchange
    ) {
        bytes memory initParams = abi.encode(
            _owner,
            _avatar,
            _avatarOwners,
            _target,
            _config,
            _exchange
        );
        setUp(initParams);
    }

    function setUp(bytes memory initParams) public override initializer {
        (
            address _owner,
            address payable _avatar,
            address[] memory _avatarOwners,
            address _target,
            address _config,
            address _exchange
        ) = abi.decode(
                initParams,
                (address, address, address[], address, address, address)
            );
        __Ownable_init();
        require(_avatar != address(0), "Avatar can not be zero address");
        require(_target != address(0), "Target can not be zero address");

        avatar = _avatar;
        target = _target;
        config = _config;
        exchange = _exchange;
        transferOwnership(_owner);

        emit ScheduledPaymentModuleSetup(
            msg.sender,
            _owner,
            _avatar,
            _avatarOwners.length > 0
                ? _avatarOwners
                : GnosisSafe(_avatar).getOwners(),
            _target,
            _config,
            _exchange,
            address(this)
        );
    }

    function schedulePayment(bytes32 spHash) external onlyAvatar {
        if (spHashes.contains(spHash)) revert AlreadyScheduled(spHash);

        spHashes.add(spHash);
        emit PaymentScheduled(spHash);
    }

    function cancelScheduledPayment(bytes32 spHash) external onlyAvatar {
        if (!spHashes.contains(spHash)) revert UnknownHash(spHash);

        spHashes.remove(spHash);
        emit ScheduledPaymentCancelled(spHash);
    }

    // Execute scheduled one-time payment
    function executeScheduledPayment(
        address token,
        uint256 amount,
        address payee,
        Fee calldata fee,
        uint256 executionGas,
        uint256 maxGasPrice,
        address gasToken,
        string memory salt,
        uint256 payAt,
        uint256 gasPrice
    ) external onlyCrank {
        uint256 startGas = gasleft();
        bytes32 spHash = createSpHash(
            token,
            amount,
            payee,
            fee,
            executionGas,
            maxGasPrice,
            gasToken,
            salt,
            payAt
        );

        if (!spHashes.contains(spHash)) revert UnknownHash(spHash);

        // Referring to the block's timestamp is susceptible to manipulation by miners, but
        // nothing critical will happen if the timestamp is manipulated. The worst case is that the off-chain caller (crank) will
        // have to pay for the gas of the reverted transaction.
        if (block.timestamp > payAt.add(IConfig(config).validForSeconds()))
            revert InvalidPeriod(spHash);

        if (gasPrice > maxGasPrice) revert ExceedMaxGasPrice(spHash);
        if (
            !_executeOneTimePayment(
                spHash,
                token,
                amount,
                payee,
                fee,
                executionGas,
                gasToken,
                gasPrice
            )
        ) revert PaymentExecutionFailed(spHash);

        uint256 gasUsed = startGas - gasleft();
        if (gasUsed > executionGas) revert OutOfGas(spHash, gasUsed);
    }

    // Estimate scheduled one-time payment execution
    function estimateExecutionGas(
        address token,
        uint256 amount,
        address payee,
        Fee calldata fee,
        uint256 maxGasPrice,
        address gasToken,
        string memory salt,
        uint256 payAt,
        uint256 gasPrice
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // This executionGas calculation only for estimation purpose
        // 32000 base cost, base transfer cost, etc
        // 1500 keccak hash cost
        // 95225  standard 2x ERC20 transfer cost
        // 2500 emit event cost
        uint256 executionGas = 32000 + 1500 + 95225 + 2500;
        bytes32 spHash = createSpHash(
            token,
            amount,
            payee,
            fee,
            executionGas,
            maxGasPrice,
            gasToken,
            salt,
            payAt
        );

        // We don't provide an error message here, as we use it to return the estimate
        require(
            _executeOneTimePayment(
                spHash,
                token,
                amount,
                payee,
                fee,
                executionGas,
                gasToken,
                gasPrice
            )
        );

        // 3500 required checks cost
        // 9500 remove value from set cost
        // 500 other cost
        uint256 requiredGas = startGas - gasleft() + 9500 + 3500 + 500;
        // Return gas estimation result via error message
        revert GasEstimation(requiredGas);
    }

    // Execute scheduled recurring payment
    function executeScheduledPayment(
        address token,
        uint256 amount,
        address payee,
        Fee calldata fee,
        uint256 executionGas,
        uint256 maxGasPrice,
        address gasToken,
        string memory salt,
        uint256 recursDayOfMonth,
        uint256 until,
        uint256 gasPrice
    ) external onlyCrank {
        uint256 startGas = gasleft();
        bytes32 spHash = createSpHash(
            token,
            amount,
            payee,
            fee,
            executionGas,
            maxGasPrice,
            gasToken,
            salt,
            recursDayOfMonth,
            until
        );
        if (!spHashes.contains(spHash)) revert UnknownHash(spHash);
        if (gasPrice > maxGasPrice) revert ExceedMaxGasPrice(spHash);

        uint256 recursDate = getRecursDate(spHash, recursDayOfMonth, until);
        if (
            !_executeRecurringPayment(
                spHash,
                token,
                amount,
                payee,
                fee,
                executionGas,
                gasToken,
                gasPrice,
                recursDate,
                until
            )
        ) revert PaymentExecutionFailed(spHash);
        if (startGas - gasleft() > executionGas)
            revert OutOfGas(spHash, startGas - gasleft());
    }

    function getRecursDate(
        bytes32 spHash,
        uint256 recursDayOfMonth,
        uint256 until
    ) public view returns (uint256) {
        uint256 validForSeconds = IConfig(config).validForSeconds();
        uint256 _prevDate = block.timestamp.sub(validForSeconds);
        uint256 recursDate = _getRecursDate(recursDayOfMonth, _prevDate);
        if (
            block.timestamp <= lastPaidAt[spHash].add(validForSeconds) ||
            block.timestamp < recursDate ||
            _prevDate > recursDate ||
            block.timestamp > until.add(validForSeconds)
        ) revert InvalidPeriod(spHash);
        return recursDate;
    }

    function _getRecursDate(uint256 recursDayOfMonth, uint256 _prevDate)
        private
        view
        returns (uint256)
    {
        (
            uint256 _prevYear,
            uint256 _prevMonth,
            uint256 _prevDay
        ) = BokkyPooBahsDateTimeLibrary.timestampToDate(_prevDate);
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary
            .timestampToDate(block.timestamp);
        uint256 recursYear = recursDayOfMonth >= _prevDay &&
            recursDayOfMonth >= day
            ? _prevYear
            : year;
        uint256 recursMonth = recursDayOfMonth >= _prevDay &&
            recursDayOfMonth >= day
            ? _prevMonth
            : month;
        uint256 daysInMonth = BokkyPooBahsDateTimeLibrary._getDaysInMonth(
            recursYear,
            recursMonth
        );
        uint256 recursDay = recursDayOfMonth > daysInMonth
            ? daysInMonth
            : recursDayOfMonth;
        return
            BokkyPooBahsDateTimeLibrary.timestampFromDate(
                recursYear,
                recursMonth,
                recursDay
            );
    }

    // Estimate scheduled recurring payment execution
    function estimateExecutionGas(
        address token,
        uint256 amount,
        address payee,
        Fee calldata fee,
        uint256 maxGasPrice,
        address gasToken,
        string memory salt,
        uint256 recursDayOfMonth,
        uint256 until,
        uint256 gasPrice
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // This executionGas calculation only for estimation purpose
        // 32000 base cost, base transfer cost, etc
        // 1500 keccak hash cost
        // 95225  standard 2x ERC20 transfer cost
        // 2500 emit event cost
        uint256 executionGas = 32000 + 1500 + 95225 + 2500;
        bytes32 spHash = createSpHash(
            token,
            amount,
            payee,
            fee,
            executionGas,
            maxGasPrice,
            gasToken,
            salt,
            recursDayOfMonth,
            until
        );

        // We don't provide an error message here, as we use it to return the estimate
        require(
            _executeRecurringPayment(
                spHash,
                token,
                amount,
                payee,
                fee,
                executionGas,
                gasToken,
                gasPrice,
                block.timestamp,
                until
            )
        );

        // 10500 required checks cost
        // 9000 convert timestamp to day
        // 9500 remove value from set cost
        // 1500 delete from map cost
        // 5000 other cost
        uint256 requiredGas = startGas -
            gasleft() +
            9000 +
            9500 +
            1500 +
            10500 +
            5000;
        // Return gas estimation result via error message
        revert GasEstimation(requiredGas);
    }

    function setConfig(address _config) external onlyOwner {
        config = _config;
        emit ConfigSet(_config);
    }

    // Create a one-time payment hash
    function createSpHash(
        address token,
        uint256 amount,
        address payee,
        Fee calldata fee,
        uint256 executionGas,
        uint256 maxGasPrice,
        address gasToken,
        string memory salt,
        uint256 payAt
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    token,
                    amount,
                    payee,
                    fee.fixedUSD.value,
                    fee.percentage.value,
                    executionGas,
                    maxGasPrice,
                    gasToken,
                    salt,
                    payAt
                )
            );
    }

    // Create recurring payment hash
    function createSpHash(
        address token,
        uint256 amount,
        address payee,
        Fee calldata fee,
        uint256 executionGas,
        uint256 maxGasPrice,
        address gasToken,
        string memory salt,
        uint256 recursDayOfMonth,
        uint256 until
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    token,
                    amount,
                    payee,
                    fee.fixedUSD.value,
                    fee.percentage.value,
                    executionGas,
                    maxGasPrice,
                    gasToken,
                    salt,
                    recursDayOfMonth,
                    until
                )
            );
    }

    function getSpHashes() public view returns (bytes32[] memory) {
        return spHashes.values();
    }

    function _executeOneTimePayment(
        bytes32 spHash,
        address token,
        uint256 amount,
        address payee,
        Fee calldata fee,
        uint256 executionGas,
        address gasToken,
        uint256 gasPrice
    ) private returns (bool status) {
        status = executePayment(
            token,
            amount,
            payee,
            fee,
            executionGas,
            gasPrice,
            gasToken
        );

        spHashes.remove(spHash);
        emit ScheduledPaymentExecuted(spHash);
    }

    function _executeRecurringPayment(
        bytes32 spHash,
        address token,
        uint256 amount,
        address payee,
        Fee calldata fee,
        uint256 executionGas,
        address gasToken,
        uint256 gasPrice,
        uint256 recursDate,
        uint256 until
    ) private returns (bool status) {
        status = executePayment(
            token,
            amount,
            payee,
            fee,
            executionGas,
            gasPrice,
            gasToken
        );

        lastPaidAt[spHash] = block.timestamp;
        emit ScheduledPaymentExecuted(spHash);

        uint256 nextExecution = BokkyPooBahsDateTimeLibrary.addMonths(
            recursDate,
            1
        );
        if (nextExecution > until) {
            spHashes.remove(spHash);
            delete lastPaidAt[spHash];
        }
    }

    function executePayment(
        address token,
        uint256 amount,
        address payee,
        Fee calldata fee,
        uint256 executionGas,
        uint256 gasPrice,
        address gasToken
    ) private returns (bool) {
        // execTransactionFromModule to execute the sheduled payment
        bytes memory spTxData = abi.encodeWithSelector(
            0xa9059cbb,
            payee,
            amount
        );
        bool spTxStatus = exec(token, 0, spTxData, Enum.Operation.Call);

        // execTransactionFromModule for percentage fee
        bytes memory feeTxData = abi.encodeWithSelector(
            0xa9059cbb,
            IConfig(config).feeReceiver(),
            Decimal.mul(amount, fee.percentage)
        );
        bool feeTxStatus = exec(token, 0, feeTxData, Enum.Operation.Call);

        // execTransactionFromModule for fixed fee and gas reimbursement
        bytes memory gasTxData = abi.encodeWithSelector(
            0xa9059cbb,
            IConfig(config).feeReceiver(),
            executionGas.mul(gasPrice).add(calculateFixedFee(gasToken, fee))
        );
        bool gasTxStatus = exec(gasToken, 0, gasTxData, Enum.Operation.Call);

        return spTxStatus && feeTxStatus && gasTxStatus;
    }

    function calculateFixedFee(address token, Fee calldata fee)
        private
        returns (uint256)
    {
        if (fee.fixedUSD.value == 0) return 0;

        uint8 tokenDecimals;
        uint256 ten = 10;
        address usdToken = IExchange(exchange).usdToken();
        if (usdToken == token) {
            tokenDecimals = ERC20(usdToken).decimals();
            return Decimal.mul(ten**tokenDecimals, fee.fixedUSD);
        }

        Decimal.D256 memory usdRate = IExchange(exchange).exchangeRateOf(token);
        require(usdRate.value > 0, "exchange rate cannot be 0");
        tokenDecimals = ERC20(token).decimals();

        return
            Decimal.div(Decimal.mul(ten**tokenDecimals, fee.fixedUSD), usdRate);
    }
}