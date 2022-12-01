// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "./Interfaces/IBridgeFactory.sol";
import "./BridgeFactory.sol";
import "./Interfaces/IBridge.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract Distribution {
    address public immutable BridgeFactoryAddress;
    address public immutable BUSD;

    mapping(uint256 => uint256) public projectTotalProfits;
    mapping(address => uint256) public valueOfRewardsPerUserBeingClaimed;

    constructor(address _NFTFactoryAddress, address _BUSDAddress) {
        BridgeFactoryAddress = _NFTFactoryAddress;
        BUSD = _BUSDAddress;
    }

    function addProfits(uint256 _projectID, uint256 _amount) external payable {
        BridgeFactory factoryInstance = BridgeFactory(BridgeFactoryAddress);

        require(_projectID <= factoryInstance.projectNumber(), "ProjectID does not exist");
        require(_projectID > 0, "Invalid ID type");

        projectTotalProfits[_projectID] = projectTotalProfits[_projectID] + _amount;

        IERC20(BUSD).transferFrom(msg.sender, address(this), _amount); // Added this to transfer funds to the contract before it gets distributed
        distributeProfits(_projectID, _amount);
    }

    function distributeProfits(uint256 _projectID, uint256 _amount) internal {
        IBridgeFactory factoryInstance = IBridgeFactory(BridgeFactoryAddress);
        IBridge bridgeInstance = IBridge(factoryInstance.getProjectAddress(_projectID));

        address[] memory usersAddress = bridgeInstance.getNFTHoldersArray();
        uint256 totalSupply = bridgeInstance.totalSupply();

        for (uint256 x = 0; x < usersAddress.length; x++) {
            require(bridgeInstance.balanceOf(usersAddress[x]) >= 1, "Address does not own any NFTs");

            uint256 portionOfNFTSHeld = 10000 / ((totalSupply * 100) / bridgeInstance.balanceOf(usersAddress[x]));
            uint256 amount = (_amount * portionOfNFTSHeld) / 100;

            valueOfRewardsPerUserBeingClaimed[usersAddress[x]] =
                valueOfRewardsPerUserBeingClaimed[usersAddress[x]] +
                amount;

            IERC20(BUSD).transfer(usersAddress[x], amount);
        }
    }
}