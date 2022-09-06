// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract DVC is ERC721Enumerable, Ownable {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 10001;
    string public baseURI;
    bool public onlyOwnerMint = false;
    string public baseExtension = ".json";
    string public ContractURI;

    constructor() ERC721("Dracula Vampire Club", "DVC") {}

    function mint(address _to, uint256 _mintAmount) public {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(supply + _mintAmount <= MAX_SUPPLY);

        if (msg.sender != owner()) {
            require(walletOfOwner(_to).length + _mintAmount <= 2, "You Cannot mint more than 2 NFTs");
            require(onlyOwnerMint,"Only owner can mint");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        
        return tokenIds;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return ContractURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function stopMint() public onlyOwner {
        onlyOwnerMint = true;
    }

    function resumeMint() public onlyOwner {
        onlyOwnerMint = false;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        ContractURI = _newContractURI;
    }
}