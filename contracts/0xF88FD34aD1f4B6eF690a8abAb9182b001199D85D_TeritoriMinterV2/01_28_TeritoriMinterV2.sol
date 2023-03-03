// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./TeritoriNft.sol";
import "../lib/UniSafeERC20.sol";

contract TeritoriMinterV2 is Ownable, Pausable, ReentrancyGuard {
    using UniSafeERC20 for IERC20;

    event MintRequest(address user);
    event WithdrawFund(address token, uint256 amount);

    struct WhitelistConfig {
        uint256 mintMax;
        uint256 mintPeriod;
        uint256 mintPrice;
        uint256 delayPeriod;
    }
    struct Config {
        uint256 maxSupply;
        address mintToken; // address(0) for ETH payment
        uint256 mintStartTime;
        uint256 whitelistCount;
        uint256 publicMintPrice;
        uint256 publicMintMax;
        address royaltyReceiver;
        uint96 royaltyPercentage;
    }

    address public minter;
    address public nft;
    Config public config;
    mapping(uint256 => WhitelistConfig) public whitelists; // whitelist phase => config
    mapping(uint256 => mapping(address => bool)) public userWhitelisted; // whitelist phase => user address => whitelisted
    mapping(uint256 => uint256) public whitelistSize; // whitelist phase => whitelisted addresses count
    mapping(address => uint256) public userMinted; // user address => minted count

    mapping(uint256 => address) public tokenRequests; // mint request index => user address
    uint256 public tokenRequestsCount;
    uint256 public currentSupply;

    uint256 public minterFee;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _nft_impl,
        address _minter,
        uint256 _minterFee,
        bool _revealed,
        string memory _revealURI
    ) Ownable() Pausable() ReentrancyGuard() {
        nft = Clones.clone(_nft_impl);
        TeritoriNft(nft).initialize(
            _name,
            _symbol,
            _contractURI,
            _revealed,
            _revealURI
        );
        minter = _minter;
        minterFee = _minterFee;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setMinter(address newMinter) external onlyOwner {
        minter = newMinter;
    }

    function setMinterFee(uint256 newMinterFee) external onlyOwner {
        minterFee = newMinterFee;
    }

    function setConfig(Config memory newConfig) external onlyOwner {
        config = newConfig;
    }

    function updateReveal(bool _revealed, string memory _revealURI)
        external
        onlyOwner
    {
        TeritoriNft(nft).updateReveal(_revealed, _revealURI);
    }

    function startMint() external onlyOwner {
        config.mintStartTime = block.timestamp;
    }

    function setWhitelistConfig(
        uint256[] memory whitelistPhases,
        WhitelistConfig[] memory newWhitelistMintConfigs
    ) external onlyOwner {
        require(
            whitelistPhases.length == newWhitelistMintConfigs.length,
            "INVALID_LENGTH"
        );
        uint256 length = whitelistPhases.length;
        for (uint256 i = 0; i < length; ++i) {
            whitelists[whitelistPhases[i]] = newWhitelistMintConfigs[i];
        }
    }

    function setWhitelist(
        uint256 whitelistPhase,
        address[] memory users,
        bool whitelisted
    ) external onlyOwner {
        uint256 changes = 0;
        for (uint256 i = 0; i < users.length; ++i) {
            if (userWhitelisted[whitelistPhase][users[i]] != whitelisted) {
                userWhitelisted[whitelistPhase][users[i]] = whitelisted;
                changes++;
            }
        }

        if (whitelisted) {
            whitelistSize[whitelistPhase] += changes;
        } else {
            whitelistSize[whitelistPhase] -= changes;
        }
    }

    function requestMintByAdmin(address user, uint256 count)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(msg.sender == owner(), "Unauthorized");
        require(
            config.mintStartTime != 0 &&
                config.mintStartTime <= block.timestamp,
            "MINT_NOT_STARTED"
        );

        require(
            userMinted[user] + count <= config.publicMintMax,
            "EXCEED_MINT_MAX"
        );

        userMinted[user] += count;
        for (uint256 i = 0; i < count; ++i) {
            tokenRequests[tokenRequestsCount + i] = user;
            TeritoriNft(nft).mint(
                user,
                currentSupply + i,
                config.royaltyReceiver,
                config.royaltyPercentage,
                ""
            );
        }
        tokenRequestsCount += count;
        currentSupply += count;
        require(tokenRequestsCount <= config.maxSupply, "EXCEED_MAX_SUPPLY");

        emit MintRequest(user);
    }

    function requestMint(address user, uint256 count)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(
            config.mintStartTime != 0 &&
                config.mintStartTime <= block.timestamp,
            "MINT_NOT_STARTED"
        );

        uint256 mintCount = userMinted[user];
        uint256 currentPhaseStart = config.mintStartTime;
        uint256 mintPrice = config.publicMintPrice;
        for (uint256 i = 0; i < config.whitelistCount; ++i) {
            WhitelistConfig memory whitelist = whitelists[i];
            if (
                currentPhaseStart +
                    whitelist.mintPeriod +
                    whitelist.delayPeriod >=
                block.timestamp
            ) {
                require(
                    currentPhaseStart + whitelist.mintPeriod >= block.timestamp,
                    "IN_DELAY"
                );
                mintPrice = whitelist.mintPrice;
                require(userWhitelisted[i][user], "NOT_WHITELISTED");
                require(
                    mintCount + count <= whitelist.mintMax,
                    "EXCEED_WHITELIST_MINT_MAX"
                );
                break;
            }
            currentPhaseStart += whitelist.mintPeriod + whitelist.delayPeriod;
        }

        require(mintCount + count <= config.publicMintMax, "EXCEED_MINT_MAX");

        if (mintPrice > 0) {
            IERC20(config.mintToken).uniSafeTransferFrom(
                msg.sender,
                mintPrice * count
            );
        }

        userMinted[user] += count;
        for (uint256 i = 0; i < count; ++i) {
            tokenRequests[tokenRequestsCount + i] = user;
            TeritoriNft(nft).mint(
                user,
                currentSupply + i,
                config.royaltyReceiver,
                config.royaltyPercentage,
                ""
            );
        }
        tokenRequestsCount += count;
        currentSupply += count;
        require(tokenRequestsCount <= config.maxSupply, "EXCEED_MAX_SUPPLY");

        emit MintRequest(user);
    }

    function withdrawFund() external onlyOwner {
        uint256 withdrawBalance = 0;
        if (config.mintToken == UniSafeERC20.NATIVE_TOKEN) {
            withdrawBalance = address(this).balance;
        } else {
            withdrawBalance = IERC20(config.mintToken).balanceOf(address(this));
        }

        require(withdrawBalance > 0, "NO_AVAILABLE_FUND");
        IERC20(config.mintToken).uniSafeTransfer(msg.sender, withdrawBalance);

        emit WithdrawFund(config.mintToken, withdrawBalance);
    }

    function userState(address user)
        external
        view
        returns (
            uint256 currentPhase,
            uint256 mintPrice,
            bool userCanMint
        )
    {
        require(
            config.mintStartTime != 0 &&
                config.mintStartTime <= block.timestamp,
            "MINT_NOT_STARTED"
        );

        uint256 mintCount = userMinted[user];
        uint256 currentPhaseStart = config.mintStartTime;
        currentPhase = config.whitelistCount;
        mintPrice = config.publicMintPrice;
        for (uint256 i = 0; i < config.whitelistCount; ++i) {
            WhitelistConfig memory whitelist = whitelists[i];
            if (
                currentPhaseStart +
                    whitelist.mintPeriod +
                    whitelist.delayPeriod >=
                block.timestamp
            ) {
                mintPrice = whitelist.mintPrice;
                currentPhase = i;
                userCanMint =
                    currentPhaseStart + whitelist.mintPeriod >=
                    block.timestamp &&
                    userWhitelisted[i][user] &&
                    mintCount < whitelist.mintMax;
                break;
            }
            currentPhaseStart += whitelist.mintPeriod + whitelist.delayPeriod;
        }
        userCanMint = userCanMint && mintCount < config.publicMintMax;
    }

    function setBaseURI(string memory newBaseURI) external {
        require(msg.sender == minter, "unauthorized");

        TeritoriNft(nft).setBaseURI(newBaseURI);
    }

    function setTokenURI(uint256 tokenId, string memory tokenUri) external {
        require(msg.sender == minter, "UNAUTHORIZED");

        TeritoriNft(nft).setTokenURI(tokenId, tokenUri);
    }
}