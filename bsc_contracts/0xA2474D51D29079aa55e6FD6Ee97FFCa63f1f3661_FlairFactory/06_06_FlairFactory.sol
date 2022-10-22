// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Clones.sol";

contract FlairFactory is Initializable, Ownable {
    using Address for address payable;

    event ProxyCreated(address indexed deployer, address indexed proxyAddress);

    function withdraw() public {
        payable(owner()).sendValue(address(this).balance);
    }

    function cloneDeterministicSimple(
        address implementation,
        bytes32 salt,
        bytes calldata data
    ) external payable returns (address deployedProxy) {
        bytes32 _salt = keccak256(abi.encodePacked(msg.sender, salt));
        deployedProxy = Clones.cloneDeterministic(implementation, _salt);

        if (data.length > 0) {
            (bool success, bytes memory returndata) = deployedProxy.call(data);

            if (!success) {
                // Look for revert reason and bubble it up if present
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("FAILED_TO_CLONE");
                }
            }
        }

        emit ProxyCreated(msg.sender, deployedProxy);
    }

    function predictDeterministicSimple(address implementation, bytes32 salt)
        external
        view
        returns (address deployedProxy)
    {
        bytes32 _salt = keccak256(abi.encodePacked(msg.sender, salt));
        deployedProxy = Clones.predictDeterministicAddress(implementation, _salt);
    }
}