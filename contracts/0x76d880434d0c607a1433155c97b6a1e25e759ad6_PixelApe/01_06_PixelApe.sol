// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PixelApe is ERC721A, Ownable, ReentrancyGuard {
    uint256 private _collectionSize = 10000;
    uint256 private _batchSize = 1;
    bool private _paused = true;
    string private _baseTokenURI =
        "ipfs://bafybeidldridsqko7yn4abhsuplpggh7i437cclsdjupsexb3p56tyctdi/";

    constructor() ERC721A("PixelApe", "pApe") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        require(
            totalSupply() + quantity <= _collectionSize,
            "Reached max supply."
        );
        _safeMint(to, quantity);
    }

    function mint() public nonReentrant {
        require(!_paused, "Public mint has not begun yet.");
        require(tx.origin == msg.sender, "The caller is another contract.");
        require(
            totalSupply() + _batchSize <= _collectionSize,
            "Reached max supply."
        );
        require(
            _numberMinted(msg.sender) < _batchSize,
            "Can not mint this many."
        );
        _safeMint(msg.sender, _batchSize);
    }

    function openPublicMint(bool state) public onlyOwner {
        _paused = !state;
    }

    function setBatchSize(uint256 size) public onlyOwner {
        _batchSize = size;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}