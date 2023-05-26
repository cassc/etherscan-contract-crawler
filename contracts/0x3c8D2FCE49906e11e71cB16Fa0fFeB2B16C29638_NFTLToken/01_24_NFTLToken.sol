// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title NFTL Token (The native ecosystem token of Nifty League)
 * @dev Extends standard ERC20 contract from OpenZeppelin
 */
contract NFTLToken is ERC20PresetMinterPauser("Nifty League", "NFTL") {
    /// @notice NFTL tokens calaimable per day for each DEGEN NFT holder
    uint256 public constant EMISSION_PER_DAY = 68.49315e18; // ~68.5 NFTL

    /// @notice Start timestamp from contract deployment
    uint256 public immutable emissionStart;

    /// @notice End date for NFTL emissions to DEGEN NFT holders
    uint256 public immutable emissionEnd;

    /// @dev A record of last claimed timestamp for DEGEN NFTs
    mapping(uint256 => uint256) private _lastClaim;

    /// @dev Contract address for DEGEN NFT
    address private _nftAddress;

    /**
     * @notice Construct the NFTL token
     * @param emissionStartTimestamp Timestamp of deployment
     */
    constructor(uint256 emissionStartTimestamp) {
        emissionStart = emissionStartTimestamp;
        emissionEnd = emissionStartTimestamp + (1 days * 365 * 3);
    }

    // External functions

    /**
     * @notice Sets the contract address to Nifty League DEGEN NFTs upon deployment
     * @param nftAddress Address of verified DEGEN NFT contract
     * @dev Only callable once
     */
    function setNFTAddress(address nftAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_nftAddress == address(0), "Already set");
        _nftAddress = nftAddress;
    }

    // Public functions

    /**
     * @notice Check last claim timestamp of accumulated NFTL for given DEGEN NFT
     * @param tokenIndex Index of DEGEN NFT to check
     * @return Last claim timestamp
     */
    function getLastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(tokenIndex <= ERC721Enumerable(_nftAddress).totalSupply(), "NFT at index not been minted");
        require(ERC721Enumerable(_nftAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : emissionStart;
        return lastClaimed;
    }

    /**
     * @notice Check accumulated NFTL tokens for a DEGEN NFT
     * @param tokenIndex Index of DEGEN NFT to check balance
     * @return Total NFTL accumulated and ready to claim
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");

        uint256 lastClaimed = getLastClaim(tokenIndex);
        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd) return 0;

        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd; // Getting the min value of both
        uint256 totalAccumulated = ((accumulationPeriod - lastClaimed) * EMISSION_PER_DAY) / 1 days;

        // If claim hasn't been done before for the index, add initial allotment
        if (lastClaimed == emissionStart) {
            if (tokenIndex > 9500 && tokenIndex < 9901)
                totalAccumulated = totalAccumulated + 21500e18; // 21500 NFTL
            else if (tokenIndex > 8500)
                totalAccumulated = totalAccumulated + 15000e18; // 15000 NFTL
            else if (tokenIndex > 6500)
                totalAccumulated = totalAccumulated + 10000e18; // 10000 NFTL
            else if (tokenIndex > 4500)
                totalAccumulated = totalAccumulated + 8000e18; // 8000 NFTL
            else if (tokenIndex > 2500)
                totalAccumulated = totalAccumulated + 6000e18; // 6000 NFTL
            else if (tokenIndex > 1000)
                totalAccumulated = totalAccumulated + 4000e18; // 4000 NFTL
            else totalAccumulated = totalAccumulated + 2000e18; // 2000 NFTL
        }
        return totalAccumulated;
    }

    /**
     * @notice Check total accumulated NFTL tokens for all DEGEN NFTs
     * @param tokenIndices Indexes of NFTs to check balance
     * @return Total NFTL accumulated and ready to claim
     */
    function accumulatedMultiCheck(uint256[] memory tokenIndices) public view returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");
        uint256 totalClaimableQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            uint256 tokenIndex = tokenIndices[i];
            // Sanity check for non-minted index
            require(tokenIndex <= ERC721Enumerable(_nftAddress).totalSupply(), "NFT at index not been minted");
            uint256 claimableQty = accumulated(tokenIndex);
            totalClaimableQty = totalClaimableQty + claimableQty;
        }
        return totalClaimableQty;
    }

    /**
     * @notice Mint and claim available NFTL for each DEGEN NFT
     * @param tokenIndices Indexes of NFTs to claim for
     * @return Total NFTL claimed
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] <= ERC721Enumerable(_nftAddress).totalSupply(), "NFT at index not been minted");
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
            }

            uint256 tokenIndex = tokenIndices[i];
            require(ERC721Enumerable(_nftAddress).ownerOf(tokenIndex) == _msgSender(), "Sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty + claimQty;
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "No accumulated NFTL");
        _mint(_msgSender(), totalClaimQty);
        return totalClaimQty;
    }
}