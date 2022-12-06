//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CyberBonk is Ownable, ERC1155 {

    uint256 public constant MAX_SUPPLY = 1111;
    uint256 public index;
    
    constructor(string memory _uri) ERC1155(_uri) {}

    function setURI(string calldata newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(string calldata pwd) external {
        require(index < MAX_SUPPLY, "supply limit");
        require(balanceOf(_msgSender(), 0) == 0, "Can only mint one NFT per address");
        require(compare(pwd, "ToBonkOrNotToBonk"), "Password not match");

        // mint
        _mint(_msgSender(), 0, 1, "");

        unchecked {
            index++;
        }
    }

    function compare(string memory str1, string memory str2) private pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}