// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IsPausable.sol";

contract WhitelistedAddresses is Initializable, OwnableUpgradeable {
    //============== INITIALIZE ==============

    function __WhitelistedAddresses_init() internal onlyInitializing {
        __WhitelistedAddresses_init_unchained();
    }

    function __WhitelistedAddresses_init_unchained()
        internal
        onlyInitializing
    {}

    //============== EVENTS ==============

    event WhitelistedToken(address indexed tokenaddressToWhitelist);
    event UnWhitelistedToken(address indexed tokenaddressToWhitelist);
    event WhitelistedNFT(address indexed nftToWhitelist);
    event UnWhitelistedNFT(address indexed nftToWhitelist);
    event WhitelistedOuterRingNFT(address indexed nftToWhitelist);
    event UnWhitelistedOuterRingNFT(address indexed nftToWhitelist);

    //============== MAPPINGS ==============

    mapping(address => bool) public whitelistedTokens;
    mapping(address => bool) public whitelistedNFTs;
    mapping(address => bool) public outerRingNFTs;

    //============== MODIFIERS ==============

    modifier isWhitelistedToken(address erc20Token) {
        require(whitelistedTokens[erc20Token], "ERC20 not Whitelisted");
        _;
    }

    modifier isWhitelistedNFT(address nftContractAddress) {
        require(whitelistedNFTs[nftContractAddress], "NFT not Whitelisted");
        _;
    }

    //============== SET FUNCTIONS ==============

    function addTokenToWhitelist(address _tokenAddressToWhitelist)
        external
        onlyOwner
    {
        whitelistedTokens[_tokenAddressToWhitelist] = true;
        emit WhitelistedToken(_tokenAddressToWhitelist);
    }

    function deleteTokenFromWhitelist(address _tokenAddressToWhitelist)
        external
        onlyOwner
    {
        whitelistedTokens[_tokenAddressToWhitelist] = false;
        emit UnWhitelistedToken(_tokenAddressToWhitelist);
    }

    function addNFTToWhitelist(address _nftToWhitelist) external onlyOwner {
        whitelistedNFTs[_nftToWhitelist] = true;
        emit WhitelistedNFT(_nftToWhitelist);
    }

    function deleteNFTFromWhitelist(address _nftToWhitelist)
        external
        onlyOwner
    {
        whitelistedNFTs[_nftToWhitelist] = false;
        emit UnWhitelistedNFT(_nftToWhitelist);
    }

    function addOuterRingNFTToWhitelist(address _nftToWhitelist) external onlyOwner {
        outerRingNFTs[_nftToWhitelist] = true;
        emit WhitelistedOuterRingNFT(_nftToWhitelist);
    }

    function deleteOuterRingNFTFromWhitelist(address _nftToWhitelist)
        external
        onlyOwner
    {
        outerRingNFTs[_nftToWhitelist] = false;
        emit UnWhitelistedOuterRingNFT(_nftToWhitelist);
    }

    uint256[50] private __gap;
}