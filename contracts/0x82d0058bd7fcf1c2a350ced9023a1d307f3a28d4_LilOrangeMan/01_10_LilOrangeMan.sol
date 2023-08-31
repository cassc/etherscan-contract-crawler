// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

/*
██╗░░░░░██╗██╗░░░░░  ░█████╗░██████╗░░█████╗░███╗░░██╗░██████╗░███████╗  ███╗░░░███╗░█████╗░███╗░░██╗
██║░░░░░██║██║░░░░░  ██╔══██╗██╔══██╗██╔══██╗████╗░██║██╔════╝░██╔════╝  ████╗░████║██╔══██╗████╗░██║
██║░░░░░██║██║░░░░░  ██║░░██║██████╔╝███████║██╔██╗██║██║░░██╗░█████╗░░  ██╔████╔██║███████║██╔██╗██║
██║░░░░░██║██║░░░░░  ██║░░██║██╔══██╗██╔══██║██║╚████║██║░░╚██╗██╔══╝░░  ██║╚██╔╝██║██╔══██║██║╚████║
███████╗██║███████╗  ╚█████╔╝██║░░██║██║░░██║██║░╚███║╚██████╔╝███████╗  ██║░╚═╝░██║██║░░██║██║░╚███║
╚══════╝╚═╝╚══════╝  ░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝░╚═════╝░╚══════╝  ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝
*/

import { ERC721A } from "lib/ERC721A/contracts/ERC721A.sol";
import { ERC2981 } from "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { Pausable } from "lib/openzeppelin-contracts/contracts/security/Pausable.sol";

error InvalidMintQuantity();
error SoldOut();

contract LilOrangeMan is ERC721A, ERC2981, Ownable, Pausable {
    address private constant _FOUNDER_1 = 0x630dC02d86c21179058a40888b502ab49Be3e121;
    address private constant _FOUNDER_2 = 0x88C4Fe80B70BF6f3bf5213A5F7ac131B73e5A679;
    uint256 public constant MAX_SUPPLY = 3333;

    string private _tokenBaseURI;
    uint256 public maxMintsPerWallet = 3;

    constructor() ERC721A("LilOrangeMan", "LILORANGEMAN") {
        _setDefaultRoyalty(address(this), 500);
        _pause();
        _safeMint(msg.sender, 1);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function mint(uint256 quantity) external whenNotPaused {
        if (quantity + _numberMinted(msg.sender) > maxMintsPerWallet) revert InvalidMintQuantity();
        if (quantity + _totalMinted() > MAX_SUPPLY) revert SoldOut();
        _safeMint(msg.sender, quantity);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId)
            || ERC2981.supportsInterface(interfaceId);
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setDefaultRoyalty(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(address(this), feeNumerator);
    }

    function setMaxMintsPerWallet(uint256 _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setTokenBaseURI(string memory tokenBaseURI_) external onlyOwner {
        _tokenBaseURI = tokenBaseURI_;
    }

    function withdraw() external onlyOwner {
        uint256 half = address(this).balance / 2;
        (bool withdrawal1, ) = _FOUNDER_1.call{value: half}("");
        require(withdrawal1, "Withdrawal 1 failed");
        (bool withdrawal2, ) = _FOUNDER_2.call{value: half}("");
        require(withdrawal2, "Withdrawal 2 failed");
    }

    receive() external payable { } 
}