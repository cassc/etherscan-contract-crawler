pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { StakeHouseAccessControls } from "./StakeHouseAccessControls.sol";

interface StakeHouseUniverse {
    /// @notice Emitted when all of the core modules are initialised
    event CoreModulesInit();

    /// @notice Emitted after a Stakehouse has been deployed. A share token and brand are also deployed
    event NewStakeHouse(address indexed stakeHouse, uint256 indexed brandId);

    /// @notice Emitted after a member is added to an existing Stakehouse
    event MemberAddedToExistingStakeHouse(address indexed stakeHouse);

    /// @notice Emitted after a member is added to an existing house but a brand was created
    event MemberAddedToExistingStakeHouseAndBrandCreated(address indexed stakeHouse, uint256 indexed brandId);

    function accessControls() external view returns (StakeHouseAccessControls);

    function stakeHouseToKNOTIndex(address _house) external view returns (uint256 houseIndex);

    /// @notice Adds a new StakeHouse into the universe
    /// @notice A StakeHouse only comes into existence if one KNOT is being added
    /// @param _summoner StakeHouse creator
    /// @param _ticker Desired StakeHouse internal identifier.
    /// @param _firstMember bytes of the public key of the first member
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _summoner
    function newStakeHouse(
        address _summoner,
        string calldata _ticker,
        bytes calldata _firstMember,
        uint256 _savETHIndexId
    ) external returns (address);

    /// @notice Adds a KNOT into an existing StakeHouse (and does not create a brand)
    /// @param _stakeHouse Address of the house receiving the new member
    /// @param _memberId Public key of the KNOT
    /// @param _applicant Account adding the KNOT to the StakeHouse (derivative recipient)
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _applicant
    function addMemberToExistingHouse(
        address _stakeHouse,
        bytes calldata _memberId,
        address _applicant,
        uint256 _brandTokenId,
        uint256 _savETHIndexId
    ) external;

    /// @notice Adds a KNOT into an existing house but this KNOT creates a brand
    /// @param _stakeHouse Address of the house receiving the new member
    /// @param _memberId Public key of the KNOT
    /// @param _applicant Account adding the KNOT to the StakeHouse (derivative recipient)
    /// @param _ticker Proposed 3-5 letter ticker for brand
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _applicant
    function addMemberToHouseAndCreateBrand(
        address _stakeHouse,
        bytes calldata _memberId,
        address _applicant,
        string calldata _ticker,
        uint256 _savETHIndexId
    ) external;

    /// @notice Escape hatch for a user that wants to immediately exit the universe on entry
    /// @param _stakeHouse Address of the house user is rage quitting against
    /// @param _memberId Public key of the KNOT
    /// @param _rageQuitter Account rage quitting
    /// @param _amountOfETHInDepositQueue Amount of ETH below 1 ETH that is yet to be sent to the deposit contract
    function rageQuitKnot(
        address _stakeHouse,
        bytes calldata _memberId,
        address _rageQuitter,
        uint256 _amountOfETHInDepositQueue
    ) external;

    /// @notice Number of StakeHouses in the universe
    function numberOfStakeHouses() external view returns (uint256);

    /// @notice Returns the address of a StakeHouse assigned to an index
    /// @param _index Query which must be greater than zero
    function stakeHouseAtIndex(uint256 _index) external view returns (address);

    /// @notice number of members of a StakeHouse (aggregate number of KNOTs)
    /// @dev Imagine we have a rope loop attached to a StakeHouse KNOT, each KNOT on the loop is a member
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
        address stakeHouse,
        address sETHAddress,
        address applicant,
        uint256 knotMemberIndex,
        uint256 flags,
        bool isActive
    );

    /// @notice Get all info about a StakeHouse KNOT (a member a.k.a a validator)
    /// @param _memberId ID of member (Validator public key) assigned to StakeHouse
    function stakeHouseKnotInfo(bytes memory _memberId) external view returns (
        address stakeHouse,     // Address of registered StakeHouse
        address sETHAddress,    // Address of sETH address associated with StakeHouse
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint256 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );
}