// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../ERC721AEnumerable.sol";

contract BadSeedsOoze is
    ERC721AEnumerable,
    Ownable
{
    uint256 public constant maxSupply = 5000;
    mapping(address => bool) public isBurner;
    string private baseURI;

    constructor() ERC721AEnumerable("Bad Seeds Ooze", "OOZE") {}

    modifier onlyBurner() {
        require(msg.sender == owner() || isBurner[msg.sender], "Only burner");
        _;
    }

    function airdrop(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "zero amount");
        require(_totalMinted() + _amount <= maxSupply, "exceeds maxsupply");

        _safeMint(_to, _amount);
    }

    function airdropBatch(address[] calldata _users, uint8[] calldata _amounts) external onlyOwner {
        require(_users.length == _amounts.length, "length missmath");

        for (uint256 i = 0; i < _users.length; ++i) {
            require(_amounts[i] > 0, "zero amount");
            _safeMint(_users[i], _amounts[i]);
        }

        require(_totalMinted() <= maxSupply, "exceeds maxsupply");
    }

    function burn(uint256 _tokenId) external onlyBurner {
        _burn(_tokenId);
    }

    function setBaseURI(string memory _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function setBurner(address _account, bool _isBurner) external onlyOwner {
        isBurner[_account] = _isBurner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}