// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IRegistry is IAccessControl {
    event MahaChanged(address indexed whom, address _old, address _new);
    event VoterChanged(address indexed whom, address _old, address _new);
    event LockerChanged(address indexed whom, address _old, address _new);
    event GovernorChanged(address indexed whom, address _old, address _new);
    event StakerChanged(address indexed whom, address _old, address _new);
    event EmissionControllerChanged(
        address indexed whom,
        address _old,
        address _new
    );

    function maha() external view returns (address);

    function gaugeVoter() external view returns (address);

    function locker() external view returns (address);

    function staker() external view returns (address);

    function emissionController() external view returns (address);

    function governor() external view returns (address);

    function getAllAddresses()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );

    function ensureNotPaused() external;

    function setMAHA(address _new) external;

    function setEmissionController(address _new) external;

    function setStaker(address _new) external;

    function setVoter(address _new) external;

    function setLocker(address _new) external;

    function setGovernor(address _new) external;
}