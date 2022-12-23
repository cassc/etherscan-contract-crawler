// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BoozyApeMetaPub is
    Ownable,
    ERC721Royalty,
    ReentrancyGuard
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    struct CustomRoyalty {
        uint256 tokenId;
        address receiver;
        uint256 feeNumerator;
    }

    struct DefaultRoyalty {
        address receiver;
        uint96 feeNumerator;
    }

    struct TimeConfig {
        uint256 whitelistStart;
        uint256 publicStart;
    }

    address internal constant _ZERO_ADDRESS = address(0);
    address internal constant _DEAD_ADDRESS = address(0xdead);
    mapping(address => bool) internal _isWhitelisted;           // Whitelisted addresses
    uint256 public immutable WHITELIST_PRICE;                   // Whitelisting price => 0.03 ETH
    uint256 public immutable PUBLIC_PRICE;                      // Public price => 0.05 ETH
    uint256 public immutable MAX_TEAM_NFT_MINTING_LIMIT;        // NFT minting limit for the owner
    uint256 public nftsMintedForTeam;                           // The counter for the team minting
    uint256 public maxSupply;                                   // Available amount of NFTs
    uint256 internal _maxLimitPerAccount;                       // The limit for max buying
    uint256 internal _maxLimitPerTx;                            // The limit for max buying per tx
    TimeConfig public timeConfig;                               // The limit for max buying
    bool internal _isMaxLimitPerAccountEnabled;                 // Is max limit enabled
    bool internal _isMaxLimitPerTxEnabled;                      // Is max limit per tx enabled
    string internal _baseUri;                                   // Current base url
    string public uriSuffix = ".json";                          // Url suffix
    Counters.Counter private _supply;                           // Supply that was minted

    event BaseUrlUpdated(string url);
    event LimitPerAccountUpdated(uint256 oldLimit, uint256 newLimit);
    event MaxLimitPerAccountStatus(bool enabled);
    event MaxSupplyUpdated(uint256 oldSupply, uint256 newSupply);
    event WhitelistedUpdated(address whitelistAddress, bool flag);
    event Withdrawn(address whitelistAddress, uint256 value);
    event UriSuffixUpdated(string oldSuffix, string newSuffix);
    event MaxLimitPerTxUpdated(uint256 oldSuffix, uint256 newSuffix);
    event MaxLimitPerTxStatus(bool enabled);

    modifier mintCompliance(uint256 amount_) {
        uint256 availableSupply = maxSupply - MAX_TEAM_NFT_MINTING_LIMIT;
        require(_supply.current() + amount_<= availableSupply, "BoozyApeMetaPub::Max _supply exceeded!");

        if(isMaxLimitPerAccountEnabled())
            require(balanceOf(msg.sender) + amount_ <= maxLimitPerAccount(), "BoozyApeMetaPub::Already approached the maximum number of holdable items");

        _;
    }

    modifier isNotAboveMaxLimitPerTx(uint256 amount_) {
        if(isMaxLimitPerTxEnabled())
            require(amount_ <= getMaxLimitPerTx(), "BoozyApeMetaPub::Amount is too much");

        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 whitelistingPrice_,
        uint256 publicPrice_,
        uint96 royaltyFeeNumerator_,
        uint256 maxLimitPerAccount_,
        uint256 maxLimitPerTx_
    )
        ERC721(
            name_,
            symbol_
        )
    {
        string memory baseUrl = "ipfs://QmXXqERw8kXWjCgJFu2KJtH7XLKCJS4MzVrLgreaCwgN8A/";
        _baseUri = baseUrl;

        WHITELIST_PRICE = whitelistingPrice_;
        PUBLIC_PRICE = publicPrice_;
        MAX_TEAM_NFT_MINTING_LIMIT = 440;

        // Set royalty to the deployer
        // Require statement don't needed here for royaltyFeeNumerator_ because it will be handled in the _setDefaultRoyalty function
        _setDefaultRoyalty(
            owner(),
            royaltyFeeNumerator_
        );

        timeConfig = TimeConfig({
            whitelistStart: 1671721200,   //  24h from 22 Dec 15:00 UTC
            publicStart: 1671807600       //  23 Dec 15:00 UTC
        });

        _setMaxLimitPerAccountEnabledStatus(true);
        _setMaxLimitPerTxEnabledStatus(true);
        _setMaxLimitPerAccount(maxLimitPerAccount_);
        _setMaxLimitPerTx(maxLimitPerTx_);

        uint256 TOTAL_SUPPLY = 3740;
        _setMaxSupply(TOTAL_SUPPLY);
    }

    function mint(
        address to_,
        uint256 amount_
    )
        external
        payable
        isNotAboveMaxLimitPerTx(amount_)
        mintCompliance(amount_)
        nonReentrant()
    {
        address msgSender = msg.sender;
        uint256 price = getCurrentPrice();
        uint256 currentSupply = _supply.current();

        require(price != 0, "BoozyApeMetaPub::Not launched yet");
        require(amount_ > 0, "BoozyApeMetaPub::The amount to mint must above 0");

        if(_isWhitelistTime())
            require(isWhitelisted(msgSender), "BoozyApeMetaPub::You are not whitelisted.");

        uint256 priceToPay = price * amount_;
        require(msg.value >= priceToPay, "BoozyApeMetaPub::Not enough. Check the current price");

        // Refund if customer paid more than the cost to mint
        if(msg.value > priceToPay)
            payable(msgSender).transfer(msg.value - priceToPay);

        for (uint256 index = 1; index <= amount_; index++) {
            _safeMint(to_, currentSupply + index);
        }
    }

    function mintForTeam(address[] memory addresses_)
        external
        onlyOwner()
    {
        require(addresses_.length > 0, "BoozyApeMetaPub::Addresses cannot be empty");

        uint256 currentSupply = _supply.current();

        for (uint256 i = 1; i <= addresses_.length; i++) {
            address currentAddr = addresses_[i - 1];

            nftsMintedForTeam++;
            _safeMint(currentAddr, currentSupply + i);
            require(nftsMintedForTeam <= MAX_TEAM_NFT_MINTING_LIMIT, "BoozyApeMetaPub::You are not able to mint more nfts for the team");
        }
    }

    function setBaseUri(string memory url_)
        external
        onlyOwner()
    {
        _baseUri = url_;
        emit BaseUrlUpdated(url_);
    }

    function bulkAddWhitelist(address[] memory addresses_)
        external
        onlyOwner()
    {
        for(uint i = 0; i < addresses_.length; i++) {
            _setWhitelist(addresses_[i], true);
        }
    }

    function bulkRemoveWhitelist(address[] memory addresses_)
        external
        onlyOwner()
    {
        for(uint i = 0; i < addresses_.length; i++) {
            _setWhitelist(addresses_[i], false);
        }
    }

    function addWhitelist(address address_)
        external
        onlyOwner()
    {
        _setWhitelist(address_, true);
    }

    function removeWhitelist(address address_)
        external
        onlyOwner()
    {
        _setWhitelist(address_, false);
    }

    function setMaxLimitPerAccount(uint256 limit_)
        external
        onlyOwner()
    {
        _setMaxLimitPerAccount(limit_);
    }

    function setMaxLimitPerTx(uint256 limit_)
        external
        onlyOwner()
    {
        _setMaxLimitPerTx(limit_);
    }

    function withdraw(uint256 amount_)
        external
        onlyOwner()
    {
        address msgSender = msg.sender;
        uint256 balanceToTransfer = _getTransferAmount(amount_);
        payable(msgSender).transfer(balanceToTransfer);

        emit Withdrawn(msgSender, balanceToTransfer);
    }

    function withdrawToAddress(
        address address_,
        uint256 amount_
    )
        external
        onlyOwner()
    {
        require(address_ != _ZERO_ADDRESS, "BoozyApeMetaPub::You cannot withdraw to zero address");
        require(address_ != _DEAD_ADDRESS, "BoozyApeMetaPub::You cannot withdraw to dead address");

        uint256 balanceToTransfer = _getTransferAmount(amount_);
        payable(address_).transfer(balanceToTransfer);

        emit Withdrawn(address_, balanceToTransfer);
    }

    function setUriSuffix(string memory uriSuffix_)
        external
        onlyOwner
    {
        string memory oldUriSuffix = uriSuffix;
        uriSuffix = uriSuffix_;

        emit UriSuffixUpdated(oldUriSuffix, uriSuffix_);
    }

    function enableMaxLimitPerAccount()
        external
        onlyOwner()
    {
        _setMaxLimitPerAccountEnabledStatus(true);
    }
    function enableMaxLimitPerTx()
        external
        onlyOwner()
    {
        _setMaxLimitPerTxEnabledStatus(true);
    }

    function disableMaxLimitPerTx()
        external
        onlyOwner()
    {
        _setMaxLimitPerTxEnabledStatus(false);
    }

    function disableMaxLimitPerAccount()
        external
        onlyOwner()
    {
        _setMaxLimitPerAccountEnabledStatus(false);
    }

    function setMaxSupply(uint256 maxSupply_)
        external
        onlyOwner()
    {
        _setMaxSupply(maxSupply_);
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _supply.current();
    }

    function isMaxLimitPerAccountEnabled()
        public
        view
        returns(bool)
    {
        return _isMaxLimitPerAccountEnabled;
    }

    function isMaxLimitPerTxEnabled()
        public
        view
        returns(bool)
    {
        return _isMaxLimitPerTxEnabled;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ?
            string(abi.encodePacked(
                baseURI,
                tokenId.toString(),
                uriSuffix
            )) :
            "";
    }

    function getRemainingTeamMintCount()
        external
        view
        onlyOwner()
        returns(uint256)
    {
        return MAX_TEAM_NFT_MINTING_LIMIT - nftsMintedForTeam;
    }

    function maxLimitPerAccount()
        public
        view
        returns(uint256)
    {
        return _maxLimitPerAccount;
    }

    function isWhitelisted(address address_)
        public
        view
        returns(bool)
    {
        return _isWhitelisted[address_];
    }

    function getMaxLimitPerTx()
        public
        view
        returns(uint256)
    {
        return _maxLimitPerTx;
    }

    function _setWhitelist(
        address address_,
        bool flag_
    )
        internal
    {
        _isWhitelisted[address_] = flag_;
        emit WhitelistedUpdated(address_, flag_);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override
    {
        super._burn(tokenId);
    }

    function _setMaxLimitPerAccount(uint256 limit_)
        internal
    {
        require(0 < limit_ && limit_ <= 300, "BoozyApeMetaPub::Limit cannot above 300");

        uint256 oldLimit = _maxLimitPerAccount;
        _maxLimitPerAccount = limit_;

        emit LimitPerAccountUpdated(oldLimit, limit_);
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return _baseUri;
    }

    function _getTransferAmount(uint256 amount_)
        internal
        view
        returns(uint256 balanceToTransfer)
    {
        balanceToTransfer = amount_;
        uint256 contractBalance = address(this).balance;

        if(amount_ == 0)
            balanceToTransfer = contractBalance;

        if(balanceToTransfer > contractBalance)
            balanceToTransfer = contractBalance;

        return balanceToTransfer;
    }

    function _setMaxLimitPerTx(uint256 limit_)
        internal
    {
        require(limit_ > 0, "BoozyApeMetaPub::Limit per tx must be at least 1");
        require(limit_ <= maxLimitPerAccount(), "BoozyApeMetaPub::Limit cannot be higher then limit per account");

        uint256 oldLimit = _maxLimitPerTx;
        _maxLimitPerTx = limit_;

        emit MaxLimitPerTxUpdated(oldLimit, limit_);
    }

    function _safeMint(address to, uint256 tokenId)
        internal
        override
    {
        _supply.increment();
        super._safeMint(to, tokenId);
    }

    function _setMaxLimitPerAccountEnabledStatus(bool flag_)
        internal
    {
        _isMaxLimitPerAccountEnabled = flag_;
        emit MaxLimitPerAccountStatus(flag_);
    }

    function _setMaxLimitPerTxEnabledStatus(bool flag_)
        internal
    {
        _isMaxLimitPerTxEnabled = flag_;
        emit MaxLimitPerTxStatus(flag_);
    }

    function _setMaxSupply(uint256 maxSupply_)
        internal
    {
        require(maxSupply_ >= MAX_TEAM_NFT_MINTING_LIMIT, "BoozyApeMetaPub::Max _supply must be higher/equal than minting amount for the team");
        uint256 oldSupply = maxSupply;
        maxSupply = maxSupply_;

        emit MaxSupplyUpdated(oldSupply, maxSupply_);
    }
    function _isWhitelistTime() internal view returns(bool) {
        TimeConfig memory config = timeConfig;

        if(block.timestamp < config.whitelistStart)
            revert("BoozyApeMetaPub::Not launched yet");

        return config.whitelistStart <= block.timestamp && block.timestamp < config.publicStart;
    }

    function _isPublicTime() internal view returns(bool) {
        TimeConfig memory config = timeConfig;

        if(block.timestamp < config.whitelistStart)
            revert("BoozyApeMetaPub::Not launched yet");

        return block.timestamp >= config.publicStart;
    }

    function getCurrentPrice() public view returns(uint256 price)  {
        bool isWhitelistTimeActive = _isWhitelistTime();
        bool isPublicTimeActive = _isPublicTime();
        price = 0;

        if(isWhitelistTimeActive) {
            price = WHITELIST_PRICE;
        } else if(isPublicTimeActive) {
            price = PUBLIC_PRICE;
        }

        return price;
    }

    receive() external payable {}
}