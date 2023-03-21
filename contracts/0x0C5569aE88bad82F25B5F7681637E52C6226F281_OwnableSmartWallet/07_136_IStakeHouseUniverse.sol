pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

interface IStakeHouseUniverse {

    ////////////
    // Events //
    ////////////

    /// @notice Emitted when all of the core modules are initialised
    event CoreModulesInit();

    /// @notice Emitted after a Stakehouse has been deployed. A share token and brand are also deployed
    event NewStakeHouse(address indexed stakeHouse, uint256 indexed brandId);

    /// @notice Emitted after a member is added to an existing Stakehouse
    event MemberAddedToExistingStakeHouse(address indexed stakeHouse);

    /// @notice Emitted after a member is added to an existing house but a brand was created
    event MemberAddedToExistingStakeHouseAndBrandCreated(address indexed stakeHouse, uint256 indexed brandId);

    ////////////
    // View   //
    ////////////

    /// @notice Number of StakeHouses in the universe
    function numberOfStakeHouses() external view returns (uint256);

    /// @notice Returns the address of a StakeHouse assigned to an index
    /// @param _index Query which must be greater than zero
    function stakeHouseAtIndex(uint256 _index) external view returns (address);

    /// @notice number of members of a StakeHouse (aggregate number of KNOTs)
    /// @dev This enumerable method is used along with `numberOfStakeHouses`
    /// @param _index of a StakeHouse
    /// @return uint256 The number of total KNOTs / members of a StakeHouse
    function numberOfSubKNOTsAtIndex(uint256 _index) external view returns (uint256);

    /// @notice Given a StakeHouse index and a member index (i.e. coordinates to a member), return the member ID
    /// @param _index Coordinate assigned to Stakehouse
    /// @param _subIndex Coordinate assigned to a member of a Stakehouse
    function subKNOTAtIndexCoordinates(uint256 _index, uint256 _subIndex) external view returns (bytes memory);

    /// @notice Get all info about a StakeHouse KNOT (a member a.k.a a validator) given index coordinates
    /// @param _index StakeHouse index
    /// @param _subIndex Member index within the StakeHouse
    function stakeHouseKnotInfoGivenCoordinates(uint256 _index, uint256 _subIndex) external view returns (
        address stakeHouse,     // Address of registered StakeHouse
        address sETHAddress,    // Address of sETH address associated with StakeHouse
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint256 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );

    // @notice Get all info about a StakeHouse KNOT (a member a.k.a a validator)
    /// @param _blsPublicKey ID of member (Validator public key) assigned to StakeHouse
    function stakeHouseKnotInfo(bytes calldata _blsPublicKey) external view returns (
        address stakeHouse,     // Address of registered StakeHouse
        address sETHAddress,    // Address of sETH address associated with StakeHouse
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint256 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );

    /// @notice Returns the address of the Stakehouse that a KNOT is associated with
    function memberKnotToStakeHouse(bytes calldata _blsPublicKey) external view returns (address);
}