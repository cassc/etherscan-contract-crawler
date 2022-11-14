// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {EvolvedCamels} from "./EvolvedCamels.sol";

/**
 * @author  . 0xFirekeeper
 * @title   . Oasis Mint
 * @notice  . Mints x amount of Evolved Camels and rewards minters with extra $OST!
 */

contract OasisMint is ReentrancyGuard, Ownable, IERC721Receiver {
     /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address payable immutable public ec;
    IERC20 immutable public ost;
    uint256 public ostRewardPerMint = 50000000000000000000000;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor (address payable _ec, IERC20 _ost) {
        ec = _ec;
        ost = _ost;
    }

    /*///////////////////////////////////////////////////////////////
                                USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function oasisMint(uint256 _amount) external payable nonReentrant {
        require(msg.value == EvolvedCamels(ec).mintCost(), "Invalid ETH Sent");

        uint256 ostReward = ostRewardPerMint * _amount;
        if(ost.balanceOf(address(this)) < ostReward) revert("Contract Balance Too Low");

        uint256 tokenIdToMint = EvolvedCamels(ec).totalSupply();
        EvolvedCamels(ec).publicSaleMint{value: msg.value}(_amount);
        IERC721(ec).transferFrom(address(this), msg.sender, tokenIdToMint);

        if(!ost.transfer(msg.sender, ostReward)) revert ("OST Transfer Failed");
    }

    /*///////////////////////////////////////////////////////////////
                                OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function withdrawOST() external onlyOwner {
        ost.transfer(owner(), ost.balanceOf(address(this)));
    }

    function setRewards(uint256 _rewards) external onlyOwner {
        ostRewardPerMint = _rewards;
    }

    /*///////////////////////////////////////////////////////////////
                                IERC721RECEIVER
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public override view returns (bytes4) {
        require(ec == _msgSender(), "Receives from EC Contract Only");

        return this.onERC721Received.selector;
    }
}