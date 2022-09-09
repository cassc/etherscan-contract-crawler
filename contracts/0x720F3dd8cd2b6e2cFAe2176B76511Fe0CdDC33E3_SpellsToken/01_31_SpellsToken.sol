// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import { ERC165Storage } from "@solidstate/contracts/introspection/ERC165Storage.sol";

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { ISpellsCoin } from "../../coin/ISpellsCoin.sol";
import { ECDSA } from "../../helpers/ECDSA.sol";
import { SpellsCastStorage } from "./SpellsCastStorage.sol";
import { SpellsStorage } from "./SpellsStorage.sol";
import { ERC721Checkpointable } from "./ERC721Checkpointable/ERC721Checkpointable.sol";
import {ERC721AQueryableUpgradeable} from "./ERC721A/extensions/ERC721AQueryableUpgradeable.sol";
import { CallProtection } from "./shared/Access/CallProtection.sol";
import { LinearVRGDA } from "./VRGDA/LinearVRGDA.sol";
import { toDaysWadUnsafe } from  "./VRGDA/math/SignedWadMath.sol";
import { ReentryProtection } from "./shared/reentry/ReentryProtection.sol";
import { ERC721Checkpointable } from "./ERC721Checkpointable/ERC721Checkpointable.sol";

contract SpellsToken is ERC721AQueryableUpgradeable, ReentryProtection, CallProtection, LinearVRGDA {
    using ERC165Storage for ERC165Storage.Layout;
    using SpellsCastStorage for SpellsCastStorage.Storage;
    using SpellsStorage for SpellsStorage.Storage;
    
    /// MINTING
    error MintClosed();
    error EternalMintNotOpen();
    error MintMaxReached();
    error MintInsufficientPayment(uint256 price);
    error MintQuantityExceedsLimit();
    error MintQuantityExceedsAllowance();
    error ZeroAmount();
    error ConjureMaxReached();
    error MintNotAuthorized();
    
    // PAYMENTS
    error PaymentTransferFailed();
    
    // ADMIN
    error SenderNotSpellGate();
    
    uint256 privateStartTime;
    uint256 publicStartTime;
    
    function initializeSpellsTokenFacet(
        string memory name_,
        string memory symbol_,
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _perTimeUnit,
        uint256 _seedPrice,
        uint256 _seedSupply,
        address _spellGate,
        address _godspell
    ) external initializerERC721A protectedCall {
        __ERC721A_init(name_, symbol_);
        __linearVRGDA_init(_targetPrice, _priceDecayPercent, _perTimeUnit);
        ERC165Storage.layout().setSupportedInterface(0x80ac58cd, true); // ERC165 interface ID for ERC721.
        ERC165Storage.layout().setSupportedInterface(0x5b5e139f, true); // ERC165 interface ID for ERC721Metadata.
        
        SpellsStorage.getStorage().seedMintPrice = _seedPrice;
        SpellsStorage.getStorage().seedSupply = _seedSupply;
        SpellsStorage.getStorage().spellGate = _spellGate;
        SpellsStorage.getStorage().godspell = _godspell;
    }
    
    modifier onlySpellGate() {
         if(msg.sender != SpellsStorage.getStorage().spellGate) revert SenderNotSpellGate();
        _;
    }

    function getPrice() external view returns (uint256) {
        return _price(totalSupply()+1);
    }
    
    function _price(uint256 tokenId) private view returns (uint256) {
        if(tokenId > SpellsStorage.getStorage().seedSupply){
            return getVRGDAPrice(
                toDaysWadUnsafe(block.timestamp - SpellsStorage.getStorage().eternalStartTime), 
                tokenId - 1 - SpellsStorage.getStorage().seedSupply);
        }
        return SpellsStorage.getStorage().seedMintPrice;
    }

    function getFaction(uint256 tokenId) external view returns (uint256) {
        return SpellsCastStorage.getStorage().factions[tokenId];
    }
    
    function eternalMintActive() public view returns (bool) {
        return SpellsStorage.getStorage().eternalStartTime > 0;
    }

    function gateMint(
        address to,
        uint256 gate
    ) external payable onlySpellGate noReentry {
        SpellsStorage.Storage storage store = SpellsStorage.getStorage();
        if(store.saleState == SpellsStorage.SaleState.CLOSED) revert MintClosed();
        if(msg.sender != address(store.spellGate)) revert SenderNotSpellGate();
        // Set faction to gate
        SpellsCastStorage.getStorage().factions[totalSupply() + 1] = gate;
        /// @dev assign faction to tokenId before minting is safe because godspell
        /// tokens are issued after the tokens are minted to recipient.
        _conjure(to, 1);
    }
    
    /// @dev Sets random seed for the given tokenId.
    function _setSeed(address to, uint256 tokenId) internal {
        SpellsStorage.Storage storage store = SpellsStorage.getStorage();
        store.seed = uint256(keccak256(abi.encodePacked(store.seed, to, tokenId, block.coinbase, block.timestamp)));
        store.tokenSeed[tokenId] = store.seed;
    }
    
    function tokenSeed(uint256 _tokenId) external view returns (uint256) {
        return SpellsStorage.tokenSeed(_tokenId);
    }
    
    function _mintTo(
        address to,
        uint256 amount
    ) private returns (uint256) {
        if(amount == 0) revert ZeroAmount();
        SpellsStorage.Storage storage store = SpellsStorage.getStorage();
        SpellsCastStorage.Storage storage spellsStorage = SpellsCastStorage
            .getStorage();
            
        uint256 tokenId = totalSupply() + 1;
        if(store.eternalStartTime == 0 && tokenId + amount - 1 >= store.seedSupply) {
            store.eternalStartTime = block.timestamp;
            store.saleState = SpellsStorage.SaleState.ETERNAL;
        }
        uint256 nGodspell = 0;
        uint256 price = 0;
        for (uint256 i; i < amount; i++) {
            _setSeed(to, tokenId);
            spellsStorage.spellsCoin.mint(
                address(this),
                tokenId,
                SpellsStorage.initialSpellsCoinOf(tokenId) *
                    spellsStorage.spellsCoinMultiplier
            );
            price += _price(tokenId);
            if(tokenId % 10 == 0) {
                nGodspell++;
            }
            ++tokenId;
        }
        _safeMint(to, amount);
        
        /// Mint tokens to godspell in single batch after target mint batch.
        /// Theoretically allows recursion to catch all founder tokens, but actual
        /// per call amount is limited and prevents this.
        if(nGodspell > 0){
            _mintTo(store.godspell, nGodspell);
        }
        return price;
    }

    /// @dev Mints tokens to recipient loading batch price dynamically based on VRGDA.
    function _conjure(
        address to,
        uint256 amount
    ) private {
        uint256 price = _mintTo(to, amount);
        if(msg.value < price) revert MintInsufficientPayment(price);
        if (price > 0) {
            bool sent = payable(LibDiamond.treasury()).send(
                price
            );
            if(!sent) revert PaymentTransferFailed();
            /// Refund the difference
            if (msg.value - price > 0) {
                payable(msg.sender).transfer(msg.value - price);
            }
        }
    }

    function conjure() external payable noReentry {
        if(SpellsStorage.getStorage().saleState < SpellsStorage.SaleState.OPEN) revert MintClosed();
        _conjure(msg.sender, 1);
    }

    function conjure(uint256 amount) external payable noReentry {
        if(amount > 5) revert MintQuantityExceedsLimit();
        if(SpellsStorage.getStorage().saleState < SpellsStorage.SaleState.OPEN) revert MintClosed();
        _conjure(msg.sender, amount);
    }
    
    /// @dev contract owner is changed to SpellsDAO after seed completed.
    function conjure(
        uint256 _allowed,
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable noReentry {
        SpellsStorage.Storage storage store = SpellsStorage.getStorage();
        if(store.saleState == SpellsStorage.SaleState.CLOSED) revert MintClosed();
        if(!ECDSA.isValidAccessMessage(
                LibDiamond.diamondStorage().contractOwner,
                keccak256(abi.encodePacked(msg.sender, _allowed)),
                _v,
                _r,
                _s
            )
        ) revert MintNotAuthorized();
        uint256 used = store.mintCounts[msg.sender];
        if(used >= _allowed || _allowed - used < _amount) revert MintQuantityExceedsAllowance();
        store.mintCounts[msg.sender] += _amount;
        _conjure(msg.sender, _amount);
    }
}