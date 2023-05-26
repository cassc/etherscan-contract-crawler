// SPDX-License-Identifier: MIT

/*
       ___       __   _______   ________          ___   ___          ________  _______   ________
      |\  \     |\  \|\  ___ \ |\   __  \        |\  \ |\  \        |\   ___ \|\  ___ \ |\   ___ \
      \ \  \    \ \  \ \   __/|\ \  \|\ /_       \ \  \\_\  \       \ \  \_|\ \ \   __/|\ \  \_|\ \
       \ \  \  __\ \  \ \  \_|/_\ \   __  \       \ \______  \       \ \  \ \\ \ \  \_|/_\ \  \ \\ \
        \ \  \|\__\_\  \ \  \_|\ \ \  \|\  \       \|_____|\  \       \ \  \_\\ \ \  \_|\ \ \  \_\\ \
         \ \____________\ \_______\ \_______\             \ \__\       \ \_______\ \_______\ \_______\
          \|____________|\|_______|\|_______|              \|__|        \|_______|\|_______|\|_______|

*/

pragma solidity ^0.8.4;

import "./ERC721Ded.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Web4Ded is ERC721Ded, Ownable {
    using Strings for uint256;

    bool public isDedMintTime = false;
    uint256 public dedMaxMint = 6;
    uint256 public constant DED_SUPPLY = 6666;

    bool public isDedTransformTime = false;
    uint256 public dedMaxTransform = 5;

    string private dedFace;
    string private dedRealFace;

    event TransfromDed(
        address dedMan,
        uint256 dedIdTransform,
        uint256[] burnedDeds
    );

    constructor() ERC721Ded("Web4Ded", "W4D") {}

    function flipDedMintState() external onlyOwner {
        isDedMintTime = !isDedMintTime;
    }

    function setDedMaxMint(uint256 _amount) external onlyOwner {
        dedMaxMint = _amount;
    }

    function dedMint(uint256 _amount) external {
        require(isDedMintTime, "why so hurry?!");
        require(totalSupply() + _amount <= DED_SUPPLY, "why u so lame?!");
        require(
            balanceOf(msg.sender) + _amount <= dedMaxMint,
            "don't be greedy u fookin !dedman"
        );

        _safeMint(msg.sender, _amount);
    }

    function dedFromAbove(address _dedMan, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= DED_SUPPLY, "why u so lame?!");
        _safeMint(_dedMan, _amount);
    }

    function flipDedTransformState() external onlyOwner {
        isDedTransformTime = !isDedTransformTime;
    }

    function setDedMaxTransform(uint256 _amount) external onlyOwner {
        dedMaxTransform = _amount;
    }

    function dedTransform(uint256[] calldata ids) external {
        require(isDedTransformTime, "why so hurry?!");

        uint256 amount = ids.length;

        require(amount > 1, "can't transform less than 1 ded");
        require(amount <= dedMaxTransform, "too much ded to transform");

        uint256[] memory burnedDeds = new uint256[](amount - 1);

        for (uint256 i; i < amount; ) {
            require(ownerOf(ids[i]) == msg.sender, "u'r not the ded owner");
            if (i > 0) {
                burnedDeds[i - 1] = ids[i];
                _burn(ids[i]);
            }
            unchecked {
                ++i;
            }
        }

        emit TransfromDed(msg.sender, ids[0], burnedDeds);
    }

    function setDedFace(string calldata URI) external onlyOwner {
        dedFace = URI;
    }

    function setDedRealFace(string calldata URI) external onlyOwner {
        dedRealFace = URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory _dedRealFace = dedRealFace;
        return
            bytes(_dedRealFace).length > 0
                ? string(abi.encodePacked(_dedRealFace, tokenId.toString()))
                : dedFace;
    }
}