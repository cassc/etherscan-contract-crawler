// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

/***
 _______    ______    ______    ______  
|       \  /      \  /      \  /      \ 
| $$$$$$$\|  $$$$$$\|  $$$$$$\|  $$$$$$\
| $$__| $$| $$  | $$| $$  | $$| $$___\$$
| $$    $$| $$  | $$| $$  | $$ \$$    \ 
| $$$$$$$\| $$  | $$| $$  | $$ _\$$$$$$\
| $$  | $$| $$__/ $$| $$__/ $$|  \__| $$
| $$  | $$ \$$    $$ \$$    $$ \$$    $$
 \$$   \$$  \$$$$$$   \$$$$$$   \$$$$$$      

*/

import { ERC721A } from "lib/ERC721A/contracts/ERC721A.sol";
import { ERC2981 } from "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { Pausable } from "lib/openzeppelin-contracts/contracts/security/Pausable.sol";

error FreeMintClaimed();
error MintLimitExceeded();
error SoldOut();
error WrongAmountSent();

contract Roos is ERC721A, ERC2981, Ownable, Pausable {
    address private constant _FOUNDER_1 = 0xdE8378F1bB13EeEf7da46DCE57486db6C642C79b;
    address private constant _FOUNDER_2 = 0x88C4Fe80B70BF6f3bf5213A5F7ac131B73e5A679;
    uint256 public constant MAX_SUPPLY = 5569;

    string private _tokenBaseURI;
    uint256 public mintLimit = 13;
    uint256 public mintPrice = .001 ether;
    mapping(address => bool) public hasFreeMinted; 

    constructor() ERC721A("Roos", "ROOS") {
        _setDefaultRoyalty(address(this), 500);
        _pause();
        _safeMint(_FOUNDER_2, 1);
    }

    modifier checkMintLimit(uint256 quantity) {
        if (quantity + _numberMinted(msg.sender) > mintLimit) revert MintLimitExceeded();
        _;
    }

    modifier checkSupply(uint256 quantity) {
        if (quantity + _totalMinted() > MAX_SUPPLY) revert SoldOut();
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function freeMint() external whenNotPaused checkMintLimit(3) checkSupply(3) {
        if (hasFreeMinted[msg.sender]) revert FreeMintClaimed();
        hasFreeMinted[msg.sender] = true;
        _safeMint(msg.sender, 3);
    }

    function mint(uint256 quantity) external payable whenNotPaused checkMintLimit(quantity) checkSupply(quantity) {
        uint256 total = quantity * mintPrice;
        if (total != msg.value) revert WrongAmountSent();
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

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
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