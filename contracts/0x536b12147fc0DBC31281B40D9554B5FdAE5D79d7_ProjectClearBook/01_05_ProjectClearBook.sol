// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/ERC721.sol";
import "./libs/SSTORE2.sol";

contract ProjectClearBook is ERC721, Ownable {
    mapping(uint256 => address) private idToPointer;
    address private mintManager;

    uint256 public constant maxSupply = 128;

    constructor() ERC721('Project Clear Book', 'PCB-NFT') {}

    function mint(address to, uint256 id, bytes calldata json) external {
        require(id < 128);
        require(IMintManager(mintManager).canMint(to, id, keccak256(json)));
        idToPointer[id] = SSTORE2.write(json);
        _mint(to, id);
    }

    function setMintManager(address newManager) external onlyOwner {
        mintManager = newManager;
    }

    function tokenURI(uint256 id) external view override returns (string memory) {
        return string(SSTORE2.read(idToPointer[id]));
    }
}

interface IMintManager {
    function canMint(address to, uint256 id, bytes32 jsonHash) external returns(bool);
}