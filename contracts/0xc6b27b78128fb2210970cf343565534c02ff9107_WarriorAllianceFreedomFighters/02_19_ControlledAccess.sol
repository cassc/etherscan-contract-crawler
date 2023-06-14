// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/* @title ControlledAccess
 * @dev The ControlledAccess contract allows function to be restricted to users
 * that possess a signed authorization from the owner of the contract. This signed
 * message includes the user to give permission to and the contract address to prevent
 * reusing the same authorization message on different contract with same owner.
 */

contract ControlledAccess is Ownable {
    /*
     * @dev Requires msg.sender to have valid access message.
     * @param _v ECDSA signature parameter v.
     * @param _r ECDSA signature parameters r.
     * @param _s ECDSA signature parameters s.
     */
    modifier onlyValidAccess(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        require(isValidAccessMessage(msg.sender, _v, _r, _s), "Access Denied");
        _;
    }

    /*
     * @dev Verifies if message was signed by owner to give access to _add for this contract.
     *      Assumes Geth signature prefix.
     * @param _add Address of agent with access
     * @param _v ECDSA signature parameter v.
     * @param _r ECDSA signature parameters r.
     * @param _s ECDSA signature parameters s.
     * @return Validity of access message for a given address.
     */
    function isValidAccessMessage(
        address _add,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(_add));
        address sender = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            _v,
            _r,
            _s
        );
        return (owner() == sender);
    }
}