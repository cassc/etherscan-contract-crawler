pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DapeX is ERC721A, Ownable {
    constructor() ERC721A("DapeX", "DAPEX") {}

    uint256 maxSupply = 500;
    address[] public allowlist;

    function airdrop() external onlyOwner {
        require(totalSupply() <= maxSupply, "mint over");
        for (uint256 i; i < allowlist.length; i++) {
            _mint(allowlist[i], 10);
        }
    }

    function seedAllowlist(address[] memory addresses)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist.push(addresses[i]);
        }
    }
}