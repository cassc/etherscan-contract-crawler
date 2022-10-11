// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "https://github.com/chiru-labs/ERC721A/blob/v3.3.0/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhiteRabbitSteak is ERC721A, Ownable {
    string private _baseTokenURI;

    mapping(uint256 => bool) private _processedBatchesForAirdrop;

    uint256 public immutable maxSupply;
    uint256 public constant BATCH_SIZE = 6;

    constructor(uint256 maxSupply_) ERC721A("WhiteRabbitSteak", "WRSTK") {
        maxSupply = maxSupply_;
    }

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

    // Used to mint directly to a single address (also useful for testing)
    function devMint(address to, uint256 quantity) external onlyOwner {
        _mintWrapper(to, quantity);
    }

    /**
     * @dev Mints `quantity` tokens in batches of `BATCH_SIZE` to the specified address
     *
     * Requirements:
     *
     * - The quantity does not exceed the max supply
     */
    function _mintWrapper(address to, uint256 quantity) internal {
        require(
            totalSupply() + quantity <= maxSupply,
            "Quantity exceeds max supply"
        );

        for (uint256 i; i < quantity / BATCH_SIZE; i++) {
            _mint(to, BATCH_SIZE);
        }
        // Mint leftover quantity
        if (quantity % BATCH_SIZE > 0) {
            _mint(to, quantity % BATCH_SIZE);
        }
    }

    /**
     * @dev Sets the base URI for the metadata.
     */
    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    string private _nameOverride;
    string private _symbolOverride;

    function name() public view override returns (string memory) {
        if (bytes(_nameOverride).length == 0) {
            return ERC721A.name();
        }
        return _nameOverride;
    }

    function symbol() public view override returns (string memory) {
        if (bytes(_symbolOverride).length == 0) {
            return ERC721A.symbol();
        }
        return _symbolOverride;
    }

    function setNameAndSymbol(
        string calldata _newName,
        string calldata _newSymbol
    ) external onlyOwner {
        _nameOverride = _newName;
        _symbolOverride = _newSymbol;
    }
}