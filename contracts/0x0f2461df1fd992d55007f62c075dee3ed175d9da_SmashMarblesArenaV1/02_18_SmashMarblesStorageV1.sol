// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

contract SmashMarblesStorageV1 is
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    //url of token
    string internal beforeUri;
    string internal afterUri;

    //token value
    uint256 public marblePrice;
    uint256 public arenaPrice;

    // discount percentage
    uint256 public publicSalePercentDiscount;

    //token counter
    uint256 public tokenCounter;

    //token counter for arena minting
    uint256 public ArenaCounter;

    //minting stop or not
    uint256 public maxNFTs;
    
    uint256 public maxArenaNFTs;
    //maximum limit
    uint256 public maxMarbleLimit;

    //Marblebundle
    uint256[2] internal Marblebundle;

    // order tuple for purchase
    struct Order {
        uint256 nftType;
        bytes32 messageHash;
    }

    //address of communitywallet
    address public COMMUNITY_WALLET;

    //white listed address
    mapping(address => bool) public whitelistedAddress;

    //black listed address
    mapping(address => bool) public blacklistedAddress;

    // ON/OFF for whiteliste sale
    bool public whiteListSale;

    // ON/OFF for arena sale
    bool public arenaSale;

    // mapping of address w.r.t their arena purchase balance
    mapping(address => uint256) public arenaBalance;

    // temporary variables
    uint256[] internal tokenArray;
    address[] internal tempAddress;
    uint256[] internal tempId;

    // mapping of address with token Ids
    mapping(address => uint256[]) public rewardIds;

    // ON/OFF for public sale
    bool public publicSale;

    // structure for storing user rewards claim history.
    struct reward {
        address user;
        bool isClaimed;
    }

    // token Id history w.r.t to its claim
    mapping(uint256 => reward) public rewardClaimed;

    // Events

    /**
     * @dev Emitted when new token is bought by user.
     */
    event AssertMinted(address to, uint256[] id);

    /**
     * @dev Emitted when addresses of users are whitelisted.
     */
    event WhiteListed(address[] _addresses, bool _status);

    /**
     * @dev Emitted when new arena is minted by user.
     */
    event ArenaMinted(address to, uint256 TokenId);

    /**
     * @dev Emitted when marble NFT is claimed by user.
     */
    event ClaimedNft(address user, uint256 TokenId, uint256 ArenaTokenId);

    /**
     * @dev Emitted when Marbbles Airdrop is done.
     */
    event AirDropMarbles(address[] users, uint256[] tokenIds);

    /**
     * @dev Emitted when user is claim his/her all NFT marbles.
     */
    event ClaimAllNft(address user, uint256[] TokenId, uint256[] ArenaTokenId);
}