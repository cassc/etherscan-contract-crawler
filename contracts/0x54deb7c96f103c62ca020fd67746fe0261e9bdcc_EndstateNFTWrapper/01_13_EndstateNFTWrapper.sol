// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IEndstateNFTWrapper} from "../interfaces/IEndstateNFTWrapper.sol";

contract EndstateNFTWrapper is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IEndstateNFTWrapper
{
    mapping(uint256 => DropInfo) public drops;
    mapping(address => uint256) public dropsByAddress;
    uint256 public totalDrops;

    function initialize(
        address[] memory dropAddresses,
        uint256[] memory dropSupplies
    ) external initializer {
        __Ownable_init_unchained();
        // In order to prevent non-existing drops being fetched, start from index 1.
        totalDrops = 1;

        require(
            dropAddresses.length == dropSupplies.length,
            "ESNFTW: drop addresses and supply length doesnt line up"
        );

        for (uint256 i = 0; i < dropAddresses.length; i++) {
            addNewDrop_(dropAddresses[i], dropSupplies[i]);
        }

        // Blitkicks
        //addNewDrop_(0xd4EA80FfEE7d0E2A3132173C56baf604D20d40E5, 80);
        //// Drop 2
        //addNewDrop_(0x140197fBB6119F17311f414C367D238D181D085D, 800);
        //// Test Drop
        //addNewDrop_(0x5d75aFA4D15E6DC18745eBd9d37670f183E35164, 1000);
    }

    function addNewDrop(
        address newDrop,
        uint256 totalSupply
    ) external onlyOwner {
        addNewDrop_(newDrop, totalSupply);
    }

    function removeLastDrop() external onlyOwner {
        require(totalDrops > 0, "ESNFTW: drop size 0");

        totalDrops--;
        DropInfo memory drop = drops[totalDrops];
        address dropAddress = drop.dropAddress;
        drops[totalDrops] = DropInfo(address(0), 0);
        dropsByAddress[dropAddress] = 0;

        emit DropRemoved(dropAddress);
    }

    function isValidNFT(
        address dropAddress,
        uint256 id
    ) external view override returns (bool) {
        if (dropsByAddress[dropAddress] == 0) {
            return false;
        }

        DropInfo memory drop = drops[dropsByAddress[dropAddress]];

        if (id >= drop.totalSupply) {
            return false;
        }

        return true;
    }

    /// Private functions

    function addNewDrop_(address newDrop_, uint256 totalSupply_) private {
        require(newDrop_ != address(0), "ESNFTW: invalid drop address");

        drops[totalDrops] = DropInfo(newDrop_, totalSupply_);
        dropsByAddress[newDrop_] = totalDrops;

        totalDrops++;

        emit DropAdded(newDrop_, totalSupply_);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}