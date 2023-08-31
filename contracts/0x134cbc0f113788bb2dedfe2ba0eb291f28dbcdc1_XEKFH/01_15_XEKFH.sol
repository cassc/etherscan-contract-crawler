// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PBTBase.sol";

contract XEKFH is PBTBase, Ownable {
    string private _baseTokenURI =
        "ar://Tr3mJfMC_VmvyN6uYBnkaa-Bq60a6vl2KWiulZFH0WA/";

    /// @notice Initialize a mapping from chipAddress to tokenId.
    /// @param chipAddresses The addresses derived from the public keys of the chips
    constructor(address[] memory chipAddresses, uint256[] memory tokenIds)
        PBTBase("XEKFH", "XEKFH")
    {
        _seedChipToTokenMapping(chipAddresses, tokenIds);
    }

    /// @param signatureFromChip The signature is an EIP-191 signature of (msgSender, blockhash),
    ///        where blockhash is the block hash for a recent block (blockNumberUsedInSig).
    /// @dev We will soon release a client-side library that helps with signature generation.
    function mintPBT(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) external {
        _mintTokenWithChip(signatureFromChip, blockNumberUsedInSig);
    }

    function mintAdmin(
        uint256 tokenId,
        address chip,
        address to
    ) external onlyOwner {
        _tokenDatas[chip] = TokenData(tokenId, chip, true);
        _mint(to, tokenId);
        emit PBTMint(tokenId, chip);
    }

    function updateChips(
        address[] calldata chipAddressesOld,
        address[] calldata chipAddressesNew
    ) external onlyOwner {
        _updateChips(chipAddressesOld, chipAddressesNew);
    }

    function seedChipToTokenMapping(
        address[] calldata chipAddresses,
        uint256[] calldata tokenIds,
        bool throwIfTokenAlreadyMinted
    ) external onlyOwner {
        _seedChipToTokenMapping(
            chipAddresses,
            tokenIds,
            throwIfTokenAlreadyMinted
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function setAuctionMode(uint256 tokenId, bool boolean) external onlyOwner {
        _setAuctionMode(tokenId, boolean);
    }
}