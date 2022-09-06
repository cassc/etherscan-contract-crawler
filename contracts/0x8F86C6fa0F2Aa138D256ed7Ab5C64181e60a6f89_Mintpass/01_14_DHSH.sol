// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract Mintpass is ERC1155, Ownable, Pausable, ERC1155Supply, ERC1155Burnable {
    bytes32 public root;
    uint256 public maxMintAmount = 1;
    string public name = "Dancing Seahorse Mint Pass";
    bool public passActive = false;
    string public symbol = "DSCMP";
    
    constructor(bytes32 _root)
        ERC1155("")
    {
        root = _root;
    }

    event Claimedmintpass(
        uint256 tokenId,
        uint256 amount,
        address indexed buyer
    );

    function setRoot(bytes32 _newRoot) public onlyOwner {
        root = _newRoot;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function flipPass() public onlyOwner {
        passActive = !passActive;
       
    }

     
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    

    function setMaxMint(uint256 _newmaxmint) public onlyOwner {
        maxMintAmount = _newmaxmint;
    }

    function makeNft(
        address _account,
        uint256 _id,
        bytes32[] memory _proof
      
    ) public {
        uint256 nftbalance = balanceOf(_account, _id);
        require(passActive == true, "Sale is not Active");
        require(nftbalance < maxMintAmount, "You have exceeding number of mints");
        require(
            isWhitelisted(_proof,keccak256(abi.encodePacked(msg.sender))),
            "Not on Whitelist"
        );
         
        _mint(_account, _id, maxMintAmount, "");
        emit Claimedmintpass(_id, maxMintAmount, msg.sender);
    }

    function gift(
        address _account,
        uint256 _id,
        uint256 _amount
    ) public onlyOwner {
        _mint(_account, _id, _amount, "");
    }

    function expel(
        uint256 _id,
        uint256 _amount,
        address _account
    ) public onlyOwner {
        _burn(_account, _id, _amount);
    }

    function isWhitelisted(bytes32[] memory prf, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(prf, root, leaf);
    }

     function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

 
}