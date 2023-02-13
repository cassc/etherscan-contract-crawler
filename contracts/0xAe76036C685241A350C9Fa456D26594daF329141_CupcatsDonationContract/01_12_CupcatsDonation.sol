// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CupcatsDonationContract is ERC1155, Ownable, ERC1155Supply {
    using SafeMath for uint256;
    bool public mintState = false;
    uint256 public cost = 0.001 ether;
    
    constructor()
        ERC1155("https://cupcat.mypinata.cloud/ipfs/QmU6eg2Pw8vQ5cScoZxLwcUFGy843add8NWPvmo5t7w95C")
    {}

    function mint(uint256 amount)
        public
        payable
    {          
        require(mintState, "rejected");
        require(msg.value == cost.mul(amount), "Ether value sent is not correct");
        _mint(msg.sender, 1, amount, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setMintState(bool _state) public onlyOwner {
         mintState = _state;
     }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable (owner()).transfer(balance);
    }
}