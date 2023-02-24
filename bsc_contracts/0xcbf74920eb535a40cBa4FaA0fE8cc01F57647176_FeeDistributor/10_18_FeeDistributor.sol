// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IClearingHouse} from "./interface/IClearingHouse.sol";
import {IFeeDistributor} from "./interface/IFeeDistributor.sol";

contract FeeDistributor is OwnableUpgradeable, IFeeDistributor {
    using SafeERC20 for IERC20;

    enum ClaimType {
        INVITE_COMMISSION,
        INVITE_FEE_DISCOUNT,
        FEE_REFUND
    }

    event Claimed(
        address indexed user,
        ClaimType indexed claimedType,
        uint256 amount
    );
    event FeeCollected(uint256 amount);
    event EpochFinalized(
        uint64 indexed epoch,
        uint256 totalFee,
        uint256 refundFee,
        uint256 insuranceFee,
        uint256 buyback,
        bytes32 merkleRoot
    );
    event OperatorUpdated(address indexed setter);
    event InsuranceFeeRatioUpdated(uint256 insuranceFeeRatio);
    event BuybackFeeRatioUpdated(uint256 buybackFeeRatio);
    event BuybackPoolUpdated(address indexed buybackPool);
    event FeePoolUpdated(address indexed feePool);

    uint256 constant DENOMINATOR = 1e18;

    // Quote token address
    IERC20 public quoteToken;

    // Merkle root for user's claim information
    bytes32 public merkleRoot;

    // The operator address
    address public operator;

    // claimed amounts per user
    mapping(address => mapping(ClaimType => uint256)) public claimedAmounts;

    // clearing house address
    address public clearingHouse;

    // insurance fund address
    address public insuranceFund;

    // fee pool address
    address public feePool;

    // current epoch
    uint64 public epoch;

    // epoch period
    uint64 public epochPeriod;

    // next epoch timestamp
    uint64 public nextEpoch;

    // insurance fund fee ratio
    uint256 public insuranceFeeRatio;

    // Buy back fee ratio
    uint256 public buybackFeeRatio;

    // Total collected fee at current epoch
    uint256 public totalFeeInEpoch;

    // Total refundable fee
    uint256 public totalRefund;

    // buyback pool address
    address public buybackPool;

    function initialize(
        IClearingHouse _clearingHouse,
        address _feePool,
        address _buybackPool,
        uint64 _epochPeriod
    ) external initializer {
        __Ownable_init();
        require(
            address(_clearingHouse) != address(0) && _feePool != address(0),
            "zero address"
        );
        require(_epochPeriod != 0, "invalid period");

        quoteToken = _clearingHouse.quoteToken();
        insuranceFund = address(_clearingHouse.insuranceFund());
        feePool = _feePool;
        clearingHouse = address(_clearingHouse);
        buybackPool = _buybackPool;

        nextEpoch = (uint64(block.timestamp) / _epochPeriod + 1) * _epochPeriod;
        epochPeriod = _epochPeriod;

        operator = msg.sender;
    }

    function emitFeeCollection(uint256 amount) external override {
        require(msg.sender == clearingHouse, "Not clearing house");

        totalFeeInEpoch += amount;
        emit FeeCollected(amount);
    }

    function finalizeEpoch(bytes32 _merkleRoot, uint256 cumulativeRefundAmount)
        external
    {
        require(msg.sender == operator, "not operator");
        require(block.timestamp >= nextEpoch, "not ready to finalize");

        nextEpoch = (uint64(block.timestamp) / epochPeriod + 1) * epochPeriod;

        merkleRoot = _merkleRoot;

        uint256 refundInEpoch = cumulativeRefundAmount - totalRefund;
        uint256 _totalFee = totalFeeInEpoch;
        uint256 left = _totalFee - refundInEpoch;
        uint256 insuranceFee = (left * insuranceFeeRatio) / DENOMINATOR;
        uint256 buyback = (left * buybackFeeRatio) / DENOMINATOR;
        left = left - (insuranceFee + buyback);
        totalRefund = cumulativeRefundAmount;

        emit EpochFinalized(
            epoch,
            _totalFee,
            refundInEpoch,
            insuranceFee,
            buyback,
            _merkleRoot
        );

        epoch += 1;
        totalFeeInEpoch = 0;

        quoteToken.safeTransfer(insuranceFund, insuranceFee);
        quoteToken.safeTransfer(feePool, left);
        quoteToken.safeTransfer(buybackPool, buyback);
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
        emit OperatorUpdated(_operator);
    }

    function setInsuranceFeeRatio(uint256 _insuranceFeeRatio)
        external
        onlyOwner
    {
        require(
            buybackFeeRatio + _insuranceFeeRatio <= DENOMINATOR,
            "invalid ratio"
        );
        insuranceFeeRatio = _insuranceFeeRatio;
        emit InsuranceFeeRatioUpdated(_insuranceFeeRatio);
    }

    function setBuybackFeeRatio(uint256 _buybackFeeRatio) external onlyOwner {
        require(
            _buybackFeeRatio + insuranceFeeRatio <= DENOMINATOR,
            "invalid ratio"
        );
        buybackFeeRatio = _buybackFeeRatio;
        emit BuybackFeeRatioUpdated(_buybackFeeRatio);
    }

    function setBuybackPool(address _buybackPool) external onlyOwner {
        buybackPool = _buybackPool;
        emit BuybackPoolUpdated(_buybackPool);
    }

    function setFeePool(address _feePool) external onlyOwner {
        feePool = _feePool;
        emit FeePoolUpdated(_feePool);
    }

    function claim(
        ClaimType claimType,
        uint256 amount,
        bytes32[] calldata merkleProofs
    ) public {
        bytes32 leaf = keccak256(abi.encode(msg.sender, claimType, amount));

        require(
            MerkleProofUpgradeable.verify(merkleProofs, merkleRoot, leaf),
            "invalid proof"
        );

        uint256 available = amount - claimedAmounts[msg.sender][claimType];
        if (available != 0) {
            claimedAmounts[msg.sender][claimType] = amount;
            quoteToken.safeTransfer(msg.sender, available);

            emit Claimed(msg.sender, claimType, available);
        }
    }

    function claimInBatch(
        ClaimType[] calldata claimType,
        uint256[] calldata amount,
        bytes32[][] calldata merkleProofs
    ) external {
        uint256 len = claimType.length;
        for (uint256 i; i < len; i += 1) {
            claim(claimType[i], amount[i], merkleProofs[i]);
        }
    }
}