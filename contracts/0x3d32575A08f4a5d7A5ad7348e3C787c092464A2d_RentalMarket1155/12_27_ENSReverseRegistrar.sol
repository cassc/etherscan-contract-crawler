// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "./OwnableUpgradeable.sol";

abstract contract ENSReverseRegistrar is OwnableUpgradeable {
    function ENS_setName(string memory name) public onlyAdmin {
        uint256 id;
        assembly {
            id := chainid()
        }
        bytes memory _data = abi.encodeWithSignature("setName(string)", name);
        require(id == 1, "not mainnet");
        Address.functionCall(
            address(0x084b1c3C81545d370f3634392De611CaaBFf8148),
            _data
        );
    }
}