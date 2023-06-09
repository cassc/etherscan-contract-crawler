// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract HipHopHeads is ERC721, Ownable {

    uint public mintPrice = 0.10 ether;
    uint public maxItems = 10000;
    uint public mintCount = 0;
    uint public maxItemsPerTx = 50;
    address public recipient;
    string public _baseTokenURI;
    uint public startTimestamp;

    event Mint(address indexed owner, uint indexed tokenId);

    constructor(address _recipient) ERC721("Hip Hop Heads", "HHH") {
        transferOwnership(0xe6Ac30A0b492A9Edd3Be7fc31eF74Bfea2C355e8);
        recipient = _recipient;
    }

    modifier mintingOpen() {
        require(startTimestamp != 0, "Start timestamp not set");
        require(block.timestamp >= startTimestamp, "Not open yet");
        _;
    }

    receive() external payable mintingOpen {
        _mintHelper(msg.value);
    }

    function preMint(uint amount) external onlyOwner {
        _mintHelper(amount * mintPrice);
    }

    function mint() external payable mintingOpen {
        _mintHelper(msg.value);
    }

    function _mintHelper(uint weiValue) internal {
        uint remainder = weiValue % mintPrice;
        uint amount = weiValue / mintPrice;
        require(amount <= maxItemsPerTx, "Exceeded max mint per tx");
        require(mintCount + amount <= maxItems, "Sold out");
        // Send back the extra
        if (remainder > 0) {
            (bool success,) = msg.sender.call{value: remainder}("");
            require(success, "Failed to refund ether");
        }
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, mintCount);
            mintCount += 1;
            emit Mint(msg.sender, mintCount);
        }
    }

    // ADMIN FUNCTIONALITY

    function setMintPrice(uint _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxItems(uint _maxItems) external onlyOwner {
        maxItems = _maxItems;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setStartTimestamp(uint _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    // WITHDRAWAL FUNCTIONALITY

    /**
     * @dev Withdraw the contract balance to the dev address or splitter address
     */
    function withdraw() external {
        uint amount = address(this).balance;
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    // METADATA FUNCTIONALITY

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

}