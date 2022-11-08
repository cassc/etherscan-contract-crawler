// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "./lib/BaronBase.sol";

contract Baron is BaronBase, ERC20, ReentrancyGuard {
    using Address for address payable;

    uint256 public constant cap = 5_000_000;

    uint256 public mintPriceUSD = 10e18; // $10.00

    // We use this price feed to pin the mint price in ETH to a fixed USD value.
    // NOTE: ideally we would resolve the price feed at namehash("eth-usd.data.eth")
    //       but this doesn't work on testnets so we set the price-feed explicitly.
    // mainnet = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    // goerli = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    // See https://docs.chain.link/docs/data-feeds/price-feeds/addresses/
    address public ETH_USD_FEED;

    constructor(address _ETH_USD_FEED) ERC20("Baron", "BARON") {
        ETH_USD_FEED = _ETH_USD_FEED;
        _mint(msg.sender, 1_000_000);
        _pause();
    }

    // Tokens are not fractionalized.
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    // This allows anyone to mint tokens.
    function mint(uint256 tokenCount)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(msg.value >= mintPriceETH() * tokenCount, "incorrect ETH payment");
        require(tokenCount > 0, "token count must be nonzero");
        require(tokenCount <= 15_000, "token count must be <= 15_000");
        require(totalSupply() + tokenCount <= cap, "cap exceeded");
        treasury.sendValue(msg.value);
        _mint(msg.sender, tokenCount);
    }

    // returns the ETH price (in wei) to mint a single token.
    function mintPriceETH() public view returns (uint256) {
        return convertUsdToEth(mintPriceUSD);
    }

    // returns the ETH (wei) for a given USD amount (in wei-ish USD, i.e. 1e18).
    function convertUsdToEth(uint256 usd) public view returns (uint256) {
        AggregatorInterface priceFeed = AggregatorInterface(ETH_USD_FEED);
        uint256 ethPrice = uint256(priceFeed.latestAnswer()) * 1e10;
        require(ethPrice > 0, "ETH price cannot be zero");
        return (usd * 1e18) / (ethPrice);
    }

    //
    // Admin Methods
    //

    // This sets the mint price in USD.
    // NOTE: it is wei-ish USD (e.g. 10e18 = $10.00)
    function setMintPriceUSD(uint256 _mintPriceUSD) external onlyOperator {
        mintPriceUSD = _mintPriceUSD;
    }

    // This updates the price feed used to pin the mint price in ETH to a fixed USD value.
    function setEthUsdFeed(address _ETH_USD_FEED) external onlyOperator {
        ETH_USD_FEED = _ETH_USD_FEED;
    }
}