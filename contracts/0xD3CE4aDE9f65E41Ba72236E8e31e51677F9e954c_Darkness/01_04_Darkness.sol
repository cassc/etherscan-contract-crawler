//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Auto reveal
// Price .003 eth each
// Give some time for metadata to show

contract Darkness is ERC721A {
    using Strings for uint256;

    uint256 public maxSupply = 777;
    uint256 public price = .003 ether;

    address public owner;
    bool public saleLive = false;

    string public cid = "QmcTwPjHVUwVjuRfP4hb6Jap3hME2nPBVnbFMj8jZjEuP6";

    constructor() ERC721A("Darkness", "DARK") {
        owner = msg.sender;
        _mint(msg.sender, 1);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    function mint(uint256 amount) external payable {
        require(tx.origin == msg.sender, "No contracts");
        require(saleLive, "Sale is not live yet");
        require(totalSupply() + amount <= maxSupply, "OOS");
        require(amount <= 10, "Exceeded max per tx");
        require(msg.value >= amount * price, "Invalid eth amount");

        _mint(msg.sender, amount);
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

    function setCid(string calldata _cid) external onlyOwner {
        cid = _cid;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function flipSale() external onlyOwner {
        saleLive = !saleLive;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        (bool succ, ) = payable(owner).call{value: address(this).balance}("");
        require(succ, "Withdraw failed");
    }
}