// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./erc721a/ERC721A.sol";
import "./erc721a/extensions/ERC721AQueryable.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20.sol";

contract PepePunks is ERC721AQueryable, AccessControl, Ownable {
	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public maxSupply = 10000;
    string public _baseTokenURI;

    constructor() ERC721A(
    	"Pepepunks NFT",
        "PePeN"
        ){
        _baseTokenURI = "";
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    	_setupRole(MINTER_ROLE, msg.sender);
    	_setupRole(ADMIN_ROLE, msg.sender);
    }

    function mint(address _to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + quantity <= maxSupply, 'Exceeds MAX_SUPPLY');
        _mint(_to, quantity);
    }

    function burn(uint256 tokenId) external {
    	_burn(tokenId, true);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseUrl(string memory _newUri) public onlyRole(ADMIN_ROLE) {
        _baseTokenURI = _newUri;
    }

    function withdraw(
        uint256 amount,
        address _to,
        address _tokenAddr
    ) public onlyRole(ADMIN_ROLE){
        require(_to != address(0));
        if(_tokenAddr == address(0)){
            payable(_to).transfer(amount);
        }else{
            IERC20(_tokenAddr).transfer(_to, amount);
        }
    }
}