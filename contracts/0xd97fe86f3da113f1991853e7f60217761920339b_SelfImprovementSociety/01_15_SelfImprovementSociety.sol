// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721ABurnable.sol";
import "./ERC721AOwnersExplicit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SelfImprovementSociety is ERC721ABurnable, ERC721AOwnersExplicit, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    
    string private baseURI;

    uint256 public immutable price = 0.06 ether;
    uint256 public immutable maxTokensWallet = 21;
    uint256 public immutable maxSupply = 5521;

    uint256 public saleIsOpen;
    
    constructor() ERC721A("SelfImprovementSociety", "SiS") {
        reserveForTeam();
    }

    function reserveForTeam() internal {
         _safeMint(msg.sender, 60);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _amount) external payable {
        require(totalSupply() + _amount < maxSupply, "Max supply reached");
        if (msg.sender != owner()) {
            require(_numberMinted(msg.sender) + _amount < maxTokensWallet, "Max token per wallet reached");
            require(saleIsOpen == 1, "Sale is paused");
            require(msg.value >= price *_amount, "Insufficient funds");
        }

        _safeMint(msg.sender, _amount);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function setSale(uint256 _saleIsOpen) external onlyOwner {
        saleIsOpen = _saleIsOpen;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    // Use with caution may run out of gas
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }
}