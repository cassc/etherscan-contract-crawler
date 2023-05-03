// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "./LlamaLand.sol";

contract LlamaLandOrigin is Context, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CLAIM_ROLE = keccak256("CLAIM_ROLE");

    string public furCid;

    LlamaLand llamaLand;
    constructor(address _llamaLand, string memory _furCid) {
        llamaLand = LlamaLand(_llamaLand);
        furCid = _furCid;

        _grantRole(ADMIN_ROLE, llamaLand.admin());
        _setRoleAdmin(CLAIM_ROLE, ADMIN_ROLE);
    }

    function owner() view public returns (address) {
        return llamaLand.owner();
    }

    function admin() view public returns (address) {
        return llamaLand.admin();
    }

    function claim(address to) onlyRole(CLAIM_ROLE) external {
        uint tokenId = llamaLand.serialNo();
        string memory cid = string(abi.encodePacked(
                furCid,
                "/",
                Strings.toString(tokenId),
                ".json"
            ));
        llamaLand.mint(to, cid);
    }

    function getCuttingIndex(string memory seed, uint256 amount) private view returns (uint16) {
        return uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed))) % amount);
    }

    function setFur(string memory cid) onlyRole(ADMIN_ROLE) external {
        furCid = cid;
    }

    function destroy() external {
        require(_msgSender() == owner(), "Caller is not the owner");
        selfdestruct(payable(owner()));
    }
}