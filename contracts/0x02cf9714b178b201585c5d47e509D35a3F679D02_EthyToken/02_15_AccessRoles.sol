// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "./Rescuable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract AccessRoles is Ownable, Rescuable {

    mapping(address => uint256) private Roles;

    modifier onlyAdmin() {
        require(Roles[msg.sender] >= 3 || msg.sender == owner(), "Not admin");
        _;
    }

    modifier onlyEditor() {
        require(Roles[msg.sender] >= 2, "Not editor");
        _;
    }

    modifier onlyMinter() {
        require(Roles[msg.sender] >= 1, "Not minter");
        _;
    }

    function setRole (address roleAddress, uint256 status) external onlyAdmin {
        Roles[roleAddress] = status;
    }

    function getRole (address roleAddress) public view returns (uint256) {
        return Roles[roleAddress];
    }

    // Pause

    bool public paused = true;

    function pause () public onlyOwner {
        paused = true;
    }

    function unpause () public onlyOwner {
        paused = false;
    }

    modifier whenNotPaused() {
        require(paused == false, "Paused");
        _;
    }

    // Freeze

    bool public frozen = false;

    function freeze () public onlyOwner {
        frozen = true;
    }

    modifier whenNotFrozen() {
        require(frozen == false, "Frozen");
        _;
    }

    // Rescuers

    function withdraw() public virtual onlyOwner {
        _withdraw(owner());
    }

    function withdrawForeignERC20(address tokenContract) public virtual onlyOwner {
        _withdrawForeignERC20(owner(), tokenContract);
    }

    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public virtual onlyOwner {
        _withdrawForeignERC721(owner(), tokenContract, tokenId);
    }

}