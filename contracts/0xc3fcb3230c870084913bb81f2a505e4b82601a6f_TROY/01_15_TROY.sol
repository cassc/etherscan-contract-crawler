// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract TROY is ERC721, IERC2981, Pausable, Ownable, ERC721Burnable {
    string public _defaultBaseURI;
    uint256 public royaltyFee;
    address public royaltyWallet;

    constructor() ERC721("Troy Lamarr Chew II - The Roof is on Fire", "TChew") {}


    function _baseURI() internal view override returns (string memory) {
        return _defaultBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _defaultBaseURI = _newBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 tokenId)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
    }

    function royaltyInfo(uint256, uint256 value) external view override returns (address, uint256)
    {
        return (royaltyWallet, (value * royaltyFee) / 10000);
    }

    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        require(value <= 10000, "INVALID Royalties");
        require(recipient != address(0), "BLACKHOLE WALLET");
        royaltyWallet = recipient;
        royaltyFee = value;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

     function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
}