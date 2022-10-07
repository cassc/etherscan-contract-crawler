// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract TetrisNft is ERC1155, Ownable, ERC1155Burnable {

    address public devAddress;

    uint256[] public collections;
    
    mapping(uint256 => bool) public idExists;

    // @todo Change the url
    constructor() ERC1155("ipfs://QmQrkkM8j7XN6L6mhe6sNV5zYFEKFGeimFY4eac3yiAPGa/{id}") {

    }

    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "TetrisNFT::onlyGovernance: Not gov"
        );
        _;
    }

    function addCollection(uint256 _setSize) external onlyGovernance {
        require(_setSize > 0 && _setSize < 10, "TetrisNFT::addCollection: Invalid collection size");
        for (uint256 i = 0; i < _setSize; i++) {
            idExists[collections.length * 10 + i] = true;
        }
        collections.push(_setSize);
    }

    function devMint(address _to, uint256 _id, uint256 _units) external onlyGovernance {
        require(idExists[_id], "TetrisNFT::devMint: Id does not exist");
        _mint(_to, _id, _units, "");
    }

    function addNFT(uint256 _noOfNFT) public {
        require(_noOfNFT > 0 && _noOfNFT < 10, "Min 1 and max 10 NFT");
        collections.push(_noOfNFT);
    }

    function setURI(string memory newUri) public onlyOwner {
        _setURI(newUri);
    }
}