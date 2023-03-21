pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

contract MockStakeHouseUniverse {

    mapping(bytes => address) associatedHouseForKnot;
    function setAssociatedHouseForKnot(bytes calldata _blsPublicKey, address _house) external {
        associatedHouseForKnot[_blsPublicKey] = _house;
    }

    mapping(bytes => bool) useOverride;
    mapping(bytes => bool) isBLSKeyActive;
    function setIsActive(bytes calldata _blsKey, bool _isActive) external {
        useOverride[_blsKey] = true;
        isBLSKeyActive[_blsKey] = _isActive;
    }

    function stakeHouseKnotInfo(bytes calldata _blsPublicKey) external view returns (
        address stakeHouse,     // Address of registered StakeHouse
        address sETHAddress,    // Address of sETH address associated with StakeHouse
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint256 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    ) {
        return (
            associatedHouseForKnot[_blsPublicKey] != address(0) ? associatedHouseForKnot[_blsPublicKey] : address(uint160(5)) ,
            address(0),
            address(0),
            0,
            0,
            useOverride[_blsPublicKey] ? isBLSKeyActive[_blsPublicKey] : true
        );
    }

    function memberKnotToStakeHouse(bytes calldata _blsPublicKey) external view returns (address) {
        return associatedHouseForKnot[_blsPublicKey];
    }
}