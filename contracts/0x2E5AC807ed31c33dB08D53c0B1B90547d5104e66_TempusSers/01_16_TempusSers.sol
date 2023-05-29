// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./Shuffle.sol";

contract TempusSers is ERC721Enumerable, Ownable {
    /// Opensea specific event to mark metadata as frozen
    event PermanentURI(string _value, uint256 indexed _id);

    /// Total supply of sers.
    uint256 public constant MAX_SUPPLY = 3333;

    /// The next batch which is yet to be issued.
    uint256 public nextBatch;

    /// The supply in each batch.
    mapping(uint256 => uint256) public batchSupply;

    /// The starting token ID for this batch.
    mapping(uint256 => uint256) public batchOffset;

    /// The base URI for the collection.
    mapping(uint256 => string) public baseTokenURIs;

    /// The merkle root of the claim list.
    mapping(uint256 => bytes32) public claimlistRoots;

    /// The seed used for the shuffling.
    mapping(uint256 => uint32) public shuffleSeeds;

    /// The map of tickets (per batch) which have been claimed already.
    mapping(uint256 => mapping(uint256 => bool)) public claimedTickets;

    /// The original minter of a given token.
    mapping(uint256 => address) public originalMinter;

    constructor() ERC721("Tempus Sers", "SERS") {}

    function totalAvailableSupply() private view returns (uint256 ret) {
        return (nextBatch == 0) ? 0 : (batchOffset[nextBatch - 1] + batchSupply[nextBatch - 1]);
    }

    function addBatch(
        uint256 batch,
        string calldata baseTokenURI,
        uint256 supply,
        bytes32 claimlistRoot,
        bytes32[] calldata proof
    ) external onlyOwner {
        require(nextBatch == batch, "TempusSers: Invalid batch");
        require(supply > 0, "TempusSers: Batch supply must be greater than 0");
        require((totalAvailableSupply() + supply) <= MAX_SUPPLY, "TempusSers: Supply will exceed maximum");

        bytes32 leaf = keccak256(abi.encode(batch, address(0), keccak256(abi.encode(supply, baseTokenURI))));
        require(MerkleProof.verify(proof, claimlistRoot, leaf), "TempusSers: Invalid proof");

        baseTokenURIs[batch] = sanitizeBaseURI(baseTokenURI);
        claimlistRoots[batch] = claimlistRoot;
        batchSupply[batch] = supply;
        batchOffset[batch] = totalAvailableSupply();

        nextBatch++;
    }

    function setSeed(uint256 batch) external onlyOwner {
        require(shuffleSeeds[batch] == 0, "TempusSers: Seed already set");
        require(batchSupply[batch] > 0, "TempusSers: Batch not initialized");

        // TODO: set it with proper source of randomness
        shuffleSeeds[batch] = uint32(uint256(blockhash(block.number - 1)));
    }

    function proveTicket(
        uint256 batch,
        address recipient,
        uint256 ticketId,
        bytes32[] calldata proof
    ) external {
        require(batch < nextBatch, "TempusSers: Invalid batch");
        require(shuffleSeeds[batch] != 0, "TempusSers: Seed not sed yet");

        // This is a short-cut for avoiding double claiming tickets.
        require(!claimedTickets[batch][ticketId], "TempusSers: Ticket already claimed");
        require(ticketId > 0 && ticketId <= MAX_SUPPLY, "TempusSers: Invalid ticket id");

        require(recipient != address(0), "TempusSers: Invalid recipient");

        bytes32 leaf = keccak256(abi.encode(batch, recipient, ticketId));
        require(MerkleProof.verify(proof, claimlistRoots[batch], leaf), "TempusSers: Invalid proof");

        // Claim ticket.
        claimedTickets[batch][ticketId] = true;

        _mintToUser(recipient, ticketToTokenId(batch, ticketId));
    }

    function _mintToUser(address recipient, uint256 tokenId) private {
        assert(totalSupply() < MAX_SUPPLY);

        // Mark who was the original owner
        originalMinter[tokenId] = recipient;

        _safeMint(recipient, tokenId);

        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 batch = tokenIdToBatch(tokenId);

        // ipfs://Qmd6FJksU1TaRkVhTiDZLqG4yi4Hg5NCXFD6QiF9zEgZSs/1.json
        return string(bytes.concat(bytes(baseTokenURIs[batch]), bytes(Strings.toString(tokenId)), bytes(".json")));
    }

    function ticketToTokenId(uint256 batch, uint256 ticketId) public view returns (uint256) {
        require(shuffleSeeds[batch] != 0, "TempusSers: Seed not set yet");
        uint256 rawTokenId = uint256(
            Shuffle.permute(SafeCast.toUint32(ticketId - 1), uint32(batchSupply[batch]), shuffleSeeds[batch])
        );
        return batchOffset[batch] + rawTokenId;
    }

    function tokenIdToBatch(uint256 tokenId) private view returns (uint256) {
        for (uint256 batch = 0; batch < nextBatch; batch++) {
            uint256 offset = batchOffset[batch];
            uint256 supply = batchSupply[batch];

            if ((offset <= tokenId) && (tokenId <= (offset + supply))) {
                return batch;
            }
        }
        // Should not be reached.
        assert(false);
        return 0;
    }

    /// Sanitize the input URI so that it always end with a forward slash.
    ///
    /// Note that we assume the URI is ASCII, and we ignore the case of empty URI.
    function sanitizeBaseURI(string memory uri) private pure returns (string memory) {
        bytes memory tmp = bytes(uri);
        require(tmp.length != 0, "TempusSers: URI cannot be empty");
        if (tmp[tmp.length - 1] != "/") {
            return string(bytes.concat(tmp, "/"));
        }
        return uri;
    }
}