// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineDeliveryService {

    function initialize(
        address manager_
    ) external;

//////////////////////////////////////// DeliverySettings

    function getPoolDateBeginOfDelivery(uint256 poolId) external view returns (uint256);

    function _editPoolDateBeginOfDelivery(uint256 poolId, uint256 dateBegin) external;

//////////////////////////////////////// DeliveryTasks public methods

    enum DeliveryTaskStatus {
        New,
        Canceled,
        Executed,
        InProcess
    }

    struct DeliveryTask {
        address tokenOwner;
        bool isInternal;
        string deliveryData;
        string supportResponse;
        DeliveryTaskStatus status;
    }

    event CreateDeliveryRequest(
        uint256 deliveryTaskId,
        uint256 poolId,
        uint256 tokenId,
        address indexed tokenOwner,
        bool isInternal
    );

    function requestDelivery(uint256 poolId, uint256 tokenId, string memory deliveryData) external returns (uint256 deliveryTaskId);

    function requestDeliveryForInternal(uint256 poolId, uint256 tokenId, string memory deliveryData) external returns (uint256 deliveryTaskId);

    function showSingleDeliveryTask(uint256 deliveryTaskId) external view returns (DeliveryTask memory);

    function showLastDeliveryTask(uint256 poolId, uint256 tokenId) external view returns (DeliveryTask memory);

    function showFullHistory(uint256 poolId, uint256 tokenId) external view returns (uint256, DeliveryTask[] memory);

    function setSupportResponse(uint256 poolId, uint256 tokenId, string memory supportResponse) external;

    function cancelDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse) external;

    function finishDeliveryTask(uint256 poolId, uint256 tokenId, string memory supportResponse) external;
}