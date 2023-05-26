// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MinimalERC1155 is ERC1155, Ownable {
    uint256 public tokenId = 1;
    uint256 public price = 0.014 ether;
    uint256 public maxSupplyPerTokenId = 50;
    address public constant BENEFICIARY = 0x007eaf4Fb660a975aF2926541A57548D7f937565;
    bool public paused = true;
    string public name = "Kurikawa uchiwa SBT";
    string public symbol = "KUS";

    mapping(uint256 => uint256) public currentSupply;

    constructor() ERC1155("https://nft.aopanda.ainy-llc.com/kus/metadata/{id}.json") {
        _mint(msg.sender, tokenId, 1, "");
        currentSupply[tokenId] += 1;
    }

    function mint(uint256 amount) external payable {
        require(!paused, "Sale is paused");
        require(msg.value == price * amount, "Incorrect payment value");
        require(currentSupply[tokenId] + amount <= maxSupplyPerTokenId, "Exceeds max supply per token ID");

        _mint(msg.sender, tokenId, amount, "");
        currentSupply[tokenId] += amount;
    }

    function setTokenId(uint256 newTokenId) external onlyOwner {
        tokenId = newTokenId;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxSupplyPerTokenId(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPerTokenId = newMaxSupply;
    }

    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(BENEFICIARY).call{
            value: address(this).balance
        }("");
        require(os);
    }

    // Override to prevent transfers and approvals
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        // This function will be called for both minting and transferring.
        // We only want to block transfers, so we check if 'from' is not the zero address.
        if (from != address(0)) {
            revert("Transfers are not allowed");
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Override to prevent approvals
    function setApprovalForAll(address, bool) public virtual override {
        revert("Approvals are not allowed");
    }
}