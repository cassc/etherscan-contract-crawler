// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";

contract SovPreOrder is ERC1155, Owned {
    string private _tokenUri;

    bool public refundActive;

    uint256 public mintTime;
    uint256 public mintPrice;
    uint256 public maxMint;

    uint256 public maxSupply;
    uint256 public totalSupply;
    mapping(address => uint256) public numMinted;

    constructor() Owned(msg.sender) {
        _tokenUri = "https://static.721.gg/sov/1.json";

        mintPrice = 0.069 ether;
        mintTime = 1677891600;

        maxMint = 3;
        maxSupply = 10000;

        refundActive = false;
    }

    function mint() public payable {
        require(msg.sender == tx.origin, "BOT");

        uint256 mintStart = mintTime;
        require(mintStart != 0 && block.timestamp > mintStart, "MINT_CLOSED");

        require(msg.value % mintPrice == 0, "VALUE_MISMATCH");
        uint256 amount = msg.value / mintPrice;

        require(totalSupply + amount <= maxSupply, "EXCEED_SUPPLY");
        uint256 currentlyMinted = numMinted[msg.sender];
        require(currentlyMinted + amount <= maxMint, "EXCEED_MAX_MINT");

        totalSupply += amount;
        numMinted[msg.sender] += amount;

        _mint(msg.sender, 1, amount, new bytes(0));
    }

    function refund(uint256 amount) public {
        require(refundActive, "REFUND_INACTIVE");
        require(numMinted[msg.sender] >= amount && balanceOf[msg.sender][1] >= amount, "EXCEED_BALANCE");

        _burn(msg.sender, 1, amount);
        totalSupply -= amount;

        (bool success,) = msg.sender.call{ value: (mintPrice * amount) / 2 }("");
        require(success, "TRANSFER_FAILED");
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "TRANSFER_FAILED");
    }

    function setRefundActive(bool newActive) public onlyOwner {
        refundActive = newActive;
    }

    function setMintTime(uint256 newTime) public onlyOwner {
        mintTime = newTime;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxMint(uint256 newMax) public onlyOwner {
        maxMint = newMax;
    }

    function setMaxSupply(uint256 newMax) public onlyOwner {
        maxSupply = newMax;
    }

    function setTokenUri(string calldata newUri) public onlyOwner {
        _tokenUri = newUri;
    }

    function uri(uint256 id) public view override returns (string memory) {
        id; return _tokenUri;
    }
}