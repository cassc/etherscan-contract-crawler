// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract MRC1155 is AccessControl, ERC1155Supply{

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri){
        name = _name;
        symbol = _symbol;
    }


    function mint(address to, uint256 id, uint256 amount, bytes memory data)
        internal virtual
    {
        _beforeMint(to, id, amount);
        _mint(to, id, amount, data);
    }

    function burn(address account, uint256 id, uint256 amount) public{
        require(isApprovedForAll(account, _msgSender()), "caller is not approved");
        _burn(account, id, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeMint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {}

    function metadata()
        public
        view
        returns(
            string memory _name, 
            string memory _symbol
        )
    {
        _name = name;
        _symbol = symbol;
    }

}