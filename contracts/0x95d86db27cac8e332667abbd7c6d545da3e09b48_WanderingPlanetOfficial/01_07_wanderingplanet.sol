// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol"; 

pragma solidity ^0.8.7;


contract WanderingPlanetOfficial is ERC721A, Ownable, Pausable, ReentrancyGuard {
    event BaseURIChanged(string newBaseURI);
    event WhitelistSaleConfigChanged(Period config_);
    event PublicSaleConfigChanged(Period config_);
    event RefundConfigChanged(Period config_);
    event Minted(address minter, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event ContractSealed();

    struct Period{
        uint256 startTime;
        uint256 endTime;
    }

    uint256 public constant PRICE = 0;  //Price
    uint64 public constant MAX_TOKEN = 2999;
    uint64 public constant MAX_TOKEN_PER_ADD = 1;
    Period public whitelistsaletime;
    Period public publicsaletime;
    Period public refundtime;
    bool public contractSealed;
    string public baseURI;
    address public refundAddress;

    mapping(address => uint256) public allowlist;
    mapping(uint256 => bool) public hasRefunded; 
    mapping(uint256 => bool) public isOwnerMint;

    constructor(string memory baseURI_) ERC721A("Wandering Planet Official", "WPO") {
        baseURI = baseURI_;
        refundAddress = msg.sender;
    }

    /***********************************|
    |               Mint                |
    |__________________________________*/

    function giveaway(address[] memory address_, uint64[] memory numberOfTokens_) external onlyOwner nonReentrant {
        require(address_.length == numberOfTokens_.length, "Check the giveaway list");
        for(uint256 i = 0; i < address_.length; i++){
            require(address_[i] != address(0), "zero address");
            require(numberOfTokens_[i] > 0 , "invalid number of tokens");
            require(totalMinted() + numberOfTokens_[i] <= MAX_TOKEN, "max supply exceeded");
            uint256 current_id = totalMinted();
            _safeMint(address_[i], numberOfTokens_[i]);
            for(uint256 j = 0; j < numberOfTokens_[i]; j++)
                isOwnerMint[current_id + j] = true;
        }
    }

    function whitelistSale(uint64 numberOfTokens_) external payable callerIsUser nonReentrant {
        require(isWhitelistSaleEnabled(), "whitelist sale has not enabled");
        require(isWhitelistAddress(), "you are not in the whitelist");
        require(numberOfTokens_ <= allowlist[msg.sender], "excess max allowed amount");
        mint(numberOfTokens_, PRICE);
        allowlist[msg.sender] = allowlist[msg.sender] - numberOfTokens_;
    }

    function publicSale(uint64 numberOfTokens_) external payable callerIsUser nonReentrant {
        require(isPublicSaleEnabled(), "public sale has not enabled");
        mint(numberOfTokens_, PRICE);
    }

    function mint(uint64 numberOfTokens_, uint256 price_) internal {
        require(numberOfTokens_ > 0, "invalid number of tokens");
        require(numberOfTokens_ + numberMinted(msg.sender) <= MAX_TOKEN_PER_ADD, "max minted amount per address exceeded");
        require(totalMinted() + numberOfTokens_ <= MAX_TOKEN, "max supply exceeded");
        uint256 amount = price_ * numberOfTokens_;
        require(amount <= msg.value, "insufficient ether");
        _safeMint(_msgSender(), numberOfTokens_);
        mint_refund(amount);
        emit Minted(msg.sender, numberOfTokens_);
    }


    function mint_refund(uint256 amount_) private {
        if (msg.value > amount_) {
            payable(_msgSender()).transfer(msg.value - amount_);
        }
    }

    function token_refund(uint256[] calldata tokenIds) external callerIsUser nonReentrant{
        require(isRefundEnabled(), "Refund Not Enabled");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not token owner");
            require(!hasRefunded[tokenId], "Already refunded");
            require(!isOwnerMint[tokenId], "Freely minted NFTs cannot be refunded");
            hasRefunded[tokenId] = true;
            transferFrom(msg.sender, refundAddress, tokenId);
        }

        uint256 refundAmount = tokenIds.length * PRICE;
        payable(_msgSender()).transfer(refundAmount);
    }
 
    /***********************************|
    |               State               |
    |__________________________________*/

    function isWhitelistSaleEnabled() public view returns (bool) {
        if (whitelistsaletime.endTime > 0 && block.timestamp > whitelistsaletime.endTime) {
            return false;
        }
        return whitelistsaletime.startTime > 0 && 
            block.timestamp > whitelistsaletime.startTime;
    }

    function isPublicSaleEnabled() public view returns (bool) {
        if (publicsaletime.endTime > 0 && block.timestamp > publicsaletime.endTime) {
            return false;
        }
        return publicsaletime.startTime > 0 && 
            block.timestamp > publicsaletime.startTime;
    }

    function isRefundEnabled() public view returns (bool){
        if (refundtime.endTime > 0 && block.timestamp > refundtime.endTime) {
            return false;
        }
        return refundtime.startTime > 0 && 
            block.timestamp > refundtime.startTime;
    }

    function isWhitelistAddress() public view returns (bool){
        return allowlist[msg.sender] > 0;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /***********************************|
    |               Owner               |
    |__________________________________*/
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    function setAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(addresses.length == numSlots.length, "Check the address");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }
    
    function setWhitelistSaleTime(Period calldata config_) external onlyOwner {
        whitelistsaletime = config_;
        emit WhitelistSaleConfigChanged(config_);
    }
    
    function setPublicSaleTime(Period calldata config_) external onlyOwner {
        publicsaletime = config_;
        emit PublicSaleConfigChanged(config_);
    }

    function setRefundTime(Period calldata config_) external onlyOwner {
        refundtime = config_;
        emit RefundConfigChanged(config_);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }
    
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "token transfer paused");
    }


    function emergencyPause() external onlyOwner notSealed {
        _pause();
    }

    function unpause() external onlyOwner notSealed {
        _unpause();
    }

    function sealContract() external onlyOwner {
        contractSealed = true;
        emit ContractSealed();
    }

    
    /***********************************|
    |              Modifier             |
    |__________________________________*/

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }
}