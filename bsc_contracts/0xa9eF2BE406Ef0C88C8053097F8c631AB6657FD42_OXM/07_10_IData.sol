// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IData {
    function setString2AddressData(string memory str, address addr) external;

    function setString2UintData(string memory str, uint256 _uint) external;

    function setString2BoolData(string memory str, bool _bool) external;

    function setString2AddressBoolData(
        string memory str,
        address addr,
        bool _bool
    ) external;

    function setString2AddressUintData(
        string memory str,
        address addr,
        uint256 uint_
    ) external;

    function setAddress2UintData(address addr, uint256 _uint) external;

    function string2addressMapping(string memory str)
        external
        view
        returns (address);

    function string2uintMapping(string memory str)
        external
        view
        returns (uint256);

    function string2boolMapping(string memory str) external view returns (bool);

    function address2uintMapping(address addr) external view returns (uint256);

    function string2AddressBoolMapping(string memory str, address addr)
        external
        view
        returns (bool);

    function string2AddressUintMapping(string memory str, address addr)
        external
        view
        returns (uint256);
}