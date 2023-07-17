// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

error ChunkAlreadyProcessed();
error MismatchedArrays();
error NotAllowed();

contract PA is ERC1155Burnable, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    // The set of chunks processed for the airdrop.
    // Intent is to help prevent double processing of chunks.
    EnumerableSet.UintSet private _processedChunksForAirdrop;

    string private _name = "PA";
    string private _symbol = "PA";

    constructor() ERC1155("") {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setNameAndSymbol(
        string calldata _newName,
        string calldata _newSymbol
    ) external onlyOwner {
        _name = _newName;
        _symbol = _newSymbol;
    }

    // Thin wrapper around privilegedMint which does chunkNum checks to reduce chance of double processing chunks in a manual airdrop.
    function airdrop(
        address[] calldata receivers,
        uint256[] calldata amounts,
        uint256 chunkNum
    ) external onlyOwner {
        if (_processedChunksForAirdrop.contains(chunkNum))
            revert ChunkAlreadyProcessed();
        privilegedMint(receivers, amounts);
        _processedChunksForAirdrop.add(chunkNum);
    }

    function privilegedMint(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) public onlyOwner {
        if (receivers.length != amounts.length || receivers.length == 0)
            revert MismatchedArrays();
        for (uint256 i; i < receivers.length; ) {
            _mint(receivers[i], 0, amounts[i], "");
            unchecked {
                ++i;
            }
        }
    }

    function setTokenUri(string calldata newUri) external onlyOwner {
        _setURI(newUri);
    }

    function setApprovalForAll(address, bool) public pure override {
        revert NotAllowed();
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert NotAllowed();
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert NotAllowed();
    }
}