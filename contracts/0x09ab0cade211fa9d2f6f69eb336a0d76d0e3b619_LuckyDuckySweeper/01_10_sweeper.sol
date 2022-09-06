pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LuckyDuckySweeper is ERC1155, Ownable {

    constructor() ERC1155("ipfs://bafybeidbz63ieml6kbdguq6ubnkosboorlfvowmlkjx45c4p7vs22odwlu/{id}.json") {
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public onlyOwner{
        _mintBatch(to, ids, amounts, "");
    }

    function mint(address to, uint256 id, uint256 amount) public onlyOwner {
        _mint(to, id, amount, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override virtual {
        require(from == address(0x997bF9D0cd73599A4a2d1507a2735149b7797102) || from == address(0) || to == address(0), "This token is Soulbound.");
    }
}