// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

contract dToolsNFT is ERC721, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Counters for Counters.Counter;

    address public dtoolsErc20Address;
    IERC20 private dtoolsErc20Contract;

    // contract dynamics
    string public baseURI;
    uint256 public immutable totalSupply;
    uint256 public allowListDtoolsGoldSupply;

    // mint dynamics
    uint256 public mintPricePublic; 

    // we setup two maps to track the minting by wallets
    mapping(address => bool) private _hasMinted;

    mapping(address => string) public telegramUsername;

    // state of mint dynamics
    bool public mintAvailableForPurchase = false; 
    bool public mintEndedByTeam = false;

    // counters for faster use by frontend
    Counters.Counter private totalMintedCounter;

    constructor() ERC721("dTools Gold", "DTOOLS") {

        dtoolsErc20Address = address(0x2c7800F451Bb32e8332b3cF5225590F5018D96a5);
        dtoolsErc20Contract = IERC20(dtoolsErc20Address);

        uint256 _totalSupply = 150;

        totalSupply = _totalSupply;
        doMint();
    }

    function exchangeErc20toNftMint() public nonReentrant {
        require(!mintEndedByTeam, "Mint is over");
        require(totalMintedCounter.current() < totalSupply, "Minted out.");

        uint256 _userErc20Balance = dtoolsErc20Contract.balanceOf(msg.sender);
        require(_userErc20Balance >= 7500000 * 10**18, "dTools ERC-20 token to NFT exchange requires 7,500,000 tokens to exchange.");

        dtoolsErc20Contract.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), 7500000 * 10**18);
        doMint();
    }


    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function endMint() external onlyOwner {
        mintEndedByTeam = true;
    }

    // start initial sale
    function toggleInitialSaleState(uint256 _mintPricePublic) external onlyOwner {
        require(!mintAvailableForPurchase, "Too late in cycle.");
        mintPricePublic = _mintPricePublic;
        mintAvailableForPurchase = true;
    }

    function mint() public payable nonReentrant {
        require(!mintEndedByTeam, "Mint is over");
        require(totalMintedCounter.current() < totalSupply, "Minted out.");
        require(mintAvailableForPurchase, "Mint is not open.");
        require(!hasMinted(_msgSender()), "You've minted already.");

        require(
            msg.value >= mintPricePublic,
            "Send more eth for mint."
        );

        doMint();
    }

    // Returns the current amount of NFTs minted in total.
    function totalMinted() public view returns (uint256) {
        return totalMintedCounter.current();
    }


    // Returns whether the address has minted
    function hasMinted(address _addy) public view returns (bool) {
        return _hasMinted[_addy];
    }

    // helper function to do the mint
    function doMint() internal {
        _safeMint(_msgSender(), (totalMintedCounter.current() + 1));
        totalMintedCounter._value += 1;
        _hasMinted[_msgSender()] = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    /// NFT holders whitelist a Telegram username to gain access to utility
    function setTelegramUsername(string memory _username) public {
        telegramUsername[msg.sender] = _username;
    }

    ///
    /// OperatorFilterer required overrides.
    /// @dev See {OperatorFilterer}
    ///
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}