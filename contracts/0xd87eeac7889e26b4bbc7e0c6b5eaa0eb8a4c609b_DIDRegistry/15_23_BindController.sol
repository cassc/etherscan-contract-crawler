// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "./BaseController.sol";

/**
 * Bind records for DID name.
 */
contract BindController is Ownable {
    IRegistry public immutable registry;

    constructor(address _registry) Ownable() {
        registry = IRegistry(_registry);
    }

    function bind(
        uint256 tokenId,
        string calldata label,
        string calldata value
    ) external {
        registry.bind(tokenId, label, value, msg.sender);
    }

    function batchBind(
        uint256 tokenId,
        string[] calldata labels,
        string[] calldata values
    ) external {
        registry.batchBind(tokenId, labels, values, msg.sender);
    }
}