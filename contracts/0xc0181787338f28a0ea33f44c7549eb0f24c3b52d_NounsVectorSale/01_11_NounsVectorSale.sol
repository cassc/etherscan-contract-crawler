// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";

import "./NounsVector.sol";

contract NounsVectorSale is Owned {
    // Token contract.
    NounsVector public nounsVector;

    // Sale state.
    bool public salePaused = true;

    // Max number of each artwork.
    uint256 public constant MAX_ARTWORK_SUPPLY = 150;

    // Number of free mints available.
    uint256 public constant MAX_FREE_MINTS = 25;

    // Number of artworks.
    uint256 public constant NUM_ARTWORKS = 8;

    // Price per mint.
    uint256 public constant MINT_PRICE = 0.15 ether;

    // Number of tokens minted for free per artwork.
    // Represented as 40 bits, 5 per artwork. Right most bits are for artwork 0.
    uint256 private freeMintCount;

    // Record of addresses that have minted a free token.
    // Represented as 8 bits, 1 per artwork. Right most bits are for artwork 0.
    mapping(address => uint256) private freeMinters;

    constructor(NounsVector _nounsVector) Owned(msg.sender) {
        nounsVector = _nounsVector;
    }

    // ADMIN //

    /**
     * @notice Set sale paused or not.
     * @param _salePaused The new sale pause status.
     */
    function setSalePaused(bool _salePaused) external onlyOwner {
        salePaused = _salePaused;
    }

    /**
     * @notice Withdraw Ether from the contract.
     * @param _recipient The receive of the funds.
     */
    function withdraw(address _recipient) external onlyOwner {
        (bool sent, ) = payable(_recipient).call{
            value: address(this).balance
        }("");
        require(sent, "FAILED TO SEND ETH");
    }

    // EXTERNAL //

    /**
     * @notice Mint a paid token of an artwork.
     * @param _artwork The artwork to mint.
     */
    function mint(uint256 _artwork) external payable {
        require(msg.value >= MINT_PRICE, "NOT ENOUGH ETH");

        _mint(_artwork);
    }

    /**
     * @notice Mint a free token of an artwork.
     * @dev We do bit manipulation on the free mint count. To increment the count,
     *      we grab the bits at the slot for the artwork. Then we zero out the slot
     *      using an AND. Then we replace the bits at the slot with an incremented
     *      value using an OR.
     * @param _artwork The artwork to mint.
     */
    function mintFree(uint256 _artwork) external {
        uint256 bits = freeMintCount; // cache value
        uint256 numFreeMinted = _getNumFreeMintedFromBits(bits, _artwork);
        require(numFreeMinted < MAX_FREE_MINTS, "MAX FREE MINT REACHED");
        uint256 newNumFreeMintedMask = (numFreeMinted + 1) * (2 ** (_artwork * 5));

        // increment count for artwork
        freeMintCount = (bits & _getEmptyMaskForArtwork(_artwork)) | newNumFreeMintedMask;

        uint256 mintStatus = freeMinters[msg.sender]; // cache value
        uint256 mask = 2 ** _artwork;
        require(mintStatus & mask == 0, "ALREADY FREE MINTED");

        // record free mint for caller
        freeMinters[msg.sender] = mintStatus ^ mask;

        _mint(_artwork);
    }

    /**
     * @notice Return the number of tokens minted for free for an artwork.
     * @param _artwork The artwork to check.
     * @return Number of free tokens that have been minted for an artwork.
     */
    function getNumFreeMinted(uint256 _artwork) public view returns (uint256) {
        return _getNumFreeMintedFromBits(freeMintCount, _artwork);
    }

    /**
     * @notice Return whether an account has minted a specific artwork for free.
     * @param _account Account to check.
     * @param _artwork The artwork to check.
     * @return Boolean representing if an account minted a free token or not.
     */
    function hasMintedFree(
        address _account,
        uint256 _artwork
    ) public view returns (bool) {
        return freeMinters[_account] & (2 ** _artwork) > 0;
    }

    // INTERNAL //

    /**
     * Calls the mint function of the token contract.
     *
     * @param _artwork Artwork of token to mint.
     */
    function _mint(uint256 _artwork) internal {
        require(!salePaused, "SALE PAUSED");
        require(_artwork < NUM_ARTWORKS, "INVALID ARTWORK");
        require(nounsVector.artworkSupply(_artwork) < MAX_ARTWORK_SUPPLY, "SOLD OUT");

        nounsVector.mint(msg.sender, _artwork);
    }

    /**
     * @notice Extracts from bits the number of free minted tokens for an artwork.
     * @dev Uses the bit representation of free mint counts.
     * @param _bits Bits representing the count of free mints.
     * @param _artwork The artwork to check.
     * @return Number of free tokens that have been minted for an artwork.
     */
    function _getNumFreeMintedFromBits(
        uint256 _bits,
        uint256 _artwork
    ) internal pure returns (uint256) {
        uint256 mask = (2 ** 5 - 1) * (2 ** (_artwork * 5));
        return (_bits & mask) / (2 ** (_artwork * 5));
    }

    /**
     * @notice Return the bit mask to zero out the bits allotted for an artwork's free mint count.
     * @dev    0 0b11111_11111_11111_11111_11111_11111_11111_00000
     *         1 0b11111_11111_11111_11111_11111_11111_00000_11111
     *         2 0b11111_11111_11111_11111_11111_00000_11111_11111
     *         3 0b11111_11111_11111_11111_00000_11111_11111_11111
     *         4 0b11111_11111_11111_00000_11111_11111_11111_11111
     *         5 0b11111_11111_00000_11111_11111_11111_11111_11111
     *         6 0b11111_00000_11111_11111_11111_11111_11111_11111
     *         7 0b00000_11111_11111_11111_11111_11111_11111_11111
     * @return Number representing bit mask.
     */
    function _getEmptyMaskForArtwork(uint256 _artwork) internal pure returns (uint256) {
        if (_artwork == 0) {
            return 1099511627744;
        } else if (_artwork == 1) {
            return 1099511626783;
        } else if (_artwork == 2) {
            return 1099511596031;
        } else if (_artwork == 3) {
            return 1099510611967;
        } else if (_artwork == 4) {
            return 1099479121919;
        } else if (_artwork == 5) {
            return 1098471440383;
        } else if (_artwork == 6) {
            return 1066225631231;
        } else {
            return 34359738367;
        }
    }

    // FALLBACKS //

    fallback() external payable {}

    receive() external payable {}
}