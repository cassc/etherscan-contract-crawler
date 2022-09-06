// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "./interfaces/IMMNFT.sol";
import "hardhat/console.sol";

contract EvolutionManager is Context, Ownable, IERC721Receiver {
    uint256 public monkeyEvoPrice = 0.05 ether;
    uint256 public gorillaEvoPrice = 0.1 ether;
    uint256 public alienEvoPrice = 0.2 ether;

    bool public isMonkeysLive;
    bool public isGorillasLive;
    bool public isAliensLive;

    // merkleRoots for proving the rarity C values of monkeys in each evolution
    bytes32[] public merkleRoots = new bytes32[](4);
    //Index is level monkeys = 0, gorillas = 1,
    IMMNFT[] public NFTs = new IMMNFT[](4);

    mapping(address => bool) public approvedAddresses;
    enum RarityGroup {
        COMMON,
        UNCOMMON,
        RARE,
        SUPERRARE,
        LEGENDARY
    }
    mapping(RarityGroup => uint256) mmCScores;

    function evolveMonkeys(
        uint256[] calldata tokenIds,
        uint256[] calldata cScores,
        bytes32[][] calldata proofs
    ) public payable {
        require(isMonkeysLive, "monkey evolution is not live yet");
        processEvolution(tokenIds, cScores, proofs, 0, 4);
    }

    function evolveGalacticGorillas(
        uint256[] calldata tokenIds,
        uint256[] calldata cScores,
        bytes32[][] calldata proofs
    ) public payable {
        require(isGorillasLive, "galactic gorillas evolution is not live yet");
        processEvolution(tokenIds, cScores, proofs, 1, 3);
    }

    function evolveAlienGorilas(
        uint256[] calldata tokenIds,
        uint256[] calldata cScores,
        bytes32[][] calldata proofs
    ) public payable {
        require(isAliensLive, "alien gorillas evolution is not live yet");
        processEvolution(tokenIds, cScores, proofs, 2, 2);
    }

    function processEvolution(
        uint256[] calldata tokenIds,
        uint256[] calldata cScores,
        bytes32[][] calldata proofs,
        uint8 evolution,
        uint8 numberRequired
    ) private {
        require(
            tokenIds.length == numberRequired,
            "missing required number of tokenIds"
        );
        require(
            cScores.length == numberRequired,
            "missing required number of cScores"
        );
        require(
            proofs.length == numberRequired,
            "missing required number of proofs"
        );

        uint256 totalRarity;
        for (uint256 i; i < numberRequired; i++) {
            require(
                isOwnedBySender(tokenIds[i], evolution, msg.sender),
                "monkey not owned by sender"
            );
            require(
                verifyRarity(evolution, tokenIds[i], cScores[i], proofs[i]),
                "rarity data submitted not correct"
            );
            totalRarity += cScores[i];
        }
        uint256 avgRarity = totalRarity / 4;
        RarityGroup rg = roundRarity(avgRarity, evolution);

        require(msg.value >= getPrice(evolution), "invalid price");

        for (uint256 i; i < 4 - evolution; i++) {
            NFTs[evolution].burn(tokenIds[i]);
        }

        NFTs[evolution + 1].mint(_msgSender(), uint256(rg));
    }

    function getPrice(uint256 evo) internal view returns (uint256) {
        if (evo == 0) return monkeyEvoPrice;
        if (evo == 1) return gorillaEvoPrice;
        if (evo == 2) return alienEvoPrice;
    }

    function roundRarity(uint256 rarity, uint256 evo)
        internal
        pure
        returns (RarityGroup rg)
    {
        if (evo == 0) return roundMooningMonkey(rarity);
        if (evo == 1) return roundGalacticGorillas(rarity);
        if (evo == 2) return roundAlienGorillas(rarity);
    }

    // Rounding works by checking whether it is within a range that would round to that value
    // then grouping by those ranges. Simple example: 0,1,2,3,4 rounds down. 5,6,7,8,9,10 rounds up.
    // You will notice in the example the round down group is 1 smaller than the round up group.
    // We are rounding to Contribution thresholds of RarityGroups rather than decimal base rounding.

    // 100, 105, 110, 115, 120 (5 gaps, 2.5 rounding limits, truncated)
    function roundMooningMonkey(uint256 rarity)
        internal
        pure
        returns (RarityGroup rg)
    {
        if (rarity >= 100 && rarity <= 102) return RarityGroup.COMMON;
        if (rarity > 102 && rarity <= 107) return RarityGroup.UNCOMMON;
        if (rarity > 107 && rarity <= 112) return RarityGroup.RARE;
        if (rarity > 112 && rarity <= 117) return RarityGroup.SUPERRARE;
        if (rarity > 117 && rarity <= 120) return RarityGroup.LEGENDARY;
    }

    // 720, 756, 792, 828, 864 (36 gaps, 18 rounding limits)
    function roundGalacticGorillas(uint256 rarity)
        internal
        pure
        returns (RarityGroup rg)
    {
        if (rarity >= 720 && rarity <= 737) return RarityGroup.COMMON;
        if (rarity > 737 && rarity <= 773) return RarityGroup.UNCOMMON;
        if (rarity > 773 && rarity <= 809) return RarityGroup.RARE;
        if (rarity > 809 && rarity <= 845) return RarityGroup.SUPERRARE;
        if (rarity > 845 && rarity <= 864) return RarityGroup.LEGENDARY;
    }

    // 3888, 4082, 4277, 4471, 4666 (194 gaps, 97 rounding limits)
    function roundAlienGorillas(uint256 rarity)
        internal
        pure
        returns (RarityGroup rg)
    {
        if (rarity >= 3888 && rarity <= 3984) return RarityGroup.COMMON;
        if (rarity > 3984 && rarity <= 4179) return RarityGroup.UNCOMMON;
        if (rarity > 4179 && rarity <= 4373) return RarityGroup.RARE;
        if (rarity > 4373 && rarity <= 4567) return RarityGroup.SUPERRARE;
        if (rarity > 4666 && rarity <= 4762) return RarityGroup.LEGENDARY;
    }

    ///////////////////

    function isOwnedBySender(
        uint256 tokenId,
        uint8 evolution,
        address sender
    ) public view returns (bool) {
        require(
            NFTs[evolution] != IMMNFT(address(0x0)),
            "NFT contract for this evolution not set"
        );
        IMMNFT NFT = NFTs[evolution];
        return NFT.ownerOf(tokenId) == sender;
    }

    /*
     *  Merkle Root functions
     */

    function verifyRarity(
        uint8 evolution,
        uint256 tokenId,
        uint256 c,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        return (
            verify(
                merkleRoots[evolution],
                keccak256(abi.encodePacked(tokenId, c)),
                proof
            )
        );
    }

    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setEvolutionContract(uint256 index, IMMNFT _nft)
        public
        adminOrOwner
    {
        NFTs[index] = _nft;
    }

    function setMerkleRoot(uint256 index, bytes32 root) public adminOrOwner {
        merkleRoots[index] = root;
    }

    function addApproved(address user) public adminOrOwner {
        approvedAddresses[user] = true;
    }

    function removeApproved(address user) public adminOrOwner {
        delete approvedAddresses[user];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setMonkeyEvoPrice(uint256 price) external adminOrOwner {
        monkeyEvoPrice = price;
    }

    function setGorillaEvoPrice(uint256 price) external adminOrOwner {
        gorillaEvoPrice = price;
    }

    function setAlienEvoPrice(uint256 price) external adminOrOwner {
        alienEvoPrice = price;
    }

    modifier adminOrOwner() {
        require(
            msg.sender == owner() || approvedAddresses[msg.sender],
            "Unauthorized"
        );
        _;
    }

    function toggleMonkeys() external adminOrOwner {
        isMonkeysLive = !isMonkeysLive;
    }

    function toggleGorillas() external adminOrOwner {
        isGorillasLive = !isGorillasLive;
    }

    function toggleAliens() external adminOrOwner {
        isAliensLive = !isAliensLive;
    }

    function withdraw() public adminOrOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }
}