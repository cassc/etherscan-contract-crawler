// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'erc721a/contracts/ERC721A.sol';

contract NekoGachaHalloween is ERC721A('Neko Gacha Halloween', 'NGH'), Ownable {
    enum Phase {
        BeforeMint,
        PublicMint
    }

    address public constant withdrawAddress = 0xBFdfc36183f1e020d6e7BA21347c2A2F253Fef81;
    uint256 public constant maxSupply = 555;
    uint256 public constant publicMaxPerTx = 2;
    string public constant baseExtension = '.json';

    IERC721A public immutable NGM;

    string public baseURI = 'ipfs://QmNjkV9XNHCJRTMx7ix91bjkjVZ3a62BRcpKghGFMx2BU8/';

    Phase public phase = Phase.BeforeMint;

    constructor(IERC721A _NGM) {
        NGM = _NGM;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // public mint
    function mint(uint256 _mintAmount) public {
        require(tx.origin == msg.sender, 'The caller is another contract.');
        require(phase == Phase.PublicMint, 'Public mint is not active.');
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(totalSupply() + _mintAmount <= maxSupply, 'Total supply cannot exceed maxSupply');
        require(_mintAmount <= publicMaxPerTx, 'Mint amount cannot exceed 2 per Tx.');
        require(NGM.balanceOf(_msgSender()) > 0, 'NGM is not enough.');

        _safeMint(msg.sender, _mintAmount);
    }

    function ownerMint(address to, uint256 count) public onlyOwner {
        _safeMint(to, count);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        phase = _newPhase;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }
}