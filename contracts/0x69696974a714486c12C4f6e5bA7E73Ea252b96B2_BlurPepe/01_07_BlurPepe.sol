// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**

__________████████_____██████
_________█░░░░░░░░██_██░░░░░░█
________█░░░░░░░░░░░█░░░░░░░░░█
_______█░░░░░░░███░░░█░░░░░░░░░█
_______█░░░░███░░░███░█░░░████░█
______█░░░██░░░░░░░░███░██░░░░██
_____█░░░░░░░░░░░░░░░░░█░░░░░░░░███
____█░░░░░░░░░░░░░██████░░░░░████░░█
____█░░░░░░░░░█████░░░████░░██░░██░░█
___██░░░░░░░███░░░░░░░░░░█░░░░░░░░███
__█░░░░░░░░░░░░░░█████████░░█████████
_█░░░░░░░░░░█████_████___████_█████___█
_█░░░░░░░░░░█______█_███__█_____███_█___█
█░░░░░░░░░░░░█___████_████____██_██████
░░░░░░░░░░░░░█████████░░░████████░░░█
░░░░░░░░░░░░░░░░█░░░░░█░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░██░░░░█░░░░░░██
░░░░░░░░░░░░░░░░░░██░░░░░░░███████
░░░░░░░░░░░░░░░░██░░░░░░░░░░█░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░█████████░░░░░░░░░░░░░░██
░░░░░░░░░░█▒▒▒▒▒▒▒▒███████████████▒▒█
░░░░░░░░░█▒▒███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░█▒▒▒▒▒▒▒▒▒█████████████████
░░░░░░░░░░████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░░░░░░░░░░██████████████████
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
██░░░░░░░░░░░░░░░░░░░░░░░░░░░██
▓██░░░░░░░░░░░░░░░░░░░░░░░░██
▓▓▓███░░░░░░░░░░░░░░░░░░░░█
▓▓▓▓▓▓███░░░░░░░░░░░░░░░██
▓▓▓▓▓▓▓▓▓███████████████▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█

**/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlurPepe is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI = "https://blurpepe.xyz/api/token/";
    
    uint256 public mintPrice = 0.002 * 1 ether;
    uint256 public maxSupply = 6969;
    uint256 public maxPerTransaction = 10;

    bool public saleStart = false;

    constructor() ERC721A("Blur Pepes", "bPEPEV2") { 
        _mint(msg.sender, 1);
        _burn(0);
    }

    function reserveTeamTokens(uint256 _quantity) onlyOwner external {
        _mint(msg.sender, _quantity);
    }

    function numberMinted() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }

    function mint(uint256 _quantity) payable external nonReentrant {
        require(saleStart, "BLURPEPE_SALE_NOT_STARTED");
        require(_quantity <= maxPerTransaction, "BLURPEPE_TOO_MANY_REQUESTED");
        require(totalSupply() + _quantity <= maxSupply, "BLURPEPE_SOLD_OUT");
        if (_numberMinted(msg.sender) > 0) {
            require(msg.value == _quantity * mintPrice, "BLURPEPE_INVALID_VALUE");
        } else {
            require(msg.value == (_quantity == 1 ? 0 : (_quantity - 1) * mintPrice), "BLURPEPE_INVALID_VALUE");
        }
        _mint(msg.sender, _quantity);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function startSale() external onlyOwner {
        saleStart = true;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function contractURI() public pure returns (string memory) {
        return "https://blurpepe.xyz/api/contracturi";
    }

}