// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineDeliveryService {

    function initialize(
        address manager_
    ) external;

//////////////////////////////////////// DeliverySettings

    function getPoolDateBeginOfDelivery(uint256 poolId) external view returns (uint256);

    function _editPoolDateBeginOfDelivery(uint256 poolId, uint256 dateBegin) external;

//////////////////////////////////////// structs

    enum DeliveryTaskStatus {
        New,
        Canceled,
        Executed,
        WaitingForPayment,
        DeliveryInProcess
    }

    struct DeliveryTask {
        address tokenOwner;
        bool isInternal;
        string deliveryData;
        string supportResponse;
        DeliveryTaskStatus status;
        uint256 amount;
        uint256 bcbAmount;
    }

//////////////////////////////////////// events

    event CreateDeliveryRequest(
        uint256 deliveryTaskId,
        uint256 poolId,
        uint256 tokenId,
        address tokenOwner,
        bool isInternal
    );

    event SetDeliveryTaskAmount(
        uint256 deliveryTaskId,
        uint256 poolId,
        uint256 tokenId,
        uint256 amount,
        uint256 bcbAmount
    );

    event PayDeliveryTaskAmount(
        uint256 deliveryTaskId,
        uint256 poolId,
        uint256 tokenId,
        bool isInternal,
        uint256 amount,
        uint256 bcbAmount
    );

    event CancelDeliveryTask(
        uint256 deliveryTaskId,
        uint256 poolId,
        uint256 tokenId
    );

//////////////////////////////////////// DeliveryTasks public methods

    function requestDelivery(uint256 poolId, uint256 tokenId, string memory deliveryData) external returns (uint256 deliveryTaskId);

    function requestDeliveryForInternal(uint256 poolId, uint256 tokenId, string memory deliveryData) external returns (uint256 deliveryTaskId);

    function showSingleDeliveryTask(uint256 deliveryTaskId) external view returns (DeliveryTask memory);

    function showLastDeliveryTask(uint256 poolId, uint256 tokenId) external view returns (uint256, DeliveryTask memory);

    function showFullHistory(uint256 poolId, uint256 tokenId) external view returns (uint256, DeliveryTask[] memory);

    function setDeliveryTaskAmount(uint256 poolId, uint256 tokenId, uint256 amount) external;

    function payDeliveryTaskAmount(uint256 poolId, uint256 tokenId) external;

    function payDeliveryTaskAmountInternal(uint256 poolId, uint256 tokenId) external;

    function cancelDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse) external;

    function finishDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse) external;

//////////////////////////////////////// DeliveryTasks withdraw payment amount

    function withdrawPaymentAmount(address to) external;

}