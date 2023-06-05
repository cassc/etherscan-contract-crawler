// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

import "./Abstract1155Factory.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BlockheadStories is ReentrancyGuard, Abstract1155Factory {
    string private _uri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    }

    bool public paused = true;
    uint256[] public storyPrices = [0.01 ether];
    bool[] public pausedStories = [false];

    function flipPause() external onlyOwner {
        paused = !paused;
    }
 
    //only price is stored, everything else in metadata
    function addStory(uint256 price) external onlyOwner {
        storyPrices.push(price);
        pausedStories.push(false);
    }

    function flipPauseStory(uint256 id) external onlyOwner {
        pausedStories[id] = !pausedStories[id];
    }

    function setStoryPrice(uint256 id, uint256 price) external onlyOwner {
        storyPrices[id] = price;
    }

    function setStories(uint256[] memory prices) external onlyOwner {
        for (uint256 i = 0; i < prices.length; i++) {
            storyPrices[i] = prices[i];
        }
    }

    function mint(uint256 _tier) payable external nonReentrant {
        require(!paused, "Contract is paused");
        require(!pausedStories[_tier], "Minting is paused for this story");
        require(_tier < storyPrices.length, "Incorrect story ID");
        require(msg.value == storyPrices[_tier], "incorrect price");
        _mint(msg.sender, (_tier), 1, "");
    }

    function ownerMint(uint256 _tier) external onlyOwner {
        require(_tier < storyPrices.length, "Incorrect story ID");
        _mint(msg.sender, (_tier), 1, "");
    }

    function withdraw() public onlyOwner() {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return
            string(
                abi.encodePacked(
                    super.uri(_id),
                    Strings.toString(_id),
                    ".json"
                )
            );
    }
}