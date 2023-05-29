// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";

contract InkePass is Ownable, ReentrancyGuard, Pausable, ERC721A {
    event BaseURIChanged(string url);
    event WhitelistSaleConfigChanged(WhitelistSaleConfig config, bytes32 root);
    event MerkleRootChanged(bytes32 root);
    event PublicSaleConfigChanged(PublicSaleConfig config);
    event Withdraw(address indexed account, uint256 amount);
    event Refund(address indexed account, uint256 tokenId, uint256 amount);
    event ContractSealed();

    /**
     * @notice for security reasons, CA is not allowed to call sensitive methods.
     */
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }

    struct WhitelistSaleConfig {
        uint64 mintQuota;           // whitelist allow mint quota
        uint256 firstStartTime;     // first start time
        uint256 firstEndTime;       // first end time
        uint256 secondStartTime;    // second start time
        uint256 secondEndTime;      // second end time
        uint256 price;              // sale price, Unit: wei
    }

    struct PublicSaleConfig {
        uint256 startTime;
        uint256 price;
    }

    bool public contractSealed = false;

    WhitelistSaleConfig public whitelistSaleConfig;
    PublicSaleConfig public publicSaleConfig;
    bytes32 public merkleRoot;                      // merkle root for whitelist checking
    uint64 public maxSupply = 1;                    // The maximum number of tokens in this total mint
    uint64 public saleSupply = 1;                   // The maximum number of tokens in this sale mint
    uint64 public selfSupply = 1;                   // The maximum number of tokens in this self mint
    uint64 public selfMinted = 0;                   // The self minted number of tokens
    string public preURI = "";                      // The NFT base uri

    // mint State Variables
    mapping(uint256=>uint256) tokenSalePrices; // Token price map

    // refund config
    uint256 public constant refundPeriod = 30 days; // Refund period
    address public refundAddress;
    // refund State Variables
    mapping(uint256 => bool) public hasRefunded;    // One token can only be refunded once

    constructor(uint64 saleSupply_, uint64 selfSupply_, string memory url_) ERC721A("INKEPASS", "IPT") {
        saleSupply = saleSupply + saleSupply_;
        selfSupply = selfSupply + selfSupply_;
        maxSupply = maxSupply + saleSupply_ + selfSupply_; // value = 1 + origin value
        preURI = url_;

        refundAddress = msg.sender;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return preURI;
    }

    function setBaseURI(string calldata url_) external onlyOwner {
        preURI = url_;
        emit BaseURIChanged(url_);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }
    function totalSale() public view returns (uint256) {
        return _totalMinted() - selfMinted;
    }

    /***********************************|
    |               Config              |
    |__________________________________*/

    // whitelist sale config
    function isWhitelistAddress(address address_, bytes32[] calldata signature_) public view returns (bool) {
        if (merkleRoot == "") {
            return false;
        }
        return MerkleProof.verify(
            signature_,
            merkleRoot,
            keccak256(abi.encodePacked(address_))
        );
    }

    function isWhitelistSaleEnabled() public view returns (bool) {
        return isFirstWhitelistSaleEnabled() || isSecondWhitelistSaleEnabled();
    }

    // first whitelist sale
    function isFirstWhitelistSaleEnabled() public view returns (bool) {
        if (whitelistSaleConfig.firstEndTime > 0 && block.timestamp > whitelistSaleConfig.firstEndTime) {
            return false;
        }
        return whitelistSaleConfig.firstStartTime > 0 &&
        block.timestamp > whitelistSaleConfig.firstStartTime &&
        whitelistSaleConfig.price > 0 &&
        merkleRoot != "";
    }

    // second whitelist sale
    function isSecondWhitelistSaleEnabled() public view returns (bool) {
        if (whitelistSaleConfig.secondEndTime > 0 && block.timestamp > whitelistSaleConfig.secondEndTime) {
            return false;
        }
        return whitelistSaleConfig.secondStartTime > 0
        && block.timestamp > whitelistSaleConfig.secondStartTime &&
        whitelistSaleConfig.price > 0 &&
        merkleRoot != "";
    }

    function getWhitelistSalePrice() public view returns (uint256) {
        return whitelistSaleConfig.price;
    }

    function setWhitelistSaleConfig(WhitelistSaleConfig calldata config_, bytes32 root_) external onlyOwner {
        require(config_.price > 0, "sale price must greater than zero");
        whitelistSaleConfig = config_;
        merkleRoot = root_;
        emit WhitelistSaleConfigChanged(config_, root_);
    }

    function setMerkleRoot(bytes32 root_) external onlyOwner {
        merkleRoot = root_;
        emit MerkleRootChanged(root_);
    }

    // public sale config
    function isPublicSaleEnabled() public view returns (bool) {
        return publicSaleConfig.startTime > 0 &&
        block.timestamp > publicSaleConfig.startTime &&
        publicSaleConfig.price > 0;
    }

    function getPublicSalePrice() public view returns (uint256) {
        return publicSaleConfig.price;
    }

    function setPublicSaleConfig(PublicSaleConfig calldata config_) external onlyOwner {
        require(config_.price > 0, "sale price must greater than zero");
        publicSaleConfig = config_;
        emit PublicSaleConfigChanged(config_);
    }

    // refund config
    function isRefundEnabled() public view returns (bool) {
        return isPublicSaleEnabled() &&
            block.timestamp < publicSaleConfig.startTime + refundPeriod;
    }
    function setRefundAddress(address refundAddress_) external onlyOwner {
        refundAddress = refundAddress_;
    }

    /***********************************|
    |               Core                |
    |__________________________________*/

    // The maximum number of mint tokens allowed selfSupply
    function selfMint(uint64 numberOfTokens_) external onlyOwner nonReentrant {
        require(numberOfTokens_ > 0, "invalid number of tokens");
        require(numberOfTokens_ < selfSupply, "can only mint max self supply at a time");
        uint64 nextMinted = selfMinted + numberOfTokens_;
        require(nextMinted < selfSupply, "max self supply exceeded");
        _mint(_msgSender(), numberOfTokens_);
        selfMinted = nextMinted;
    }

    // Only one token can be mint at a time
    function whitelistSale(bytes32[] calldata signature_) external payable callerIsUser nonReentrant {
        require(isWhitelistSaleEnabled(), "whitelist sale has not enabled");
        require(isWhitelistAddress(_msgSender(), signature_), "caller is not in whitelist or invalid signature");
        require(_getAux(_msgSender()) < 1, "max mint 1 amount for per wallet exceeded");
        require(totalMinted() < whitelistSaleConfig.mintQuota + selfMinted, "max mint amount for whitelist exceeded");
        _sale(1, getWhitelistSalePrice());
        _setAux(_msgSender(), 1);
    }

    function publicSale(uint64 numberOfTokens_) external payable callerIsUser nonReentrant {
        require(isPublicSaleEnabled(), "public sale has not enabled");
        _sale(numberOfTokens_, getPublicSalePrice());
    }

    function refund(uint256 tokenId) external callerIsUser nonReentrant {
        require(msg.sender == ownerOf(tokenId), "Not token owner");
        require(!hasRefunded[tokenId], "Already refunded");
        require(isRefundEnabled(), "Outside the refundable period");
        uint256 tokenPrice = tokenSalePrices[tokenId];
        require(tokenPrice > 0, "Not sale token");
        transferFrom(msg.sender, refundAddress, tokenId);
        Address.sendValue(payable(msg.sender), tokenPrice);
        hasRefunded[tokenId] = true;
        emit Refund(_msgSender(), tokenId, tokenPrice);
    }

    // The maximum number of mint tokens allowed 2 per/token
    // The maximum number of mint tokens allowed saleSupply
    function _sale(uint64 numberOfTokens_, uint256 price_) internal {
        require(numberOfTokens_ > 0, "invalid number of tokens");
        require(numberOfTokens_ < 3, "can only mint 2 tokens at a time");
        require(totalMinted() + numberOfTokens_ < saleSupply + selfMinted, "max sale supply exceeded");
        uint256 amount = price_ * numberOfTokens_;
        require(amount <= msg.value, "ether value sent is not correct");
        _safeMint(_msgSender(), numberOfTokens_);
        _setSaleState(numberOfTokens_, price_);
        refundExcessPayment(amount);
    }
    function _setSaleState(uint256 numberOfTokens_, uint256 price_) internal{
        if (numberOfTokens_ == 1) {
            tokenSalePrices[totalMinted()] = price_;
        } else {
            tokenSalePrices[totalMinted()] = price_;
            tokenSalePrices[totalMinted()-1] = price_;
        }
    }

    /**
     * @notice when the amount paid by the user exceeds the actual need, the refund logic will be executed.
     * @param amount_ the actual amount that should be paid
     */
    function refundExcessPayment(uint256 amount_) private {
        if (msg.value > amount_) {
            payable(_msgSender()).transfer(msg.value - amount_);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |               Pause               |
    |__________________________________*/

    /**
     * @notice hook function, used to intercept the transfer of token.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "token transfer paused");
    }

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external onlyOwner notSealed {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner notSealed {
        _unpause();
    }

    /**
     * @notice when the project is stable enough, the issuer will call sealContract
     * to give up the permission to call emergencyPause and unpause.
     */
    function sealContract() external onlyOwner {
        contractSealed = true;
        emit ContractSealed();
    }
}