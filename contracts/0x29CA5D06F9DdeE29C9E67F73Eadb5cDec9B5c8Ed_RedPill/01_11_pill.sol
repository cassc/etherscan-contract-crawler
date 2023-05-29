// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

interface IMainContract {
    function evolveFromPill(uint256 _tokenId) external;
    function getOwnerOfMain(uint256 _tokenId) external returns (address owner);
}

contract RedPill is Ownable, ERC721A, ReentrancyGuard {
    IMainContract mainContract;
    using ECDSA for bytes32;
    using Strings for uint256;
    using SafeMath for uint256; 

    bytes32 public merkleRoot;

    uint256 public maxSupply = 1000;

    bool public paused = true;
    bool public pausedBurn = true;

    string private baseMetadataUri;
    mapping(address => uint) private mintedPerAddress;

    constructor() ERC721A('RedPill', 'RedPill') {}

    function mintWhitelist(bytes32[] calldata _merkleProof) public {
        require(!paused, "sale not active");
        require(totalSupply() + 1 <= maxSupply, 'Max supply exceeded!');

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

        require(mintedPerAddress[_msgSender()] == 0, "max mints");
        mintedPerAddress[_msgSender()] += 1;
        _safeMint(_msgSender(), 1);
    }

    function eatPill(uint256 _pillTokenId, uint256 _charTokenId) public {
        require(!pausedBurn, "burn not active");
        require(_exists(_pillTokenId), 'Token does not exist');
        require(ownerOf(_pillTokenId) == _msgSender(), 'not pill owner');
        require(mainContract.getOwnerOfMain(_charTokenId) == _msgSender(), 'not main owner');
        _burn(_pillTokenId);
        mainContract.evolveFromPill(_charTokenId);
    }

    function setMainContract(address _contract) public onlyOwner {
        mainContract = IMainContract(_contract);
    }

    function setBaseMetadataUri(string memory a) public onlyOwner {
        baseMetadataUri = a;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPausedBurn(bool _state) public onlyOwner {
        pausedBurn = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseMetadataUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function teamMint(uint256 _teamAmount) external onlyOwner  {
        require(totalSupply() + _teamAmount <= maxSupply, 'Max supply exceeded!');
        _safeMint(_msgSender(), _teamAmount);
    }
}