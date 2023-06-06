//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct FeeInfo {
    address collectionAddress;
    uint32 feeBasisPoints;
    uint32 bullaTokenThreshold; //# of BULLA tokens held to get fee reduction
    uint32 reducedFeeBasisPoints; //reduced fee for BULLA token holders
}

interface IBullaManager {
    event FeeChanged(
        address indexed bullaManager,
        uint256 prevFee,
        uint256 newFee,
        uint256 blocktime
    );
    event CollectorChanged(
        address indexed bullaManager,
        address prevCollector,
        address newCollector,
        uint256 blocktime
    );
    event OwnerChanged(
        address indexed bullaManager,
        address prevOwner,
        address newOwner,
        uint256 blocktime
    );
    event BullaTokenChanged(
        address indexed bullaManager,
        address prevBullaToken,
        address newBullaToken,
        uint256 blocktime
    );
    event FeeThresholdChanged(
        address indexed bullaManager,
        uint256 prevFeeThreshold,
        uint256 newFeeThreshold,
        uint256 blocktime
    );
    event ReducedFeeChanged(
        address indexed bullaManager,
        uint256 prevFee,
        uint256 newFee,
        uint256 blocktime
    );

    function setOwner(address _owner) external;

    function setFee(uint32 _feeBasisPoints) external;

    function setCollectionAddress(address _collectionAddress) external;

    function setbullaThreshold(uint32 _threshold) external;

    function setReducedFee(uint32 reducedFeeBasisPoints) external;

    function setBullaTokenAddress(address _bullaTokenAddress) external;

    function getBullaBalance(address _holder) external view returns (uint256);

    function getFeeInfo(address _holder)
        external
        view
        returns (uint32, address);
    
    function getTransactionFee(address _holder, uint paymentAmount) external view returns(address sendFeesTo, uint transactionFee);
}