// SPDX-License-Identifier: MIT

/* 
 ______  __                  __                        __        ____                                                       
/\__  _\/\ \                /\ \                      /\ \__    /\  _`\                                               __    
\/_/\ \/\ \ \___      __    \ \ \         __      ____\ \ ,_\   \ \,\L\_\     __      ___ ___   __  __  _ __    __   /\_\   
   \ \ \ \ \  _ `\  /'__`\   \ \ \  __  /'__`\   /',__\\ \ \/    \/_\__ \   /'__`\  /' __` __`\/\ \/\ \/\`'__\/'__`\ \/\ \  
    \ \ \ \ \ \ \ \/\  __/    \ \ \L\ \/\ \L\.\_/\__, `\\ \ \_     /\ \L\ \/\ \L\.\_/\ \/\ \/\ \ \ \_\ \ \ \//\ \L\.\_\ \ \ 
     \ \_\ \ \_\ \_\ \____\    \ \____/\ \__/.\_\/\____/ \ \__\    \ `\____\ \__/.\_\ \_\ \_\ \_\ \____/\ \_\\ \__/.\_\\ \_\
      \/_/  \/_/\/_/\/____/     \/___/  \/__/\/_/\/___/   \/__/     \/_____/\/__/\/_/\/_/\/_/\/_/\/___/  \/_/ \/__/\/_/ \/_/                                                                                                                                                                                                                                                    
The Last Samurai is an art project composed of 1500 images of Japanese samurai in dry brush and ink style. 
The creation lasted for one and a half years. The content and emotions of each work is the non-homogeneous. 
Every piece is unique.
*/

pragma solidity ^0.8.14;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract TheLastSamurai is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    bytes32 public saleMerkleRoot;
    string public baseTokenURI;
    uint256 public maxSupply;
    bool public paused = false;

    constructor(
        uint256 _maxSupply,
        string memory _baseTokenURI,
        bytes32 merkleRoot
    ) ERC721('TheLastSamurai', 'TLS') {
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        setSaleMerkleRoot(merkleRoot);
        selfMint(10);
    }

    modifier isValidMint(uint256 amount) {
        uint256 balance = balanceOf(_msgSender());
        require(!paused, 'contract is paused');
        require(balance < 5, 'mint more than 5 times');
        require(amount + balance <= 5, 'mint more than 5 times');
        require(totalSupply() < maxSupply, 'max supply exceeded');
        _;
    }

    function mint(bytes32[] calldata merkleProof, uint256 amount) public payable isValidMint(amount) {
        bool inWhiteList = MerkleProof.verify(merkleProof, saleMerkleRoot, keccak256(abi.encodePacked(_msgSender())));
        uint256 balance = balanceOf(_msgSender());
        if (inWhiteList) {
            if (balance == 0) {
                require((0.0072 ether * (amount - 1)) == msg.value, 'ether value you sent not correct');
            } else {
                require((0.0072 ether * amount) == msg.value, 'ether value you sent not correct');
            }
        } else {
            require((0.0072 ether * amount) == msg.value, 'ether value you sent not correct');
        }
        for (uint256 i = 0; i < amount; i++) {
            currentTokenId.increment();
            uint256 itemId = currentTokenId.current();
            _safeMint(_msgSender(), itemId);
        }
    }

    function selfMint(uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount < maxSupply, 'max supply exceeded');
        for (uint256 i = 0; i < _amount; i++) {
            currentTokenId.increment();
            uint256 itemId = currentTokenId.current();
            _safeMint(_msgSender(), itemId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), '.json')) : '';
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setSaleMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        saleMerkleRoot = merkleRoot;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}