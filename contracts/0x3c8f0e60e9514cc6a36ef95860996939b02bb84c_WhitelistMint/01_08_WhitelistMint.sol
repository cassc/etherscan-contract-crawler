pragma solidity ^0.8.4;

import './FootballCollection.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract WhitelistMint is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter public round; // round index

    struct MintRound {
        uint256 mintPrice; // price for one nft
        bytes32 merkleRoot; // merkle root for whitelist
        uint256 totalSupply; // total supply for this round
        uint256 maxMintAmount; // max amount that user can mint on this round
        bool needWhitelist; // if whitelist is needed
        mapping(address => uint256) mintedByUser; // minted amount by user
    }

    FootballCollection private immutable footballCollection; // nft collection for minting
    mapping(uint256 => MintRound) public mintRound; // config for minting

    constructor(FootballCollection _footballCollection) {
        footballCollection = _footballCollection;
    }

    // add config for new round
    function createNewRound(uint256 mintPrice, bytes32 merkleRoot, uint256 totalSupply, uint256 maxMintAmount, bool needWhitelist) external onlyOwner {
        round.increment();
        mintRound[round.current()].mintPrice = mintPrice;
        mintRound[round.current()].merkleRoot = merkleRoot;
        mintRound[round.current()].totalSupply = totalSupply;
        mintRound[round.current()].maxMintAmount = maxMintAmount;
        mintRound[round.current()].needWhitelist = needWhitelist;
    }

    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable {
        if (mintRound[round.current()].needWhitelist) {
            checkWhitelist(_merkleProof);
        }
        require(mintRound[round.current()].totalSupply - amount >= 0, "Total supply is run out");
        require(mintRound[round.current()].mintedByUser[msg.sender] + amount <= mintRound[round.current()].maxMintAmount, 'You cant mint this amount');
        require(msg.value == amount * mintRound[round.current()].mintPrice, 'invalid value');
        footballCollection.mint(msg.sender, amount);
        mintRound[round.current()].totalSupply -= amount;
        mintRound[round.current()].mintedByUser[msg.sender] += amount;
    }

    function checkWhitelist(bytes32[] calldata _merkleProof) private {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, mintRound[round.current()].merkleRoot, leaf), 'you are not whitelisted');
    }

    function getMintPrice() public view returns(uint256) {
        return mintRound[round.current()].mintPrice;
    }

    function getMaxMintAmount() public view returns(uint256) {
        return mintRound[round.current()].maxMintAmount;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}