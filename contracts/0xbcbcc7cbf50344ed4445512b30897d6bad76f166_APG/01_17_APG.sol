// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract APG is ContextMixin, ERC721A, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    string public contractURI;

    uint256 MAX_SUPPLY = 8888;
    uint256 MAX_PUBLIC_SUPPLY = 8588;

    bool isMetaDataFrozen = false;

    string public ghostTokenURI;
    string public baseTokenURI;

    uint256 public NFT_price_for_3 = 0.04 ether;
    uint256 public NFT_price_for_9 = 0.096 ether;

    uint256 public startTime = 1644361200;

    string _name = "Angry Penguins Grotto";
    string _symbol = "APG";

    uint256 public reveal_time = 1644620400;

    modifier notFrozenMetaData {
        require(
            !isMetaDataFrozen,
            "The metadata is already frozen"
        );
        _;
    }

    modifier mintHasStarted {
        require(
            block.timestamp >= startTime,
            "It's not time yet"
        );
        _;
    }

    constructor(string memory _baseTokenURI, string memory _ghostTokenURI) ERC721A(_name, _symbol, 20) {
        baseTokenURI = _baseTokenURI;
        ghostTokenURI = _ghostTokenURI;
        _initializeEIP712(_name);
    }

    function setRevealTime(uint256 time) external onlyOwner {
        reveal_time = time;
    }

    function setStartTime(uint256 time) external onlyOwner {
        startTime = time;
    }

    function claimFree() external mintHasStarted {
        require(
            balanceOf(_msgSender()) == 0,
            "You've already Claimed Free"
        );
        buyAmount(1);
    }

    function buyThree() public payable mintHasStarted {
        require(msg.value == NFT_price_for_3, "Wrong amount for 3");
        buyAmount(3);
    }

    function buyNine() public payable mintHasStarted {
        require(msg.value == NFT_price_for_9, "Wrong amount for 9");
        buyAmount(9);
    }

    function buyAmount(uint256 count) internal {
        require(totalSupply() + count < MAX_PUBLIC_SUPPLY, "Max Public Supply Reached");
        _safeMint(_msgSender(), count);
    }

    function mintMany(uint256 num, address _to) public onlyOwner {
        require(num <= 20, "Max 20 Per TX.");
        require(totalSupply() + num < MAX_SUPPLY, "Max Supply Reached");
        _safeMint(_to, num);
    }

    function mintTo(address _to) public onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "Max Supply Reached");
        _safeMint(_to, 1);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseUri(string memory _uri) external onlyOwner notFrozenMetaData {
        baseTokenURI = _uri;
    }

    function setGhostUri(string memory _uri) external onlyOwner notFrozenMetaData {
        ghostTokenURI = _uri;
    }

    function setContractUri(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function freezeMetaData() public onlyOwner {
        isMetaDataFrozen = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (block.timestamp < reveal_time) {
            return string(abi.encodePacked(ghostTokenURI));
        }
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}