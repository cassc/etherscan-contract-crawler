// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721StakingVault.sol";

contract ERC721StakingVaultFactory is Ownable {

    address public deployerAddress;

    constructor(address _deployerAddress) {
        deployerAddress = _deployerAddress;
    }

    function updateDeployer(address _deployerAddress) external onlyOwner {
        deployerAddress = _deployerAddress;
    }

    function deploy(
        bool _softStaking,
        bool _hardStaking,
        address _owner
    ) external returns (address) {
        require(deployerAddress == msg.sender, "Not authorized");
        ERC721StakingVault _contract = new ERC721StakingVault(_softStaking, _hardStaking, _owner);
        return address(_contract);
    }
}