// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "erc721a/contracts/ERC721A.sol";

contract IllusionByAndrew is ERC721A {
    // uriPrefix
    string public uriPrefix;

    // owner
    address public owner;

    // maxSupply
    uint256 public maxSupply;

    // mint price
    uint256 public price;

    // entry per addr
    uint256 public maxFreeAmount = 0;

    // mint status
    bool public status = false;

    // max mint amount per transaction
    uint256 private maxPerTx;

    mapping(address => uint256) _numForFree;

    mapping(uint256 => uint256) _numMinted;

    constructor() ERC721A("Olympian Elements By Andrew", "OLYMPIAN") {
        uriPrefix = "ipfs://Qmem6gFJTWAbWzWz1FjFgKmhomJKe6uupgv6yNPWeA7C4P/";
        owner = msg.sender;
        maxPerTx = 5;
        maxSupply = 555;
        price = 0.002 ether;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function mint(uint256 amount) public payable {
        require(status);
        require(totalSupply() + amount <= maxSupply);
        if (msg.value == 0) {
            freemint(amount);
            return;
        }
        require(amount <= maxPerTx);
        require(msg.value >= amount * price);
        _safeMint(msg.sender, amount);
    }

    function freemint(uint256 amount) internal {
        require(
            amount == maxFreeAmount && _numForFree[tx.origin] < maxFreeAmount
        );
        _numForFree[tx.origin]++;
        _safeMint(msg.sender, maxFreeAmount);
    }

    function giveAway(address rec, uint256 amount) public onlyOwner {
        _safeMint(rec, amount);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(uriPrefix, _toString(tokenId), ".json"));
    }

    function setMaxFreePerAdr(uint256 amount) external onlyOwner {
        maxFreeAmount = amount;
    }

    function setURIPrefix(string calldata prefix) external onlyOwner {
        uriPrefix = prefix;
    }

    function flipMintStatus() external onlyOwner {
        status = !status;
    }

    function withdraw(address rec) external onlyOwner {
        payable(rec).transfer(address(this).balance);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}