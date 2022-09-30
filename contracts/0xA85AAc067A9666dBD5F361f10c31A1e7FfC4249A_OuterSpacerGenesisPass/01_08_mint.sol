// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract OuterSpacerGenesisPass is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {

    uint public immutable maxSupply = 1069;
    string public baseURI = 'https://asset.laserspaceman.xyz/metadata/';
    uint public mintLimit = 5;
    uint public cost = 0.01 ether; // 0.01

    mapping(address => uint[]) public mintTokenIdsMap;

    constructor() ERC721A('OuterSpacerGenesisPass', 'OuterSpacerGenesisPass') {
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateMintLimit(uint mintLimit_) public onlyOwner {
        mintLimit = mintLimit_;
    }

    function updateCost(uint cost_) public onlyOwner {
        cost = cost_;
    }

    function getMintTokenIds(address msgSender) public view returns (uint[] memory _tokenIds) {
        _tokenIds = mintTokenIdsMap[msgSender];
    }

    function mint(uint quantity) external payable {
        address msgSender = _msgSender();
        uint expectedCost = quantity * cost;

        require(quantity > 0, 'Invalid quantity');
        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= expectedCost, 'Insufficient funds');
        require(mintTokenIdsMap[msgSender].length + quantity <= mintLimit, 'Max mints per wallet met');

        _doMint(msgSender, quantity);
        for (uint i = 0; i < quantity; i++) {
            mintTokenIdsMap[msgSender].push(totalSupply() - quantity + i);
        }
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}