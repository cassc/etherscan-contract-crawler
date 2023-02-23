pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Babyravens is ERC721A, Ownable {
    constructor() ERC721A("Babyravens", "BABYRAVENS") {}

    address[] public allowlist;

    bool once_call = true;

    function mint() external onlyOwner {
        require(once_call, "mint over");
        for (uint256 i; i < allowlist.length; i++) {
            _mint(allowlist[i], 5);
        }
        once_call = false;
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