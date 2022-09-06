// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./base/CloneFactory.sol";
import "./interfaces/INFTGaugeFactory.sol";
import "./libraries/Integers.sol";
import "./libraries/Tokens.sol";
import "./NFTGauge.sol";

contract NFTGaugeFactory is CloneFactory, Ownable, INFTGaugeFactory {
    using SafeERC20 for IERC20;
    using Integers for int128;
    using Integers for uint256;

    struct Fee {
        uint64 timestamp;
        uint192 amountPerShare;
    }

    address public immutable override tokenURIRenderer;
    address public immutable override minter;
    address public immutable override votingEscrow;

    address public override target;
    uint256 public override targetVersion;

    uint256 public override feeRatio;
    mapping(address => address) public override currencyConverter;
    mapping(address => address) public override gauges;
    mapping(address => bool) public override isGauge;

    mapping(address => Fee[]) public override fees;
    mapping(address => mapping(address => uint256)) public override lastFeeClaimed;

    constructor(
        address _tokenURIRenderer,
        address _minter,
        uint256 _feeRatio
    ) {
        tokenURIRenderer = _tokenURIRenderer;
        minter = _minter;
        votingEscrow = IGaugeController(IMinter(_minter).controller()).votingEscrow();
        feeRatio = _feeRatio;

        emit UpdateFeeRatio(_feeRatio);

        NFTGauge gauge = new NFTGauge();
        gauge.initialize(address(0), address(0), address(0));
        target = address(gauge);
    }

    function feesLength(address token) external view override returns (uint256) {
        return fees[token].length;
    }

    function upgradeTarget(address _target) external override onlyOwner {
        target = _target;

        uint256 version = targetVersion + 1;
        targetVersion = version;

        emit UpgradeTarget(_target, version);
    }

    function updateCurrencyConverter(address token, address converter) external override onlyOwner {
        currencyConverter[token] = converter;

        emit UpdateCurrencyConverter(token, converter);
    }

    function updateFeeRatio(uint256 _feeRatio) external override onlyOwner {
        feeRatio = _feeRatio;

        emit UpdateFeeRatio(_feeRatio);
    }

    function createNFTGauge(address nftContract) external override returns (address gauge) {
        require(gauges[nftContract] == address(0), "NFTGF: GAUGE_CREATED");

        gauge = _createClone(target);
        INFTGauge(gauge).initialize(nftContract, tokenURIRenderer, minter);

        gauges[nftContract] = gauge;
        isGauge[gauge] = true;

        emit CreateNFTGauge(nftContract, gauge);
    }

    function executePayment(
        address currency,
        address from,
        uint256 amount
    ) external override {
        require(isGauge[msg.sender], "NFTGF: FORBIDDEN");
        require(currencyConverter[currency] != address(0), "NFTGF: INVALID_TOKEN");

        IERC20(currency).safeTransferFrom(from, msg.sender, amount);
    }

    function distributeFeesETH() external payable override returns (uint256 amountFee) {
        amountFee = (msg.value * feeRatio) / 10000;
        _distributeFees(address(0), amountFee);
    }

    function distributeFees(address token, uint256 amount) external override returns (uint256 amountFee) {
        amountFee = (amount * feeRatio) / 10000;
        _distributeFees(token, amountFee);
    }

    function _distributeFees(address token, uint256 amount) internal {
        require(isGauge[msg.sender], "NFTGF: FORBIDDEN");

        fees[token].push(
            Fee(uint64(block.timestamp), uint192((amount * 1e18) / IVotingEscrow(votingEscrow).totalSupply()))
        );

        emit DistributeFees(token, fees[token].length - 1, amount);
    }

    /**
     * @notice Claim accumulated fees
     * @param token In which currency fees were paid
     * @param to the last index of the fee (exclusive)
     */
    function claimFees(address token, uint256 to) external override {
        uint256 from = lastFeeClaimed[token][msg.sender];

        (int128 value, , uint256 start, ) = IVotingEscrow(votingEscrow).locked(msg.sender);
        require(value > 0, "NFTGF: LOCK_NOT_FOUND");

        uint256 epoch = IVotingEscrow(votingEscrow).userPointEpoch(msg.sender);
        (int128 bias, int128 slope, uint256 ts, ) = IVotingEscrow(votingEscrow).userPointHistory(msg.sender, epoch);

        uint256 amount;
        for (uint256 i = from; i < to; ) {
            Fee memory fee = fees[token][i];
            if (start < fee.timestamp) {
                int128 balance = bias - slope * (uint256(fee.timestamp) - ts).toInt128();
                if (balance > 0) {
                    amount += (balance.toUint256() * uint256(fee.amountPerShare)) / 1e18;
                }
            }
            unchecked {
                ++i;
            }
        }
        lastFeeClaimed[token][msg.sender] = to;

        emit ClaimFees(token, amount, msg.sender);
        Tokens.transfer(token, msg.sender, amount);
    }
}