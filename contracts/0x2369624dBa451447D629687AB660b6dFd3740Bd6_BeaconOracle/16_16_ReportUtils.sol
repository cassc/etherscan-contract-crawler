// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

library ReportUtils {
    /**
     * description: Compress report data
     * @return compressed data
     */
    function compressReportData(
        bytes32 _validatorRankingRoot,
        uint256 _beaconBalance,
        uint256 _beaconValidators,
        uint16 _sameCount
    ) internal pure returns (bytes memory) {
        return abi.encode(_validatorRankingRoot, _beaconBalance, _beaconValidators, _sameCount);
    }

    /**
     * description: decompress data
     * @param {bytes memory} data compressed data
     * @return decompressed data
     */
    function decompressReportData(bytes memory data) internal pure returns (bytes32, uint256, uint256, uint16) {
        return abi.decode(data, (bytes32, uint256, uint256, uint16));
    }

    /**
     * description: Compress report data
     * @return compressed data
     */
    function isReportDifferentAndCount(
        bytes memory value,
        bytes32 _validatorRankingRoot,
        uint256 _beaconBalance,
        uint256 _beaconValidators
    ) internal pure returns (bool, uint16) {
        (bytes32 root, uint256 balance, uint256 validators, uint16 sameCount) = decompressReportData(value);
        bool isDifferent =
            !(root == _validatorRankingRoot && balance == _beaconBalance && validators == _beaconValidators);
        return (isDifferent, sameCount);
    }
}