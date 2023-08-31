// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Factions is ERC721A, Ownable {
    string private _baseTokenURI;

    mapping(uint256 => bool) private _processedBatchesForAirdrop;

    uint256 public constant BATCH_SIZE = 6;

    constructor() ERC721A("WRABFactions", "Factions") {}

    /**
     * @dev Airdrops tokens to `receivers` in quantities of `quantities`, matching
     * address to quantity by index. We also support a `batchId` to help manage aidrops
     * in batches, and validate which batches have already been processed.
     *
     * Requirements:
     *
     * - The `receivers` and `quantities` arrays must match in length
     * - The current `batchId` should not have been processed already
     */
    function airdrop(
        address[] calldata receivers,
        uint256[] calldata quantities,
        uint256 batchId
    ) external onlyOwner {
        require(
            receivers.length == quantities.length,
            "Mismatch of receivers/quantities"
        );

        require(
            !_processedBatchesForAirdrop[batchId] &&
                balanceOf(receivers[0]) == 0,
            "Batch already airdropped"
        );

        for (uint256 i; i < receivers.length; i++) {
            _mintWrapper(receivers[i], quantities[i]);
        }

        _processedBatchesForAirdrop[batchId] = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function devMint(address to, uint256 quantity) external onlyOwner {
        _mintWrapper(to, quantity);
    }

    /**
     * @dev Mints `quantity` tokens in batches of `BATCH_SIZE` to the specified address
     */
    function _mintWrapper(address to, uint256 quantity) internal {
        for (uint256 i; i < quantity / BATCH_SIZE; i++) {
            _mint(to, BATCH_SIZE);
        }
        // Mint leftover quantity
        if (quantity % BATCH_SIZE > 0) {
            _mint(to, quantity % BATCH_SIZE);
        }
    }
}