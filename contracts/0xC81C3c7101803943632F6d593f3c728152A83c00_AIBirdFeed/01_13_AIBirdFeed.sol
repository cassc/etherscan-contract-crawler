// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';

contract AIBirdFeed is ERC1155Supply, ERC1155Burnable, Ownable {
    
    address public _minter;
    string private _metadataURI;
    string private _name;
    string private _symbol;

    uint public constant supply = 1_001; // 1000
    uint public minted = 0;

    constructor(address minter_) 
        ERC1155("") {
        _minter = minter_;
        _name = "AI Bird Feed";
        _symbol = "AIFEED";
    }

    function mint(address addr, uint quantity) external {
        require(msg.sender == _minter, "Invalid minter");
        minted += quantity;
        if(minted < supply) {
            _mint(addr, 0, quantity, "");
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    function metadataURI() public view returns (string memory) {
        return _metadataURI;
    }

    function setMetadataURI(string memory uri_) external onlyOwner {
        _metadataURI = uri_;
    }
    
    function setMinter(address addr) external onlyOwner {
        _minter = addr;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId), "Token does not exist.");
        return _metadataURI;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}