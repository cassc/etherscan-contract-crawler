// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract AncientFarm is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {

    uint public immutable maxSupply = 20000000;
    bool public isOpen = false;
    string public baseURI = 'https://res.ancientfarm.xyz/metadata/';
    uint public mintLimit = 10;
    uint public cost = 0; 
    mapping(address => bool) public mintedAddressMap;

    constructor(bool isOpen_) ERC721A('Ancient Farm', 'AF') {
        isOpen = isOpen_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateOpenStatus(bool isOpen_) public onlyOwner {
        isOpen = isOpen_;
    }

    function mint() external payable {
        address msgSender = _msgSender();

        require(isOpen == true, 'The contract is not open, please wait...');
        require(tx.origin == msgSender, 'Only EOA');
        require(mintedAddressMap[msgSender] == false, 'Mint limit reached');

        _doMint(msgSender, mintLimit);
        mintedAddressMap[msgSender] = true;
    }

    function airdrop(address[] memory mintAddresses, uint[] memory mintCounts) public onlyOwner {
        for (uint i = 0; i < mintAddresses.length; i++) {
            _doMint(mintAddresses[i], mintCounts[i]);
        }
    }

    function _doMint(address to, uint quantity) private {
        require(totalSupply() + quantity <= maxSupply, 'Max supply exceeded');
        require(to != address(0), 'Cannot have a non-address as reserve.');
        _safeMint(to, quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}('');
        require(os);
    }
}