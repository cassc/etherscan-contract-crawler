/**
 * @author -- Decoded Labs  .
 * @title -- HonestPay   .
 * @dev Contract is designed to smoothly serve the payment needs of creators and recruiters.
 */
// #  888    888                                     888          8888888b.
// #  888    888                                     888          888   Y88b
// #  888    888                                     888          888    888
// #  8888888888  .d88b.  88888b.   .d88b.  .d8888b  888888       888   d88P  8888b.  888  888
// #  888    888 d88""88b 888 "88b d8P  Y8b 88K      888          8888888P"      "88b 888  888
// #  888    888 888  888 888  888 88888888 "Y8888b. 888          888        .d888888 888  888
// #  888    888 Y88..88P 888  888 Y8b.          X88 Y88b.        888        888  888 Y88b 888
// #  888    888  "Y88P"  888  888  "Y8888   88888P'  "Y888       888        "Y888888  "Y88888
// #                                                                                       888
// #                                                                                  Y8b d88P
// #                                                                                   "Y88P"

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../Registry/IHWRegistry.sol";
import "../HonestWorkNFT.sol";
import "forge-std/console.sol";

import "../Registry/IHWRegistry.sol";
import "../utils/IUniswapV2Router01.sol";
import "../utils/IPool.sol";
import "../utils/SigUtils.sol";

