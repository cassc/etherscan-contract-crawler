// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//   ____  _                   _               ____  _
//  / ___|| |_ ___ _ __  _ __ (_)_ __   __ _  / ___|| |_ ___  _ __   ___
//  \___ \| __/ _ \ '_ \| '_ \| | '_ \ / _` | \___ \| __/ _ \| '_ \ / _ \
//   ___) | ||  __/ |_) | |_) | | | | | (_| |  ___) | || (_) | | | |  __/
//  |____/ \__\___| .__/| .__/|_|_| |_|\__, | |____/ \__\___/|_| |_|\___|
//                |_|   |_|            |___/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PriceConverter.sol";
import "hardhat/console.sol";

// Errors
error IncorrectAmountOfEthSent();
error TransferFailed();
error NothingToWithdraw();
error NotOwner();
error CannotRedeemUnownedToken();

contract SteppingStone is ERC721URIStorage, Ownable, ReentrancyGuard {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    using Counters for Counters.Counter;
    Counters.Counter private _totalSupply;

    uint256 internal mintFee;
    uint256 private s_tokenCounter;

    // Constant Variables
    address private immutable i_owner;
    string[] internal s_typeTokenUris;
    uint256 public constant MINIMUM_USD_TOKEN_ONE = 50 * 10**18;
    uint256 public constant MINIMUM_USD_TOKEN_TWO = 300 * 10**18;

    struct Target {
        uint256 expires;
        uint256 tokenId;
        bool burned;
    }

    mapping(uint256 => Target) internal s_targets;

    // Price Feeds

    AggregatorV3Interface private s_priceFeed;

    // ///////////////////
    ////// Events ///////
    //////////////////////

    event NftMinted(address minter, address nftContract, uint256 tokenId);
    event NftBurned(address burner, uint256 tokenId);
    event PerformUpKeepCompleted();
    event HandledExpiredTokens();
    event NftNeedsToBeBurned(uint256 tokenId);

    constructor(address priceFeed, string[2] memory typeTokenUris)
        ERC721("SteppingStoneNft", "SSN")
    {
        s_typeTokenUris = typeTokenUris;
        i_owner = owner();
        s_tokenCounter = 0;

        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    //    /**
    //    * @notice Gets a list of tokens that are expired
    //    * @return list of tokens that are expired
    //    */
    // interval is no longer needed since chainlink keepers
    // cron job is handling the interval at which the function is ran

    function handleExpiredTokens() external {
        // currently x amount of nfts
        uint256 amountOfTokens = s_tokenCounter;

        Target memory target;

        for (uint256 i = 0; i < amountOfTokens; ) {
            target = s_targets[i];

            if (!target.burned) {
                if (0 > (int(target.expires) - int(block.timestamp))) {
                    emit NftNeedsToBeBurned(target.tokenId);
                    break;
                }
            }
            unchecked {
                ++i;
            }
        }

        emit HandledExpiredTokens();
    }

    //    /**
    //    * @notice Mints a one time use nft that will burn after x amount of seconds or until redeemed
    //    * @emits NftMinted Event
    //    */

    function mintNft() public payable returns (uint256) {
        uint256 oneTimeMintFee = getMintFeeForOneTimeUse();
        uint256 UnlimitedMintFee = getMintFeeUnlimitedUse();

        if (msg.value != oneTimeMintFee && msg.value != UnlimitedMintFee) {
            revert IncorrectAmountOfEthSent();
        }

        uint256 newTokenId = s_tokenCounter;

        _totalSupply.increment();
        s_tokenCounter = s_tokenCounter + 1;

        if (msg.value == oneTimeMintFee) {
            _safeMint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, s_typeTokenUris[0]);
        }

        if (msg.value == UnlimitedMintFee) {
            _safeMint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, s_typeTokenUris[1]);
        }

        s_targets[newTokenId] = Target({
            expires: (block.timestamp + 2629746),
            tokenId: newTokenId,
            burned: false
        });

        emit NftMinted(msg.sender, address(this), newTokenId);
    }

    //    /**
    //    * @notice Burns nft that has either been redeemed or expired
    //    * @emits NftBurned Event
    //    */
    function redeemNft(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
        _totalSupply.decrement();
        s_targets[tokenId].burned = true;

        emit NftBurned(msg.sender, tokenId);
    }

    function userRedeemsNft(uint256 tokenId) public nonReentrant {
        address tokenOwner = ownerOf(tokenId);

        if (tokenOwner != msg.sender) {
            revert CannotRedeemUnownedToken();
        }

        _burn(tokenId);
        _totalSupply.decrement();
        s_targets[tokenId].burned = true;

        emit NftBurned(msg.sender, tokenId);
    }

    function withdraw() public onlyOwner {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }

        uint256 amount = address(this).balance;

        if (amount < 0) {
            revert NothingToWithdraw();
        }

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }
    }

    // ///////////////////
    // Getter Functions //
    //////////////////////

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getNftTokenUri(uint256 index) public view returns (string memory) {
        return s_typeTokenUris[index];
    }

    function getCurrentTotalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenData(uint256 tokenId) public view returns (Target memory) {
        return s_targets[tokenId];
    }

    function getMintFeeForOneTimeUse() public view returns (uint256) {
        uint256 price = PriceConverter.getConversionRate(
            MINIMUM_USD_TOKEN_ONE,
            s_priceFeed
        );

        return price;
    }

    function getMintFeeUnlimitedUse() public view returns (uint256) {
        uint256 price = PriceConverter.getConversionRate(
            MINIMUM_USD_TOKEN_TWO,
            s_priceFeed
        );

        return price;
    }

    function getExpirationTimeStamp(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return s_targets[tokenId].expires;
    }
}