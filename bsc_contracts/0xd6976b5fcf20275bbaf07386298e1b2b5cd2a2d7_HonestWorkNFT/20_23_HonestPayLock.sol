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







contract HonestPayLock is Ownable, ReentrancyGuard {
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
        uint256 availablePayment; // a variable to keep track of the unlocked payment which can be claimed by the creator
        Status status; // deal Status
        uint256[] recruiterRating; // recruiter's rating array
        uint256[] creatorRating; // creator's rating array
    }
    IHWRegistry public registry; //registry contract definition for retreiving the whitelisted payment mediums
    HonestWorkNFT public hw721; //nft contract definition for recording grossRevenues to the nft.


    IUniswapV2Router01 public router = IUniswapV2Router01(0x10ED43C718714eb63d5aA57B78B54704E256024E); //pancake router
    IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // busd
    IPool public pool = IPool(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16); // busd-bnb pool

    
    uint256 public extraPaymentLimit; //limit for additional payments--currently capped to 3
    uint256 public honestWorkSuccessFee; //honestWork's cut from the deals, currently set to %5
    uint256 public totalCollectedSuccessFee; //total amount of success fee collected by honestWork
    

    mapping(uint256 => uint256) public additionalPaymentLimit; //keeps track of the additional payments made for each deal
    mapping(uint256 => Deal) public dealsMapping; //mapping for keeping track of each offered deal. DealIds are unique.


    event OfferCreatedEvent(address indexed _recruiter, address indexed _creator, uint256 indexed _totalPayment, address _paymentToken); 
    event paymentUnlockedEvent(uint256 _dealId,address indexed _recruiter, uint256 indexed _unlockedAmount);
    event claimPaymentEvent(uint256 indexed _dealId,address indexed _creator, uint256 indexed _paymentReceived);
    event additionalPaymentEvent(uint256 indexed _dealId, address indexed _recruiter, uint256 indexed _payment);
    event withdrawPaymentEvent(uint256 indexed _dealId, Status status);
    event successFeeChangedEvent(uint256 _newSuccessFee);
    event claimSuccessFeeEvent(uint256 indexed _dealId, uint256 _amount);
    event changeExtraPaymentLimitEvent(uint256 _newPaymentLimit);
    event claimSuccessFeeAllEvent(address _collector);

    //Using a counter to count the dealIds, keeping them unique
    using Counters for Counters.Counter;
    Counters.Counter public dealIds;



    constructor(
        address _registry,
        address _HW721
    ) Ownable() {
        honestWorkSuccessFee = 5;
        registry = IHWRegistry(_registry);
        hw721 = HonestWorkNFT(_HW721);
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
     * @param   _nonce.
     */
    function createDeal(
        address _recruiter,
        address _creator,
        address _paymentToken,
        uint256 _totalPayment,
        uint256 _nonce
        //bytes memory signature
    ) external payable returns (uint256) {
        // if (msg.sender == _recruiter) {
        //     require(
        //         verify(
        //             _creator,
        //             _recruiter,
        //             _creator,
        //             _paymentToken,
        //             _totalPayment,
        //             _nonce,
        //             signature
        //         )
        //     );
        // }

        require(
            registry.isAllowedAmount(_paymentToken, _totalPayment),
            "the token you are trying to pay with is either not whitelisted or you are exceeding the allowed amount"
        );
        dealIds.increment();
        uint256 _dealId = dealIds.current();
        uint256[] memory arr1;
        uint256[] memory arr2;
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
        emit OfferCreatedEvent(_recruiter, _creator, _totalPayment, _paymentToken);
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
        uint256 _rating,
        uint256 _recruiterNFT
    ) external {
        require(
            dealsMapping[_dealId].status == Status.OfferInitiated,
            "deal is either completed or cancelled"
        );
        require(
            _rating >= 0 && _rating <= 10,
            "rating must be between 0 and 10"
        );
        require(
            dealsMapping[_dealId].recruiter == msg.sender,
            "only recruiter can unlock payments"
        );
        require(
            hw721.tokenOfOwnerByIndex(dealsMapping[_dealId].recruiter,0) == _recruiterNFT,
            "only recruiter owned nftId can be passed as an argument"
        );
        

        dealsMapping[_dealId].availablePayment += _paymentAmount;
        address _paymentToken = dealsMapping[_dealId].paymentToken;

        require(
            dealsMapping[_dealId].totalPayment >=
                dealsMapping[_dealId].availablePayment + dealsMapping[_dealId].paidAmount,
            "can not go above total payment, use additional payment function pls"
        );
        dealsMapping[_dealId].creatorRating.push(_rating * 100);

        if (hw721.balanceOf(msg.sender) == 1) {
            uint256 grossRev = (_paymentToken == address(0) ? getBnbPrice(_paymentAmount) : _paymentAmount);
            hw721.recordGrossRevenue(_recruiterNFT, grossRev);
        }
        emit paymentUnlockedEvent(_dealId, dealsMapping[_dealId].recruiter, _paymentAmount);
    }


    /**
     * @notice function cancels the deal.
     * @dev    function is to be called by the recruiter of the _dealId specified
        Upon calling, the recruiter shows intent to cancel the deal. Function sends the remaining
        token amount to the recruiter. 
     * @param   _dealId  .
     */
    function withdrawPayment(uint256 _dealId) external {
        require(
            dealsMapping[_dealId].status == Status.OfferInitiated,
            "job should be active"
        );
        require(
            dealsMapping[_dealId].recruiter == msg.sender,
            "only recruiter can withdraw payments"
        );  
        address _paymentToken = dealsMapping[_dealId].paymentToken;
        uint256 amountToBeWithdrawn = dealsMapping[_dealId].totalPayment -
            dealsMapping[_dealId].paidAmount;
        if (_paymentToken == address(0)) {
            (bool payment, ) = payable(dealsMapping[_dealId].recruiter).call{
                value: amountToBeWithdrawn
            }("");
            require(payment, "Failed to send payment");
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);
            paymentToken.approve(
                dealsMapping[_dealId].recruiter,
                amountToBeWithdrawn
            );
            paymentToken.transferFrom(
                address(this),
                msg.sender,
                (amountToBeWithdrawn)
            );
        }

        dealsMapping[_dealId].status = Status.JobCancelled;
        emit withdrawPaymentEvent(_dealId, dealsMapping[_dealId].status);
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
        uint256 _rating,
        uint256 _creatorNFT
    ) external {
        require(
            dealsMapping[_dealId].status == Status.OfferInitiated,
            "deal is either completed or cancelled"
        );

        require(
            _rating >= 0 && _rating <= 10,
            "rating must be between 0 and 10"
        );
        require(
            dealsMapping[_dealId].creator == msg.sender,
            "only creator can receive payments"
        );
        require(
            dealsMapping[_dealId].availablePayment >= _withdrawAmount,
            "desired payment is not available yet"
        );
        require(
            hw721.tokenOfOwnerByIndex(dealsMapping[_dealId].creator,0) == _creatorNFT,
            "only creator owned nftId can be passed as an argument"
        );
        address _paymentToken = dealsMapping[_dealId].paymentToken;
        dealsMapping[_dealId].paidAmount += _withdrawAmount;
        dealsMapping[_dealId].availablePayment -= _withdrawAmount;
        dealsMapping[_dealId].recruiterRating.push(_rating * 100);
        dealsMapping[_dealId].successFee +=
            (_withdrawAmount * honestWorkSuccessFee) /
            100;
        if (_paymentToken == address(0)) {
            (bool payment, ) = payable(dealsMapping[_dealId].creator).call{
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
        if (hw721.balanceOf(msg.sender) == 1) {
            uint256 grossRev = (_paymentToken == address(0) ? getBnbPrice(_withdrawAmount) : _withdrawAmount);
            hw721.recordGrossRevenue(_creatorNFT, grossRev);
        }
        if (
            dealsMapping[_dealId].paidAmount >=
            dealsMapping[_dealId].totalPayment
        ) {
            dealsMapping[_dealId].status = Status.JobCompleted;
        }

        emit claimPaymentEvent(_dealId, dealsMapping[_dealId].creator, _withdrawAmount);
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
        uint256 _rating
    ) external payable {

        require(
            dealsMapping[_dealId].status == Status.OfferInitiated,
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
            dealsMapping[_dealId].status == Status.OfferInitiated,
            "job should be active"
        );
        require(
            dealsMapping[_dealId].recruiter == msg.sender,
            "only recruiter can add payments"
        );

        require(
            hw721.tokenOfOwnerByIndex(dealsMapping[_dealId].recruiter,0) == _recruiterNFT,
            "only recruiter owned nftId can be passed as an argument"
        );
        address _paymentToken = dealsMapping[_dealId].paymentToken;
        if (_paymentToken == address(0)) {
            require(
                msg.value >= _payment,
                "recruiter should deposit the additional payment"
            );
            dealsMapping[_dealId].availablePayment += _payment;
            dealsMapping[_dealId].totalPayment += _payment;
        } else {
            IERC20 paymentToken = IERC20(_paymentToken);
            paymentToken.transferFrom(msg.sender, address(this), _payment);
            dealsMapping[_dealId].availablePayment += _payment;
            dealsMapping[_dealId].totalPayment += _payment;
        }

        if (hw721.balanceOf(msg.sender) == 1) {
            uint256 grossRev = (_paymentToken == address(0) ? getBnbPrice(_payment) : _payment);
            hw721.recordGrossRevenue(_recruiterNFT, grossRev);
        }

        additionalPaymentLimit[_dealId] += 1;
        dealsMapping[_dealId].creatorRating.push(_rating * 100);
        emit additionalPaymentEvent(_dealId, dealsMapping[_dealId].recruiter, _payment);
    }

    function getOfferHash(
        address _employer,
        address _creator,
        address _paymentToken,
        uint256 _totalAmount,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _employer,
                    _creator,
                    _paymentToken,
                    _totalAmount,
                    _nonce
                )
            );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                ) 
            );
    }

    function verify(
        address _signer,
        address _recruiter,
        address _creator,
        address _paymentToken,
        uint256 _totalAmount,
        uint256 _nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getOfferHash(
            _recruiter,
            _creator,
            _paymentToken,
            _totalAmount,
            _nonce
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    //Getters

    function getDeal(uint256 _dealId) external view returns (Deal memory) {
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

    function getPaidAmount(uint256 _dealId) external view returns (uint256) {
        return dealsMapping[_dealId].paidAmount;
    }

    function getAvailablePayment(uint256 _dealId)
        external
        view
        returns (uint256)
    {
        return dealsMapping[_dealId].availablePayment;
    }

    function getJobCompletionRate(uint256 _dealId)
        external
        view
        returns (uint256)
    {
        return ((dealsMapping[_dealId].paidAmount * 100) /
            dealsMapping[_dealId].totalPayment);
    }

    function getTotalPayment(uint256 _dealId)
        external
        view
        returns (uint256)
    {
        return (dealsMapping[_dealId].totalPayment);
    }


    function getRecruiterRating(uint256 _dealId)
        external
        view
        returns (uint256[] memory)
    {
        return (dealsMapping[_dealId].recruiterRating);
    }

    function getCreatorRating(uint256 _dealId)
        external
        view
        returns (uint256[] memory)
    {
        return (dealsMapping[_dealId].creatorRating);
    }

    function getAvgCreatorRating(uint256 _dealId)
        external
        view
        returns (uint256)
    {
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

    function getAvgRecruiterRating(uint256 _dealId)
        external
        view
        returns (uint256)
    {
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

    function getTotalSuccessFee()
        external
        view
        returns (uint256 totalSuccessFee)
    {
        for (uint256 i = 1; i <= dealIds.current(); i++) {
            totalSuccessFee += dealsMapping[i].successFee;
        }
    }

    function getDealSuccessFee(uint256 _dealId)
        external
        view
        returns (uint256)
    {
        
        return dealsMapping[_dealId].successFee;
    }


    function getDealStatus(uint256 _dealId) external view returns(uint) {
        return uint(dealsMapping[_dealId].status);
    }

    function getAdditionalPaymentLimit(uint256 _dealId) external view returns(uint) {
        return additionalPaymentLimit[_dealId];
    }

    // admin functions

    function changeSuccessFee(uint256 _fee) external onlyOwner {
        honestWorkSuccessFee = _fee;
        emit successFeeChangedEvent(_fee);
    }

    function changeRegistry(IHWRegistry _registry) external onlyOwner {
        registry = _registry;
    }

    function claimSuccessFee(uint256 _dealId, address _feeCollector)
        external
        onlyOwner
    {
        uint256 successFee = dealsMapping[_dealId].successFee;

        if(dealsMapping[_dealId].paymentToken != address(0)) {
            IERC20 paymentToken = IERC20(dealsMapping[_dealId].paymentToken);
            paymentToken.transfer(_feeCollector, successFee );
        }
        else {
            (bool payment, ) = payable(_feeCollector).call{
                value: successFee
            }("");
            require(payment, "payment failed");
            
            
            
    }
            totalCollectedSuccessFee += successFee;
            dealsMapping[_dealId].successFee = 0;
            emit claimSuccessFeeEvent(_dealId,dealsMapping[_dealId].successFee );
    }

    function claimSuccessFeeAll(address _feeCollector) external onlyOwner {
        
        for (uint256 i = 1; i <= dealIds.current(); i++) {
            uint256 successFee = dealsMapping[i].successFee;
            if(successFee > 0) {
            if(dealsMapping[i].paymentToken == address(0)) {
                (bool payment, ) = payable(_feeCollector).call{
                value: successFee
            }("");
            require(payment, "payment failed");
            }
            else {
                IERC20 paymentToken = IERC20(dealsMapping[i].paymentToken);
                paymentToken.transfer(_feeCollector, successFee);
            }
            dealsMapping[i].successFee = 0;
        }
        }
        emit claimSuccessFeeAllEvent(_feeCollector);
    }
    
    function changeExtraPaymentLimit(uint256 _limit) external onlyOwner {
        extraPaymentLimit = _limit;
        emit changeExtraPaymentLimitEvent(_limit);
    }


    function getBnbPrice(uint256 _amount) public view returns(uint) {
        uint256 reserve1;
        uint256 reserve2;
        (reserve1, reserve2, ) = pool.getReserves();
        return router.quote(_amount, reserve1, reserve2);
    }

}