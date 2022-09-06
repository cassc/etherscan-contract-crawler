// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CommentGraffiti is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public basePrice;
    uint256 private ownerBalance;
    uint256 private prizeBalance;

    event NewComment(
        address minter,
        string videoId,
        string username,
        string comment,
        string timeStamp,
        uint256 price,
        uint256 blockTimeStamp
    );

    struct CommentMetadata {
        address minter;
        string videoId;
        string username;
        string comment;
        string timeStamp;
        uint256 price;
        uint256 blockTimeStamp;
    }

    CommentMetadata[] commentObjects;

    constructor() payable ERC721("Comment Graffiti", "GRAFFITI") {
        basePrice = 0.05 ether;
    }

    fallback() external payable {}

    receive() external payable {}

    function currentPriceToMint() public view returns (uint256) {
        //increments price by 0.02 ETH every 10th comment
        return basePrice + ((commentObjects.length / 10) * 0.02 ether);
    }

    function recordBreakDown() private {
        //route 30% of transaction to contract owner. 20% of transaction will be reserved for the original video creator
        ownerBalance += (msg.value * 3) / 10;
        //route 70% of transaction to prize balance
        prizeBalance += (msg.value * 7) / 10;
    }

    function graffitiComment(
        string memory _videoId,
        string memory _username,
        string memory _comment,
        string memory _timeStamp,
        string memory _videoLink
    ) public payable {
        require(
            msg.value >= currentPriceToMint(),
            "Not enough ether to mint NFT :("
        );

        recordBreakDown();

        commentObjects.push(
            CommentMetadata(
                msg.sender,
                _videoId,
                _username,
                _comment,
                _timeStamp,
                msg.value,
                block.timestamp
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"videoId": "https://www.youtube.com/watch?v=',
                        _videoId,
                        '", "username": "',
                        _username,
                        '", "comment": "',
                        _comment,
                        '", "timestamp": "',
                        _timeStamp,
                        '", "blockTimeStamp": "',
                        Strings.toString(block.timestamp),
                        // TODO: make this a link that I can edit on the backend once I create the visual
                        '", "image": "',
                        _videoLink, 
                        '"}'
                    )
                )
            )
        );
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        //mint an NFT & send to user
        _mintNFT(finalTokenUri);

        emit NewComment(
            msg.sender,
            _videoId,
            _username,
            _comment,
            _timeStamp,
            msg.value,
            block.timestamp
        );
    }

    function _mintNFT(string memory tokenURI) private {
        uint256 newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _setTokenURI(newTokenID, tokenURI);
        _tokenIds.increment();
    }

    //2/3 of this amount will be reserved for the original video creator
    function withdraw(uint256 _amount) public onlyOwner {
        require(
            ownerBalance >= _amount,
            "Attempt to withdraw more than balance"
        );
        payable(msg.sender).transfer(_amount);
        ownerBalance -= _amount;
    }
    
    //owner can withdraw balance that was used to initially seed the contract
    function withdrawSeed(uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(
            (balance - ownerBalance - prizeBalance) >= _amount,
            "Attempt to withdraw more than balance"
        );
        payable(msg.sender).transfer(_amount);
    }

    //prize pool will be sent to the last commenter
    function awardWinner(uint256 _prize, address _addr) public onlyOwner {
        require(
            prizeBalance >= _prize,
            "Trying to withdraw more money than the prize pool."
        );
        (bool success, ) = (payable(_addr)).call{value: _prize}("");
        require(success, "Failed to withdraw money from contract.");
        prizeBalance -= _prize;
    }

    function getAllComments() public view returns (CommentMetadata[] memory) {
        return commentObjects;
    }

    function getOwnerBalance() public view returns (uint256) {
        return ownerBalance;
    }

    function getPrizeBalance() public view returns (uint256) {
        return prizeBalance;
    }
}