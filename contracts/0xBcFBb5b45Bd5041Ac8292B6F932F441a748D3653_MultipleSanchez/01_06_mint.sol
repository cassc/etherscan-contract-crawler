// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract MultipleSanchez is ERC721A, Ownable, ReentrancyGuard {

    uint public immutable maxSupply = 2000;

    string public baseURI = 'https://res.multiplesanchez.xyz/metadata/';

    bool public publicSaleEnable = false;
    uint public mintLimit = 2;
    uint public cost = 0;

    mapping(address => uint[]) public mintTokenIdsMap;

    constructor() ERC721A('MultipleSanchez', 'MultipleSanchez') {
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updatePublicSaleEnable(bool publicSaleEnable_) public onlyOwner {
        publicSaleEnable = publicSaleEnable_;
    }

    function updateMintLimit(uint mintLimit_) public onlyOwner {
        mintLimit = mintLimit_;
    }

    function updateCost(uint cost_) public onlyOwner {
        cost = cost_;
    }

    function getMintTokenIds(address addr) public view returns (uint[] memory _tokenIds) {
        _tokenIds = mintTokenIdsMap[addr];
    }

    function checkCanMint(address from) public view {
        require(from != address(0), 'Cannot have a non-address as reserve');
        require(publicSaleEnable, 'Public-Sale is not open!');
    }

    function mint() external payable {
        address msgSender = _msgSender();

        checkCanMint(msgSender);
        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= cost, 'Insufficient funds');
        require(mintTokenIdsMap[msgSender].length + 2 <= mintLimit, 'Max mints per wallet met');

        _doMint(msgSender, 2);
        mintTokenIdsMap[msgSender].push(totalSupply() - 2);
        mintTokenIdsMap[msgSender].push(totalSupply() - 1);
    }

    function airdrop(address[] memory toAddresses, uint[] memory mintCounts) public onlyOwner {
        for (uint i = 0; i < toAddresses.length; i++) {
            _doMint(toAddresses[i], mintCounts[i]);
        }
    }

    function _doMint(address to, uint quantity) private {
        require(totalSupply() + quantity <= maxSupply, 'Max supply exceeded');
        require(to != address(0), 'Cannot have a non-address as reserve');
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