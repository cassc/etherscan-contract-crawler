//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract FramergenceCore is ERC721Enumerable, Pausable {
    using SafeMath for uint256;
    uint256 internal lastTokenId = 0;
    uint256 public totalMints = 0;
    uint256[] public burnt;
    address public creator;

    event BurnAndMint(address indexed from, uint256[] tokenIds);

    modifier onlyCreator() {
        require(_msgSender() == creator, "Only the creator can unpause!");
        _;
    }

    constructor(address creatorAddress) ERC721("Framergence", "FRAM")  {
        creator = creatorAddress;
    }
    
    function generateRandomHash() internal view returns (bytes32) {
        return keccak256(abi.encode(blockhash(block.number-1), block.coinbase, lastTokenId));
    }

    function _generateNewTokenId() internal view returns (uint256) {
        bytes32 hashRandom = generateRandomHash();
        uint8 i = 28;
        uint256 value = uint8(hashRandom[i]);
        for (i = 29; i < 30; i++) {
            value = value << 8;
            value = value + uint8(hashRandom[i]);
        }
        value = value << 16;
        value = value.add(totalMints);
        return uint256(value);
    }
    
    function mintGenesis(address receiver) public whenNotPaused {
        require(totalMints < 1000, "Total mint limit is 1000");
        require(balanceOf(receiver) < 10 || creator == _msgSender(), "Only accounts with less than 10 Framergences can genesis mint");
        totalMints = totalMints + 1;
        _mintNew(receiver);
    }
    
    function _mintNew(address receiver) internal {
        uint256 tokenId = _generateNewTokenId();
        lastTokenId = tokenId;
        _safeMint(receiver, tokenId);
    }

    function burnAndMint(uint256[] memory tokenIds) public  {
        require(tokenIds.length > 0, "Burn at least 1 piece");
        require(tokenIds.length < 10, "Total burn limit is 10");
        for (uint8 i = 0; i < tokenIds.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "Only the owner can burn pieces");
        }

        _burn(tokenIds[0]);
        burnt.push(tokenIds[0]);

        for (uint8 i = 1; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
            burnt.push(tokenIds[0]);
            _mintNew(_msgSender());
        }

        emit BurnAndMint(_msgSender(), tokenIds);
        
    }
    
    function pause() public onlyCreator {
        _pause();
    }

    function unpause() public onlyCreator{
        _unpause();
    }

    function changeCreator(address newCreator) public onlyCreator {
        creator = newCreator;
    }
    
}