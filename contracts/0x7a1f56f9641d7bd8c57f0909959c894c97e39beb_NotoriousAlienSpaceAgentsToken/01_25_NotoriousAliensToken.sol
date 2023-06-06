// SPDX-License-Identifier: MIT

/// @title The Notorious Alien Space Agents ERC-721 token

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IRoyaltySharing} from "../interfaces/IRoyaltySharing.sol";
import {InitialYollarStaking} from "../staking/InitialYollarStaking.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

error WhitelistNotStarted();
error AuctionNotActive();
error NotInReservedList();
error WillExceedMaxAllowedToken();
error IncorrectEth();
error MaxFiveMintPerAuction();
error AtLeastOneMint();
error Soldout();
error TransferFailed();
error NotYourAlien();
error AlreadyAtMaxLevel();
error NotEnoughInputTokens();
error NotEnoughTokenInWallet();
error BaseUriIsFrozen();

contract NotoriousAlienSpaceAgentsToken is Ownable, ERC721Enumerable, Pausable {
    address private yollarAddress;
    address private gameTreasuryAddress;

    // ----------------------- Fair distribution
    // The hash of the hashes of all the ordered pfps.
    string public provenance;

    // The random starting postion that shifst the tokenId to alienId mapping.
    uint256 public startingIndex;

    // --------------------------------------------------------
    InitialYollarStaking private staking;
    // --------------------------------------------------------
    uint256 public currentTokenId;

    // Max number of Aliens: 5555
    // The first 5 are reserved for the founders.
    // The remaining 5550 are split "randomly" in the following way:
    // 1. 250 for the team givaways.
    // 2. 5300 for public minting.
    struct MintInfo {
        uint256 maxTokenId;
        uint256 firstPublicMintId;
    }
    MintInfo public mintInfo;

    mapping(address => bool) private devMintWhitelist;

    // The base token URI.
    string[] private tokenBaseURIs;
    bool public tokenBaseURIFrozen;

    // The stored balance.
    uint256 public balance;

    // reserved[address] = [count, price]
    // This is used for the following type of reserved lists.
    // 1. Initial giveaways (free mints)
    // 2. Team reserve
    // 3. Whitelist (guaranteed at a min price)
    struct ReservedInfo {
        uint256 count;
        uint256 price;
    }
    mapping(address => ReservedInfo) public reserved;

    // The whitelist starts with a delay after deploy.
    uint256 public whitelistStartTime;

    modifier whenWhitelistActive() {
        if (!isWhitelistActive()) {
            revert WhitelistNotStarted();
        }
        _;
    }

    // -----------------  Auction related

    // The dutch auction starts at `startTime`. The starting price keeps decreasing by stepPrice every stepInterval until it reaches the minimumPrice or until someone mints.
    struct AuctionInfo {
        bool isActive;
        uint256 startTime;
        uint256[] prices;
        uint128[] yollars;
        uint256 stepInterval;
    }
    AuctionInfo public auctionInfo;

    modifier whenAuctionActive() {
        if (!isAuctionActive()) {
            revert AuctionNotActive();
        }
        _;
    }

    // ----------------- Game related
    // Aliens can burn various utility tokens to level up and get new pfps!
    mapping(uint256 => uint256) public levels;
    ERC20Burnable[] public expTokens;
    uint256[][] public expNeededToUpgrade;

    // ----------------------------------

    constructor(
        string memory _tokenBaseURI,
        uint256 _maxTokenId,
        address[5] memory _founderAddresses,
        string memory _provenance,
        address _gameTreasuryAddress
    ) ERC721("Notorious Alien Space Agents", "NASA") {
        tokenBaseURIs.push(_tokenBaseURI);
        tokenBaseURIFrozen = false;
        currentTokenId = 1;
        mintInfo = MintInfo({maxTokenId: _maxTokenId, firstPublicMintId: 0});
        auctionInfo.isActive = false;
        // Mint the 5 founders pfps.
        for (uint256 i = 0; i < _founderAddresses.length; i++) {
            _mintTo(_founderAddresses[i]);
        }
        provenance = _provenance;
        gameTreasuryAddress = _gameTreasuryAddress;
    }

    function setStakingAddress(address _address) public onlyOwner {
        staking = InitialYollarStaking(_address);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // allow the staking contract to transfer without approval to save one transaction fee.
        if (_operator == address(staking)) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }

    // ----------------- Initial Whitelist
    /**
     * @notice Called once for dao members and once for other whitelist members.
     */
    function setWhitelists(
        address[] memory _whitelistAddresses,
        uint256[] memory _counts,
        uint256[] memory _prices,
        uint256 _whitelistStartTime
    ) public onlyOwner {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            reserved[_whitelistAddresses[i]] = ReservedInfo({
                count: _counts[i],
                price: _prices[i]
            });
        }
        whitelistStartTime = _whitelistStartTime;
    }

    /**
     * @notice enables the owner to undo mistakes
     */
    function removeWhitelists(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            delete reserved[addresses[i]];
        }
    }

    /**
     * @dev Call _mintTo
     */
    function mintWhitelist(
        uint256 _count,
        bool _stake,
        uint256 _duration
    ) public payable whenWhitelistActive whenNotPaused {
        ReservedInfo storage info = reserved[msg.sender];
        if (info.count < _count) {
            revert NotInReservedList();
        }
        if (currentTokenId + _count > mintInfo.maxTokenId) {
            revert WillExceedMaxAllowedToken();
        }
        uint256 price = info.price * _count;
        if (msg.value != price) {
            revert IncorrectEth();
        }

        balance = balance + price;
        reserved[msg.sender].count = reserved[msg.sender].count - _count;
        uint256[] memory tokenIds = new uint256[](_count);

        address _owner = _stake ? address(staking) : msg.sender;
        for (uint256 i = 0; i < _count; i++) {
            tokenIds[i] = _mintTo(_owner);
        }

        if (_stake) {
            for (uint256 i = 0; i < _count; i++) {
                staking.stakeDuringMint(tokenIds[i], _duration, msg.sender);
            }
        }
    }

    // ----------------- Auction

    function startAuction(
        uint256 _startTime,
        uint256 _stepInterval,
        address _yollarAddress
    ) external onlyOwner {
        auctionInfo.startTime = _startTime;
        auctionInfo.isActive = true;
        yollarAddress = _yollarAddress;

        auctionInfo.prices.push(0.79 ether);
        auctionInfo.prices.push(0.65 ether);
        auctionInfo.prices.push(0.55 ether);
        auctionInfo.prices.push(0.45 ether);
        auctionInfo.prices.push(0.4 ether);
        auctionInfo.prices.push(0.35 ether);
        auctionInfo.prices.push(0.3 ether);
        auctionInfo.prices.push(0.25 ether);
        auctionInfo.prices.push(0.2 ether);
        auctionInfo.prices.push(0.15 ether);
        auctionInfo.prices.push(0.08 ether);

        auctionInfo.yollars.push(15_000 ether);
        auctionInfo.yollars.push(10_000 ether);
        auctionInfo.yollars.push(8_000 ether);
        auctionInfo.yollars.push(6_000 ether);
        auctionInfo.yollars.push(5_000 ether);
        auctionInfo.yollars.push(4_000 ether);
        auctionInfo.yollars.push(3_000 ether);
        auctionInfo.yollars.push(2_000 ether);
        auctionInfo.yollars.push(0 ether);
        auctionInfo.yollars.push(0 ether);
        auctionInfo.yollars.push(0 ether);

        auctionInfo.stepInterval = _stepInterval;

        // Stop the minting by setting the start mint price 10 years in the future!
        whitelistStartTime = block.timestamp + 3650 days;
    }

    function stopAuction() external onlyOwner {
        auctionInfo.isActive = false;
    }

    /**
     * @notice mints from auction only if auction is active.
     * @dev Call _mintTo
     */
    function mintAuction(
        uint256 count,
        bool _stake,
        uint256 _duration
    ) external payable whenAuctionActive whenNotPaused {
        if (count > 5) {
            revert MaxFiveMintPerAuction();
        }
        if (count < 1) {
            revert AtLeastOneMint();
        }
        // NOTE: VERY IMPORTANT: the assupmtion is that the devs have minted their 5 pfp and also the 250 reserve. Once the auction starts, everything is up for grab!
        if (currentTokenId > mintInfo.maxTokenId) {
            revert Soldout();
        }
        uint256 step = getCurrentPrice();
        uint256 mintPrice = auctionInfo.prices[step];
        uint128 yollarAmount = auctionInfo.yollars[step];

        if (msg.value < mintPrice * count) {
            revert IncorrectEth();
        }
        if (mintInfo.firstPublicMintId == 0) {
            mintInfo.firstPublicMintId = currentTokenId;
        }

        uint256 mintable = count;
        uint256 remaining = mintInfo.maxTokenId - currentTokenId + 1;
        if (remaining <= count) {
            mintable = remaining;
        }

        uint256 unspent = msg.value;
        address _owner = _stake ? address(staking) : msg.sender;
        uint256[] memory tokenIds = new uint256[](mintable);
        for (uint256 i = 0; i < mintable; i++) {
            balance = balance + mintPrice;
            unspent = unspent - mintPrice;
            tokenIds[i] = _mintTo(_owner);
            if (yollarAmount != 0) {
                staking.rewardAuctionYollar(msg.sender, yollarAmount);
            }
        }

        if (currentTokenId > mintInfo.maxTokenId) {
            // All mints are done, now randomize the mapping!
            setStartingIndex();
        }

        if (_stake) {
            for (uint256 i = 0; i < mintable; i++) {
                staking.stakeDuringMint(tokenIds[i], _duration, msg.sender);
            }
        }

        if (unspent != 0) {
            // refund the extra eth
            // https://consensys.github.io/smart-contract-best-practices/recommendations/ recommends using this instead of transfer
            (bool success, ) = msg.sender.call{value: unspent}(""); // solhint-disable-line
            if (!success) {
                revert TransferFailed();
            }
        }
    }

    function getCurrentPrice() public view whenAuctionActive returns (uint256) {
        // 15 second delay could cause one going to the lower interval, but we have a way of refunding the buyer so it is ok.
        uint256 timeDiff = block.timestamp - auctionInfo.startTime; // solhint-disable-line

        uint256 step = timeDiff / auctionInfo.stepInterval;
        if (step >= 11) {
            step = 10;
        }
        return step;
    }

    // ----------------- Game

    function setExpTokens(
        address[] calldata _expTokenAddresses,
        uint256[][] memory _expNeeded
    ) public onlyOwner {
        require(
            _expTokenAddresses.length == _expNeeded.length,
            "Mismatched input length"
        );
        expTokens = new ERC20Burnable[](_expTokenAddresses.length);
        expNeededToUpgrade = _expNeeded;
        for (uint256 i = 0; i < _expTokenAddresses.length; i++) {
            expTokens[i] = ERC20Burnable(_expTokenAddresses[i]);
        }
        // Ensure that they all have the same length, which is going to be the max level.
        uint256 _maxLevel = expNeededToUpgrade[0].length;
        for (uint256 i = 0; i < expNeededToUpgrade.length; i++) {
            assert(expNeededToUpgrade[i].length == _maxLevel);
        }
    }

    function upgrade(uint256 _tokenId, uint256[] calldata _expCount)
        public
        whenNotPaused
    {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotYourAlien();
        }

        uint256 currentLevel = levels[_tokenId];
        if (currentLevel < 1) {
            currentLevel = 1;
        }
        if (currentLevel >= expNeededToUpgrade[0].length + 1) {
            revert AlreadyAtMaxLevel();
        }
        uint256 tokensCount = expNeededToUpgrade[0].length;
        for (uint256 i = 0; i < tokensCount; i++) {
            uint256 expNeeded = expNeededToUpgrade[i][currentLevel - 1]; // the array is zero indexed
            if (_expCount[i] != expNeeded) {
                revert NotEnoughInputTokens();
            }
            if (expTokens[i].balanceOf(msg.sender) < expNeeded) {
                revert NotEnoughTokenInWallet();
            }
        }

        levels[_tokenId] = currentLevel + 1;

        for (uint256 i = 0; i < tokensCount; i++) {
            expTokens[i].transferFrom(msg.sender, address(this), _expCount[i]);
            expTokens[i].burn(_expCount[i]);
        }
    }

    // ----------------- Withdraw

    /**
     * @notice sends the accumulated eth to the profit distributer contract.
     */
    function withdraw(address _address) public onlyOwner {
        IRoyaltySharing royaltySharingContract = IRoyaltySharing(_address);
        uint256 transferBalance = balance;
        balance = 0;
        royaltySharingContract.deposit{value: transferBalance}(20, 80, 0);
    }

    // ----------------- Fair distribution

    /**
     * This function creates a "random" starting point. Note that this definitely NOT a secure random but it is enough!
     * The function is called when the last pfp is minted. At that point, only the devs know about the ordering of pfps.
     * Therefore in order for the devs to cheat, they will need to make sure to mint the last pfp at a time of their choosing.
     * The assupmtion is that since the last item is auctioned, and there is enough interest in the project, the devs will have
     * a hard time competeing with others to choose something a mint time that is suitable for them.
     */
    function setStartingIndex() internal {
        assert(startingIndex == 0);

        // Note: the first 5 aliens are exceptions to the randomization rule.
        uint256 maxSupply = mintInfo.maxTokenId - 5;
        uint256 startingIndexBlock = block.number;
        startingIndex =
            (uint256(blockhash(startingIndexBlock)) % maxSupply) +
            5;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex =
                (uint256(blockhash(block.number - 1)) % maxSupply) +
                5;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 5;
        }
    }

    // ----------------- Utils

    /**
     * @notice mints to address and sends funds to royalty distributer.
     * @dev Call _mintTo
     */
    function _mintTo(address receipient) private returns (uint256) {
        _mint(receipient, currentTokenId);
        currentTokenId++;

        return currentTokenId - 1;
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 level = 1;
        if (levels[tokenId] > 1) {
            level = levels[tokenId];
        }
        string memory baseURI = "";
        if (level - 1 < tokenBaseURIs.length) {
            baseURI = tokenBaseURIs[level - 1];
        } else {
            baseURI = tokenBaseURIs[tokenBaseURIs.length - 1];
        }
        if (bytes(baseURI).length == 0) {
            return "";
        }

        uint256 alienId = tokenId;
        if (alienId > 5) {
            alienId =
                ((tokenId - 6 + startingIndex) % (mintInfo.maxTokenId - 5)) +
                6;
        }
        return string(abi.encodePacked(baseURI, Strings.toString(alienId)));
    }

    function reveal(string memory baseURI_, bool frozen_) external onlyOwner {
        if (tokenBaseURIFrozen) {
            revert BaseUriIsFrozen();
        }
        tokenBaseURIFrozen = frozen_;
        tokenBaseURIs[0] = baseURI_;
    }

    /**
     * @notice Since we can only append, this means that base URIs are forzen.
     */
    function setBaseURIForNextLevel(string memory baseURI_) external onlyOwner {
        tokenBaseURIs.push(baseURI_);
    }

    function isAuctionActive() public view returns (bool) {
        return auctionInfo.isActive && block.timestamp >= auctionInfo.startTime; // solhint-disable-line
    }

    function isWhitelistActive() public view returns (bool) {
        return block.timestamp >= whitelistStartTime; // solhint-disable-line
    }
}