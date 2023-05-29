// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UnbankedBankersNFT is ERC721Enumerable, Ownable {
    /* 
    
    Created by: Black Jesus
    Reviewed and deployed by: Brainster
    
     */

    constructor() payable ERC721("Unbanked Bankers NFT", "Bankers") {}

    // Initialize SafeMath library for UINT
    using SafeMath for uint256;
    // Make sure you have enough you change this to mainnet Bankers Contract address before deploy
    ERC721 bankers = ERC721(0x20d4DdB3d16aDdcA064b7126F4b3cEe5437d4194);
    uint256 MINT_PER_MINT_PASS = 1;

    // General NFT Variables
    uint256 public maxTokens = 10000;

    uint256 public tokensReservedForWhitelist = 336;
    uint256 public tokensMintedForWhitelist = 0;

    uint256 public tokensReservedForDutchAuction = 9565;
    uint256 public tokensMintedForDutchAuction = 0;

    uint256 public tokensReservedForReserved = 99;
    uint256 public tokensMintedForReserved = 0;

    string internal baseTokenURI;
    string internal baseTokenURI_EXT;

    event MintAsOwner(address indexed to, uint256 tokenId);
    event MintWhitelist(address indexed to, uint256 tokenId);
    event MintDutchAuction(address indexed to, uint256 price, uint256 tokenId);
    event MintRolloverSale(address indexed to, uint256 tokenId);

    // Modifiers
    modifier onlySender() {
        require(msg.sender == tx.origin, "No smart contracts!");
        _;
    }

    // Contract Governance
    mapping(address => bool) internal shareholderToUnlockGovernance;

    address internal Shareholder_1 = 0xAB2c989e7eD65f558a2f5DF46968B82dC7Fa8F53;
    address internal Shareholder_2 = 0x8173FAe402f05d62B8B5ccAAD09CA4EDFcBA3fb4;
    address internal Shareholder_3 = 0x333e7e956FeA76dA56c6a2EA7DE97d0B043c54bb;

    uint256 internal Shareholder_1_Share = 90;
    uint256 internal Shareholder_2_Share = 1;
    uint256 internal Shareholder_3_Share = 9;

    // Receive Ether
    event Received(address from, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Withdraw Ether
    function withdrawEther() public onlyOwner {
        uint256 _totalETH = address(this).balance;

        uint256 _Shareholder_1_ETH = ((_totalETH * Shareholder_1_Share) / 100);
        uint256 _Shareholder_2_ETH = ((_totalETH * Shareholder_2_Share) / 100);
        uint256 _Shareholder_3_ETH = ((_totalETH * Shareholder_3_Share) / 100);

        payable(Shareholder_1).transfer(_Shareholder_1_ETH);
        payable(Shareholder_2).transfer(_Shareholder_2_ETH);
        payable(Shareholder_3).transfer(_Shareholder_3_ETH);
    }

    function viewWithdrawEtherAmounts()
        public
        view
        onlyOwner
        returns (uint256[] memory)
    {
        uint256 _totalETH = address(this).balance;
        uint256[] memory _ethToSendArray = new uint256[](9);

        uint256 _Shareholder_1_ETH = ((_totalETH * Shareholder_1_Share) / 100);
        uint256 _Shareholder_2_ETH = ((_totalETH * Shareholder_2_Share) / 100);
        uint256 _Shareholder_3_ETH = ((_totalETH * Shareholder_3_Share) / 100);

        _ethToSendArray[0] = _Shareholder_1_ETH;
        _ethToSendArray[1] = _Shareholder_2_ETH;
        _ethToSendArray[2] = _Shareholder_3_ETH;

        return _ethToSendArray;
    }

    // Emergency Withdraw -- Tested and working!
    // Governance Functions
    // It looks super hardcoded but I guess it's okay for something like this.
    modifier onlyShareholder() {
        require(
            msg.sender == Shareholder_1 ||
                msg.sender == Shareholder_2 ||
                msg.sender == Shareholder_3,
            "You are not a shareholder!"
        );
        _;
    }

    function unlockEmergencyFunctionAsShareholder() public onlyShareholder {
        shareholderToUnlockGovernance[msg.sender] = true;
    }

    modifier emergencyOnly() {
        require(
            shareholderToUnlockGovernance[Shareholder_1] &&
                shareholderToUnlockGovernance[Shareholder_2] &&
                shareholderToUnlockGovernance[Shareholder_3],
            "The emergency function has not been unlocked!"
        );
        _;
    }

    function emergencyWithdrawEther() public onlyOwner emergencyOnly {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Check Governance View function
    function checkGovernanceStatus(address address_)
        public
        view
        onlyShareholder
        returns (bool)
    {
        return shareholderToUnlockGovernance[address_];
    }

    ////////// Minting /////////////

    // Owner Mint
    function ownerMintMany(address address_, uint256 amount_) public onlyOwner {
        require(
            tokensReservedForReserved >= tokensMintedForReserved + amount_,
            "No more reserved tokens!"
        );

        tokensMintedForReserved += amount_; // increment tokens minted for reserved

        for (uint256 i = 0; i < amount_; i++) {
            uint256 _mintId = totalSupply();
            _mint(address_, _mintId);

            emit MintAsOwner(address_, _mintId);
        }
    }

    function ownerMint(address address_) public onlyOwner {
        require(
            tokensReservedForReserved > tokensMintedForReserved,
            "No more reserved tokens!"
        );

        tokensMintedForReserved++; // increment tokens minted for reserved

        uint256 _mintId = totalSupply();
        _mint(address_, _mintId);

        emit MintAsOwner(address_, _mintId);
    }

    // Whitelist Items
    uint256 public addressesWhitelisted = 0; // tracker for whitelist amount
    uint256 public whiteListPrice = 0 ether; // fixed price for whitelisted addresses
    mapping(address => uint256) public addressToWhitelistQuota; // mapping for whitelist to quota
    mapping(address => uint256) public addressToWhitelistMinted; // mapping for whitelist to minted
    bool public whiteListMintEnabled;

    modifier whiteListMint() {
        require(whiteListMintEnabled, "Whitelist Mints are not enabled yet!");
        _;
    }

    // Whitelist Functions
    function setWhiteListMintStatus(bool bool_) public onlyOwner {
        whiteListMintEnabled = bool_;
    }

    function addAddressToWhitelist(address[] memory addresses_)
        public
        onlyOwner
    {
        uint256 _amountOfAddresses = addresses_.length;
        for (uint256 i = 0; i < _amountOfAddresses; i++) {
            addressToWhitelistQuota[addresses_[i]] = 1; // record the whitelisted address and quota
        }
        addressesWhitelisted += _amountOfAddresses; // increase tracker by amount of whitelisted addreses
    }

    function checkWhitelistArrayIsUnique(address[] memory addresses_)
        public
        view
        onlyOwner
        returns (bool)
    {
        uint256 _amountOfAddresses = addresses_.length;
        for (uint256 i = 0; i < _amountOfAddresses; i++) {
            if (addressToWhitelistQuota[addresses_[i]] == 1) {
                return false;
            }
        }
        return true;
    }

    function checkWhitelistArrayIsAllUnclaimed(address[] memory addresses_)
        public
        view
        onlyOwner
        returns (bool)
    {
        uint256 _amountOfAddresses = addresses_.length;
        for (uint256 i = 0; i < _amountOfAddresses; i++) {
            if (addressToWhitelistMinted[msg.sender] != 0) {
                return false;
            }
        }
        return true;
    }

    function mintWhitelist() public payable onlySender whiteListMint {
        require(
            addressToWhitelistQuota[msg.sender] > 0,
            "You are not whitelisted!"
        );
        require(
            addressToWhitelistMinted[msg.sender] == 0,
            "You have no more whitelist mints left!"
        );
        require(msg.value == whiteListPrice, "Invalid value sent!");
        require(
            tokensReservedForWhitelist > tokensMintedForWhitelist,
            "No more whitelist tokens!"
        );
        require(maxTokens > totalSupply(), "No more tokens remaining!");

        addressToWhitelistMinted[msg.sender]--; // increments the tracker so that they cannot mint again
        tokensMintedForWhitelist++; // increments tracker of how many tokens have been minted from whitelist

        uint256 _mintId = totalSupply();
        _mint(msg.sender, _mintId);

        emit MintWhitelist(msg.sender, _mintId);
    }

    // Merkle Tree Whitelisting
    bytes32 public merkleRoot =
        0x57c359b719e25852692060d2b4d8ce73ad9fea9406622eab2d3cb352cf46373c;

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function isMerkleWhitelisted(bytes32[] memory proof_)
        public
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));

        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i]
                ? keccak256(abi.encodePacked(_leaf, proof_[i]))
                : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == merkleRoot;
    }

    function mintWhitelistMerkleTree(bytes32[] memory proof_)
        public
        payable
        onlySender
        whiteListMint
    {
        require(isMerkleWhitelisted(proof_), "You are not whitelisted!");
        require(
            addressToWhitelistMinted[msg.sender] == 0,
            "You have no more whitelist mints left!"
        );
        require(msg.value == whiteListPrice, "Invalid value sent!");
        require(
            tokensReservedForWhitelist > tokensMintedForWhitelist,
            "No more whitelist tokens!"
        );
        require(maxTokens > totalSupply(), "No more tokens remaining!");

        addressToWhitelistMinted[msg.sender]++; // increments the tracker so that they cannot mint again
        tokensMintedForWhitelist++; // increments tracker of how many tokens have been minted from whitelist

        uint256 _mintId = totalSupply();
        _mint(msg.sender, _mintId);

        emit MintWhitelist(msg.sender, _mintId);
    }

    // Dutch Auction Items
    uint256 public dutchEndingPrice = 0.01 ether;
    uint256 public dutchPriceAdditional = 0.99 ether; // record the additional price of dutch and deduct
    uint256 public dutchStartTime; // record the start time
    uint256 public dutchDuration; // record the duration
    uint256 public dutchEndTime; // record the end time
    bool public dutchAuctionStarted; // boolean for dutch auction

    modifier dutchAuction() {
        require(
            dutchAuctionStarted && block.timestamp >= dutchStartTime,
            "Dutch auction has not started yet!"
        );
        _;
    }

    function setDutchAuctionStartStatus(bool bool_) public onlyOwner {
        dutchAuctionStarted = bool_;
    }

    // Dutch Action Initialize
    function setDutchAuction(
        uint256 dutchPriceAdditional_,
        uint256 dutchStartTime_,
        uint256 dutchDuration_
    ) public onlyOwner {
        dutchPriceAdditional = dutchPriceAdditional_; // set the additional price of dutch to deduct
        dutchStartTime = dutchStartTime_; // record the current start time as UNIX timestamp
        dutchDuration = dutchDuration_; // record the duration of the dutch in order to deduct
        dutchEndTime = dutchStartTime.add(dutchDuration); // record for safekeeping the ending time
    }

    // Dutch Auction Functions
    function getTimeElapsed() public view returns (uint256) {
        return
            dutchStartTime > 0
                ? dutchStartTime.add(dutchDuration) >= block.timestamp
                    ? block.timestamp.sub(dutchStartTime)
                    : dutchDuration
                : 0; // this value will end at dutchDuration as maximum.
    }

    function getTimeRemaining() public view returns (uint256) {
        return dutchDuration.sub(getTimeElapsed());
    }

    function getAdditionalPrice() public view returns (uint256) {
        return
            dutchDuration.sub(getTimeElapsed()).mul(dutchPriceAdditional).div(
                dutchDuration
            ); // magic equation to calculate additional price on top of ending price
    }

    function getCurrentDutchPrice() public view returns (uint256) {
        return dutchEndingPrice.add(getAdditionalPrice());
    }

    // untested
    function mintDutchAuctionMany(uint256 amount_)
        public
        payable
        onlySender
        dutchAuction
    {
        require(
            tokensReservedForDutchAuction >=
                tokensMintedForDutchAuction + amount_,
            "No more tokens for Dutch Auction!"
        );
        require(
            maxTokens >= totalSupply() + amount_,
            "No more tokens remaining!"
        );
        require(50 >= amount_, "You can only mint up to 50 per transaction!");
        require(
            msg.value >= getCurrentDutchPrice() * amount_,
            "Invalid value sent!"
        );

        tokensMintedForDutchAuction += amount_; // increase tokens minted for dutch auction tracker

        for (uint256 i = 0; i < amount_; i++) {
            uint256 _mintId = totalSupply();
            uint256 _currentPrice = getCurrentDutchPrice();
            _mint(msg.sender, _mintId);

            emit MintDutchAuction(msg.sender, _currentPrice, _mintId);
        }
    }

    function mintDutchAuction() public payable onlySender dutchAuction {
        require(
            tokensReservedForDutchAuction > tokensMintedForDutchAuction,
            "No more tokens for Dutch Auction!"
        );
        require(maxTokens > totalSupply(), "No more tokens remaining!");
        require(msg.value >= getCurrentDutchPrice(), "Invalid value sent!");

        tokensMintedForDutchAuction++; // increase tokens minted for dutch auction tracker

        uint256 _mintId = totalSupply();
        uint256 _currentPrice = getCurrentDutchPrice();
        _mint(msg.sender, _mintId);

        emit MintDutchAuction(msg.sender, _currentPrice, _mintId);
    }

    // Rollover Sale Items
    uint256 public rolloverSalePrice;
    uint256 public rolloverSaleStartTime;
    bool public rolloverSaleStarted;
    uint256 public rolloverSaleTokensMinted;

    modifier rolloverSale() {
        require(
            rolloverSaleStarted && block.timestamp >= rolloverSaleStartTime,
            "Rollover sale has not started yet!"
        );
        _;
    }

    // Rollover Sale Functions
    function setRolloverSalePrice(uint256 price_) public onlyOwner {
        rolloverSalePrice = price_;
    }

    function setRolloverSaleStatus(uint256 rolloverSaleStartTime_, bool bool_)
        public
        onlyOwner
    {
        require(
            rolloverSalePrice != 0,
            "You have not set a rollover sale price!"
        );
        rolloverSaleStartTime = rolloverSaleStartTime_;
        rolloverSaleStarted = bool_;
    }

    function mintRolloverSaleMany(uint256 amount_)
        public
        payable
        onlySender
        rolloverSale
    {
        require(
            maxTokens >= totalSupply() + amount_,
            "No remaining tokens left!"
        );
        require(5 >= amount_, "You can only mint up to 5 per transaction!");
        require(
            msg.value == rolloverSalePrice * amount_,
            "Invalid value sent!"
        );

        rolloverSaleTokensMinted += amount_; // add to tracker of public sale tokens minted

        for (uint256 i = 0; i < amount_; i++) {
            uint256 _mintId = totalSupply();
            _mint(msg.sender, _mintId);

            emit MintRolloverSale(msg.sender, _mintId);
        }
    }

    function mintRolloverSale() public payable onlySender rolloverSale {
        require(maxTokens > totalSupply(), "No remaining tokens left!");
        require(msg.value == rolloverSalePrice, "Invalid value sent!");

        rolloverSaleTokensMinted++; // add to tracker of public sale tokens minted

        uint256 _mintId = totalSupply();
        _mint(msg.sender, _mintId);

        emit MintRolloverSale(msg.sender, _mintId);
    }

    // Mint Pass Mint Function
    function MintPassClaim(uint256 tokenId) public dutchAuction {
        // Require the claimer to have at least one Banker Mint Pass NFT from the specified contract
        require(bankers.ownerOf(tokenId) == msg.sender, "Not Mint Pass owner");
        // Set limit to no more than MINT_PER_MINT_PASS times of the owned Harems
        require(
            super.balanceOf(msg.sender) <
                bankers.balanceOf(msg.sender) * MINT_PER_MINT_PASS,
            "Purchase more Mint Passes"
        );
        require(super.totalSupply() < maxTokens, "Maximum supply reached.");
        uint256 _mintId = totalSupply();

        _mint(msg.sender, _mintId);
    }

    // New White List Functons

    mapping(address => uint8) private _allowList;

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) public whiteListMint {
        uint256 ts = totalSupply();
        require(
            numberOfTokens <= _allowList[msg.sender],
            "Exceeded max available to purchase"
        );
        require(super.totalSupply() < maxTokens, "Maximum supply reached.");

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender, ts + i);
        }
    }

    // General NFT Administration
    function setBaseTokenURI(string memory uri_) external onlyOwner {
        baseTokenURI = uri_;
    }

    function setBaseTokenURI_EXT(string memory ext_) external onlyOwner {
        baseTokenURI_EXT = ext_;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "Query for non-existent token!");
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(tokenId_),
                    baseTokenURI_EXT
                )
            );
    }

    function walletOfOwner(address address_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_); // get balance of address
        uint256[] memory _tokenIds = new uint256[](_balance); // initialize array
        for (uint256 i = 0; i < _balance; i++) {
            _tokenIds[i] = tokenOfOwnerByIndex(address_, i);
        }
        return _tokenIds;
    }
}