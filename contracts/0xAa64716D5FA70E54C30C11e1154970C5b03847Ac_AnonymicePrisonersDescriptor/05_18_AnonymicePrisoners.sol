/* solhint-disable quotes */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "erc721a/contracts/ERC721A.sol";
import "./IAnonymicePrisonersDescriptor.sol";
import "./IAnonymiceBadges.sol";

contract AnonymicePrisoners is Ownable, ERC721A {
    using EnumerableSet for EnumerableSet.UintSet;
    struct Prisoner {
        uint256 genesisId;
        uint256 imprisonTime;
    }

    address public badgesAddress;
    address public genesisAddress;
    address public descriptorAddress;
    mapping(uint256 => Prisoner) public prisoners;

    constructor() ERC721A("Anonymice Prisoners", "AnonymicePrisoners") {}

    function imprison(uint256 genesisId) external {
        uint256 startTokenId = _currentIndex;
        IERC721(genesisAddress).transferFrom(msg.sender, address(this), genesisId);
        prisoners[startTokenId] = Prisoner(genesisId, block.timestamp);
        _safeMint(msg.sender, 1);
        IAnonymiceBadges(badgesAddress).externalClaimPOAP(31, msg.sender);
    }

    function release(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not allowed");
        Prisoner memory prisoner = prisoners[tokenId];
        uint256 timeElapsed = block.timestamp - prisoner.imprisonTime;
        require(timeElapsed >= 364 days, "not release time");
        IERC721(genesisAddress).transferFrom(address(this), msg.sender, prisoner.genesisId);
        _burn(tokenId);
    }

    function getPrisonerGenesisId(uint256 tokenId) external view returns (uint256) {
        return prisoners[tokenId].genesisId;
    }

    function getIsBurned(uint256 tokenId) external view returns (bool) {
        return _ownerships[tokenId].burned;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return IAnonymicePrisonersDescriptor(descriptorAddress).tokenURI(tokenId);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("soul bound");
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("soul bound");
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert("soul bound");
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setAddresses(
        address _genesisAddress,
        address _descriptorAddress,
        address _badgesAddress
    ) external onlyOwner {
        genesisAddress = _genesisAddress;
        descriptorAddress = _descriptorAddress;
        badgesAddress = _badgesAddress;
    }
}