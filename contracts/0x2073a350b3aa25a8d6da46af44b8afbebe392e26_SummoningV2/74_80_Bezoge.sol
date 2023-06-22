//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../accessControl/AccessProtected.sol";

contract Bezogi is ERC721AQueryable, Pausable,AccessProtected {
    using Strings for uint256;

    bool public transferPause; 
    string public baseURI;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) 
        ERC721A(name_, symbol_) {

        baseURI = baseURI_;
        transferPause = false;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function mintTo(address to, uint quantity) external whenNotPaused onlyAdmin{
        require(to != address(0), "Can't mint to empty address");
        _safeMint(to, quantity);
    }

    function burn(uint256[] memory tokenIds) external whenNotPaused{
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address owner = ownerOf(tokenId);
            require(msg.sender == owner, string(abi.encodePacked(tokenId.toString()," is not your NFT")));
            _burn(tokenId);
        }
    }

    function updateTranferStatus(bool value)external onlyOwner{
        transferPause = value;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        require(!transferPause, "NFT transfers paused");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }
}