// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract URSFactory is ERC721, Ownable {
    string public baseURI;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public totalSupply;
    address public ursStore;

    event SetURSStore(address ursStore);
    event SetBaseURI(string baseURI);

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI
    ) ERC721(__name, __symbol) {
        baseURI = __baseURI;
    }

    modifier onlyOwnerOrStore() {
        require(
            ursStore == msg.sender || owner() == msg.sender,
            "caller is neither ursStore nor owner"
        );
        _;
    }

    function setURSStore(address _ursStore) external onlyOwner {
        ursStore = _ursStore;
        emit SetURSStore(_ursStore);
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
        emit SetBaseURI(__baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address to) public onlyOwnerOrStore {
        require(totalSupply < MAX_SUPPLY, "Exceeds max supply");
        _mint(to, totalSupply);
        totalSupply += 1;
    }
}