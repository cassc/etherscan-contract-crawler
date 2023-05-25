/*

  ╗▄▄▄▄▄▄▄▄▄▄▄▄▄  ╓╥       _ _     ,▄      ,▄  ▄▄▄µ╓,,,,,╓╥▄▄▄  _ ▄─      ╓µ
  _█████████████⌐ ╫██µ _,▄▓███▌   ██▌     ███  ███████████████  ╫██⌐    ▐██▌
     ███     ▓██⌐ ╫██▌▓████▀╙__  _██▌    _███  ███_  ███__ ███  ╫██⌐    ╟██▌
 _,,,███,,,,,▓██⌐ ╫██████▄▄,     _██▌    _███  ███   ███   ███  ╫██⌐    ╟██▌
  ╙█████████████⌐ ╫██▌▀▀█████Q   _██▌    _███  ███   ███   ███  ╫██⌐    ╟██▌
   __███_    ▓██⌐ ╫██µ     ███▄  _██▌    _███  ███   ███   ███  ╫██⌐    ╟██▌
   ╓███▀     ▓██⌐ ╫██µ      ███  ╥███▄▄▄▄▄███_ ███   █▀▀   ███ .▓██▄▄▄▄▄▓██▌_
  ╙███─      ╙▀█⌐ ╫█▀       ╙██Γ ▓███████████╨ ╙██   _     ╙▀█_ ████████████

      █▀▄ █▀█ ▄▀█ █▀▀ █▀█ █▄░█ ▀█    █░█ █▄░█ █▀▀ █░█ ▄▀█ █ █▄░█ █▀▀ █▀▄
      █▄▀ █▀▄ █▀█ █▄█ █▄█ █░▀█ █▄    █▄█ █░▀█ █▄▄ █▀█ █▀█ █ █░▀█ ██▄ █▄▀

*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { ERC721Base } from "./ERC721Base.sol";
import { LoyalAkumuDragonz } from "./LoyalAkumuDragonz.sol";

/// @author frolic.eth
/// @title  Akumu Dragonz
/// @notice From the creators of Boryoku Dragonz. Akumu Dragonz can be minted
///         for free by burning their Solana Bloodmoon BOKU via the mint
///         website. Folks without Bloodmoon BOKU can mint for a fee during the
///         allowlist and public mint phases.
contract AkumuDragonz is ERC721Base, LoyalAkumuDragonz {

    enum MintPhase {
        OFF,
        MINT_PASS,
        ALLOWLIST,
        PUBLIC
    }

    struct MintPassBundle {
        uint256[] ids;
        address claimedBy;
    }

    uint256 public constant VAULT_SUPPLY = 200;
    uint256 public constant MINT_PASS_SUPPLY = 3300;

    MintPhase public currentMintPhase = MintPhase.OFF;
    address public mintSigner;
    uint256 public vaultMinted = 0;
    uint256 public mintPassMinted = 0;

    // mint pass ID => boolean
    BitMaps.BitMap internal usedMintPasses;

    event MintPhaseUpdated(MintPhase previousPhase, MintPhase newPhase);
    event MintSignerUpdated(address previousSigner, address newSigner);


    // ****************** //
    // *** INITIALIZE *** //
    // ****************** //

    constructor() ERC721Base("Akumu Dragonz", "AKUMU", 0.169 ether, 10_000) {
    }


    // ****************** //
    // *** CONDITIONS *** //
    // ****************** //

    error MintPhaseNotOpen(MintPhase expectedMintPhase);
    error InvalidMintPass();
    error MintPassAlreadyUsed(uint256 id);
    error MintSignerNotConfigured();
    error InvalidSignature();

    modifier requireMintPhase(MintPhase expectedMintPhase) {
        if (expectedMintPhase > currentMintPhase) {
            revert MintPhaseNotOpen(expectedMintPhase);
        }
        _;
    }

    modifier validateMintPass(MintPassBundle calldata mintPass, bytes memory signature) {
        if (mintPass.claimedBy != _msgSender()) {
            revert InvalidMintPass();
        }
        if (mintSigner == address(0)) {
            revert MintSignerNotConfigured();
        }
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encode(mintPass));
        if (!SignatureChecker.isValidSignatureNow(mintSigner, messageHash, signature)) {
            revert InvalidSignature();
        }
        uint256 length = mintPass.ids.length;
        for (uint256 i = 0; i < length;) {
            uint256 id = mintPass.ids[i];
            if (id < 1 || id > 5000) {
                revert InvalidMintPass();
            }
            if (BitMaps.get(usedMintPasses, id)) {
                revert MintPassAlreadyUsed(id);
            }
            BitMaps.set(usedMintPasses, id);
            unchecked { ++i; }
        }
        _;
    }

    modifier validateAllowlist(bytes memory signature) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encode(_msgSender()));
        if (!SignatureChecker.isValidSignatureNow(mintSigner, messageHash, signature)) {
            revert InvalidSignature();
        }
        _;
    }

    // Allow only one general sale mint (allowlist, public)
    modifier onlyOneGeneralSaleMint() {
        if (hasMintedInGeneralSale(_msgSender())) {
            revert MintLimitExceeded(1);
        }
        _;
        _setAux(_msgSender(), 1);
    }


    // ******************* //
    // *** BEFORE MINT *** //
    // ******************* //

    function isMintPassUsed(uint256 id) public view returns (bool) {
        return BitMaps.get(usedMintPasses, id);
    }

    function getUsedMintPasses(uint256[] memory ids) public view returns (bool[] memory results) {
        results = new bool[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            results[i] = BitMaps.get(usedMintPasses, ids[i]);
        }
        return results;
    }

    function hasMintedInGeneralSale(address minter) public view returns (bool) {
        return _getAux(minter) > 0;
    }

    function publicSupply() public view returns (uint256) {
        return MAX_SUPPLY - VAULT_SUPPLY - MINT_PASS_SUPPLY;
    }

    function publicMinted() public view returns (uint256) {
        return _totalMinted() - vaultMinted - mintPassMinted;
    }


    // ************ // 
    // *** MINT *** //
    // ************ //

    function vaultMint(uint256 numToBeMinted)
        external
        onlyOwner
        withinSupply(VAULT_SUPPLY, vaultMinted, numToBeMinted)
    {
        _mintMany(owner(), numToBeMinted);
        vaultMinted += numToBeMinted;
    }

    function passMint(MintPassBundle calldata mintPass, bytes memory signature)
        external
        requireMintPhase(MintPhase.MINT_PASS)
        withinSupply(MINT_PASS_SUPPLY, mintPassMinted, mintPass.ids.length)
        validateMintPass(mintPass, signature)
    {
        _mintMany(_msgSender(), mintPass.ids.length);
        mintPassMinted += mintPass.ids.length;
    }

    function allowlistMint(uint256 numToBeMinted, bytes memory signature)
        external
        payable
        requireMintPhase(MintPhase.ALLOWLIST)
        withinSupply(publicSupply(), publicMinted(), numToBeMinted)
        onlyOneGeneralSaleMint
        hasExactPayment(numToBeMinted)
        validateAllowlist(signature)
    {
        _mintMany(_msgSender(), numToBeMinted);
    }

    function publicMint(uint256 numToBeMinted)
        external
        payable
        requireMintPhase(MintPhase.PUBLIC)
        withinSupply(publicSupply(), publicMinted(), numToBeMinted)
        onlyOneGeneralSaleMint
        hasExactPayment(numToBeMinted)
    {
        _mintMany(_msgSender(), numToBeMinted);
    }


    // ****************** //
    // *** AFTER MINT *** //
    // ****************** //

    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal override(ERC721A, LoyalAkumuDragonz) {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }


    // ************* //
    // *** ADMIN *** //
    // ************* //

    function setMintSigner(address signer) external onlyOwner {
        emit MintSignerUpdated(mintSigner, signer);
        mintSigner = signer;
    }

    function setMintPhase(MintPhase phase) external onlyOwner {
        emit MintPhaseUpdated(currentMintPhase, phase);
        currentMintPhase = phase;
    }

    // Some time after the mint, allow minting out the rest of the tokens to
    // the vault. This mostly takes care of unused mint passes.
    function vaultRemainingSupply(uint256 numToBeMinted)
        external
        onlyOwner
    {
        _mintMany(owner(), numToBeMinted);
        vaultMinted += numToBeMinted;
    }
}