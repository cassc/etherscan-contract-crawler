// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";

contract ERC721_LEGENDS is ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;

    mapping(address => bool) public minter;
    mapping(address => bool) public admin;

    string private _baseTokenURI;

    constructor() ERC721A("TRIBE QUOKKA LEGENDS", "TQLGNDS") {
        admin[msg.sender] = true;
    }

    function setAdmin(address addr, bool active) public onlyOwner {
        admin[addr] = active;
    }

    modifier onlyAdmin() {
        require(msg.sender != address(0), "Roles: account is the zero address");
        require(admin[msg.sender], "Must be admin");
      _;
    }

    function setMinter(address addr, bool active) public onlyAdmin {
        minter[addr] = active;
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address to, uint count) public virtual {
        require(_msgSender() != address(0), "Account cannot be the zero address");
        require(minter[_msgSender()], "ERC721A: must have minter role to mint");
        _mint(to, count);
    }

    function adminMint(address to, uint count) public onlyAdmin {
        _mint(to, count);
    }

    function adminBurn(uint tokenId) public onlyAdmin {
        // owner must also own tokenId
        require(ownerOf(tokenId) == msg.sender, "Must own token to burn");
        _burn(tokenId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns(uint256) {
        require(owner != address(0));
        require(index < balanceOf(owner), "ERC721: out of bounds");
        uint count = 0;
        for(uint i = 1; i <= totalSupply(); i++) {
            if(ownerOf(i) == owner) {
                count += 1;
            }
            if(count > index) {
                return i;
            }
        }
        revert("unable to get token of owner by index");
    }

}