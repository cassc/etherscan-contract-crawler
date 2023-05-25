// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFeesFacet {
    struct IntegratorFeeInfo {
        bool isIntegrator; // flag for setting 0 fees for integrator      - 1 byte
        uint32 tokenFee; // total fee percent gathered from user          - 4 bytes
        uint32 RubicTokenShare; // token share of platform commission     - 4 bytes
        uint32 RubicFixedCryptoShare; // native share of fixed commission - 4 bytes
        uint128 fixedFeeAmount; // custom fixed fee amount                - 16 bytes
    }

    /**
     * @dev Initializes the FeesFacet with treasury address and max fee amount
     * No need to check initialized status because if max fee is 0 than there is no token fees
     * @param _feeTreasure Address to send fees to
     * @param _maxRubicPlatformFee Max value of Tubic token fees
     */
    function initialize(
        address _feeTreasure,
        uint256 _maxRubicPlatformFee,
        uint256 _maxFixedNativeFee
    ) external;

    /**
     * @dev Sets fee info associated with an integrator
     * @param _integrator Address of the integrator
     * @param _info Struct with fee info
     */
    function setIntegratorInfo(
        address _integrator,
        IntegratorFeeInfo memory _info
    ) external;

    /**
     * @dev Sets address of the treasure
     * @param _feeTreasure Address of the treasure
     */
    function setFeeTreasure(address _feeTreasure) external;

    /**
     * @dev Sets fixed crypto fee
     * @param _fixedNativeFee Fixed crypto fee
     */
    function setFixedNativeFee(uint256 _fixedNativeFee) external;

    /**
     * @dev Sets Rubic token fee
     * @notice Cannot be higher than limit set only by an admin
     * @param _platformFee Fixed crypto fee
     */
    function setRubicPlatformFee(uint256 _platformFee) external;

    /**
     * @dev Sets the limit of Rubic token fee
     * @param _maxFee The limit
     */
    function setMaxRubicPlatformFee(uint256 _maxFee) external;

    /// VIEW FUNCTIONS ///

    function calcTokenFees(
        uint256 _amount,
        address _integrator
    )
        external
        view
        returns (uint256 totalFee, uint256 RubicFee, uint256 integratorFee);

    function fixedNativeFee() external view returns (uint256 _fixedNativeFee);

    function RubicPlatformFee()
        external
        view
        returns (uint256 _RubicPlatformFee);

    function maxRubicPlatformFee()
        external
        view
        returns (uint256 _maxRubicPlatformFee);

    function maxFixedNativeFee()
        external
        view
        returns (uint256 _maxFixedNativeFee);

    function feeTreasure() external view returns (address feeTreasure);

    function integratorToFeeInfo(
        address _integrator
    ) external view returns (IFeesFacet.IntegratorFeeInfo memory _info);
}