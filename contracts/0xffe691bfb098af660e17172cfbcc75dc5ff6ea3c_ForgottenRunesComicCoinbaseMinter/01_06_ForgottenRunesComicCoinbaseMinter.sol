// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IForgottenRunesComic.sol";

contract ForgottenRunesComicCoinbaseMinter is Ownable {
    uint256 public startTimestamp = type(uint256).max;
    IForgottenRunesComic public comicToken;

    function setStartTimestamp(uint256 newStartTimestamp) public onlyOwner {
        startTimestamp = newStartTimestamp;
    }

    function setComicToken(IForgottenRunesComic newComicToken)
        public
        onlyOwner
    {
        comicToken = newComicToken;
    }

    function mint(uint256 tokenId) public {
        require(
            tokenId >= 1 && tokenId <= 5,
            "Can only mint tokenIds 1 through 5"
        );
        require(started(), "Not started yet");
        comicToken.mint(msg.sender, tokenId, 1, "");
    }

    function started() public view returns (bool) {
        return block.timestamp >= startTimestamp;
    }
}