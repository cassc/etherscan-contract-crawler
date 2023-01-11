// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BaseController.sol";

interface IENS {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * Register an OpenDID name for free if already own an ENS name.
 */
contract ENSController is BaseController {
    IENS public immutable ens;

    constructor(address _registry, address _ens) BaseController(_registry) {
        ens = IENS(_ens);
    }

    function register(string memory name) external {
        uint256 tokenId = uint256(keccak256(bytes(name)));
        require(ens.ownerOf(tokenId) == msg.sender, "invalid ens name");
        uint256 len;
        (, len) = registry.register(name, msg.sender);
        require(len >= 4, "short name");
        bindAvatar(tokenId, msg.sender);
    }
}