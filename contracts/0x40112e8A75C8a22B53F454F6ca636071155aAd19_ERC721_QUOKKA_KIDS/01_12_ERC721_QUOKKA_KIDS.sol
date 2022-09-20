// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";

import "hardhat/console.sol";


interface IERC1155Burnable {
    function burn(
        address from,
        uint256 id,
        uint256 amount) external;
    // function totalSupply() external view returns (uint256);
    // function ownerOf(uint256 tokenId) external view returns (address);
    // function balanceOf(address owner) external view returns (uint256);
}

// azuki contract
// with the necessary setters and helper functions
// 
contract ERC721_QUOKKA_KIDS is ERC721A, Ownable {
    uint256 public constant DOUBLE_TICKET = 2;
    uint256 public constant TRIPLE_TICKET = 3;

    using Address for address;
    using Strings for uint256;

    mapping(address => bool) public minter;
    mapping(address => bool) public admin;

    string public _baseTokenURI;
    address public preorderContract;
    uint256 public adoptedTotalSupply;
    uint256 public adoptedAvailable = 4250;
    uint256 public generalAvailable = 7750;
    bool public holdForParenting = true;

    mapping(uint256 => bool) public genesisParents;
    mapping(uint256 => bool) public legendParents;

    constructor() ERC721A("TRIBE QUOKKA KIDS", "TQK") {
        admin[msg.sender] = true;
    }

    function setAdmin(address addr, bool active) public onlyOwner {
        admin[addr] = active;
    }

    function setPreorderContract(address preorderContract_) public onlyOwner {
        preorderContract = preorderContract_;
    }

    modifier onlyAdmin() {
        require(msg.sender != address(0), "Roles: account is the zero address");
        require(admin[msg.sender], "Must be admin");
      _;
    }

    function setAvailable(uint256 adopted_, uint256 general_) public onlyAdmin {
      adoptedAvailable = adopted_;
      generalAvailable = general_;
    }

    function setHoldForParenting(bool hold_) public onlyAdmin {
      holdForParenting = hold_;
    }
    
    function setGenesisParentUsed(uint256 index, bool used) public virtual onlyMinter {
      console.log('setting genesis', index);
      genesisParents[index] = used;
    }

    function setLegendParentUsed(uint256 index, bool used) public virtual onlyMinter {
      legendParents[index] = used;
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

    function mint(address to, uint count) public virtual onlyMinter {
      if (holdForParenting) {
        require(totalSupply() + count - adoptedTotalSupply <= generalAvailable, "Not enough non-parented tokens available");
      } else {
        require(totalSupply() + count <= generalAvailable + adoptedAvailable, "Not enough tokens available");
      }
      _mint(to, count);
    }

    function parentMint(address to, uint count) public virtual onlyMinter {
        require(adoptedTotalSupply + count <= adoptedAvailable, "Too many adopted tokens");
        adoptedTotalSupply += count;
        _mint(to, count);
    }

    modifier onlyMinter() {
      require(_msgSender() != address(0), "Account cannot be the zero address");
      require(minter[_msgSender()], "ERC721InitMint: must have minter role to mint");
      _;
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