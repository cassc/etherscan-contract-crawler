// SPDX-License-Identifier: MIT
/*
  /$$$$$$  /$$$$$$$  /$$$$$$$$ /$$$$$$$  /$$$$$$$$        /$$$$$$  /$$   /$$ /$$   /$$  /$$$$$$ 
 /$$__  $$| $$__  $$| $$_____/| $$__  $$| $$_____/       /$$__  $$| $$  / $$| $$$ | $$ /$$__  $$
| $$  \ $$| $$  \ $$| $$      | $$  \ $$| $$            | $$  \__/|  $$/ $$/| $$$$| $$| $$  \__/
| $$$$$$$$| $$$$$$$/| $$$$$   | $$$$$$$/| $$$$$         | $$ /$$$$ \  $$$$/ | $$ $$ $$| $$ /$$$$
| $$__  $$| $$____/ | $$__/   | $$____/ | $$__/         | $$|_  $$  >$$  $$ | $$  $$$$| $$|_  $$
| $$  | $$| $$      | $$      | $$      | $$            | $$  \ $$ /$$/\  $$| $$\  $$$| $$  \ $$
| $$  | $$| $$      | $$$$$$$$| $$      | $$$$$$$$      |  $$$$$$/| $$  \ $$| $$ \  $$|  $$$$$$/
|__/  |__/|__/      |________/|__/      |________/       \______/ |__/  |__/|__/  \__/ \______/ 
*/
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

error TransactionLimitExceeded();
error WalletLimitExceeded();
error SoldOut();

contract APepeGxng is ERC721A, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = 3333;

    uint256 public maxMintsPerTransaction = 2;
    uint256 public maxMintsPerWallet = 5;

    string private _tokenBaseURI;
    address private _founder1 = 0xC197cC18f5a1521879d4018dCbf729b8296dCeCf;
    address private _founder2 = 0x676e5020066B544F9157C433b23df681a9A71E49;

    constructor(uint256 quantity) ERC721A("Apepe Gxng", "APEPEGXNG") {
        _mint(_founder1, quantity);
        _mint(_founder2, quantity);
        _pause();
    }

    function mint(uint256 quantity) external whenNotPaused {
        if (quantity > maxMintsPerTransaction) revert TransactionLimitExceeded();
        if (_numberMinted(msg.sender) + quantity > maxMintsPerWallet) revert WalletLimitExceeded();
        if (_totalMinted() + quantity > MAX_SUPPLY) revert SoldOut();
        _mint(msg.sender, quantity);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function setMaxMintsPerTransaction(uint256 _maxMintsPerTransaction) external onlyOwner {
        maxMintsPerTransaction = _maxMintsPerTransaction;
    }

    function setMaxMintsPerWallet(uint256 _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setTokenBaseURI(string memory tokenBaseURI_) external onlyOwner {
        _tokenBaseURI = tokenBaseURI_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        uint256 half = address(this).balance / 2;
        (bool withdrawal1, ) = _founder1.call{value: half}("");
        require(withdrawal1, "Withdrawal 1 failed");
        (bool withdrawal2, ) = _founder2.call{value: half}("");
        require(withdrawal2, "Withdrawal 2 failed");
    }

    receive() external payable {}
}