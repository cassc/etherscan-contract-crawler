// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract ChimneyTownDAOPoubelle is ERC721A,Ownable,ReentrancyGuard {
    address private minterAddress;
    string public baseURI = "";
    string public baseExtension = ".json";
    
    modifier onlyOwnerORMinter(){
        require(minterAddress == _msgSender() || owner() == _msgSender(), "Ownable: caller is not the Owner or Minter");
        _;
    }

    constructor() ERC721A("CHIMNEY TOWN DAO Poubelle", "CTDP") {
        minterAddress = _msgSender();
    }

    function mint(address _to, uint256 _quantity) external onlyOwnerORMinter nonReentrant{
        _safeMint(_to, _quantity);
    }

    function setBaseURI(string memory _value) public onlyOwner {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value) public onlyOwner {
        baseExtension = _value;
    }

    function setMinterAddr(address _newMinterAddress) external onlyOwner {
        minterAddress = _newMinterAddress;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}