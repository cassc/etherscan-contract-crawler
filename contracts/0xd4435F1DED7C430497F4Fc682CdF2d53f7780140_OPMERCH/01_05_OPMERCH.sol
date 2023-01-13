// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/LibString.sol";
import "./ERC1155.sol";

contract OPMERCH is Ownable, ERC1155 {
    string private ipfsHash;
    address private minter;

    string public constant name = "1-800-POCKETS";
    string public constant symbol = "OP-MERCH";

    constructor() {
        ipfsHash = "bafybeifkoulyaxqy4n23jlvlgnzqitxdpav45qzmrlvm5kg5d5hj5a35cy";
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    function mint(address recipient, uint256 id, uint256 amount) external onlyMinter {
        _mint(recipient, id, amount, "");
    }

    function updateMetadata(string calldata newHash) external onlyOwner {
        ipfsHash = newHash;
    }

    function updateMinter(address newMinter) external onlyOwner {
        minter = newMinter;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string.concat("ipfs://", ipfsHash, "/", LibString.toString(id), ".json");
    }
}