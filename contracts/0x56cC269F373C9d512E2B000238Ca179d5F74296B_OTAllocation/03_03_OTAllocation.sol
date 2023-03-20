// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IOTMint {
    function mint(address, uint256) external;
}

contract OTAllocation is Ownable {
    uint256 private constant OT_MAX_SUPPLY = 1000000000 ether;
    uint256 private constant MINTED_NFT_HOLDER_BONUS = 3715637940000000000000;

    struct AllocationBucket {
        address currentAddress;
        uint256 weight;
        uint256 mintedAmount;
    }

    mapping(string => AllocationBucket) public allocationBuckets;
    IOTMint public openTownContract;

    constructor(address otContractAddr) {
        require(otContractAddr != address(0), "Invalid OT contract address");
        openTownContract = IOTMint(otContractAddr);

        allocationBuckets["TOWNS"] = AllocationBucket(
            address(0),
            30,
            MINTED_NFT_HOLDER_BONUS
        );
        allocationBuckets["TREASURY"] = AllocationBucket(address(0), 20, 0);
        allocationBuckets["COMMUNITY"] = AllocationBucket(address(0), 9, 0);
        allocationBuckets["PROJECT_TEAM"] = AllocationBucket(address(0), 21, 0);
        allocationBuckets["PRESALE"] = AllocationBucket(address(0), 12, 0);
        allocationBuckets["PUBLIC_SALE"] = AllocationBucket(address(0), 8, 0);
    }

    function setBucketAddress(
        string calldata key,
        address addr
    ) external onlyOwner {
        require(allocationBuckets[key].weight > 0, "Invalid bucket");
        allocationBuckets[key].currentAddress = addr;
    }

    function mint(string calldata key, uint256 amount) external onlyOwner {
        address to = allocationBuckets[key].currentAddress;
        require(to != address(0), "Invalid bucket address");

        uint256 maxSupplyForBucket = (OT_MAX_SUPPLY *
            allocationBuckets[key].weight) / 100;

        require(
            allocationBuckets[key].mintedAmount + amount <= maxSupplyForBucket,
            "Bucket max supply exceeded"
        );

        allocationBuckets[key].mintedAmount += amount;
        openTownContract.mint(allocationBuckets[key].currentAddress, amount);
    }
}