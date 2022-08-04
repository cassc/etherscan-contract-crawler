// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721PresetMinterPauserAutoId.sol";
import "./GeneGenerator.sol";

contract McBroHats is ERC721PresetMinterPauserAutoId, Ownable {
    using GeneGenerator for GeneGenerator.Gene;

    GeneGenerator.Gene internal geneGenerator;

    uint256 public maxSupply;
    mapping(uint256 => uint256) internal _genes;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _owner,
        uint96 _royaltyFee,
        uint256 _maxSupply
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseURI, _owner) {
        maxSupply = _maxSupply;
        geneGenerator.random();
        _setDefaultRoyalty(_owner, _royaltyFee);

    }

    function mintFree(uint256 amount) external {
        require(amount <= 2, "Can't mint more than 2 NFTs in one tx");
        require(_tokenId + amount <= maxSupply, "Total supply reached");
        require(balanceOf(_msgSender()) < 2, "Mint limit exceeded");

        for (uint256 i = 0; i < amount; i++) {
            _tokenId++;
            _genes[_tokenId] = geneGenerator.random();
            _mint(_msgSender(), _tokenId);
        }
    }

    function mint(address to) public override(ERC721PresetMinterPauserAutoId) {
        revert("Should not use this one");
    }

    function setDefaultRoyalty(address receiver, uint96 royaltyFee)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, royaltyFee);
    }

    function geneOf(uint256 tokenId) public view returns (uint256 gene) {
        return _genes[tokenId];
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }
}