// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "closedsea/src/OperatorFilterer.sol";

error ChunkAlreadyProcessed();
error MismatchedArrays();
error NotOwnerOrAllowlistedContract();

contract ProofOfPurchase is
    ERC2981,
    ERC1155Burnable,
    Ownable,
    OperatorFilterer
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Keys are tokenIds, values are the set of chunks processed for that tokenId.
    // Intent is to help prevent double processing of chunks.
    mapping(uint256 => EnumerableSet.UintSet)
        private _processedChunksForAirdropForToken;

    EnumerableSet.AddressSet private allowlistedContractsForMint;

    string private _name = "Proof of Purchase";
    string private _symbol = "POP";

    bool public operatorFilteringEnabled = true;

    constructor() ERC1155("") {
        _registerForOperatorFiltering(address(0), false);
    }

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

    modifier onlyOwnerOrAllowlistedMinterContract() {
        address msgSender = _msgSender();
        if (
            owner() != msgSender &&
            !allowlistedContractsForMint.contains(msgSender)
        ) {
            revert NotOwnerOrAllowlistedContract();
        }
        _;
    }

    // Thin wrapper around privilegedMint which does chunkNum checks to reduce chance of double processing chunks in a manual airdrop.
    function airdrop(
        address[] calldata receivers,
        uint256[] calldata amounts,
        uint256 tokenId,
        uint256 chunkNum
    ) external onlyOwnerOrAllowlistedMinterContract {
        if (_processedChunksForAirdropForToken[tokenId].contains(chunkNum))
            revert ChunkAlreadyProcessed();
        privilegedMint(receivers, amounts, tokenId);
        _processedChunksForAirdropForToken[tokenId].add(chunkNum);
    }

    function privilegedMint(
        address[] calldata receivers,
        uint256[] calldata amounts,
        uint256 tokenId
    ) public onlyOwnerOrAllowlistedMinterContract {
        if (receivers.length != amounts.length || receivers.length == 0)
            revert MismatchedArrays();
        for (uint256 i; i < receivers.length; ) {
            _mint(receivers[i], tokenId, amounts[i], "");
            unchecked {
                ++i;
            }
        }
    }

    function setTokenUri(string calldata newUri) external onlyOwner {
        _setURI(newUri);
    }

    // Managing allowlisted contracts for mint
    // ---------------------------------------
    function addAllowlistedContractForMint(address contractAddress)
        external
        onlyOwner
    {
        allowlistedContractsForMint.add(contractAddress);
    }

    function removeAllowlistedContractForMint(address contractAddress)
        external
        onlyOwner
    {
        allowlistedContractsForMint.remove(contractAddress);
    }

    // EIP-2981
    // --------
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // OperatorFilterer
    // ----------------
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // EIP-165
    // -------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}