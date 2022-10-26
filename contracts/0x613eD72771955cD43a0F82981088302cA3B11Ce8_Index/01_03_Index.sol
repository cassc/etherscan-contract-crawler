// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "Ownable.sol";

contract Index is Ownable {
    mapping(uint256 => string) public SilksContractsIndextoName;
    mapping(string => address) public SilksContractsMapping;
    mapping(address => string) public SilksContractsbyAddress;
    uint256 public addressCount;

    constructor(string[] memory names, address[] memory addresses) {
        addressCount = 0;
        for (uint256 i = 0; i < names.length; i++) {
            _setAddress(names[i], addresses[i]);
        }
    }

    function getAddress(string memory name) public view returns (address) {
        return SilksContractsMapping[name];
    }

    function getName(address contractAddress)
        public
        view
        returns (string memory)
    {
        return SilksContractsbyAddress[contractAddress];
    }

    function getAllContracts() public view returns (string memory) {
        string memory result;

        for (uint256 i = 0; i < addressCount; i++) {
            if (i == 0) {
                result = string(abi.encodePacked(result, "{"));
            }
            result = string(
                abi.encodePacked(
                    result,
                    "'",
                    SilksContractsIndextoName[i],
                    "'",
                    ":",
                    "'",
                    "0x",
                    toAsciiString(
                        SilksContractsMapping[SilksContractsIndextoName[i]]
                    ),
                    "'"
                )
            );
            if (i != addressCount - 1) {
                result = string(abi.encodePacked(result, ","));
            }
            if (i == addressCount - 1) {
                result = string(abi.encodePacked(result, "}"));
            }
        }
        return result;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function setAddress(string memory name, address contractAddress)
        public
        onlyOwner
    {
        _setAddress(name, contractAddress);
    }

    function _setAddress(string memory name, address contractAddress) internal {
        if (SilksContractsMapping[name] == address(0)) {
            SilksContractsIndextoName[addressCount] = name;
            SilksContractsbyAddress[contractAddress] = name;
            addressCount++;
        }
        SilksContractsMapping[name] = contractAddress;
        SilksContractsbyAddress[contractAddress] = name;
    }
}