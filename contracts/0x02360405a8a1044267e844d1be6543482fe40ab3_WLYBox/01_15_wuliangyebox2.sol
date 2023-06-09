// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

pragma solidity ^0.8.7;

abstract contract WLYInterface {
    function mint(address address_, uint256 tokenId_) public virtual returns (uint256);
}

contract WLYBox is ERC721, Ownable, Pausable, ReentrancyGuard {
    event BaseURIChanged(string newBaseURI);
    event WhitelistSaleConfigChanged(WhitelistSaleConfig config);
    event PublicSaleConfigChanged(PublicSaleConfig config);
    event RevealConfigChanged(RevealConfig config);
    event Withdraw(address indexed account, uint256 amount);
    event ContractSealed();

    struct WhitelistSaleConfig {
        uint64 mintQuota;
        uint256 startTime;
        uint256 endTime;
        bytes32 merkleRoot;
        uint256 price;
    }

    struct WaitlistSaleConfig {
        uint64 mintQuota;
        uint256 startTime;
        uint256 endTime;
        bytes32 merkleRoot;
        uint256 price;
    }


    struct PublicSaleConfig {
        uint256 startTime;
        uint256 price;
        uint64 mintQuota;
    }
    struct RevealConfig {
        uint64 startTime;
        address wlyContractAddress;
    }

    struct AirdropConfig {
        address airdropAddress;
        uint64 num;
    }

    uint256 public MAX_TOKEN = 3000;
    uint256 public totalMinted=0;
    bool public contractSealed;
    string public baseURI;
    mapping(address=>uint256) userMintCount;
    WhitelistSaleConfig public whitelistSaleConfig;
    WaitlistSaleConfig public waitlistSaleConfig;
    PublicSaleConfig public publicSaleConfig;
    RevealConfig public revealConfig;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(string memory baseURI_, WhitelistSaleConfig memory whiteSaleConfig_) ERC721("Wuliangye NFT", "WLY") {
        baseURI = baseURI_;
        whitelistSaleConfig = whiteSaleConfig_;
    }

    function giveaway(AirdropConfig[] memory air) external onlyOwner nonReentrant {
        for (uint256 j;j<air.length;j++){
            require(air[j].airdropAddress != address(0), "zero address");
            require(air[j].num > 0, "invalid number of tokens");
            require(totalMinted + air[j].num <= MAX_TOKEN, "max supply exceeded");
            for(uint64 i=0;i<air[j].num;i++){
                mintNFT(air[j].airdropAddress);
            }
        }
    }

    function whitelistSale(bytes32[] calldata signature_) external payable callerIsUser nonReentrant {
        require(isWhitelistSaleEnabled(), "whitelist sale has not enabled");
        require(isWhitelistAddress(_msgSender(), signature_), "caller is not in whitelist or invalid signature");
        require(userMintCount[_msgSender()] < whitelistSaleConfig.mintQuota, "every account max supply exceeded");
        _sale(getWhitelistSalePrice());
    }

    function waitlistSale(bytes32[] calldata signature_) external payable callerIsUser nonReentrant {
        require(isWaitlistSaleEnabled(), "waitlist sale has not enabled");
        require(isWaitlistAddress(_msgSender(), signature_), "caller is not in waitlist or invalid signature");
        require(userMintCount[_msgSender()] < waitlistSaleConfig.mintQuota, "every account max supply exceeded");
        _sale(getWaitlistSalePrice());
    }

    function publicSale() external payable callerIsUser nonReentrant {
        require(isPublicSaleEnabled(), "public sale has not enabled");
        require(userMintCount[_msgSender()] < publicSaleConfig.mintQuota, "every account max supply exceeded");
        _sale(getPublicSalePrice());
    }

    function _sale(uint256 price_) internal {
        require(totalMinted+1 <= MAX_TOKEN, "max supply exceeded");
        require(price_ <= msg.value, "ether value sent is not correct");
        mintNFT(_msgSender());
    }
    function mintNFT(address to) internal {
        totalMinted++;
        userMintCount[_msgSender()]+=1;
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function reveal(uint256 tokenId_) external callerIsUser nonReentrant returns (uint256) {
        require(isRevealEnabled(), "reveal has not enabled");
        require(ownerOf(tokenId_) == _msgSender(), "caller is not owner");
        _burn(tokenId_);
        WLYInterface wlyContract = WLYInterface(revealConfig.wlyContractAddress);
        uint256 wlyTokenId = wlyContract.mint(_msgSender(), tokenId_);
        return wlyTokenId;
    }

    function withdraw(uint256 _amount) external onlyOwner nonReentrant {
        payable(_msgSender()).transfer(_amount);
        emit Withdraw(_msgSender(), _amount);
    }

    function isWhitelistSaleEnabled() public view returns (bool) {
        if (whitelistSaleConfig.endTime > 0 && block.timestamp > whitelistSaleConfig.endTime) {
            return false;
        }
        return whitelistSaleConfig.startTime > 0 &&
        block.timestamp > whitelistSaleConfig.startTime &&
        whitelistSaleConfig.price > 0 &&
        whitelistSaleConfig.merkleRoot != "";
    }

    function isWaitlistSaleEnabled() public view returns (bool) {
        if (waitlistSaleConfig.endTime > 0 && block.timestamp > waitlistSaleConfig.endTime) {
            return false;
        }
        return waitlistSaleConfig.startTime > 0 &&
        block.timestamp > waitlistSaleConfig.startTime &&
        waitlistSaleConfig.price > 0 &&
        waitlistSaleConfig.merkleRoot != "";
    }

    function isRevealEnabled() public view returns (bool) {
        return revealConfig.startTime > 0 &&
        block.timestamp > revealConfig.startTime &&
        revealConfig.wlyContractAddress != address(0);
    }

    function isWhitelistAddress(address address_, bytes32[] calldata signature_) public view returns (bool) {
        if (whitelistSaleConfig.merkleRoot == "") {
            return false;
        }
        return MerkleProof.verify(
            signature_,
            whitelistSaleConfig.merkleRoot,
            keccak256(abi.encodePacked(address_))
        );
    }

    function isWaitlistAddress(address address_, bytes32[] calldata signature_) public view returns (bool) {
        if (waitlistSaleConfig.merkleRoot == "") {
            return false;
        }
        return MerkleProof.verify(
            signature_,
            waitlistSaleConfig.merkleRoot,
            keccak256(abi.encodePacked(address_))
        );
    }

    function getWhitelistSalePrice() public view returns (uint256) {
        return whitelistSaleConfig.price;
    }
    function getWaitlistSalePrice() public view returns (uint256) {
        return waitlistSaleConfig.price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    function setWhitelistSaleConfig(WhitelistSaleConfig calldata config_) external onlyOwner {
        require(config_.price > 0, "sale price must greater than zero");
        whitelistSaleConfig = config_;
        emit WhitelistSaleConfigChanged(config_);
    }

    function setWaitlistSaleConfig(WaitlistSaleConfig calldata config_) external onlyOwner {
        require(config_.price > 0, "sale price must greater than zero");
        waitlistSaleConfig = config_;
    }

    function setPublicSaleConfig(PublicSaleConfig calldata config_) external onlyOwner {
        require(config_.price > 0, "sale price must greater than zero");
        publicSaleConfig = config_;
        emit PublicSaleConfigChanged(config_);
    }

    function setRevealConfig(RevealConfig calldata config_) external onlyOwner {
        revealConfig = config_;
        emit RevealConfigChanged(config_);
    }

    function isPublicSaleEnabled() public view returns (bool) {
        return publicSaleConfig.startTime > 0 &&
        block.timestamp > publicSaleConfig.startTime &&
        publicSaleConfig.price > 0;
    }

    function getPublicSalePrice() public view returns (uint256) {
        return publicSaleConfig.price;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 startTokenId
    ) internal override{
        super._beforeTokenTransfer(from, to, startTokenId);
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

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }
}