contract HonestPayLock is Ownable, ReentrancyGuard, SigUtils {
    //@notice enum to keep track of the state of the deal
    enum Status {
        OfferInitiated,
        JobCompleted,
        JobCancelled
    }

    //@dev core of the contract, the deal struct reflects the terms of the agreement
    //@params required notation is written next to the vars
    struct Deal {
        address recruiter; //address of the recruiter
        address creator; //address of the creator-freelancer
        address paymentToken; //address of the payment token
        uint256 totalPayment; //total payment amount denoted in the form of the payment token
        uint256 successFee; //a variable to keep track of honestWork success fee
        uint256 paidAmount; //a variable to keep track of the payments made
        uint256 claimablePayment; // a variable to keep track of the unlocked payment which can be claimed by the creator
        Status status; // deal Status
        uint128[] recruiterRating; // recruiter's rating array
        uint128[] creatorRating; // creator's rating array
    }
    IHWRegistry public registry; //registry contract definition for retreiving the whitelisted payment mediums
    HonestWorkNFT public hw721; //nft contract definition for recording grossRevenues to the nft.

    IUniswapV2Router01 public router =
        IUniswapV2Router01(0x10ED43C718714eb63d5aA57B78B54704E256024E); //pancake router
    IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // busd
    IPool public pool = IPool(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16); // busd-bnb pool

    uint64 public extraPaymentLimit; //limit for additional payments--currently capped to 3
    uint128 public honestWorkSuccessFee; //honestWork's cut from the deals, currently set to %5
    bool public nativePaymentAllowed;
    uint256 public totalCollectedSuccessFee; //total amount of success fee collected by honestWork

    mapping(uint256 => uint256) public additionalPaymentLimit; //keeps track of the additional payments made for each deal
    mapping(uint256 => Deal) public dealsMapping; //mapping for keeping track of each offered deal. DealIds are unique.


    event OfferCreatedEvent(
        address indexed _recruiter,
        address indexed _creator,
        uint256 indexed _totalPayment,
        address _paymentToken
    );
    event paymentUnlockedEvent(
        uint256 _dealId,
        address indexed _recruiter,
        uint256 indexed _unlockedAmount
    );
    event claimPaymentEvent(
        uint256 indexed _dealId,
        address indexed _creator,
        uint256 indexed _paymentReceived
    );
    event additionalPaymentEvent(
        uint256 indexed _dealId,
        address indexed _recruiter,
        uint256 indexed _payment
    );
    event withdrawPaymentEvent(uint256 indexed _dealId, Status status);
    event successFeeChangedEvent(uint256 _newSuccessFee);
    event claimSuccessFeeEvent(uint256 indexed _dealId, uint256 _amount);
    event changeExtraPaymentLimitEvent(uint256 _newPaymentLimit);
    event claimSuccessFeeAllEvent(address _collector);

    //Using a counter to count the dealIds, keeping them unique
    using Counters for Counters.Counter;
    Counters.Counter public dealIds;

    constructor(address _registry, address _HW721) Ownable() {
        honestWorkSuccessFee = 5;
        registry = IHWRegistry(_registry);
        hw721 = HonestWorkNFT(_HW721);
    }

    function createDealSignature(
        address _recruiter,
        address _creator,
        address _paymentToken,
        uint256 _totalPayment,
        uint256 _downPayment,
        uint256 _deadline,
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
                _deadline,
                v,
                r,
                s
            );
    }

    /**
     * @notice function to create deals  .
     * @dev function fills in the deal Struct with the terms of the deal. 
        The agreed amount is deposited into the contract upon calling this function.
        if the recruiter is calling the function, the signature of the creator must be given as a parameter.
     * @param   _recruiter.
     * @param   _creator.
     * @param   _paymentToken function checks if the paymentToken is whitelisted.
     * @param   _totalPayment.
     * @param   _deadline.
     */
    function createDeal(
        address _recruiter,
        address _creator,
        address _paymentToken,
        uint256 _totalPayment,
        uint256 _downPayment,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable returns (uint256) {
        require(_recruiter != address(0), "recruiter address cannot be 0");
        require(_creator != address(0), "creator address cannot be 0");
        require(_totalPayment > 0, "total payment cannot be 0");
        require(_deadline > block.timestamp, "deadline cannot be in the past");

        if(_paymentToken == address(0)){
            require(nativePaymentAllowed, "native payment is not allowed");
        }

        bytes32 signedMessage = getMessageHash(
            _recruiter,
            _creator,
            _paymentToken,
            _totalPayment,
            _downPayment,
            _deadline
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
            _downPayment,
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

        emit paymentUnlockedEvent(_dealId, _recruiter, _downPayment);

        emit OfferCreatedEvent(
            _recruiter,
            _creator,
            _totalPayment,
            _paymentToken
        );
        return _dealId;
    }

    /**
     * @notice  function to unlock payments which allow the creator to claim.
     * @dev     function can be called by the recruiter of the _dealId parameter.
     * @param   _dealId  .
     * @param   _paymentAmount amount to be unlocked .
     * @param   _rating upon intending to make a payment, recruiter rates the creator.
     * @param   _recruiterNFT tokenId of recruiters nft which is required to record the gross rev.
     */
    function unlockPayment(
        uint256 _dealId,
        uint256 _paymentAmount,
        uint128 _rating,
        uint256 _recruiterNFT
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
            currentDeal.recruiter == msg.sender,
            "only recruiter can unlock payments"
        );

        currentDeal.claimablePayment += _paymentAmount;
        address _paymentToken = currentDeal.paymentToken;

        require(
            currentDeal.totalPayment >=
                currentDeal.claimablePayment + currentDeal.paidAmount,
            "can not go above total payment, use additional payment function pls"
        );
        currentDeal.creatorRating.push(_rating * 100);

        if (hw721.balanceOf(msg.sender) == 1) {
            uint256 grossRev = (
                _paymentToken == address(0)
                    ? getBnbPrice(_paymentAmount)
                    : _paymentAmount
            );
            hw721.recordGrossRevenue(_recruiterNFT, grossRev);
        }
        emit paymentUnlockedEvent(
            _dealId,
            currentDeal.recruiter,
            _paymentAmount
        );
    }

    /**
     * @notice function cancels the deal.
     * @dev    function is to be called by the recruiter of the _dealId specified
        Upon calling, the recruiter shows intent to cancel the deal. Function sends the remaining
        token amount to the recruiter. 
     * @param   _dealId  .
     */
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
            currentDeal.paidAmount;
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
        emit withdrawPaymentEvent(_dealId, currentDeal.status);
    }

    /**
     * @notice  function to claim the Payment.
     * @dev     function can be called by the creator of the _dealId.
        if recruiter has intenteded to make any payment, creator claims it with this function
     * @param   _dealId  .
     * @param   _withdrawAmount  .
     * @param   _rating  cretor rates the recruiter upon claiming.
     * @param   _creatorNFT  tokenId of creatorNFT to record grossRev.
     */
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
            currentDeal.claimablePayment >= _withdrawAmount,
            "desired payment is not available yet"
        );
        require(
            hw721.tokenOfOwnerByIndex(currentDeal.creator, 0) == _creatorNFT,
            "only creator owned nftId can be passed as an argument"
        );
        address _paymentToken = currentDeal.paymentToken;
        currentDeal.paidAmount += _withdrawAmount;
        currentDeal.claimablePayment -= _withdrawAmount;
        currentDeal.recruiterRating.push(_rating * 100);
        currentDeal.successFee +=
            (_withdrawAmount * honestWorkSuccessFee) /
            100;
        if (_paymentToken == address(0)) {
            (bool payment, ) = payable(currentDeal.creator).call{
                value: (_withdrawAmount * (100 - honestWorkSuccessFee)) / 100
            }("");
            require(payment, "Failed to send payment");
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);

            paymentToken.transfer(
                msg.sender,
                ((_withdrawAmount * (100 - honestWorkSuccessFee)) / 100)
            );
        }
            uint256 grossRev = (
                _paymentToken == address(0)
                    ? getBnbPrice(_withdrawAmount)
                    : _withdrawAmount
            );
            hw721.recordGrossRevenue(_creatorNFT, grossRev);
        if (currentDeal.paidAmount >= currentDeal.totalPayment) {
            currentDeal.status = Status.JobCompleted;
        }

        emit claimPaymentEvent(_dealId, currentDeal.creator, _withdrawAmount);
    }

    /**
     * @notice  function to make additional payments which are not intended when creating the deal.
     * @dev     function is to be called by the recruiter of the _dealId, function increases total payment
        and available payment paramters. The intented amount is immediately unlocked for the creator to claim.
     * @param   _dealId  .
     * @param   _payment  .
     * @param   _recruiterNFT  .
     * @param   _rating  .
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

        require(
            hw721.tokenOfOwnerByIndex(currentDeal.recruiter, 0) ==
                _recruiterNFT,
            "only recruiter owned nftId can be passed as an argument"
        );
        address _paymentToken = currentDeal.paymentToken;
        if (_paymentToken == address(0)) {
            require(
                msg.value >= _payment,
                "recruiter should deposit the additional payment"
            );
            currentDeal.claimablePayment += _payment;
            currentDeal.totalPayment += _payment;
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);
            paymentToken.transferFrom(msg.sender, address(this), _payment);
            currentDeal.claimablePayment += _payment;
            currentDeal.totalPayment += _payment;
        }

        if (hw721.balanceOf(msg.sender) == 1) {
            uint256 grossRev = (
                _paymentToken == address(0) ? getBnbPrice(_payment) : _payment
            );
            hw721.recordGrossRevenue(_recruiterNFT, grossRev);
        }

        additionalPaymentLimit[_dealId] += 1;
        currentDeal.creatorRating.push(_rating * 100);
        emit additionalPaymentEvent(_dealId, currentDeal.recruiter, _payment);
    }

    //Getters

    /**
     * @notice  function to the requested deal struct.
     * @param   _dealId  .
     * @return  Deal  .
     */
    function getDeal(uint256 _dealId) external view returns (Deal memory) {
        return dealsMapping[_dealId];
    }

    /**
     * @notice  function to return the creator address of a specified deal.
     * @param   _dealId  .
     * @return  address  .
     */
    function getCreator(uint256 _dealId) external view returns (address) {
        return dealsMapping[_dealId].creator;
    }

    /**
     * @notice  function to return the recruiter address of a specfied deal.
     * @param   _dealId  .
     * @return  address  .
     */
    function getRecruiter(uint256 _dealId) external view returns (address) {
        return dealsMapping[_dealId].recruiter;
    }

    /**
     * @notice  function to return the payment token of a specified deal.
     * @dev     returns address(0) if payment method is native currency of the network.
     * @param   _dealId  .
     * @return  address  .
     */
    function getPaymentToken(uint256 _dealId) external view returns (address) {
        return dealsMapping[_dealId].paymentToken;
    }

    /**
     * @notice  function to return the paidAmount by the recruiter.
     * @param   _dealId  .
     * @return  uint256  .
     */
    function getPaidAmount(uint256 _dealId) external view returns (uint256) {
        return dealsMapping[_dealId].paidAmount;
    }

    /**
     * @notice  function to return the available amount which is claimable by the creator.
     * @param   _dealId  .
     * @return  uint256  .
     */
    function getclaimablePayment(
        uint256 _dealId
    ) external view returns (uint256) {
        return dealsMapping[_dealId].claimablePayment;
    }

    /**
     * @notice  function returns the completion rate of a deal accounted by the paidAmount/TotalPayment.
     * @param   _dealId  .
     * @return  uint256  .
     */
    function getJobCompletionRate(
        uint256 _dealId
    ) external view returns (uint256) {
        return ((dealsMapping[_dealId].paidAmount * 100) /
            dealsMapping[_dealId].totalPayment);
    }

    /**
     * @notice  function to return the total payment of a specified deal.
     * @param   _dealId  .
     * @return  uint256  .
     */
    function getTotalPayment(uint256 _dealId) external view returns (uint256) {
        return (dealsMapping[_dealId].totalPayment);
    }

    /**
     * @notice  function to return the recruiter's rating array.
     * @param   _dealId  .
     * @return  uint256  .
     */
    function getRecruiterRating(
        uint256 _dealId
    ) external view returns (uint128[] memory) {
        return (dealsMapping[_dealId].recruiterRating);
    }

    /**
     * @notice  function to return the creator's rating array.
     * @param   _dealId  .
     * @return  uint256  .
     */
    function getCreatorRating(
        uint256 _dealId
    ) external view returns (uint128[] memory) {
        return (dealsMapping[_dealId].creatorRating);
    }

    /**
     * @notice  function to return the creator's average rating.
     * @param   _dealId  .
     * @return  uint256  .
     */
    function getAvgCreatorRating(
        uint256 _dealId
    ) external view returns (uint256) {
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

    /**
     * @notice  function to return the recruiter's average rating.
     * @param   _dealId  .
     * @return  uint256  .
     */
    function getAvgRecruiterRating(
        uint256 _dealId
    ) external view returns (uint256) {
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

    /**
     * @notice  function to return the totalSuccessFee claimable or claimed by HW.
     * @return  uint256.
     */
    function getTotalSuccessFee() external view returns (uint256) {
        uint256 totalSuccessFee;
        for (uint256 i = 1; i <= dealIds.current(); i++) {
            totalSuccessFee += dealsMapping[i].successFee;
        }
        return totalSuccessFee;
    }

    /**
     * @notice  function to return the success fee of a specified deal.
     * @param   _dealId  .
     * @return  uint256  .
     */
    function getDealSuccessFee(
        uint256 _dealId
    ) external view returns (uint256) {
        return dealsMapping[_dealId].successFee;
    }

    /**
     * @notice  function to return the status of a specified deal.
     * @param   _dealId  .
     * @return  uint  .
     */
    function getDealStatus(uint256 _dealId) external view returns (uint256) {
        return uint256(dealsMapping[_dealId].status);
    }

    /**
     * @notice  function to return the additional payment limit of a specified deal.
     * @param   _dealId  .
     * @return  uint  .
     */
    function getAdditionalPaymentLimit(
        uint256 _dealId
    ) external view returns (uint256) {
        return additionalPaymentLimit[_dealId];
    }

    /**
     * @notice  function to return the dealIds of a specified address.
     * @param   _address  .
     * @return  uint256[]  .
     */
    function getDealsOfAnAddress(
        address _address
    ) public view returns (uint256[] memory) {
        uint256[] memory dealsOfAnAddress = new uint[](dealIds.current());
        uint256 arrayLocation = 0;
        for (uint256 i = 0; i <= dealIds.current(); i++) {
            if (
                dealsMapping[i].creator == _address ||
                dealsMapping[i].recruiter == _address
            ) {
                dealsOfAnAddress[arrayLocation] = i;
                arrayLocation++;
            }
        }
        return dealsOfAnAddress;
    }

    // admin functions

    /**
     * @notice  function to change the successFee ratio.
     * @dev     onlyOwner restriction, value is expressed as a percentage.
     * @param   _fee  .
     */
    function changeSuccessFee(uint128 _fee) external onlyOwner {
        honestWorkSuccessFee = _fee;
        emit successFeeChangedEvent(_fee);
    }

    /**
     * @notice  function to change the registry address.
     * @dev     onlyOwner restriction.
     * @param   _registry  .
     */
    function changeRegistry(IHWRegistry _registry) external onlyOwner {
        registry = _registry;
    }

    /**
     * @notice  function to claim the successFee earned by HW for a specified deal.
     * @dev     onlyOwner restriction.
     * @param   _dealId _feeCollector.
     */
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
        emit claimSuccessFeeEvent(_dealId, dealsMapping[_dealId].successFee);
    }

    /**
     * @notice  function to claim the successFee earned by HW for all deals.
     * @dev     onlyOwner restriction.
     * @param   _feeCollector  .
     */
    function claimSuccessFeeAll(address _feeCollector) external onlyOwner {
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
        emit claimSuccessFeeAllEvent(_feeCollector);
    }

    /**
     * @notice  function to change the extra payment limit.
     * @dev     onlyOwner restriction.
     * @param   _limit  .
     */
    function changeExtraPaymentLimit(uint64 _limit) external onlyOwner {
        extraPaymentLimit = _limit;
        emit changeExtraPaymentLimitEvent(_limit);
    }
    
    /**
     * @notice  function to change nativePayment allowances.
     * @dev     onlyOwner restriction.
     * @param   _bool  .
     */
    function allowNativePayment(bool _bool) external onlyOwner {
        nativePaymentAllowed = _bool;
    }

    /**
     * @notice  function to get Bnb price denominated in BUSD from pancakeswap.
     * @param   _amount  .
     */
    function getBnbPrice(uint256 _amount) public view returns (uint256) {
        uint256 reserve1;
        uint256 reserve2;
        (reserve1, reserve2, ) = pool.getReserves();
        return router.quote(_amount, reserve1, reserve2);
    }
}