pragma solidity ^0.8.0;

interface IFeeController {
    /**
     * @dev Emitted when origination fee is updated
     */
    event UpdateOriginationFee(uint256 _newFee);

    function setOriginationFee(uint256 _originationFee) external;

    function getOriginationFee() external view returns (uint256);
}