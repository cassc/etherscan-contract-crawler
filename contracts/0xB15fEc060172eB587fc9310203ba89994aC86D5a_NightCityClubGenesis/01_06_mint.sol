// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract NightCityClubGenesis is ERC721A, Ownable, ReentrancyGuard {

    uint public immutable maxSupply = 555;

    string public baseURI = 'https://arweave.net/KnaIHC1QNwcjWDmmfzxGrGsx3BsEpw0D2zJA-GguqXg/';

    uint public publicSaleOpenTimestamp = 1664640000;
    uint public mintLimit = 1;
    uint public cost = 0;

    mapping(address => uint[]) public mintTokenIdsMap;

    constructor() ERC721A('NightCityClubGenesis', 'NightCityClubGenesis') {
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateSaleOpenTimestamp(uint publicSaleOpenTimestamp_) public onlyOwner {
        publicSaleOpenTimestamp = publicSaleOpenTimestamp_;
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
        uint blockTimestamp = block.timestamp;
        require(blockTimestamp >= publicSaleOpenTimestamp, 'Public-Sale is not open!');
    }

    function mint() external payable {
        address msgSender = _msgSender();

        checkCanMint(msgSender);
        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= cost, 'Insufficient funds');
        require(mintTokenIdsMap[msgSender].length + 1 <= mintLimit, 'Max mints per wallet met');

        _doMint(msgSender, 1);
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