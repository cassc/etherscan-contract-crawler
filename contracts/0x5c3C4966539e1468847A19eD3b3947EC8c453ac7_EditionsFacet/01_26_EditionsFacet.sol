// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Pausable} from "../abstracts/Pausable.sol";
import {Edition} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {PriceConsumer} from "../libraries/PriceConsumer.sol";
import {CoinSwapper} from "../libraries/CoinSwapper.sol";
import {Shared} from "../libraries/Shared.sol";
import {ERC721ALib} from "../libraries/ERC721ALib.sol";

/**
 * Create editions for diamond ERC721A
 * @author https://github.com/lively
 */
contract EditionsFacet is Pausable {
    uint256 constant MAX_UINT256 = type(uint256).max;
    uint64 constant MAX_UINT64 = type(uint64).max;

    error AlreadyMinted();
    error EditionsEnabled();
    error URIRequired();
    error EditionSoldOut();
    error InsufficientValue();
    error InvalidEditionId();
    error InvalidValueSent();
    error ExceedsMaxSupply();
    error ExceedsMaxMintPerAddress();
    error ExceedsMaxMintPerTx();
    error InvalidAirdropCaller();

    modifier validEdition(uint256 _editionIndex) {
        if (_editionIndex >= s.editionsByIndex.length) {
            revert InvalidEditionId();
        }

        _;
    }

    function createEdition(
        string calldata _name,
        uint256 _maxSupply,
        uint256 _price
    ) public onlyOwner {
        Shared.createEdition(_name, _maxSupply, _price);
    }

    // Maybe don't want to allow editions to be disabled...
    function enableEditions() public onlyOwner {
        if (s.currentIndex != 0) revert AlreadyMinted();
        if (s.editionsEnabled) revert EditionsEnabled();

        // Set flag to true
        s.editionsEnabled = true;
        // Reset max supply, calculated based on editions
        s.maxSupply = 0;
    }

    // Mint for a specific edition
    function mint(
        address to,
        uint256 quantity,
        uint256 editionIndex
    ) public payable whenNotPaused validEdition(editionIndex) {
        if (s.airdrop) airdropCheck();
        if (!s.editionsEnabled) revert Shared.EditionsDisabled();

        // Need to use storage to increment at end
        Edition storage _edition = s.editionsByIndex[editionIndex];

        // Check if edition is unlimited or if it would exceed supply
        unchecked {
            if (
                _edition.maxSupply > 0 &&
                (_edition.totalSupply + quantity) > _edition.maxSupply
            ) {
                revert EditionSoldOut();
            }

            if (msg.value < (quantity * price(editionIndex)))
                revert InsufficientValue();
        }

        // Set token edition
        // Next token ID is s.currentIndex;
        s.tokenEdition[s.currentIndex] = editionIndex;

        // Mint the token
        _mintApproved(to, quantity);

        // Increment the edition supply
        _edition.totalSupply = _edition.totalSupply + quantity;
    }

    // Minting is allowed, do checks against set limits
    function _mintApproved(address to, uint256 quantity)
        internal
        whenNotPaused
    {
        emit Shared.PaymentReceived(_msgSender(), msg.value);

        // If conversion is automatically enabled then convert the ETH to USD
        if (s.automaticUSDConversion) {
            CoinSwapper.convertEthToUSDC();
        }

        ERC721ALib._mint(to, quantity);
    }

    // =============================================================
    //                    Check functions
    // =============================================================

    function airdropCheck() private view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        if (_msgSender() != ds.contractOwner) revert InvalidAirdropCaller();
    }

    // =============================================================
    //                        Getters
    // =============================================================
    function price(uint256 _editionIndex) public view returns (uint256) {
        Edition memory edition = s.editionsByIndex[_editionIndex];
        return
            s.isPriceUSD
                ? ERC721ALib.convertUSDtoWei(edition.price)
                : edition.price;
    }

    function maxSupply(uint256 _editionIndex)
        public
        view
        validEdition(_editionIndex)
        returns (uint256)
    {
        return s.editionsByIndex[_editionIndex].maxSupply;
    }

    function totalSupply(uint256 _editionIndex)
        public
        view
        validEdition(_editionIndex)
        returns (uint256)
    {
        return s.editionsByIndex[_editionIndex].totalSupply;
    }

    // =============================================================
    //                        Setters
    // =============================================================
    function setPrice(uint256 _price, uint256 _editionIndex)
        external
        onlyOwner
        validEdition(_editionIndex)
    {
        s.editionsByIndex[_editionIndex].price = _price;
    }

    function setMaxSupply(uint256 _maxSupply, uint256 _editionIndex)
        external
        onlyOwner
        validEdition(_editionIndex)
    {
        Edition storage _edition = s.editionsByIndex[_editionIndex];
        require(
            _edition.totalSupply <= _maxSupply,
            "Cannot set max supply lower than current supply"
        );
        _edition.maxSupply = _maxSupply;
    }

    function updateTotalSupply(uint256 _totalSuppy, uint256 _editionIndex)
        public
        onlyOwner
        validEdition(_editionIndex)
    {
        s.editionsByIndex[_editionIndex].totalSupply = _totalSuppy;
    }
}