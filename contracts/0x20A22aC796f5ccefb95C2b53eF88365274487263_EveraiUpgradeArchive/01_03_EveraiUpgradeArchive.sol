// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IEveraiMemoryCore {
    function ownerOf(uint256 tokenId) external view returns (address);

    function burn(uint256 tokenId) external;

    function mint(address to, uint256 quantity) external;
}

interface IEveraiOriginArchive {
    function ownerOf(uint256 tokenId) external view returns (address);

    function burn(uint256 tokenId) external;

    function upgrade(uint256 tokenId, uint16 memoryCoreType) external;
}

contract EveraiUpgradeArchive is Ownable {
    IEveraiMemoryCore public everaiMemoryCore;
    IEveraiOriginArchive public everaiOriginArchive;

    event Link(uint256 _archiveId);

    constructor(
        address everaiMemoryCoreAddress,
        address everaiOriginArchiveAddress
    ) {
        everaiMemoryCore = IEveraiMemoryCore(everaiMemoryCoreAddress);
        everaiOriginArchive = IEveraiOriginArchive(everaiOriginArchiveAddress);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract");
        _;
    }

    function link(uint16 archiveId, uint256[] memory memoryCoreIds)
        external
        callerIsUser
    {
        address originArchiveOwner = everaiOriginArchive.ownerOf(archiveId);
        require(
            originArchiveOwner == msg.sender,
            "the caller must be owner of the origin archive"
        );

        for (uint256 i = 0; i < memoryCoreIds.length; i++) {
            uint256 tokenId = memoryCoreIds[i];
            require(
                everaiMemoryCore.ownerOf(tokenId) == msg.sender,
                "the caller must be owner of the selected memory core"
            );
            everaiMemoryCore.burn(tokenId);
        }

        everaiOriginArchive.upgrade(archiveId, archiveId);
        emit Link(archiveId);
    }

    function burnMemoryCore(uint256 id) external onlyOwner {
        everaiMemoryCore.burn(id);
    }
}