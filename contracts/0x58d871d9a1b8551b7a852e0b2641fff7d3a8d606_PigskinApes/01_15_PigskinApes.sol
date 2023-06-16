// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PigskinApes is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 15;

    uint256 public mintPrice = 0.069 ether;

    bool public saleIsActive = false;

    bool public baycPreSaleIsActive = false;

    bool public maycPreSaleIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public giveawayPool = 0;

    address[8] private _shareholders;

    uint[8] private _shares;

    address private _manager;

    uint256 public ethDepositedPerToken = 0;

    IERC721 private _baycContractInstance;

    IERC721 private _maycContractInstance;

    // Mapping from token ID to the amount of claimed eth
    mapping(uint256 => uint256) private _claimedEth;

    event PaymentReleased(address to, uint256 amount);

    event EthDepositedForGiveaways(uint256 amount);

    event GiveawayDistributed(address to, uint256 amount);

    event EthDeposited(uint256 amount);

    event EthClaimed(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxPigskinApeSupply) ERC721(name, symbol) {
        maxTokenSupply = maxPigskinApeSupply;

        _shareholders[0] = 0x744e2D8dEE01C0030a8bc127994C3e7DF7947bCb; // Mark
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0xBaC76260da2763003f1d1D110DAfac140daA4644; // Jose
        _shareholders[3] = 0xF2d499b0cDBF95B5eF7173cE0CD862b3Dc800251; // Performance Bonus Pool
        _shareholders[4] = 0x4D842f973158E70a6A54e0b0FBF752A70aF14FbD; // Toni
        _shareholders[5] = 0x67b573b40b563CC5bD7eEEa0feF9ed92d4968f84; // Brantin
        _shareholders[6] = 0x6A6552d90a15c075CbB6a08687707c367dea51c8; // Project Dev Wallet
        _shareholders[7] = 0x32be1dAD006285f95ED456Ff111D738Bd146cC61; // Community Wagers Wallet

        _shares[0] = 2300;
        _shares[1] = 2200;
        _shares[2] = 1700;
        _shares[3] = 1200;
        _shares[4] = 1000;
        _shares[5] = 700;
        _shares[6] = 500;
        _shares[7] = 400;

        _baycContractInstance = IERC721(address(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D));
        _maycContractInstance = IERC721(address(0x60E4d786628Fea6478F785A6d7e704777c86a7c6));
    }

    function setBaycMaycContractAddresses(address baycContractAddress, address maycContractAddress) public onlyOwner {
        _baycContractInstance = IERC721(baycContractAddress);
        _maycContractInstance = IERC721(maycContractAddress);
    }

    function setMaxTokenSupply(uint256 maxPigskinApeSupply) public onlyOwner {
        maxTokenSupply = maxPigskinApeSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    /*
    * Distribute giveaways to token ID holders from the giveaway pool. There are 3 giveaway types:
    * 1. For specific token ID holders (this function). Direct distribution.
    * 2. For specific addresses (withdrawForGiveaway). Direct distribution.
    * 3. Giveaways to be distributed equally among all holders (deposit/claim functions). Require holders to claim them.
    */
    function distributeGiveaways(uint256 amount, uint256[] calldata tokenIds) public onlyOwner {
        require(giveawayPool >= amount * tokenIds.length, "Insufficient giveaway pool for distribution");

        for(uint256 i = 0; i < tokenIds.length; i++) {
            address owner = ownerOf(tokenIds[i]);
            Address.sendValue(payable(owner), amount);
            emit GiveawayDistributed(owner, amount);
        }

        giveawayPool -= amount * tokenIds.length;
    }

    /*
    * Distribute giveaways to specific addresses. These are not distributed from the pool, just the contract balance.
    */
    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 8; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause pre-sale if active, make active if paused.
    */
    function flipBaycPreSaleState() public onlyOwner {
        baycPreSaleIsActive = !baycPreSaleIsActive;
    }

    /*
    * Pause pre-sale if active, make active if paused.
    */
    function flipMaycPreSaleState() public onlyOwner {
        maycPreSaleIsActive = !maycPreSaleIsActive;
    }

    /*
    * Mint Pigskin Ape NFTs, woot!
    */
    function adoptApes(uint256 numberOfTokens) public payable {
        require(saleIsActive || (baycPreSaleIsActive && _baycContractInstance.balanceOf(msg.sender) > 0) || (maycPreSaleIsActive && _maycContractInstance.balanceOf(msg.sender) > 0), "Sale is not active or your address doesn't own a BAYC/MAYC");
        require(totalSupply() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available pigskin apes");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can only adopt 15 pigskin apes at a time");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index, set the starting index block.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }

    /*
    * Set the manager address for deposits.
    */
    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }

    /**
     * @dev Throws if called by any account other than the owner or manager.
     */
    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller is not the owner or manager");
        _;
    }

    /*
    * Deposit eth for token ID holder giveaways.
    */
    function depositForGiveaways() public payable onlyOwnerOrManager {
        giveawayPool += msg.value;
        emit EthDepositedForGiveaways(msg.value);
    }

    /*
    * Deposit eth for distribution to token owners. These are supposed to be equally distributed among holders.
    */
    function deposit() public payable onlyOwnerOrManager {
        ethDepositedPerToken += msg.value / totalSupply();

        emit EthDeposited(msg.value);
    }

    /*
    * Get the claimable balance of a token ID.
    */
    function claimableBalanceOfTokenId(uint256 tokenId) public view returns (uint256) {
        return ethDepositedPerToken - _claimedEth[tokenId];
    }

    /*
    * Get the total claimable balance for an owner.
    */
    function claimableBalance(address owner) public view returns (uint256) {
        uint256 balance = 0;
        uint256 numTokens = balanceOf(owner);

        for(uint256 i = 0; i < numTokens; i++) {
            balance += claimableBalanceOfTokenId(tokenOfOwnerByIndex(owner, i));
        }

        return balance;
    }

    function claim() public {
        uint256 amount = 0;
        uint256 numTokens = balanceOf(msg.sender);

        for(uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            amount += ethDepositedPerToken - _claimedEth[tokenId];
            // Add the claimed amount so as to protect against re-entrancy attacks.
            _claimedEth[tokenId] = ethDepositedPerToken;
        }

        require(amount > 0, "There is no amount left to claim");

        emit EthClaimed(msg.sender, amount);

        // We must transfer at the very end to protect against re-entrancy.
        Address.sendValue(payable(msg.sender), amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Set the starting index for the collection.
     */
    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % maxTokenSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % maxTokenSupply;
        }
        // Prevent default sequence.
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}