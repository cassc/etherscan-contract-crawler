// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract FuckPelosi is ERC721A, Ownable, ReentrancyGuard {

    uint public maxSupply = 4444;
    string public baseURI = '';
    uint public mintLimit = 1;
    uint public cost = 0;

    mapping(address => uint[]) public mintTokenIdsMap;
    mapping(uint => string) public tokenIdNameMap;
    mapping(string => bool) public nameMap;

    constructor() ERC721A('Fuck Pelosi', 'FuckPelosi') {
    }

    function updateMaxSupply(uint8 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
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

    function mint(string memory name) external payable {
        address msgSender = _msgSender();

        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= cost, 'Insufficient funds');
        require(mintTokenIdsMap[msgSender].length + 1 <= mintLimit, 'Max mints per wallet met');
        require(nameMap[name] == false, 'Name duplicate');
        require(totalSupply() + 1 <= maxSupply, 'Max supply exceeded');

        tokenIdNameMap[totalSupply()] = name;
        nameMap[name] = true;
        mintTokenIdsMap[msgSender].push(totalSupply());

        _safeMint(msgSender, 1);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}('');
        require(os);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(baseURI, _toString(_tokenId), '?name=', tokenIdNameMap[_tokenId]));
    }
}