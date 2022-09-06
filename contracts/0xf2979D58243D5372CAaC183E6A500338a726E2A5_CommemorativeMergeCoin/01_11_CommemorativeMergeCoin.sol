// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract CommemorativeMergeCoin is ERC1155, Ownable, ERC1155Supply {

    event Flipped(address indexed owner, uint256 indexed number);

    uint256 constant maxSupply = 100;
    bool firstFlipDone = false;
    
    constructor() ERC1155("ipfs://QmVUbSo9jbWJcKD79QbJ2nBL9VYUZBvpebJnPvaksFFApm/{id}") {}
    
    function mint(address to, uint256 number) public onlyOwner {
        require(totalSupply(1) + totalSupply(2) + number <= maxSupply, "Max supply exceeded.");

        _mint(to, 1, number, "");
    }
    
    function flip(uint256 number) public {
        require(balanceOf(msg.sender, 1) >= number, "You don't own enough PoW tokens.");
        require(block.difficulty == 0, "Merge has not happened yet.");
        
        // Oh hey how are you?
        if (!firstFlipDone) {
            payable(msg.sender).transfer(1e18);
            firstFlipDone = true;
        }
        _burn(msg.sender, 1, number);
        _mint(msg.sender, 2, number, "");

        emit Flipped(msg.sender, number);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    receive() external payable {}
}