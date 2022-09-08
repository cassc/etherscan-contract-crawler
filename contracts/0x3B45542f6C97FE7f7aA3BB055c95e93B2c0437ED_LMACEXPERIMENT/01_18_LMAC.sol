// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
 
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "erc721a/contracts/ERC721A.sol";

contract LMACEXPERIMENT is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    uint256 public mintPrice = 0.05 ether;
    uint256 public LBACHoldersMintPrice = 0 ether;
    uint256 public maxSupply = 10000;
    uint256 public mintLimit = 20;
    string public baseTokenUri;
    bool public revealed = false;
    string public unRevealUri;
    Addresses public addresses;
    address[] private beneficiaries;
    SaleState public sale;

    mapping(address => claimingData) public claimingDetails;
    mapping(address => uint256) public LBACHoldersSupply;
 
    modifier rewardTime(address user) {
        require(block.timestamp >= claimingDetails[user].lastClaimed + 1 days, "Claim time hasn't passed yet.");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory unRevealUri_,
        string memory baseTokenUri_,
        address coinAddress,
        address coinOwnerAddress,
        address LBACCoinAddress,
        address lilBananaCoinAddress,
        address[] memory beneficiaries_
    ) ERC721A (
        name_,
        symbol_
    ) {
        sale = SaleState.Initial;
        unRevealUri = unRevealUri_;
        baseTokenUri = baseTokenUri_;
        beneficiaries = beneficiaries_;
        addresses = Addresses(coinAddress, coinOwnerAddress, LBACCoinAddress, lilBananaCoinAddress);
    }

    struct claimingData {
        uint256 lastClaimed;
        uint256 claimed;
    }

    struct Addresses {
        address coinAddress;
        address coinOwnerAddress;
        address NFTAddress;
        address lilBCoinAddress;
    }

    enum SaleState {
        Initial,
        StartSale,
        EndSale
    }

    function startSale() external onlyOwner {
        sale = SaleState.StartSale;
    }
   
    function EndSale() external onlyOwner {
        sale = SaleState.EndSale;
    }
 
    function setBaseTokenUri(string memory baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function setUnRevealUrl(string memory revealUri_) external onlyOwner {
        unRevealUri = revealUri_;
    }

    function changeBeneficiaries(address[] memory newBeneficiaries) external onlyOwner {
        beneficiaries = newBeneficiaries;
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
 
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        balance = balance / 3;
        for(uint256 i=0; i < beneficiaries.length;i++) {
            payable(beneficiaries[i]).transfer(balance);
        }
    }
 
    function changeMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }
 
    function setMintLimit(uint256 limit) external onlyOwner {
        mintLimit = limit;
    }
 
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setLBACHoldersMintPrice(uint256 price) external onlyOwner {
        LBACHoldersMintPrice = price;
    }
 
    function mint(
        uint256 amount
    ) external payable nonReentrant {
        require(
            sale == SaleState.StartSale,
            "Sale hasn't Started Yet."
        );
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint."
        );
        require(
            _totalMinted() + amount <= maxSupply,
            "Amount should not exceed max supply."
        );
        if (totalSupply() <= 5000) {
            require(
                amount <= mintLimit,
                "Mint limit exceeded."
            );
            require(
                amount * mintPrice <= msg.value,
                "Insuficient ETH to mint."
            );
            if(msg.value > amount * mintPrice) {
                payable(msg.sender).transfer(msg.value - (amount * mintPrice));
            }
        } else {
            require(
                LBACHoldersSupply[msg.sender] + amount <= ERC721(addresses.NFTAddress).balanceOf(msg.sender),
                "Not enough LBAC'S in your account"
            );
            require(
                amount * LBACHoldersMintPrice <= msg.value,
                "Insuficient ETH to mint."
            );
            LBACHoldersSupply[msg.sender] += amount; 
            if(msg.value > amount * LBACHoldersMintPrice) {
                payable(msg.sender).transfer(msg.value - (amount * LBACHoldersMintPrice));
            }
        }
        _safeMint(msg.sender, amount);
        claimingDetails[msg.sender].lastClaimed = block.timestamp;
        ERC20(addresses.coinAddress).transferFrom(addresses.coinOwnerAddress, msg.sender, amount * 1e18);
    }
    function pendingRewards() public view returns(uint256) {
        uint256 userBalance = ERC20(addresses.lilBCoinAddress).balanceOf(msg.sender);
        if (claimingDetails[msg.sender].lastClaimed == 0) {
            if (userBalance >= 1e18) {
            return userBalance;
            } else return 0;
        } else {
            uint256 totalReward = block.timestamp - claimingDetails[msg.sender].lastClaimed / 1 days;
            totalReward = (totalReward * 1e18) * userBalance;
            if (totalReward >= 1e18) {
                return totalReward;
            } else return 0;
        }
    }

    function claim() external nonReentrant rewardTime(msg.sender) {
        uint256 userBalance = ERC20(addresses.lilBCoinAddress).balanceOf(msg.sender);
        if (claimingDetails[msg.sender].lastClaimed == 0) {
            require(userBalance * 1e18 >= 1e18, "Not enough rewards to claim");
            claimingDetails[msg.sender].lastClaimed = block.timestamp;
            claimingDetails[msg.sender].claimed = userBalance * 1e18;
            ERC20(addresses.coinAddress).transferFrom(addresses.coinOwnerAddress, msg.sender, userBalance * 1e18);
        } else {
            uint256 totalReward = block.timestamp - claimingDetails[msg.sender].lastClaimed / 1 days;
            require((totalReward * 1e18) * userBalance >= 1e18, "Not enough rewards to claim");
            claimingDetails[msg.sender].lastClaimed = block.timestamp;
            claimingDetails[msg.sender].claimed = (totalReward * 1e18) * userBalance;
            ERC20(addresses.coinAddress).transferFrom(addresses.coinOwnerAddress, msg.sender, (totalReward * 1e18) * userBalance);
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