/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./@chainlink/VRFV2WrapperConsumerBaseUpgradeable.sol";

/// @title Variables for the V2 contract of the squirrel degens project
abstract contract AuctionV2Base is ERC721Upgradeable, OwnableUpgradeable, VRFV2WrapperConsumerBaseUpgradeable {

    /*
        Constants
    */
    uint32 constant internal callbackGasLimit = 100000;
    uint16 constant internal requestConfirmations = 3;
    uint32 constant internal numWords = 1;

    /*
        Initialisation
    */
    CountersUpgradeable.Counter internal _tokenCounter; // Used to track new and existing (from V2) tokens
    uint256 public preMintCount;

    address public signatureAddress;

    string internal __baseURI;
    string internal __realURI;
    string internal _contractURI;

    mapping(address => bool) internal _whitelistMap;

    /*
        Staking
    */

    uint256[] internal _definedStakeLevels;
    mapping(uint256 => address) internal _stakeOwnerMap;
    mapping(uint256 => uint256) internal _stakeLevelTimeMap;
    mapping(uint256 => uint256) internal _stakeStartTimeMap;

    /*
        Auction
    */
    address[] internal _ticketHolders;

    bool public privateAuctionStarted;
    bool public privateAuctionStopped;
    uint256 public privateAuctionPrice;
    uint256 public privateAuctionTicketCount;
    uint256 public privateAuctionTicketSupply;
    uint256 public privateAuctionTicketsPerWallet;
    mapping(address => uint256) internal privateAuctionTicketMap;

    bool internal publicAuctionStarted;
    bool internal publicAuctionStopped;
    uint256 internal publicAuctionPrice;
    uint256 internal publicAuctionTicketCount;
    uint256 internal publicAuctionTicketSupply;
    uint256 internal publicAuctionTicketsPerWallet;
    mapping(address => uint256) internal publicAuctionTicketMap;

    /*
        MintV2
    */
    uint256 internal _holderIndex;
    uint256 internal _nextHolderTokenIndex;

    /*
        Reveal
    */


    uint256 public revealVrfRequestId;
    bool public revealed;
    uint256 public seed;

    /*
    * Returns the contract URI for the contract level metadata
    */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /*
    * Adds the given addresses to the whitelist for the private mint
    */
    function whitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            _whitelistMap[addresses[i]] = true;
        }
    }

    /*
    * Returns a boolean indicating whether the sender wallet is whitelisted
    */
    function whitelisted() public view returns (bool) {
        return _whitelistMap[_msgSender()];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*
    * Returns the amount of tickets bought by the sender wallet in the private auction of the V2 contract
    */
    function privateAuctionTickets() public view returns (uint256) {
        return privateAuctionTicketMap[_msgSender()];
    }

    /*
       Compatibility functions
    */
    function _burn(uint256) internal pure override(ERC721Upgradeable) {
        revert("Burning is not allowed");
    }
}