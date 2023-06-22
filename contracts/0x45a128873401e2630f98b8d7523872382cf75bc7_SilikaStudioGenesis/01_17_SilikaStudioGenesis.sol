//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: Silika Studio
/// @title: Silika Studio Genesis

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SilikaStudioGenesis is
    ERC721Enumerable,
    KeeperCompatibleInterface,
    Ownable,
    Pausable
{
    string public tokenBaseURI;
    string public contractURI;
    bool public isDayState = true;

    // Keeper variables
    uint256 public interval;
    uint256 public lastTimestamp;

    event SetTokenBaseURI(string indexed tokenBaseURI);
    event SetContractURI(string indexed contractURI);
    event FlipState(bool indexed initialState);
    event UpdateInterval(uint256 indexed interval);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenBaseURI,
        string memory _contractURI,
        uint256 _interval
    ) ERC721(_name, _symbol) {
        tokenBaseURI = _tokenBaseURI;
        contractURI = _contractURI;
        interval = _interval;
        lastTimestamp = block.timestamp;
        emit SetTokenBaseURI(tokenBaseURI);
    }

    function setTokenBaseURI(string memory _tokenBaseURI) external onlyOwner {
        tokenBaseURI = _tokenBaseURI;
        emit SetTokenBaseURI(tokenBaseURI);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
        emit SetContractURI(contractURI);
    }

    function mint() external whenNotPaused {
        require(tx.origin == msg.sender, "Caller is not an EOA");
        require(balanceOf(msg.sender) == 0, "Caller has already minted");
        _safeMint(msg.sender, totalSupply());
    }

    function updateKeepersInterval(uint256 _newInterval) external onlyOwner {
        interval = _newInterval;
        emit UpdateInterval(interval);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (block.timestamp - lastTimestamp) > interval;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if ((block.timestamp - lastTimestamp) > interval) {
            lastTimestamp = block.timestamp;
            _flipState();
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721: invalid token ID");
        require(bytes(tokenBaseURI).length > 0, "tokenBaseURI not set");

        return
            string(
                abi.encodePacked(tokenBaseURI, isDayState ? "day" : "night")
            );
    }

    function _flipState() private {
        isDayState = !isDayState;
        emit FlipState(isDayState);
    }
}