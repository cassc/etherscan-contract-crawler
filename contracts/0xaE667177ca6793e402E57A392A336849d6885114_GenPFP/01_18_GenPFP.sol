// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./WatcherMinter.sol";

contract GenPFP is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    AdminMinter public adminMinter;
    WatcherMinter public watcherMinter;

    bool public active = true;

    uint256 public ZERO_S_ID = 5;
    uint256 public ZERO_ID = 6;

    mapping(uint256 => uint8) public NFT_TYPE;

    string public baseURI = "https://api.missingfrontier.com/pfp/";
    bool public uriChanged = false;

    constructor(address _adminMinter, address _watcherMinter)
        ERC721("GenPFP", "PFP")
    {
        adminMinter = AdminMinter(_adminMinter);
        watcherMinter = WatcherMinter(_watcherMinter);
    }

    function toggleActive() external onlyOwner {
        active = !active;
    }

    function burnForMint(uint256 _id, uint256 _amount) external {
        require(active == true, "Minting is not active");
        require(_id == ZERO_S_ID || _id == ZERO_ID, "Invalid id");
        require(
            watcherMinter.isApprovedForAll(msg.sender, address(this)),
            "User is not authorized"
        );
        require(
            watcherMinter.balanceOf(msg.sender, _id) >= _amount,
            "User does not own this many NFTs"
        );

        uint256[] memory burnIds = new uint256[](1);
        burnIds[0] = _id;

        uint256[] memory burnAmounts = new uint256[](1);
        burnAmounts[0] = _amount;

        uint256[] memory mintIds;
        uint256[] memory mintAmounts;
        adminMinter.burnForMint(
            msg.sender,
            burnIds,
            burnAmounts,
            mintIds,
            mintAmounts
        );
        for (uint256 i = 0; i < _amount; i++) {
            safeMint(msg.sender, _id == ZERO_ID);
        }
    }

    function safeMint(address to, bool isZero) internal {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        if (isZero) {
            NFT_TYPE[tokenId] = 2;
        } else {
            NFT_TYPE[tokenId] = 1;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updateURI(string memory _newURI) external onlyOwner {
        require(uriChanged == false, "URI has already been updated");
        baseURI = _newURI;
        uriChanged = true;
    }
}

abstract contract AdminMinter {
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external virtual;

    function burnForMint(
        address _from,
        uint256[] memory _burnIds,
        uint256[] memory _burnAmounts,
        uint256[] memory _mintIds,
        uint256[] memory _mintAmounts
    ) external virtual;

    function setURI(uint256 _id, string memory _uri) external virtual;
}