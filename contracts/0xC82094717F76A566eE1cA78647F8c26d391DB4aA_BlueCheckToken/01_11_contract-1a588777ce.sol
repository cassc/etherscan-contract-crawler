// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC1155/ERC1155.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC1155/extensions/ERC1155Supply.sol";

contract BlueCheckToken is ERC1155, Ownable, ERC1155Supply {
    uint256 public minimumDonationAmount;
    constructor() ERC1155("") {}

    function setMinimumDonationAmount(uint256 newDonationAmount) public onlyOwner {
        minimumDonationAmount = newDonationAmount;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint()
        public
        payable
    {
        require(msg.value >= minimumDonationAmount, 'Amount was lower than minimum donation');
        _mint(msg.sender, 1, 1, "");
        payable(owner()).transfer(msg.value);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}