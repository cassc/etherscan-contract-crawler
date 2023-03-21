pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

contract MockSlotRegistry {

    mapping(address => mapping(address => mapping(bytes => uint256))) userCollateralisedSLOTBalanceForKnot;
    function setUserCollateralisedSLOTBalanceForKnot(address _stakeHouse, address _user, bytes calldata _blsPublicKey, uint256 _bal) external {
        userCollateralisedSLOTBalanceForKnot[_stakeHouse][_user][_blsPublicKey] = _bal;
    }

    /// @notice Total collateralised SLOT owned by an account for a given KNOT in a Stakehouse
    function totalUserCollateralisedSLOTBalanceForKnot(address _stakeHouse, address _user, bytes calldata _blsPublicKey) external view returns (uint256) {
        return userCollateralisedSLOTBalanceForKnot[_stakeHouse][_user][_blsPublicKey];
    }

    mapping(bytes => uint256) _numberOfCollateralisedSlotOwnersForKnot;
    function setNumberOfCollateralisedSlotOwnersForKnot(bytes calldata _blsPublicKey, uint256 _numOfOwners) external {
        _numberOfCollateralisedSlotOwnersForKnot[_blsPublicKey] = _numOfOwners;
    }

    /// @notice Total number of collateralised SLOT owners for a given KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    function numberOfCollateralisedSlotOwnersForKnot(bytes calldata _blsPublicKey) external view returns (uint256) {
        return _numberOfCollateralisedSlotOwnersForKnot[_blsPublicKey] == 0 ? 1 : _numberOfCollateralisedSlotOwnersForKnot[_blsPublicKey];
    }

    mapping(bytes => mapping(uint256 => address)) collateralisedOwnerAtIndex;
    function setCollateralisedOwnerAtIndex(bytes calldata _blsPublicKey, uint256 _index, address _owner) external {
        collateralisedOwnerAtIndex[_blsPublicKey][_index] = _owner;
    }

    /// @notice Fetch a collateralised SLOT owner address for a specific KNOT at a specific index
    function getCollateralisedOwnerAtIndex(bytes calldata _blsPublicKey, uint256 _index) external view returns (address) {
        return collateralisedOwnerAtIndex[_blsPublicKey][_index];
    }

    mapping(address => address) houseToShareToken;
    function setShareTokenForHouse(address _stakeHouse, address _sETH) external {
        houseToShareToken[_stakeHouse] = _sETH;
    }

    /// @notice Returns the address of the sETH token for a given Stakehouse registry
    function stakeHouseShareTokens(address _stakeHouse) external view returns (address) {
        return houseToShareToken[_stakeHouse];
    }

    function currentSlashedAmountOfSLOTForKnot(bytes calldata) external view returns (uint256) {
        return 0;
    }
}