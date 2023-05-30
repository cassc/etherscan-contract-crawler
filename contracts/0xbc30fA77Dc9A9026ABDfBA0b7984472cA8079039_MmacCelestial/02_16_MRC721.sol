// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MRC721 is ERC721Enumerable, AccessControl{

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    string public _baseTokenURI;

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol){
        _baseTokenURI = _uri;
    }


    function mint(address to, uint256 id) external onlyRole(MINTER_ROLE){
        _beforeMint(to, id);
        _mint(to, id);
    }

    function burn(uint256 tokenId) public{
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensIds = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
          tokensIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensIds;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeMint(
        address to,
        uint256 id
    ) internal virtual {}

}