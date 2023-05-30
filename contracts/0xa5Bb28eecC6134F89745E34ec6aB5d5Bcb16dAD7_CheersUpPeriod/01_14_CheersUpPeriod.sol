// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol"; 

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

abstract contract CheersUpInterface {
    function mint(address address_, uint256 cucpTokenId_)
        public
        virtual
        returns (uint256);
}

/**
 * @title CheersUpPeriod
 * @author BaseLabs
 */
contract CheersUpPeriod is ERC721A, Ownable, Pausable, ReentrancyGuard {
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
    struct PublicSaleConfig {
        uint256 startTime;
        uint256 price;
    }
    struct RevealConfig {
        uint64 startTime;
        address cheersUpContractAddress;
    }

    uint64 public constant MAX_TOKEN = 10000;
    uint64 public constant MAX_TOKEN_PER_MINT = 3;
    WhitelistSaleConfig public whitelistSaleConfig;
    PublicSaleConfig public publicSaleConfig;
    RevealConfig public revealConfig;
    bool public contractSealed;

    string public baseURI;

    constructor(string memory baseURI_, WhitelistSaleConfig memory whiteSaleConfig_) ERC721A("Cheers UP Period", "CUP") {
        baseURI = baseURI_;
        whitelistSaleConfig = whiteSaleConfig_;
    }

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice giveaway is used for airdropping to specific addresses.
     * The issuer also reserves tokens through this method.
     * This process is under the supervision of the community.
     * @param address_ the target address of airdrop
     * @param numberOfTokens_ the number of airdrop
     */
    function giveaway(address address_, uint64 numberOfTokens_) external onlyOwner nonReentrant {
        require(address_ != address(0), "zero address");
        require(numberOfTokens_ > 0, "invalid number of tokens");
        require(totalMinted() + numberOfTokens_ <= MAX_TOKEN, "max supply exceeded");
        _safeMint(address_, numberOfTokens_);
    }

    /**
     * @notice whitelistSale is used for whitelist sale.
     * @param numberOfTokens_ quantity
     * @param signature_ merkel proof
     */
    function whitelistSale(uint64 numberOfTokens_, bytes32[] calldata signature_) external payable callerIsUser nonReentrant {
        require(isWhitelistSaleEnabled(), "whitelist sale has not enabled");
        require(isWhitelistAddress(_msgSender(), signature_), "caller is not in whitelist or invalid signature");
        uint64 whitelistMinted = _getAux(_msgSender()) + numberOfTokens_;
        require(whitelistMinted <= whitelistSaleConfig.mintQuota, "max mint amount per wallet exceeded");
        _sale(numberOfTokens_, getWhitelistSalePrice());
        _setAux(_msgSender(), whitelistMinted);
    }

    /**
     * @notice publicSale is used for public sale.
     * @param numberOfTokens_ quantity
     */
    function publicSale(uint64 numberOfTokens_) external payable callerIsUser nonReentrant {
        require(isPublicSaleEnabled(), "public sale has not enabled");
        _sale(numberOfTokens_, getPublicSalePrice());
    }

    /**
     * @notice internal method, _sale is used to sell tokens at the specified unit price.
     * @param numberOfTokens_ quantity
     * @param price_ unit price
     */
    function _sale(uint64 numberOfTokens_, uint256 price_) internal {
        require(numberOfTokens_ > 0, "invalid number of tokens");
        require(numberOfTokens_ <= MAX_TOKEN_PER_MINT, "can only mint MAX_TOKEN_PER_MINT tokens at a time");
        require(totalMinted() + numberOfTokens_ <= MAX_TOKEN, "max supply exceeded");
        uint256 amount = price_ * numberOfTokens_;
        require(amount <= msg.value, "ether value sent is not correct");
        _safeMint(_msgSender(), numberOfTokens_);
        refundExcessPayment(amount);
    }

    /**
     * @notice reveal is used to open the blind box.
     * @param tokenId_ tokenId of the blind box to be revealed.
     * @return tokenId after revealing the blind box.
     */
    function reveal(uint256 tokenId_) external callerIsUser nonReentrant returns (uint256) {
        require(isRevealEnabled(), "reveal has not enabled");
        require(ownerOf(tokenId_) == _msgSender(), "caller is not owner");
        _burn(tokenId_);
        CheersUpInterface cheersUpContract = CheersUpInterface(revealConfig.cheersUpContractAddress);
        uint256 cheerUpTokenId = cheersUpContract.mint(_msgSender(), tokenId_);
        return cheerUpTokenId;
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

    /**
     * @notice issuer withdraws the ETH temporarily stored in the contract through this method.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }


    /***********************************|
    |               Getter              |
    |__________________________________*/

    /**
     * @notice isWhitelistSaleEnabled is used to return whether whitelist sale has been enabled.
     */
    function isWhitelistSaleEnabled() public view returns (bool) {
        if (whitelistSaleConfig.endTime > 0 && block.timestamp > whitelistSaleConfig.endTime) {
            return false;
        }
        return whitelistSaleConfig.startTime > 0 && 
            block.timestamp > whitelistSaleConfig.startTime &&
            whitelistSaleConfig.price > 0 &&
            whitelistSaleConfig.merkleRoot != "";
    }

    /**
     * @notice isPublicSaleEnabled is used to return whether the public sale has been enabled.
     */
    function isPublicSaleEnabled() public view returns (bool) {
        return publicSaleConfig.startTime > 0 &&
            block.timestamp > publicSaleConfig.startTime &&
            publicSaleConfig.price > 0;
    }

    /**
     * @notice isRevealEnabled is used to return whether the reveal has been enabled.
     */
    function isRevealEnabled() public view returns (bool) {
        return revealConfig.startTime > 0 &&
            block.timestamp > revealConfig.startTime &&
            revealConfig.cheersUpContractAddress != address(0);
    }

    /**
     * @notice isWhitelistAddress is used to verify whether the given address_ and signature_ belong to merkleRoot.
     * @param address_ address of the caller
     * @param signature_ merkle proof
     */
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

    /**
     * @notice getPublicSalePrice is used to get the price of the public sale.
     * @return price
     */
    function getPublicSalePrice() public view returns (uint256) {
        return publicSaleConfig.price;
    }

    /**
     * @notice getWhitelistSalePrice is used to get the price of the whitelist sale.
     * @return price
     */
    function getWhitelistSalePrice() public view returns (uint256) {
        return whitelistSaleConfig.price;
    }

    /**
     * @notice totalMinted is used to return the total number of tokens minted. 
     * Note that it does not decrease as the token is burnt.
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @notice _baseURI is used to override the _baseURI method.
     * @return baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    /***********************************|
    |               Setter              |
    |__________________________________*/


    /**
     * @notice setBaseURI is used to set the base URI in special cases.
     * @param baseURI_ baseURI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }
    
    /**
     * @notice setWhitelistSaleConfig is used to set the configuration related to whitelist sale.
     * This process is under the supervision of the community.
     * @param config_ config
     */
    function setWhitelistSaleConfig(WhitelistSaleConfig calldata config_) external onlyOwner {
        require(config_.price > 0, "sale price must greater than zero");
        whitelistSaleConfig = config_;
        emit WhitelistSaleConfigChanged(config_);
    }
    
    /**
     * @notice setPublicSaleConfig is used to set the configuration related to public sale.
     * This process is under the supervision of the community.
     * @param config_ config
     */
    function setPublicSaleConfig(PublicSaleConfig calldata config_) external onlyOwner {
        require(config_.price > 0, "sale price must greater than zero");
        publicSaleConfig = config_;
        emit PublicSaleConfigChanged(config_);
    }
    
    /**
     * @notice setRevealConfig is used to set the configuration related to reveal.
     * This process is under the supervision of the community.
     * @param config_ config
     */
    function setRevealConfig(RevealConfig calldata config_) external onlyOwner {
        revealConfig = config_;
        emit RevealConfigChanged(config_);
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


    /***********************************|
    |             Modifier              |
    |__________________________________*/

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
}