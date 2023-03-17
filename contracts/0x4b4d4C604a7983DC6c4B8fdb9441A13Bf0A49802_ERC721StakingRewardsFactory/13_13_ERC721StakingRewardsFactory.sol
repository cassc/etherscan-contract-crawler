// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721StakingRewards.sol";

contract ERC721StakingRewardsFactory is Ownable {

    address public deployerAddress;

    constructor(address _deployerAddress) {
        deployerAddress = _deployerAddress;
    }

    function updateDeployer(address _deployerAddress) external onlyOwner {
        deployerAddress = _deployerAddress;
    }

    function deploy(
        address _vaultAddress,
        address _owner
    ) external returns (address) {
        require(deployerAddress == msg.sender, "Not authorized");
        ERC721StakingRewards _contract = new ERC721StakingRewards(_vaultAddress, _owner);
        return address(_contract);
    }
}