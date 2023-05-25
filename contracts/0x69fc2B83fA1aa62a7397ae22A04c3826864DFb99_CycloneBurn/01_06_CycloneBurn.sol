// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IManifoldERC1155.sol";
import "./IBurnExtension.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CycloneBurn is Ownable {
    IManifoldERC1155 public duuContract =
        IManifoldERC1155(0x1386f70A946Cf9F06E32190cFB2F4F4f18365b87);
    IBurnExtension public cycloneBurn = IBurnExtension(0xfa1B15dF09c2944a91A2F9F10A6133090d4119BD);
    
    uint256 public pinkCycloneTokenId = 3;
    uint256 public blueCycloneTokenId = 5;
    uint256 public greenCycloneTokenId = 6;
    uint256 public artworkTokenId = 7;

    uint256[] public cycloneTokenIds;
    uint256[] public artworkTokenIds;

    uint256 public startTime;
    uint256 public endTime;

    constructor(uint256 _startTime, uint256 _endTime) {
        startTime = _startTime;
        endTime = _endTime;

        cycloneTokenIds = new uint256[](3);
        cycloneTokenIds[0] = pinkCycloneTokenId;
        cycloneTokenIds[1] = blueCycloneTokenId;
        cycloneTokenIds[2] = greenCycloneTokenId;

        artworkTokenIds = new uint256[](1);
        artworkTokenIds[0] = artworkTokenId;
    }

    event CyclonesBurned(
        address indexed user,
        uint32 pinkCyclones,
        uint32 blueCyclones,
        uint32 greenCyclones
    );

    function burnCyclones(
        uint32 pinkCyclones,
        uint32 blueCyclones,
        uint32 greenCyclones
    ) external {
        require(block.timestamp < endTime && block.timestamp >= startTime, "CycloneBurn: Contract is disabled");
        require(
            pinkCyclones + blueCyclones + greenCyclones > 0,
            "CycloneBurn: You must burn at least one cyclone"
        );
        require((pinkCyclones + blueCyclones + greenCyclones) % 2 == 0, "CycloneBurn: You must burn an even number of cyclones");

        uint256[] memory cycloneAmounts = new uint256[](3);
        cycloneAmounts[0] = pinkCyclones;
        cycloneAmounts[1] = blueCyclones;
        cycloneAmounts[2] = greenCyclones;
        
        duuContract.burn(msg.sender, cycloneTokenIds, cycloneAmounts);

        address[] memory addresses = new address[](1);
        addresses[0] = msg.sender;

        uint256[] memory artworkAmounts = new uint256[](1);
        artworkAmounts[0] = (pinkCyclones + blueCyclones + greenCyclones) / 2;

        duuContract.mintBaseExisting(addresses, artworkTokenIds, artworkAmounts);

        emit CyclonesBurned(msg.sender, pinkCyclones, blueCyclones, greenCyclones);
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    function getInfo(
        address user
    )
        public
        view
        returns (
            uint256 balance,
            bool hasApproved,
            uint256 _startTime,
            uint256 _endTime,
            uint256 pinkCycloneAmount,
            uint256 blueCycloneAmount,
            uint256 greenCycloneAmount,
            uint256 artworkAmount,
            uint256 pinkCycloneTotalAmount,
            uint256 blueCycloneTotalAmount,
            uint256 greenCycloneTotalAmount,
            uint256 artworkTotalAmount
        )
    {
        if (user == address(0)) {
            hasApproved = false;
            balance = 0;

            pinkCycloneAmount = 0;
            blueCycloneAmount = 0;
            greenCycloneAmount = 0;
            artworkAmount = 0;
        } else {
            hasApproved = duuContract.isApprovedForAll(user, address(this));
            balance = payable(user).balance;

            pinkCycloneAmount = duuContract.balanceOf(user, pinkCycloneTokenId);
            blueCycloneAmount = duuContract.balanceOf(user, blueCycloneTokenId);
            greenCycloneAmount = duuContract.balanceOf(user, greenCycloneTokenId);
            artworkAmount = duuContract.balanceOf(user, artworkTokenId);
        }

        _startTime = startTime;
        _endTime = endTime;

        pinkCycloneTotalAmount = duuContract.totalSupply(pinkCycloneTokenId);
        blueCycloneTotalAmount = duuContract.totalSupply(blueCycloneTokenId);
        greenCycloneTotalAmount = duuContract.totalSupply(greenCycloneTokenId);
        artworkTotalAmount = duuContract.totalSupply(artworkTokenId);
    }
}