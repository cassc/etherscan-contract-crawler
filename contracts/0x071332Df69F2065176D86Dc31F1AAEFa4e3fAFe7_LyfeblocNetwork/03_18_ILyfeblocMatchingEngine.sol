// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;


import "./ILyfeblocStorage.sol";


interface ILyfeblocMatchingEngine {
    enum ProcessWithRate {NotRequired, Required}

    function setNegligibleRateDiffBps(uint256 _negligibleRateDiffBps) external;

    function setLyfeblocStorage(ILyfeblocStorage _LyfeblocStorage) external;

    function getNegligibleRateDiffBps() external view returns (uint256);

    function getTradingReserves(
        IERC20 src,
        IERC20 dest,
        bool isTokenToToken,
        bytes calldata hint
    )
        external
        view
        returns (
            bytes32[] memory reserveIds,
            uint256[] memory splitValuesBps,
            ProcessWithRate processWithRate
        );

    function doMatch(
        IERC20 src,
        IERC20 dest,
        uint256[] calldata srcAmounts,
        uint256[] calldata feesAccountedDestBps,
        uint256[] calldata rates
    ) external view returns (uint256[] memory reserveIndexes);
}