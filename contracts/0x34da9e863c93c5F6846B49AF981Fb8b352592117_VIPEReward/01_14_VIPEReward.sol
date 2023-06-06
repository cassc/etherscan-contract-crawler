// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/* 

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@.................................................[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@@@@[email protected]@@@@[email protected]@@*[email protected]@@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@[email protected]@@*[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@
@@@@@[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@@@
@@@@@[email protected]@@[email protected]@[email protected]@[email protected]@@@[email protected]@@[email protected]@@[email protected]@@@
@@@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@@[email protected]@@[email protected]@@@@([email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@[email protected]@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@[email protected]@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@&[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@[email protected]@[email protected]@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@@[email protected]@@@[email protected]@@@@[email protected]@@[email protected]@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   
 
*/

contract VIPEReward is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    constructor() ERC1155("ipfs://QmSh2LFcZJ7S4msieeJ4HC9yciAYhhQB6vyjW8o2o3UCcP") {}

    error NotTransferable();
    string folderHash; 
   
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

    function airdrop(address[] memory to , uint256 id)
        public
        onlyOwner   
    {
        for(uint256 i = 0 ; i< to.length; i++){
            _mint(to[i], id, 1 , ""); 
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        if(from == address(0) || to == address(0) ){
            super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
            return;
        }
        revert NotTransferable();
    }

    function setFolderHash(string memory _newFolderHash) public onlyOwner {
        folderHash = _newFolderHash; 
    }

    function uri(uint256 tokenId) override public view returns(string memory)
    {
        return(
            string(abi.encodePacked(
                folderHash,"/", Strings.toString(tokenId), ".json"
            ))
        );
    }
}