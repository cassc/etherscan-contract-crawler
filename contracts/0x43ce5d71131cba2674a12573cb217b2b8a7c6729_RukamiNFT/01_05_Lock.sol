// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RukamiNFT is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 5040;
    uint256 public constant PRICE_PER_TOKEN = 0 ether;
    string private _baseTokenURI;
    string private _ContractURI;

    constructor() ERC721A("RUKAMI", "RKM") {

    }

    function mint(address to, uint256 quantity) external onlyOwner payable {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max Supply Hit");
        require(msg.value >= quantity * PRICE_PER_TOKEN, "Insufficient Funds");
        _mint(to, quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string calldata setedContractURI) external onlyOwner {
        _ContractURI = setedContractURI;
    }

    function contractURI() public view returns (string memory) {
        return _ContractURI;
    }


    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}