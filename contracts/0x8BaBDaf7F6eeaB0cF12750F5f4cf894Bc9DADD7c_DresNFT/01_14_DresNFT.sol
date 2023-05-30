//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./IDresNFT.sol";

contract DresNFT is ERC721Enumerable, Ownable, IDresNFT {
    uint256 public immutable MAX_SUPPLY;

    uint256 public currentTokenId;

    uint256 public reservedSupply;

    uint256 public mintedReservedNFTs;

    string public TOKEN_URI;

    mapping(address => bool) public minters;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _reservedSupply
    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        reservedSupply = _reservedSupply;
    }

    function addMinter(address _minter) external onlyOwner {
        require(!minters[_minter], "DresNFT: Already added");
        minters[_minter] = true;
    }

    function removeMinter(address _minter) external onlyOwner {
        require(minters[_minter], "DresNFT: Not minter");
        minters[_minter] = false;
    }

    function setTokenURI(string memory _tokenURI) external onlyOwner {
        TOKEN_URI = _tokenURI;
    }

    function _mintNFT(address _who, uint256 _amount) private {
        for (uint256 i = 0; i < _amount; i++) {
            currentTokenId++;
            _mint(_who, currentTokenId);
        }
    }

    function mint(address _who, uint256 _amount) external override onlyMinter {
        require(_amount > 0, "DresNFT: Amount should be greater than 0");
        require(
            currentTokenId + _amount <= MAX_SUPPLY - reservedSupply,
            "DresNFT: Overflowed MAX Supply"
        );

        _mintNFT(_who, _amount);
    }

    function mintReservedNFT(address _who, uint256 _amount)
        external
        override
        onlyMinter
    {
        require(_amount > 0, "DresNFT: Amount should be greater than 0");
        require(
            mintedReservedNFTs + _amount <= reservedSupply,
            "DresNFT: Overflowed MAX Supply"
        );

        mintedReservedNFTs += _amount;
        _mintNFT(_who, _amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return TOKEN_URI;
    }

    modifier onlyMinter() {
        require(minters[_msgSender()], "DresNFT: Caller is not a minter");
        _;
    }
}