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

/// @title Upgradeable 2 Phase auction and minting for the squirreldegens NFT project
contract AuctionV2Upgradeable is ERC721Upgradeable, OwnableUpgradeable, VRFV2WrapperConsumerBaseUpgradeable {
    using MathUpgradeable for uint;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    using ECDSAUpgradeable for bytes32;
    using ECDSAUpgradeable for bytes;

    using StringsUpgradeable for uint256;

    /*
        Constants
    */
    uint32 constant callbackGasLimit = 100000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords = 1;

    /*
        Initialisation
    */
    CountersUpgradeable.Counter private _tokenCounter;
    uint256 public preMintCount;

    address public signatureAddress;

    string private __baseURI;
    string private __realURI;
    string private _contractURI;

    mapping(address => bool) private _whitelistMap;

    /*
        Staking
    */
    event TokenStaked(address indexed _owner, uint256 indexed _token);
    event TokenUnStaked(address indexed _owner, uint256 indexed _token);

    uint256[] private _definedStakeLevels;
    mapping(uint256 => address) private _stakeOwnerMap;
    mapping(uint256 => uint256) private _stakeLevelTimeMap;
    mapping(uint256 => uint256) private _stakeStartTimeMap;

    /*
        Auction
    */
    address[] private _ticketHolders;

    event PrivateAuctionStarted(uint256 _price, uint256 _supply, uint256 _ticketsPerWallet);

    bool public privateAuctionStarted;
    bool public privateAuctionStopped;
    uint256 public privateAuctionPrice;
    uint256 public privateAuctionTicketCount;
    uint256 public privateAuctionTicketSupply;
    uint256 public privateAuctionTicketsPerWallet;
    mapping(address => uint256) public privateAuctionTicketMap;

    event PublicAuctionStarted(uint256 _price, uint256 _supply, uint256 _ticketsPerWallet);

    bool public publicAuctionStarted;
    bool public publicAuctionStopped;
    uint256 public publicAuctionPrice;
    uint256 public publicAuctionTicketCount;
    uint256 public publicAuctionTicketSupply;
    uint256 public publicAuctionTicketsPerWallet;
    mapping(address => uint256) public publicAuctionTicketMap;

    /*
        Mint
    */
    uint256 private _holderIndex;
    uint256 private _nextHolderTokenIndex;

    /*
        Reveal
    */

    event Revealed(string _uri, uint256 _seed);

    uint256 public revealVrfRequestId;
    bool public revealed;
    uint256 public seed;

    function initialize(string memory tokenName_, string memory tokenSymbol_, address signatureAddress_, string memory baseURI_, string memory contractURI_, address vrfLink_, address vrfWrapper_) public initializer {
        __ERC721_init(tokenName_, tokenSymbol_);
        __Ownable_init();
        __VRFV2WrapperConsumerBase_init(vrfLink_, vrfWrapper_);

        signatureAddress = signatureAddress_;
        __baseURI = baseURI_;
        _contractURI = contractURI_;
    }

    /*
    * Returns the contract URI for the contract level metadata
    */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /*
    * The total supply consisting of the premint + private auction + public auction tickets
    */
    function totalSupply() public view returns (uint256) {
        return preMintCount + privateAuctionTicketCount + publicAuctionTicketCount;
    }

    /*
    * Adds the given addresses to the whitelist for the private auction
    */
    function whitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            _whitelistMap[addresses[i]] = true;
        }
    }

    /*
    * Removes the given addresses from the whitelist for the private auction
    */
    function unWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            delete _whitelistMap[addresses[i]];
        }
    }
    /*
    * Returns a boolean indicating whether the sender wallet is whitelisted
    */
    function whitelisted() public view returns (bool) {
        return _whitelistMap[_msgSender()];
    }

    /*
    * Returns the amount of tickets bought by the sender wallet in the all auctions
    */
    function tickets() public view returns (uint256) {
        return privateAuctionTicketMap[_msgSender()] + publicAuctionTicketMap[_msgSender()];
    }

    /*
    * Starts the public auction with a specific price and supply. This method may not be called once the auction has been started.
    */
    function startPrivateAuction(uint256 price_, uint256 supply_, uint256 ticketsPerWallet_) public onlyOwner {
        require(!privateAuctionStarted, "Private auction has already been started");
        require(ticketsPerWallet_ > 0, "Requires at least 1 ticket per wallet");
        privateAuctionPrice = price_;
        privateAuctionTicketSupply = supply_;
        privateAuctionStarted = true;
        privateAuctionTicketsPerWallet = ticketsPerWallet_;
        emit PrivateAuctionStarted(price_, supply_, ticketsPerWallet_);
    }

    /*
    * Returns true if the private auction has been started and not yet stopped. false otherwise
    */
    function privateAuctionActive() public view returns (bool) {
        return privateAuctionStarted && !privateAuctionStopped && privateAuctionTicketCount < privateAuctionTicketSupply;
    }

    /*
    * Buy (value/price) tokens while the private auction is active
    * Only whitelisted addresses may use this method
    */
    function buyPrivateAuction(bytes memory signature) public payable {
        // Basic check
        require(privateAuctionActive(), "Private auction is not active");

        // Whitelist check
        require(_whitelistMap[_msgSender()], "Wallet is not whitelisted");

        // Signature check
        bytes32 hash = keccak256(abi.encode(_msgSender(), msg.value, "private")).toEthSignedMessageHash();
        require(hash.recover(signature) == signatureAddress, "Invalid signature");

        // Value check
        require(msg.value > 0, "Value has to be greater than 0");
        require(msg.value % privateAuctionPrice == 0, "Value has to be a multiple of the price");

        uint256 ticketsToBuy = msg.value / privateAuctionPrice;
        uint256 currentTickets = privateAuctionTicketMap[_msgSender()];

        // Ticket amount check
        require(ticketsToBuy + currentTickets <= privateAuctionTicketsPerWallet, "Total ticket count is higher than the max allowed tickets per wallet for the private auction");
        require(privateAuctionTicketCount + ticketsToBuy <= privateAuctionTicketSupply, "There are not enough tickets left in the private auction");

        privateAuctionTicketCount += ticketsToBuy;
        privateAuctionTicketMap[_msgSender()] += ticketsToBuy;
        if (currentTickets == 0) {
            _ticketHolders.push(_msgSender());
        }
    }

    /*
    * Returns the amount of tickets bought by the sender wallet in the private auction
    */
    function privateAuctionTickets() public view returns (uint256) {
        return privateAuctionTicketMap[_msgSender()];
    }

    /*
    * Stops the private auction and corrects the private auction supply count if necessary. May only be called if the private auction is active.
    */
    function stopPrivateAuction() public onlyOwner {
        require(privateAuctionStarted, "Private auction has not been started");
        privateAuctionStopped = true;
        privateAuctionTicketSupply = privateAuctionTicketCount;
    }

    /*
    * Starts the public auction with a specific price and supply. This method may not be called once the auction has been started.
    */
    function startPublicAuction(uint256 price_, uint256 supply_, uint256 ticketsPerWallet_) public onlyOwner {
        require(!publicAuctionActive(), "Public auction has already been started");
        require(privateAuctionStarted, "Public auction must start after private auction");
        require(!privateAuctionActive(), "Private auction is still active");
        require(privateAuctionStopped, "Private auction has to be cleaned up using the stopPrivateAuction() function before starting the public auction");
        require(ticketsPerWallet_ > 0, "Requires at least 1 ticket per wallet");

        publicAuctionStarted = true;
        publicAuctionPrice = price_;
        publicAuctionTicketSupply = supply_;
        publicAuctionTicketsPerWallet = ticketsPerWallet_;
        emit PublicAuctionStarted(price_, supply_, ticketsPerWallet_);
    }

    /*
    * Returns true if the public auction has been started and not yet stopped. false otherwise
    */
    function publicAuctionActive() public view returns (bool) {
        return publicAuctionStarted && !publicAuctionStopped && publicAuctionTicketCount < publicAuctionTicketSupply;
    }

    /*
    * Buy (value/price) tokens while the public auction is active
    */
    function buyPublicAuction(bytes memory signature) public payable {
        // Basic check
        require(publicAuctionActive(), "Public auction is not active");

        // Signature check
        bytes32 hash = keccak256(abi.encode(_msgSender(), msg.value, "public")).toEthSignedMessageHash();
        require(hash.recover(signature) == signatureAddress, "Invalid signature");

        // Value check
        require(msg.value > 0, "Value has to be greater than 0");
        require(msg.value % publicAuctionPrice == 0, "Value has to be a multiple of the price");

        uint256 ticketsToBuy = msg.value / publicAuctionPrice;
        uint256 currentTickets = publicAuctionTicketMap[_msgSender()];

        // Ticket amount check
        require(ticketsToBuy + currentTickets <= publicAuctionTicketsPerWallet, "Total ticket count is higher than the max allowed tickets per wallet for the public auction");
        require(publicAuctionTicketCount + ticketsToBuy <= publicAuctionTicketSupply, "There are not enough tickets left in the public auction");

        publicAuctionTicketCount += ticketsToBuy;
        publicAuctionTicketMap[_msgSender()] += ticketsToBuy;
        if (currentTickets == 0 && privateAuctionTicketMap[_msgSender()] == 0) {
            _ticketHolders.push(_msgSender());
        }
    }

    /*
    * Returns the amount of tickets bought by the sender wallet in the public auction
    */
    function publicAuctionTickets() public view returns (uint256) {
        return publicAuctionTicketMap[_msgSender()];
    }

    /*
    * Stops the public auction
    */
    function stopPublicAuction() public onlyOwner {
        require(publicAuctionStarted, "Public auction has not been started");
        publicAuctionStopped = true;
        publicAuctionTicketSupply = publicAuctionTicketCount;
    }

    /*
    * Mint a specific amount of tokens before the auction starts. The tokens will be minted on the owners wallet.
    * Can be used to activate the collection on a marketplace, like OpenSeas.
    */
    function preMint(uint256 count) public onlyOwner {
        require(!minted(), "Mint is already over");
        for (uint256 i = 0; i < count; ++i) {
            _safeMint(owner(), _tokenCounter.current() + 1);
            _tokenCounter.increment();
        }
        preMintCount = _tokenCounter.current();
    }

    /*
    * Mint n tokens. This can only handle about 1000 tokens, more would use too much gas
    */
    function mintAndDistribute(uint256 count_) public onlyOwner {
        require(publicAuctionStopped, "Public auction has to be cleaned up using the stopPublicAuction() function before minting");

        uint256 localIndex = _tokenCounter.current();
        uint256 localHolderIndex = _holderIndex;
        uint256 localNextHolderTokenIndex = _nextHolderTokenIndex;

        uint256 localEnd = localIndex + count_;
        uint256 localTotal = totalSupply();
        if (localEnd > localTotal) {
            localEnd = localTotal;
        }

        require(_tokenCounter.current() < localEnd, "All tokens have been minted");

        address localHolder = _ticketHolders[localHolderIndex];
        uint256 localTotalTickets = privateAuctionTicketMap[localHolder] + publicAuctionTicketMap[localHolder];

        while (_tokenCounter.current() < localEnd) {
            if (localNextHolderTokenIndex >= localTotalTickets) {
                localNextHolderTokenIndex = 0;
                localHolder = _ticketHolders[++localHolderIndex];
                localTotalTickets = privateAuctionTicketMap[localHolder] + publicAuctionTicketMap[localHolder];
            }

            _safeMint(localHolder, _tokenCounter.current() + 1);
            localNextHolderTokenIndex++;
            _tokenCounter.increment();
        }
        _nextHolderTokenIndex = localNextHolderTokenIndex;
        _holderIndex = localHolderIndex;
    }

    /*
    * Returns true of all tokens have been minted
    */
    function minted() public view returns (bool) {
        return publicAuctionStopped && _tokenCounter.current() == totalSupply();
    }

    /*
    * Requests randomness from the oracle
    */
    function requestReveal(string memory realURI_) public onlyOwner {
        require(_tokenCounter.current() == totalSupply(), "All tokens must be minted before revealing them");
        require(_definedStakeLevels.length > 0, "Tokens may not be revealed until staking levels are defined");

        __realURI = realURI_;
        revealVrfRequestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
    }

    /*
    * Will be called by ChainLink with an array containing 1 random word (our seed)
    */
    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        seed = randomWords[0];
        revealed = true;
        emit Revealed(__realURI, seed);
    }

    /*
    * Withdraw all the ETH stored inside the contract to the owner wallet
    */
    function withdraw() public onlyOwner {
        require(minted(), "Tokens have not been minted yet.");

        uint256 balance = address(this).balance;
        require(balance > 0, "The contract contains no ETH to withdraw");
        payable(_msgSender()).transfer(address(this).balance);
    }

    /*
    * Transfer the LINK of this contract to the owner wallet
    */
    function withdrawLink() public onlyOwner {
        require(minted(), "Tokens have not been minted yet.");

        LinkTokenInterface link = LinkTokenInterface(LINK);
        uint256 balance = link.balanceOf(address(this));
        require(balance > 0, "The contract contains no LINK to withdraw");
        require(link.transfer(msg.sender, balance), "Unable to withdraw LINK");
    }

    /*
    * Stakes the defined token
    * The token will be transferred to the contract until un-staked
    */
    function stake(uint256 tokenId_) public {
        require(minted(), "Tokens have not been minted");
        require(revealed, "Tokens have not been revealed");
        require(_stakeStartTimeMap[tokenId_] == 0, "Token has already been staked");
        require(_stakeLevelTimeMap[tokenId_] == 0, "Token has already been staked beyond level 0");
        require(ownerOf(tokenId_) == _msgSender(), "This token does not belong to the sender wallet");

        _stakeOwnerMap[tokenId_] = _msgSender();
        _stakeStartTimeMap[tokenId_] = block.timestamp;

        transferFrom(_msgSender(), address(this), tokenId_);

        emit TokenStaked(_msgSender(), tokenId_);
    }

    /*
    * Returns a boolean indicating if the token is currently staked
    */
    function staked(uint256 tokenId_) public view returns (bool) {
        return _stakeStartTimeMap[tokenId_] != 0;
    }

    /*
    * Returns a boolean indicating if the token is currently staked
    */
    function tokens() public view returns (uint256[] memory) {
        uint256[] memory possibleOwnedTokens = new uint256[](_tokenCounter.current());
        uint256 index = 0;
        for (uint256 i = 1; i <= _tokenCounter.current(); ++i) {
            if (ownerOf(i) == _msgSender() || _stakeOwnerMap[i] == _msgSender()) {
                possibleOwnedTokens[index++] = i;
            }
        }
        // Copy token ids to correct sized array
        uint256[] memory ownedTokens = new uint256[](index);
        for (uint256 i = 0; i < index; ++i) {
            ownedTokens[i] = possibleOwnedTokens[i];
        }
        return ownedTokens;
    }

    /*
    * Unlocks a token. This will unlock the token for trading and set the stake level for this token.
    */
    function unStake(uint256 tokenId_) public {
        require(_stakeStartTimeMap[tokenId_] != 0, "Token has not been staked");
        require(_stakeOwnerMap[tokenId_] == _msgSender(), "Token does not belong to the sender wallet");

        uint256 time = block.timestamp - _stakeStartTimeMap[tokenId_];
        if (_definedStakeLevels[0] <= time) {
            _stakeLevelTimeMap[tokenId_] = time;
        }
        _stakeStartTimeMap[tokenId_] = 0;

        delete _stakeOwnerMap[tokenId_];

        _transfer(address(this), _msgSender(), tokenId_);
        emit TokenUnStaked(_msgSender(), tokenId_);
    }

    /*
    * Returns how long the given token has been staked for
    */
    function stakeTime(uint256 token) public view returns (uint256) {
        uint256 stakeLevelTime = _stakeLevelTimeMap[token];
        if (stakeLevelTime == 0 && _stakeStartTimeMap[token] > 0) {
            stakeLevelTime = block.timestamp - _stakeStartTimeMap[token];
        }
        return stakeLevelTime;
    }

    /*
    * Returns the stake level for the given token
    */
    function stakeLevel(uint256 token) public view returns (uint256) {
        uint256 stakeLevelTime = _stakeLevelTimeMap[token];
        if (stakeLevelTime == 0 && _stakeStartTimeMap[token] > 0) {
            stakeLevelTime = block.timestamp - _stakeStartTimeMap[token];
        }

        uint256 level = 0;
        for (uint256 i = 0; i < _definedStakeLevels.length; ++i) {
            if (stakeLevelTime < _definedStakeLevels[i]) {
                break;
            }
            level = i + 1;
        }
        return level;
    }

    /*
    * Returns the URI pointing to the given tokens metadata. The value may change depending on the reveal state and the level of the given token.
    */
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory){
        if (!revealed) return __baseURI;
        uint256 level = stakeLevel(tokenId);
        uint256 offset = seed % totalSupply();
        uint256 metaId = ((tokenId + offset) % totalSupply()) + 1;
        return string.concat(__realURI, '/', metaId.toString(), '_', level.toString(), '.json');
    }

    /*
    * Defines the stake level for a given duration
    */
    function defineStakeLevels(uint256[] memory levelTimes) public onlyOwner {
        require(!revealed, "Stake levels may not be changed after revealing the metadata");
        _definedStakeLevels = levelTimes;
    }

    /*
    * Returns the defined stake levels
    */
    function stakeLevels() public view returns (uint256[] memory) {
        return _definedStakeLevels;
    }

    /*
       Compatibility functions
    */
    function _burn(uint256) internal pure override(ERC721Upgradeable) {
        revert("Burning is not allowed");
    }

}