// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LockContract is Ownable {
    address immutable TargetContract;
    uint256 createdDate;
    uint256 lockDuration;
    mapping(address => uint16[]) nftIds;
    mapping(uint16 => uint32) unlockDateOffset;

    constructor(address _address) {
        TargetContract = _address;
        createdDate = block.timestamp;
    }

    function setLockDuration(uint256 _duration) public onlyOwner {
        lockDuration = _duration;
    }

    function lock(uint16[] calldata tokenIds) external {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            nftIds[msg.sender].push(tokenIds[i]);
            unlockDateOffset[tokenIds[i]] = uint32(
                block.timestamp - createdDate + lockDuration
            );
            IERC721(TargetContract).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }
    }

    function withdraw(uint16[] calldata orderedTokenIds) external {
        // must be called with correct withdraw order or tx will revert

        uint16 j = 0;

        for (uint16 i = 0; i < nftIds[msg.sender].length; ) {
            if (nftIds[msg.sender][i] == orderedTokenIds[j]) {
                require(
                    block.timestamp >=
                        createdDate + unlockDateOffset[orderedTokenIds[j]],
                    "This token is locked"
                );

                nftIds[msg.sender][i] = nftIds[msg.sender][
                    nftIds[msg.sender].length - 1
                ];
                nftIds[msg.sender].pop();

                IERC721(TargetContract).transferFrom(
                    address(this),
                    msg.sender,
                    orderedTokenIds[j]
                );

                j++;

                if (j == orderedTokenIds.length) {
                    break;
                }
            } else {
                i++;
            }
        }

        if (j != orderedTokenIds.length) {
            revert(
                "Invalid input. Check orderedTokenIds input ordering and ownership."
            );
        }
    }

    function getLockedIds(address _address)
        external
        view
        returns (uint16[] memory)
    {
        return nftIds[_address];
    }

    function getUnlockDates(uint16[] calldata tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory dates = new uint256[](tokenIds.length);

        for (uint16 i = 0; i < tokenIds.length; i++) {
            dates[i] = createdDate + unlockDateOffset[tokenIds[i]];
        }

        return dates;
    }
}