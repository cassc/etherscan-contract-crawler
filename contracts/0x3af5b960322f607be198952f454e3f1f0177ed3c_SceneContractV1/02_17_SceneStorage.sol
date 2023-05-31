// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";

contract SceneStorage is ERC721RoyaltyUpgradeable, OwnableUpgradeable {
    // token counter
    uint256 public tokenCounter;

    // token uri base and extension
    string baseUri;
    string baseExtension;

    // reveal time for metadata
    uint256 public revealTime;
    // total scenes to be minted
    uint256 public maxMintCount;

    // token price on sales
    uint256 public tokenPrice;
    // defaut metadata
    string public unRevealURI;

    // collection wallet address
    address public CollectionWalletAddress;
    // max per minted on sale
    uint256 public maxPerWallet;

    // 1: presale 2: public sale 3: stop all
    uint256 public saleStatus;

    // reveal timestamp w.r.t token id
    mapping(uint256 => uint256) public revealTimestamp;
    // check whether address is blacklisted or not
    mapping(address => bool) public isBlacklisted;
    // check whether address is whitelisted or not
    mapping(address => bool) public isWhitelistedAddress;

    // mapping of balance on presale count
    mapping(address => uint256) public whitelistedAddressCount;
    // mapping of balance on public count
    mapping(address => uint256) public publicAddressCount;

    /**
     * @dev Emitted when new token minted by owner.
     */
    event Minted(address Owner, uint256[] TokenIds);

    /**
     * @dev Emitted when owner airdrops to user addresses.
     */
    event Airdrop(address[] Addresses, uint256[] TokenIds);

    /**
     * @dev Emitted when owner airdrops to user addresses.
     */
    event UpdatedURI(string indexed BaseURI, string indexed ExtensionURI, string indexed DefaultURI);

    /**
     * @dev Emitted when owner airdrops to user addresses.
     */
    event UpdatedData(address indexed CollectionAddress, uint256 indexed MaxMintCount, uint256 indexed TokenPrice, uint256 RevealTime);

    /**
     * @dev Emitted when owner airdrops to user addresses.
     */
    event UpdatedSaleStatus(uint256 indexed SaleStatus, uint256 indexed MaxPerWallet);

}