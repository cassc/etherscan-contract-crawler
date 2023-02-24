// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./IHWRegistry.sol";

interface IHWEscrow {
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

    function createDealSignature(
        address _recruiter,
        address _creator,
        address _paymentToken,
        uint256 _totalPayment,
        uint256 _downPayment,
        uint256 _recruiterNFTId,
        bytes memory _signature
    ) external payable returns (uint256);

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
    ) external payable returns (uint256);

    function unlockPayment(
        uint256 _dealId,
        uint256 _paymentAmount,
        uint128 _rating,
        uint256 _recruiterNFT
    ) external;

    function withdrawPayment(uint256 _dealId) external;

    function claimPayment(
        uint256 _dealId,
        uint256 _withdrawAmount,
        uint128 _rating,
        uint256 _creatorNFT
    ) external;

    function additionalPayment(
        uint256 _dealId,
        uint256 _payment,
        uint256 _recruiterNFT,
        uint128 _rating
    ) external payable;

    function getDeal(uint256 _dealId) external view returns (Deal memory);

    function getCreator(uint256 _dealId) external view returns (address);

    function getRecruiter(uint256 _dealId) external view returns (address);

    function getPaymentToken(uint256 _dealId) external view returns (address);

    function getclaimedAmount(uint256 _dealId) external view returns (uint256);

    function getClaimableAmount(
        uint256 _dealId
    ) external view returns (uint256);

    function getDealCompletionRate(
        uint256 _dealId
    ) external view returns (uint256);

    function getTotalPayment(uint256 _dealId) external view returns (uint256);

    function getRecruiterRating(
        uint256 _dealId
    ) external view returns (uint128[] memory);

    function getCreatorRating(
        uint256 _dealId
    ) external view returns (uint128[] memory);

    function getAvgCreatorRating(
        uint256 _dealId
    ) external view returns (uint256);

    function getAvgRecruiterRating(
        uint256 _dealId
    ) external view returns (uint256);

    function getTotalSuccessFee() external view returns (uint256);

    function getDealSuccessFee(uint256 _dealId) external view returns (uint256);

    function getDealStatus(uint256 _dealId) external view returns (uint256);

    function getAdditionalPaymentLimit(
        uint256 _dealId
    ) external view returns (uint256);

    function getDealsOf(
        address _address
    ) external view returns (uint256[] memory);

    function changeSuccessFee(uint128 _fee) external;

    function changeRegistry(IHWRegistry _registry) external;

    function claimSuccessFee(uint256 _dealId, address _feeCollector) external;

    function claimTotalSuccessFee(address _feeCollector) external;

    function changeExtraPaymentLimit(uint64 _limit) external;

    function allowNativePayment(bool _bool) external;

    function getEthPrice(uint256 _amount) external view returns (uint256);

    function getNFTGrossRevenue(
        uint256 _tokenId
    ) external view returns (uint256);
}