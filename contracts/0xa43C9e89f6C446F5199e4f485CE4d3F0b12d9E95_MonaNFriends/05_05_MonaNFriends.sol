// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";

interface IMonaverse {
    function balanceOf(address tokenId) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract MonaNFriends is Ownable, ERC721A {
    address public immutable MONAVERSE;
    bool public claimableStatus;
    string public baseURI;

    mapping(uint256 => bool) private _monaIdStatus;

    constructor(address _monaverse, string memory uri) ERC721A("Mona & Friends", "MNF") {
        MONAVERSE = _monaverse;
        baseURI = uri;
    }

    function setURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setClaimableStatus(bool status) external onlyOwner {
        claimableStatus = status;
    }

    function claim(uint256[] memory _monaTokenIds) external {
        require(claimableStatus, "Not Claimable yet");
        require(_monaTokenIds.length % 2 == 0, "Invalid Length");

        IMonaverse _Monaverse = IMonaverse(MONAVERSE);
        for (uint256 i = 0; i < _monaTokenIds.length; i++) {
            require(_Monaverse.ownerOf(_monaTokenIds[i]) == msg.sender, "Invalid Owner");
            require(!_monaIdStatus[_monaTokenIds[i]], "Claimed");
            _monaIdStatus[_monaTokenIds[i]] = true;
        }

        uint256 _qty = _monaTokenIds.length / 2;
        _mint(msg.sender, _qty);
    }

    function isMonaIdsClaimed(uint256[] memory _monaTokenIds) external view returns (bool[] memory) {
        bool[] memory _monaIdsStatus = new bool[](_monaTokenIds.length);
        for (uint256 i = 0; i < _monaTokenIds.length; i++) {
            _monaIdsStatus[i] = _monaIdStatus[_monaTokenIds[i]];
        }
        return _monaIdsStatus;
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        IMonaverse _Monaverse = IMonaverse(MONAVERSE);
        uint256 count = _Monaverse.balanceOf(owner);
        uint256[] memory ids = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = _Monaverse.tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length != 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), ".json"))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}