// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC1155.sol";
import "Ownable.sol";
import "Pausable.sol";
import "ERC1155Burnable.sol";

contract GracelandPortrait is ERC1155, Ownable, Pausable, ERC1155Burnable {

    string public name = "Graceland Portrait PFP";

    constructor() ERC1155("https://ipfs.io/ipfs/QmTjeRoEnSsjiJ8vVijuFc6nAsb1bZhGVCtaYiDwL9oj3A/{id}.json") {}
    

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function destroy(address apocalypse) public onlyOwner {
        selfdestruct(payable(apocalypse));
    }

}