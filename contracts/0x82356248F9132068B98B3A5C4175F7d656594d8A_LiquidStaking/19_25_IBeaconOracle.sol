// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

/**
 * @title Beacon Oracle and Dao
 *
 * BeaconOracle data acquisition and verification
 * Dao management
 */
interface IBeaconOracle {
    /**
     * @notice Verify the value of nft. leaf: bytes calldata pubkey, uint256 validatorBalance, uint256 nftTokenID
     * @param _proof validator's merkleTree proof
     * @param _pubkey validator pubkey
     * @param _validatorBalance validator consensus layer balance
     * @param _tokenId nft token Id
     * @return whether the validation passed
     */
    function verifyNftValue(
        bytes32[] calldata _proof,
        bytes calldata _pubkey,
        uint256 _validatorBalance,
        uint256 _tokenId
    ) external view returns (bool);

    /**
     * @return {bool} is oracleMember
     */
    function isOracleMember(address _oracleMember) external view returns (bool);

    /**
     * Add oracle member
     */
    function addOracleMember(address _oracleMember) external;

    /**
     * Add oracle member and configure all members to re-report
     */
    function removeOracleMember(address _oracleMember) external;

    /**
     * @return {uint128} The total balance of the consensus layer
     */
    function getBeaconBalances() external view returns (uint256);

    /**
     * @return {uint128} The total balance of the pending validators
     */
    function getPendingBalances() external view returns (uint256);
    /**
     * @return {uint128} The total validator count of the consensus layer
     */
    function getBeaconValidators() external view returns (uint256);

    /**
     * @notice add pending validator value
     */
    function addPendingBalances(uint256 _pendingBalance) external;

    event AddOracleMember(address _oracleMember);
    event RemoveOracleMember(address _oracleMember);
    event ResetExpectedEpochId(uint256 _expectedEpochId);
    event ExpectedEpochIdUpdated(uint256 _expectedEpochId);
    event ResetEpochsPerFrame(uint256 _epochsPerFrame);
    event ReportBeacon(
        uint256 _pochId,
        address _oracleMember,
        uint32 _sameReportCount,
        uint256 _beaconBalance,
        uint256 _beaconValidators,
        bytes32 _validatorRankingRoot
    );
    event ReportSuccess(
        uint256 _epochId,
        uint256 _sameReportCount,
        uint32 _quorum,
        uint256 _beaconBalance,
        uint256 _beaconValidators,
        bytes32 _validatorRankingRoot
    );
    event PendingBalancesAdd(uint256 _addBalance, uint256 _totalBalance);
    event PendingBalancesReset(uint256 _totalBalance);
    event LiquidStakingChanged(address _before, address _after);
    event DaoAddressChanged(address _oldDao, address _dao);
}