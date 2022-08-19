//SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/Helper.sol";

//This is a Soulbound NFT given to the victims who got rugged by NFT projects. This NFT also serves as a proof of membership to JomoDAO, where we embrace the Joy of Missing (or Missed) Out, where we're building the strongest community with anger and despair, instead of hopes and dreams. While we expose the darkest histories of those rugged project founders, we build a true community with talents and resources.

contract JomoPoo is ERC1155, ERC1155Supply, Helper {

    string public name = "JomoPoo";
    string public symbol = "POO";
    uint256 public serial = 1;
    bool public pause = true;

    constructor() ERC1155("https://storageapi.fleek.co/e64b9171-c423-4d06-90fd-2384927f4ce6-bucket/JomoPoo/{id}.json"){
    }

    function setSerial(uint256 _serial) public onlyOwner {
        serial = _serial;
    }

    function setURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    function batchMintById(address _to ,uint256 _serial, uint256 _amount) public onlyHelper {
        _mint(_to, _serial , _amount , "");
    }

    function batchMint(address _to ,uint256 _amount) public onlyHelper {
        _mint(_to, serial , _amount , "");
    }

    function pauseStatus(bool _status) public onlyOwner{
        pause = _status;
    }

    function burn(address from, uint256 id, uint256 amounts) public onlyHelper {
        _burn(from,id,amounts);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        if (pause && from != address(0)){
            require(pause == false,"NOT ALLOW TRANSFER");
        }
        _safeTransferFrom(from, to, id, amount, data);
    }
}