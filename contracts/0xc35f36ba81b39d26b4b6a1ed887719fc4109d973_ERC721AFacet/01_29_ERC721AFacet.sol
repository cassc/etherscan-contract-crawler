// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.9;

import {Shared} from "../libraries/Shared.sol";
// import {RoyaltyFacet} from "./RoyaltyFacet.sol";
import {ERC721A} from "../abstracts/ERC721A.sol";
import {Pausable} from "../abstracts/Pausable.sol";
import {Modifiers} from "../libraries/Modifiers.sol";
import {AllowList} from "../libraries/AllowList.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {CoinSwapper} from "../libraries/CoinSwapper.sol";
import {PriceConsumer} from "../libraries/PriceConsumer.sol";

import "hardhat/console.sol";

// import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AFacet is ERC721A {
    // using PRBMathUD60x18 for uint256;
    uint256 constant MAX_UINT256 = type(uint256).max;
    uint64 constant MAX_UINT64 = type(uint64).max;

    // =============================================================
    //                           Mint functions
    // =============================================================
    function mint(address to) public payable whenNotPaused {
        mint(to, 1);
    }

    function mint(address to, uint256 quantity) public payable whenNotPaused {
        require(
            !s.allowListEnabled,
            "Allow list is enabled, supply merkleProof"
        );
        _mintApproved(to, quantity);
    }

    function mint(
        address to,
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) public payable whenNotPaused {
        require(
            s.allowListEnabled,
            "AllowList is not enabled. Use regular mint."
        );
        require(
            AllowList.checkValidity(merkleProof),
            "Merkle proof is invalid"
        );
        _mintApproved(to, quantity);
    }

    function _mintApproved(address to, uint256 quantity)
        internal
        whenNotPaused
    {
        quantityCheck(to, quantity);
        s.airdrop ? airdropCheck() : priceCheck(quantity);

        emit Shared.PaymentReceived(_msgSender(), msg.value);

        // If conversion is automatically enabled then convert the ETH to USD
        if (s.automaticUSDConversion) {
            CoinSwapper.convertEthToUSDC();
        }

        _mint(to, quantity);
    }

    // =============================================================
    //                    Check functions
    // =============================================================
    function quantityCheck(address to, uint256 quantity) private view {
        unchecked {
            require(
                (s.currentIndex + quantity) <= maxSupply(),
                "Purchase would exceed max supply of tokens"
            );
            require(
                _numberMinted(to) + quantity <= maxMintPerAddress(),
                "Exceeds max amount of mints per address"
            );
        }
        require(
            quantity <= maxMintPerTx(),
            "Exceeds max amount of mints per transaction"
        );
    }

    function airdropCheck() private view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bool isContractOwner = _msgSender() == ds.contractOwner;

        require(
            isContractOwner,
            "Contract is an airdrop and can only be minted from approved accounts"
        );
    }

    function priceCheck(uint256 quantity) private {
        require(
            msg.value >= (quantity * price()),
            "Ether value sent is not correct"
        );
    }

    // =============================================================
    //                        Getters
    // =============================================================
    function airdrop() public view returns (bool) {
        return s.airdrop;
    }

    function maxMintPerTx() public view returns (uint256) {
        return s.maxMintPerTx == 0 ? MAX_UINT256 : s.maxMintPerTx;
    }

    function maxMintPerAddress() public view returns (uint256) {
        return s.maxMintPerAddress == 0 ? MAX_UINT64 : s.maxMintPerAddress;
    }

    function maxSupply() public view returns (uint256) {
        return s.maxSupply == 0 ? MAX_UINT256 : s.maxSupply;
    }

    function price() public view returns (uint256) {
        return s.isPriceUSD ? convertUSDtoWei(s.price) : s.price;
    }

    // =============================================================
    //                        Setters
    // =============================================================
    function setName(string memory _name) public onlyOwner {
        s.name = _name;
    }

    function setSymbol(string memory _symbol) public onlyOwner {
        s.symbol = _symbol;
    }

    function setTokenURI(string memory tokenURI) public onlyOwner {
        s.baseTokenUri = tokenURI;
    }

    function setPrice(uint256 _price) public onlyOwner {
        s.price = _price;
    }

    function setAirdrop(bool _airdrop) public onlyOwner {
        s.airdrop = _airdrop;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        s.maxMintPerTx = _maxMintPerTx;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) public onlyOwner {
        s.maxMintPerAddress = _maxMintPerAddress;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        s.maxSupply = _maxSupply;
    }

    function setIsPriceUSD(bool _isPriceUSD) public onlyOwner {
        s.isPriceUSD = _isPriceUSD;
    }

    function setAutomaticUSDConversion(bool _automaticUSDConversion)
        public
        onlyOwner
    {
        s.automaticUSDConversion = _automaticUSDConversion;
    }

    // =============================================================
    //                        Other
    // =============================================================
    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId, false);

        // Call Royalty Burn

        /** Type safe and more explicity example */
        // RoyaltyFacet(address(this)).royaltyBurn(tokenId);

        /** @dev Gas efficient example, needs testing. If it doesn't work the simpler above way will. */
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 functionSelector = bytes4(keccak256("royaltyBurn(uint256)"));
        // get facet address of function
        address facet = address(bytes20(ds.facets[functionSelector]));

        bytes memory myFunctionCall = abi.encodeWithSelector(
            functionSelector,
            tokenId
        );
        (bool success, bytes memory result) = address(facet).delegatecall(
            myFunctionCall
        );

        require(success, "myFunction failed");
    }

    function convertUSDtoWei(uint256 _price) private view returns (uint256) {
        /** 1e18 is equivalent to one eth in wei. 1e6 needed to convert price return to correct decimals (8).  */
        uint256 ethPerUSD = 1e18 / (PriceConsumer.getLatestPrice() / 1e6);
        return ethPerUSD * _price;
    }
}