// SPDX-License-Identifier: MIT

// .001/ea
// 5/tx

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheCreator is ERC721A {
    using Strings for uint256;

    uint256 public maxSupply = 666;
    uint256 public price = .001 ether;

    string public cid = "QmcUSGbVRBekqzjgzLQufmpdWzHYuU861AqndVCQNXLHym";

    address public owner;

    constructor() ERC721A("The Creator", "CREATION") {
        owner = msg.sender;
        _mint(msg.sender, 1);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    function mint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= maxSupply, "oos");
        require(quantity <= 5, "over limit");
        require(msg.value >= quantity * price, "more eth");
        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "ipfs://",
                    cid,
                    "/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setCID(string memory _cid) external onlyOwner {
        cid = _cid;
    }

    function withdraw() external onlyOwner {
        (bool succ, ) = payable(owner).call{value: address(this).balance}("");
        require(succ, "Withdraw failed");
    }
}