// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IHWRegistry.sol";
import "./interfaces/IHWRegistry.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IPool.sol";
import "./utils/SigUtils.sol";

/// @title HonestWork Escrow Contract
/// @author @takez0_o, @ReddKidd
/// @notice Escrow contract for HonestWork
/// @dev Facilitates deals between creators and recruiters
contract HWEscrow is Ownable, ReentrancyGuard, SigUtils {
    using Counters for Counters.Counter;

    enum Status {
        OfferInitiated,
        JobCompleted,
        JobCancelled
    }
    struct Deal {
        address recruiter;
        address creator;
        address paymentToken;
        uint256 totalPayment;
        uint256 successFee;
        uint256 claimedAmount;
        uint256 claimableAmount;
        Status status;
        uint128[] recruiterRating;
        uint128[] creatorRating;
    }

    uint128 immutable PRECISION = 1e2;

    Counters.Counter public dealIds;
    IHWRegistry public registry;
    IUniswapV2Router01 public router;
    IERC20 public stableCoin;
    IPool public pool;
    uint64 public extraPaymentLimit;
    uint128 public honestWorkSuccessFee;
    bool public nativePaymentAllowed;
    uint256 public totalCollectedSuccessFee;

    mapping(uint256 => uint256) public additionalPaymentLimit;
    mapping(uint256 => Deal) public dealsMapping;

    constructor(
        address _registry,
        address _pool,
        address _stableCoin,
        address _router
    ) Ownable() {
        honestWorkSuccessFee = 5;
        registry = IHWRegistry(_registry);
        pool = IPool(_pool);
        stableCoin = IERC20(_stableCoin);
        router = IUniswapV2Router01(_router);
    }

    //-----------------//
    //  admin methods  //
    //-----------------//

    /**
     * @dev value is expressed as a percentage.
     */
    function changeSuccessFee(uint128 _fee) external onlyOwner {
        honestWorkSuccessFee = _fee;
        emit FeeChanged(_fee);
    }

    function changeRegistry(IHWRegistry _registry) external onlyOwner {
        registry = _registry;
    }

    function claimSuccessFee(
        uint256 _dealId,
        address _feeCollector
    ) external onlyOwner {
        uint256 successFee = dealsMapping[_dealId].successFee;

        if (dealsMapping[_dealId].paymentToken != address(0)) {
            IERC20 paymentToken = IERC20(dealsMapping[_dealId].paymentToken);
            paymentToken.transfer(_feeCollector, successFee);
        } else {
            (bool payment, ) = payable(_feeCollector).call{value: successFee}(
                ""
            );
            require(payment, "payment failed");
        }
        totalCollectedSuccessFee += successFee;
        dealsMapping[_dealId].successFee = 0;
        emit FeeClaimed(_dealId, dealsMapping[_dealId].successFee);
    }

    function claimTotalSuccessFee(address _feeCollector) external onlyOwner {
        for (uint256 i = 1; i <= dealIds.current(); i++) {
            uint256 successFee = dealsMapping[i].successFee;
            if (successFee > 0) {
                if (dealsMapping[i].paymentToken == address(0)) {
                    (bool payment, ) = payable(_feeCollector).call{
                        value: successFee
                    }("");
                    require(payment, "payment failed");
                } else {
                    IERC20 paymentToken = IERC20(dealsMapping[i].paymentToken);
                    paymentToken.transfer(_feeCollector, successFee);
                }
                dealsMapping[i].successFee = 0;
            }
        }
        emit TotalFeeClaimed(_feeCollector);
    }

    function changeExtraPaymentLimit(uint64 _limit) external onlyOwner {
        extraPaymentLimit = _limit;
        emit ExtraLimitChanged(_limit);
    }

    function allowNativePayment(bool _bool) external onlyOwner {
        nativePaymentAllowed = _bool;
    }

    function setStableCoin(address _stableCoin) external onlyOwner {
        stableCoin = IERC20(_stableCoin);
    }

    function setRouter(address _router) external onlyOwner {
        router = IUniswapV2Router01(_router);
    }

    function setPool(address _pool) external onlyOwner {
        pool = IPool(_pool);
    }

    //--------------------//
    //  mutative methods  //
    //--------------------//

    function createDealSignature(
        address _recruiter,
        address _creator,
        address _paymentToken,
        uint256 _totalPayment,
        uint256 _downPayment,
        uint256 _recruiterNFTId,
        bytes memory _signature
    ) external payable returns (uint256) {
        (bytes32 r, bytes32 s, uint8 v) = SigUtils.splitSignature(_signature);
        return
            createDeal(
                _recruiter,
                _creator,
                _paymentToken,
                _totalPayment,
                _downPayment,
                _recruiterNFTId,
                v,
                r,
                s
            );
    }

    function createDeal(
        address _recruiter,
        address _creator,
        address _paymentToken,
        uint256 _totalPayment,
        uint256 _downPayment,
        uint256 _recruiterNFTId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable returns (uint256) {
        require(_recruiter != address(0), "recruiter address cannot be 0");
        require(_creator != address(0), "creator address cannot be 0");
        require(_totalPayment > 0, "total payment cannot be 0");
        require(
            _creator != _recruiter,
            "creator and recruiter cannot be the same address"
        );

        if (_paymentToken == address(0)) {
            require(nativePaymentAllowed, "native payment is not allowed");
        }

        bytes32 signedMessage = getEthSignedMessageHash(
            getMessageHash(
                _recruiter,
                _creator,
                _paymentToken,
                _totalPayment,
                _downPayment
            )
        );

        require(
            recoverSigner(signedMessage, v, r, s) == _creator,
            "invalid signature, creator needs to sign the deal paramers first"
        );

        require(
            registry.isAllowedAmount(_paymentToken, _totalPayment),
            "the token you are trying to pay with is either not whitelisted or you are exceeding the allowed amount"
        );
        dealIds.increment();
        uint256 _dealId = dealIds.current();
        uint128[] memory arr1;
        uint128[] memory arr2;
        dealsMapping[_dealId] = Deal(
            _recruiter,
            _creator,
            _paymentToken,
            _totalPayment,
            0,
            0,
            0,
            Status.OfferInitiated,
            arr1,
            arr2
        );
        if (_paymentToken == address(0)) {
            require(
                msg.value >= _totalPayment,
                "employer should deposit the payment"
            );
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);
            paymentToken.transferFrom(
                msg.sender,
                address(this),
                (_totalPayment)
            );
        }
        emit OfferCreated(_recruiter, _creator, _totalPayment, _paymentToken);

        if (_downPayment != 0) {
            unlockPayment(_dealId, _downPayment, 0, _recruiterNFTId);
        }
        return _dealId;
    }

    function unlockPayment(
        uint256 _dealId,
        uint256 _paymentAmount,
        uint128 _rating,
        uint256 _recruiterNFT
    ) public {
        Deal storage currentDeal = dealsMapping[_dealId];
        require(
            currentDeal.status == Status.OfferInitiated,
            "deal is either completed or cancelled"
        );
        require(
            _rating >= 0 && _rating <= 10,
            "rating must be between 0 and 10"
        );
        require(
            currentDeal.recruiter == msg.sender,
            "only recruiter can unlock payments"
        );

        currentDeal.claimableAmount += _paymentAmount;
        address _paymentToken = currentDeal.paymentToken;

        require(
            currentDeal.totalPayment >=
                currentDeal.claimableAmount + currentDeal.claimedAmount,
            "can not go above total payment, use additional payment function pls"
        );
        if (_rating != 0) {
            currentDeal.creatorRating.push(_rating * PRECISION);
        }

        uint256 grossRev = (
            _paymentToken == address(0)
                ? getEthPrice(_paymentAmount)
                : _paymentAmount
        );

        registry.setNFTGrossRevenue(_recruiterNFT, grossRev);

        emit GrossRevenueUpdated(_recruiterNFT, grossRev);
        emit PaymentUnlocked(_dealId, currentDeal.recruiter, _paymentAmount);
    }

    function withdrawPayment(uint256 _dealId) external {
        Deal storage currentDeal = dealsMapping[_dealId];
        require(
            currentDeal.status == Status.OfferInitiated,
            "job should be active"
        );
        require(
            currentDeal.recruiter == msg.sender,
            "only recruiter can withdraw payments"
        );
        address _paymentToken = currentDeal.paymentToken;
        uint256 amountToBeWithdrawn = currentDeal.totalPayment -
            currentDeal.claimedAmount -
            currentDeal.claimableAmount;
        if (_paymentToken == address(0)) {
            (bool payment, ) = payable(currentDeal.recruiter).call{
                value: amountToBeWithdrawn
            }("");
            require(payment, "Failed to send payment");
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);
            paymentToken.transfer(msg.sender, (amountToBeWithdrawn));
        }

        currentDeal.status = Status.JobCancelled;
        emit PaymentWithdrawn(_dealId, currentDeal.status);
    }

    function claimPayment(
        uint256 _dealId,
        uint256 _withdrawAmount,
        uint128 _rating,
        uint256 _creatorNFT
    ) external {
        Deal storage currentDeal = dealsMapping[_dealId];
        require(
            currentDeal.status == Status.OfferInitiated,
            "deal is either completed or cancelled"
        );
        require(
            _rating >= 0 && _rating <= 10,
            "rating must be between 0 and 10"
        );
        require(
            currentDeal.creator == msg.sender,
            "only creator can receive payments"
        );
        require(
            currentDeal.claimableAmount >= _withdrawAmount,
            "desired payment is not available yet"
        );

        address _paymentToken = currentDeal.paymentToken;
        currentDeal.claimedAmount += _withdrawAmount;
        currentDeal.claimableAmount -= _withdrawAmount;
        currentDeal.recruiterRating.push(_rating * PRECISION);
        currentDeal.successFee +=
            (_withdrawAmount * honestWorkSuccessFee) /
            PRECISION;
        if (_paymentToken == address(0)) {
            (bool payment, ) = payable(currentDeal.creator).call{
                value: (_withdrawAmount * (PRECISION - honestWorkSuccessFee)) /
                    PRECISION
            }("");
            require(payment, "Failed to send payment");
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);

            paymentToken.transfer(
                msg.sender,
                ((_withdrawAmount * (PRECISION - honestWorkSuccessFee)) /
                    PRECISION)
            );
        }
        uint256 grossRev = (
            _paymentToken == address(0)
                ? getEthPrice(_withdrawAmount)
                : _withdrawAmount
        );
        registry.setNFTGrossRevenue(_creatorNFT, grossRev);
        if (currentDeal.claimedAmount >= currentDeal.totalPayment) {
            currentDeal.status = Status.JobCompleted;
        }
        emit GrossRevenueUpdated(_creatorNFT, grossRev);
        emit PaymentClaimed(_dealId, currentDeal.creator, _withdrawAmount);
    }

    /**
     * @dev recruiter immediately unlocks an additional amount for the creator to claim
     */
    function additionalPayment(
        uint256 _dealId,
        uint256 _payment,
        uint256 _recruiterNFT,
        uint128 _rating
    ) external payable {
        Deal storage currentDeal = dealsMapping[_dealId];
        require(
            currentDeal.status == Status.OfferInitiated,
            "deal is either completed or cancelled"
        );
        require(
            _rating >= 0 && _rating <= 10,
            "rating must be between 0 and 10"
        );
        require(
            additionalPaymentLimit[_dealId] <= extraPaymentLimit,
            "you can not make more than 3 additional payments"
        );
        require(
            currentDeal.status == Status.OfferInitiated,
            "job should be active"
        );
        require(
            currentDeal.recruiter == msg.sender,
            "only recruiter can add payments"
        );

        address _paymentToken = currentDeal.paymentToken;
        if (_paymentToken == address(0)) {
            require(
                msg.value >= _payment,
                "recruiter should deposit the additional payment"
            );
            currentDeal.claimableAmount += _payment;
            currentDeal.totalPayment += _payment;
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);
            paymentToken.transferFrom(msg.sender, address(this), _payment);
            currentDeal.claimableAmount += _payment;
            currentDeal.totalPayment += _payment;
        }

        uint256 grossRev = (
            _paymentToken == address(0) ? getEthPrice(_payment) : _payment
        );
        registry.setNFTGrossRevenue(_recruiterNFT, grossRev);

        additionalPaymentLimit[_dealId]++;
        currentDeal.creatorRating.push(_rating * PRECISION);

        emit GrossRevenueUpdated(_recruiterNFT, grossRev);
        emit AdditionalPayment(_dealId, currentDeal.recruiter, _payment);
    }

    //----------------//
    //  view methods  //
    //----------------//

    function getDeal(uint256 _dealId) public view returns (Deal memory) {
        return dealsMapping[_dealId];
    }

    function getCreator(uint256 _dealId) external view returns (address) {
        return dealsMapping[_dealId].creator;
    }

    function getRecruiter(uint256 _dealId) external view returns (address) {
        return dealsMapping[_dealId].recruiter;
    }

    function getPaymentToken(uint256 _dealId) external view returns (address) {
        return dealsMapping[_dealId].paymentToken;
    }

    function getclaimedAmount(uint256 _dealId) external view returns (uint256) {
        return dealsMapping[_dealId].claimedAmount;
    }

    function getClaimableAmount(
        uint256 _dealId
    ) external view returns (uint256) {
        return dealsMapping[_dealId].claimableAmount;
    }

    function getDealCompletionRate(
        uint256 _dealId
    ) external view returns (uint256) {
        return ((dealsMapping[_dealId].claimedAmount * PRECISION) /
            dealsMapping[_dealId].totalPayment);
    }

    function getTotalPayment(uint256 _dealId) external view returns (uint256) {
        return (dealsMapping[_dealId].totalPayment);
    }

    function getRecruiterRating(
        uint256 _dealId
    ) external view returns (uint128[] memory) {
        return (dealsMapping[_dealId].recruiterRating);
    }

    function getCreatorRating(
        uint256 _dealId
    ) external view returns (uint128[] memory) {
        return (dealsMapping[_dealId].creatorRating);
    }

    function getAvgCreatorRating(
        uint256 _dealId
    ) public view returns (uint256) {
        uint256 sum;
        for (
            uint256 i = 0;
            i < dealsMapping[_dealId].creatorRating.length;
            i++
        ) {
            sum += dealsMapping[_dealId].creatorRating[i];
        }
        return (sum / dealsMapping[_dealId].creatorRating.length);
    }

    function getAvgRecruiterRating(
        uint256 _dealId
    ) public view returns (uint256) {
        uint256 sum;
        for (
            uint256 i = 0;
            i < dealsMapping[_dealId].recruiterRating.length;
            i++
        ) {
            sum += dealsMapping[_dealId].recruiterRating[i];
        }
        return (sum / dealsMapping[_dealId].recruiterRating.length);
    }

    function getAggregatedRating(
        address _address
    ) public view returns (uint256) {
        uint256 gross_amount = 0;
        uint256 gross_rating = 0;
        uint256[] memory deal_ids = getDealsOf(_address);
        for (uint256 i = 0; i < deal_ids.length; i++) {
            Deal memory deal = getDeal(deal_ids[i]);
            if (
                _address == deal.recruiter && deal.recruiterRating.length != 0
            ) {
                gross_rating +=
                    getAvgRecruiterRating(deal_ids[i]) *
                    deal.claimedAmount;
                gross_amount += deal.claimedAmount;
            } else if (
                _address == deal.creator && deal.creatorRating.length != 0
            ) {
                gross_rating +=
                    getAvgCreatorRating(deal_ids[i]) *
                    (deal.claimedAmount + deal.claimableAmount);
                gross_amount += (deal.claimedAmount + deal.claimableAmount);
            }
        }
        return gross_rating / gross_amount;
    }

    function getTotalSuccessFee() external view returns (uint256) {
        uint256 totalSuccessFee;
        for (uint256 i = 1; i <= dealIds.current(); i++) {
            totalSuccessFee += dealsMapping[i].successFee;
        }
        return totalSuccessFee;
    }

    function getDealSuccessFee(
        uint256 _dealId
    ) external view returns (uint256) {
        return dealsMapping[_dealId].successFee;
    }

    function getDealStatus(uint256 _dealId) external view returns (uint256) {
        return uint256(dealsMapping[_dealId].status);
    }

    function getAdditionalPaymentLimit(
        uint256 _dealId
    ) external view returns (uint256) {
        return additionalPaymentLimit[_dealId];
    }

    function getDealsOf(
        address _address
    ) public view returns (uint256[] memory) {
        uint256[] memory deals = new uint256[](getDealsCount(_address));
        uint256 arrayLocation = 0;
        for (uint256 i = 0; i <= dealIds.current(); i++) {
            if (
                dealsMapping[i].creator == _address ||
                dealsMapping[i].recruiter == _address
            ) {
                deals[arrayLocation] = i;
                arrayLocation++;
            }
        }
        return deals;
    }

    function getDealsCount(address _address) internal view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i <= dealIds.current(); i++) {
            if (
                dealsMapping[i].creator == _address ||
                dealsMapping[i].recruiter == _address
            ) {
                count++;
            }
        }
        return count;
    }

    function getEthPrice(uint256 _amount) public view returns (uint256) {
        uint256 reserve1;
        uint256 reserve2;
        (reserve1, reserve2, ) = pool.getReserves();
        return router.quote(_amount, reserve1, reserve2);
    }

    function getNFTGrossRevenue(
        uint256 _tokenId
    ) public view returns (uint256) {
        return registry.getNFTGrossRevenue(_tokenId);
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    event OfferCreated(
        address indexed _recruiter,
        address indexed _creator,
        uint256 indexed _totalPayment,
        address _paymentToken
    );
    event PaymentUnlocked(
        uint256 _dealId,
        address indexed _recruiter,
        uint256 indexed _unlockedAmount
    );
    event PaymentClaimed(
        uint256 indexed _dealId,
        address indexed _creator,
        uint256 indexed _paymentReceived
    );
    event AdditionalPayment(
        uint256 indexed _dealId,
        address indexed _recruiter,
        uint256 indexed _payment
    );
    event PaymentWithdrawn(uint256 indexed _dealId, Status status);
    event FeeChanged(uint256 _newSuccessFee);
    event FeeClaimed(uint256 indexed _dealId, uint256 _amount);
    event ExtraLimitChanged(uint256 _newPaymentLimit);
    event TotalFeeClaimed(address _collector);
    event GrossRevenueUpdated(uint256 indexed _tokenId, uint256 _grossRevenue);
}