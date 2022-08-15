// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
 
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";
 
contract Astrobabies is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
 
    enum State {
        Setup,
        PreSale,
        PublicSale,
        Finished
    }
 
    State private _state;
    uint256 private mintPrice = 0.02 ether;
    uint256 private maxSupply = 8880;
    uint256 private mintLimit = 10;
    string private baseTokenUri;
    bool private revealed = false;
    mapping(address => bool) private whitelistedUsers;
    string private unRevealUri;
 
    constructor(
        string memory name_,
        string memory symbol_,
        string memory unRevealUri_,
        string memory baseTokenUri_
    ) ERC721A (
        name_,
        symbol_
    ) {
        _state = State.Setup;
        unRevealUri = unRevealUri_;
        baseTokenUri = baseTokenUri_;
    }
 
    function setBaseTokenUri(string memory baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function setUnRevealUrl(string memory revealUri_) external onlyOwner {
        unRevealUri = revealUri_;
    }
    
    function revealCollection() external onlyOwner{
        revealed = true;
    }
 
    function tokenURI(uint256 tokenId_) public view override(ERC721A) returns (string memory ) {
        if (!_exists(tokenId_)) revert URIQueryForNonexistentToken(); 
        if (revealed == true) {
            return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
       } else {
           return unRevealUri;
       }
    }
 
    function withdrawAll(address recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
    }
 
    function setStateToSetup() external onlyOwner {
        _state = State.Setup;
    }
   
    function startPreSale() external onlyOwner {
        _state = State.PreSale;
    }
 
    function startPublicSale() external onlyOwner {
        _state = State.PublicSale;
    }
   
    function finishSale() external onlyOwner {
        _state = State.Finished;
    }
 
    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }
 
    function getMaxSupply() public view returns(uint256) {
        return maxSupply;
    }
 
    function setMintLimit(uint256 limit) external onlyOwner {
        mintLimit = limit;
    }
 
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }
 
    function getMintPrice() public view returns(uint256) {
        if (_state == State.PreSale) {
            return 0;
        }
        return mintPrice;
    }
 
    function isWhitelisted(address user) public view virtual returns (bool) {
        return whitelistedUsers[user];
    }
 
    function whitelistUser(address user) public onlyOwner {
        whitelistedUsers[user] = true;
    }
 
    function getMintLimit() public view returns(uint256) {
        return mintLimit;
    }
 
    function mint(
        uint256 amount
    ) external payable nonReentrant {
        require(_state != State.Setup, "Minting hasn't started yet.");
        require(_state != State.Finished, "Minting is closed.");
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint."
        );
        if (_state == State.PreSale) {
            require(
                whitelistedUsers[msg.sender] == true,
                "You're not whitelisted."
            );
            require(
                balanceOf(msg.sender) + amount <= 2,
                "Mint limit exceeded for Presale."
            );
            require(
                _totalMinted() + amount <= 1110,
                "Max Presale supply reached."
            );
            _safeMint(msg.sender, amount);
        } else {
            require(
                balanceOf(msg.sender) + amount <= mintLimit,
                "Mint limit exceeded."
            );
            require(
                _totalMinted() + amount <= maxSupply,
                "Amount should not exceed max supply."
            );
            require(
                amount * mintPrice <= msg.value,
                "Insuficient ETH to mint."
            );
            _safeMint(msg.sender, amount);
        }
    }
 
    function airDrop(address[] memory recipients, uint256[] memory numberOfTokensPerWallet, uint256 numberOfTokensToAirdrop) public onlyOwner {
        require(
            recipients.length == numberOfTokensPerWallet.length,
            "Different array sizes"
        );
 
        require(
            _totalMinted() + numberOfTokensToAirdrop <= maxSupply,
            "Exceeded max supply"
        );
 
        for (uint256 i=0; i<recipients.length; i++) {
            address recipient = recipients[i];
            _safeMint(recipient, numberOfTokensPerWallet[i]);
        }
    }
 }