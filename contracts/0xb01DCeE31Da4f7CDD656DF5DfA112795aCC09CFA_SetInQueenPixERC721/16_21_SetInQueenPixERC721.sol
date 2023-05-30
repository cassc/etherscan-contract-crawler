// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./abstract/SetInBaseERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SetInQueenPixERC721 is DefaultOperatorFilterer, SetInBaseERC721 {

    using Counters for Counters.Counter;
    
    struct WL {
        bytes32 root;
        bool enabled;
        uint40 start;
        uint40 end;
        uint24 limit;
    }

    mapping(uint8 => WL) public WLs;
    mapping(address => mapping(uint => uint)) public minted;

    uint16 public qpReserveSupply;
    uint16 public qpTotalSupply;

    Counters.Counter public reserveCounter;
    Counters.Counter public counter;

    string public metadataFolder;

    constructor(string memory _metadataFolder, uint16 _qTotalSupply, uint16 _qReserveSupply) SetInBaseERC721("SET IN QUEEN PIX", "SIQP", "ipfs://", msg.sender, 1000) {

        qpTotalSupply = _qTotalSupply;
        qpReserveSupply = _qReserveSupply;
        reserveCounter._value = 0;
        counter._value = qpReserveSupply;
        metadataFolder = _metadataFolder;
    }

    /**
     * Only manager access
     */
    function setMetadata(string calldata metadata) external onlyManager {

        metadataFolder = metadata;
    }

    function setWhitelist(uint8 id, WL calldata wl) external onlyManager {

        WLs[id] = wl;
    }

    function mintReserve(uint count, address to) external onlyManager {

        require(reserveCounter.current() + count <= qpReserveSupply, "SIQP: exceeded reserve supply");
        _mint(count, to, reserveCounter);
    }

    function airdrop(address[] memory receivers, uint[] memory counts) external onlyManager {

        require(receivers.length == counts.length, "SIQP: arrays should be of the same size");
        for (uint i = 0; i < receivers.length; i++) {
            address receiver = receivers[i];
            uint count = counts[i];
            _mint(count, receiver, reserveCounter);
        }
    }

    /**
     * Public access
     */
    function mint(uint8 wlId, uint count, bytes32[] calldata proof) external payable {
        
        WL memory wl = WLs[wlId];
        
        require(wl.enabled, "SIQP: WL is not enabled");
        require(block.timestamp >= wl.start, "SIQP: mint is not started");
        require(block.timestamp <= wl.end, "SIQP: mint ended");

        minted[msg.sender][wlId] += count;
        require(minted[msg.sender][wlId] <= wl.limit, "SIQP: exceeded WL limit");
        require(counter.current() + count <= qpTotalSupply, "SIQP: exceeded total supply");

        if (wl.root != 0) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proof, wl.root, leaf), "SIQP: invalid proof");
        }

        _mint(count, msg.sender, counter);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        return
            string(
                abi.encodePacked(baseURI, metadataFolder, "/", Strings.toString(tokenId), ".json")
            );
    }

    /**
     * Internal
     */
    function _mint(uint count, address to, Counters.Counter storage _counter) internal {

        for (uint256 i = 0; i < count; i++) {
            _counter.increment();
            uint256 tokenId = _counter.current();
            _mint(to, tokenId);
        }
    }

    /**
     * Opensea filter
     */

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}