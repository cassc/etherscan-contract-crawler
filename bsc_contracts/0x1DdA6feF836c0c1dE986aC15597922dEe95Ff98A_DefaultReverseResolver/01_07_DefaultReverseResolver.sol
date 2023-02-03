// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../registry/SID.sol";
import "../registry/ReverseRegistrar.sol";

contract DefaultReverseResolver {
    // namehash('addr.reverse')
    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    SID public sid;
    mapping (bytes32 => string) public name;

    event RverseNameSet(bytes32 node, string name);

    /**
     * @dev Only permits calls by the reverse registrar.
     * @param node The node permission is required for.
     */
    modifier onlyOwner(bytes32 node) {
        require(tx.origin == sid.owner(node));
        _;
    }

    /**
     * @dev Constructor
     * @param sidAddr The address of the SID registry.
     */
    constructor(SID sidAddr) public {
        sid = sidAddr;

        // Assign ownership of the reverse record to our deployer
        ReverseRegistrar registrar = ReverseRegistrar(sid.owner(ADDR_REVERSE_NODE));
        if (address(registrar) != address(0x0)) {
            registrar.claim(msg.sender);
        }
    }

    /**
     * @dev Sets the name for a node.
     * @param node The node to update.
     * @param _name The name to set.
     */
    function setName(bytes32 node, string memory _name) public onlyOwner(node) {
        emit RverseNameSet(node, _name);
        name[node] = _name;
    }
}