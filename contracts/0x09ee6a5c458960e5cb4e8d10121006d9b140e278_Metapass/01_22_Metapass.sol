// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC721OwnershipBasedStaking} from "../token/ERC721/extensions/ERC721OwnershipBasedStaking.sol";
import {ERC721Royalty} from "../token/ERC721/extensions/ERC721Royalty.sol";
import {ERC721} from "../token/ERC721/ERC721.sol";
import {MintGate} from "../token/libraries/MintGate.sol";
import {Withdrawable} from "../utilities/Withdrawable.sol";

error AddressNotWhitelisted();

contract Metapass is ERC721OwnershipBasedStaking, ERC721Royalty, Withdrawable {

    uint256 public constant GAME_RESERVE = 250;

    uint256 public constant MAX_MINT_PER_WALLET = 2;
    uint256 public constant MAX_SUPPLY = 5000;

    // April 17, 2022 - 9:00 AM PST
    uint256 public constant MINT_END_TIME = 1650211200;

    // April 16, 2022 - 9:00 AM PST
    uint256 public constant MINT_START_TIME = 1650124800;

    uint256 public constant PUBLIC_PRICE = 0.2 ether;

    uint256 public constant VAULT_RESERVE = 750;
    address public constant VAULT_WALLET = 0x24D9EC1327eE15cD102ba72Fe98B580A7424af8B;

    bytes32 public constant WHITELIST_MERKLE_ROOT = 0xce40398c6324370b2faa1f4b6080e79641d61160efbb67c338bdde85a78e5313;
    uint256 public constant WHITELIST_PRICE = 0.15 ether;

    // April 15, 2022 - 9:00 AM PST
    uint256 public constant WHITELIST_START_TIME = 1650038400;


    constructor() ERC721OwnershipBasedStaking("Metapass", "metapass") ERC721Royalty(_msgSender(), 750) {
        setConfig(ERC721OwnershipBasedStaking.Config({
            fusible: false,
            listingFee: 0,
            resetOnTransfer: true,
            rewardsPerWeek: 3,
            // ( Rewards per week ) * ( 4 weeks ) * ( 6 months ) * ( x4 Minter Multiplier )
            upgradeFee: (3 * 4 * 3 * 4)
        }));
        setMultipliers(ERC721OwnershipBasedStaking.Multipliers({
            level: 1000,
            max: 80000,
            minter: 40000,
            // Once 'MINTER_MULTIPLIER' is lost it should take 4 months to regain
            month: 10000
        }));
    }


    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override(ERC721, ERC721OwnershipBasedStaking) virtual {
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function mintPublic(uint256 quantity) external nonReentrant payable {
        uint256 available = MAX_SUPPLY - GAME_RESERVE - VAULT_RESERVE - totalMinted();
        address buyer = _msgSender();

        MintGate.price(buyer, PUBLIC_PRICE, quantity, msg.value);
        MintGate.supply(available, MAX_MINT_PER_WALLET, uint256(_owner(buyer).minted), quantity);
        MintGate.time(MINT_END_TIME, MINT_START_TIME);

        _safeMint(buyer, quantity);
    }

    function mintToGameWallet(uint256 quantity) external nonReentrant onlyOwner {
        MintGate.supply((MAX_SUPPLY - totalMinted()), GAME_RESERVE, uint256(_owner(_msgSender()).minted), quantity);

        _safeMint(_msgSender(), quantity);
    }

    function mintToVaultWallet(uint256 quantity) external nonReentrant onlyOwner {
        MintGate.supply((MAX_SUPPLY - totalMinted()), VAULT_RESERVE, uint256(_owner(VAULT_WALLET).minted), quantity);

        _safeMint(VAULT_WALLET, quantity);
    }

    function mintUnsoldToVaultWallet() external nonReentrant onlyOwner {
        uint256 quantity = MAX_SUPPLY - totalMinted();

        if (MINT_END_TIME > block.timestamp || quantity == 0) {
            revert();
        }

        if (quantity > 10) {
            quantity = 10;
        }

        _safeMint(VAULT_WALLET, quantity);
    }

    function mintWhitelist(bytes32[] calldata proof, uint256 quantity) external nonReentrant payable {
        uint256 available = MAX_SUPPLY - GAME_RESERVE - VAULT_RESERVE - totalMinted();
        address buyer = _msgSender();

        if (proof.length == 0 || !MintGate.isWhitelisted(buyer, proof, WHITELIST_MERKLE_ROOT)) {
            revert AddressNotWhitelisted();
        }

        MintGate.price(buyer, WHITELIST_PRICE, quantity, msg.value);
        MintGate.supply(available, MAX_MINT_PER_WALLET, _owner(buyer).minted, quantity);
        MintGate.time(MINT_START_TIME, WHITELIST_START_TIME);

        _safeMint(buyer, quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721OwnershipBasedStaking, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner nonReentrant whenNotPaused {
        _withdraw(owner(), address(this).balance);
    }
}