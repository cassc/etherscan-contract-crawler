//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HonoraryNFT is ERC721A, Ownable, ReentrancyGuard {

    // State Variables
    string private _baseTokenURI;

    // Events
    event TokenMint(address indexed target, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721A(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    // External Functions

    function mint(address _to, uint256 _amount) public onlyOwner {
        _safeMint(_to, _amount);
        emit TokenMint(_to, _amount);
    }

    function mintToEach(address[] memory _to, uint256 amount) external onlyOwner {
        for(uint i; i<_to.length; ++i){
            _mint(_to[i], amount);
        }
    }

    function setBaseURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    // Internal Functions
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}