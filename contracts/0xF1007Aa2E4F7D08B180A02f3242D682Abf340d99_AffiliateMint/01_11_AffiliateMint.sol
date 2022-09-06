//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title Affiliate DAO Membership Mint
/// @author WhiteOakKong - 0nyX Labs
/// @notice This contract is the first iteration of the Affiliate DAO Partner Protocol
///          Smart Contracts with On-chain affiliate rewards tracking.

contract AffiliateMint is ERC1155, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;

    uint256 public constant MENTOR = 0;
    uint256 public constant MEMBER = 1;

    uint256 public constant MENTOR_MAX_SUPPLY = 75;
    uint256 public memberMaxSupply = 3000;

    uint256 public constant AFFILIATE_REWARD_PRIMARY = 125;
    uint256 public constant AFFILIATE_REWARD_SECONDARY = 50;
    uint256 private constant AFFILIATE_REWARD_DENOMINATOR = 1000;

    uint256 public earlySalePrice = 0.47 ether;
    uint256 public salePrice = 0.7 ether;

    uint256 public totalSupplyMember;
    uint256 public totalSupplyMentor;

    bool public isPublicSaleActive;

    bool public saleLock;
    bool public permaLock;

    mapping(address => uint256) public userTotalRewards;
    mapping(address => uint256) public userRewardsClaimed;

    mapping(uint256 => string) public tokenURI;

    uint256 public totalRewards;
    uint256 public claimedRewards;

    uint256 public unlockTime;

    address public vault = 0xB1486965829e6574d2E6EF6564021982949d8502;

    event AffMint(uint256 indexed quantity, string clickid);

    receive() external payable {}

    // ============ Modifiers ============

    /// @notice This modifier controls ability to complete a mint based on contract status and supply.
    /// @dev requires public sale to be opened and max supply not reached for tokenId 1
    modifier canMint(uint256 quantity) {
        require(isPublicSaleActive, "Sale is not active");
        require(totalSupplyMember + quantity <= memberMaxSupply, "Not enough remaining to mint");
        _;
    }

    /// @notice This modifier confirms receipt of funds.
    /// @dev requires earlySalePrice to be sent if supply < 1251, or salePrice aftert that condition has been met.
    modifier isCorrectPayment(uint256 quantity) {
        if (totalSupplyMember + quantity < 1251) {
            require(earlySalePrice * quantity == msg.value, "Incorrect ETH value sent");
        } else if (totalSupplyMember > 1250) {
            require(salePrice * quantity == msg.value, "Incorrect ETH value sent");
        } else {
            uint256 num = quantity - (1250 - totalSupplyMember);
            uint256 earlyNum = quantity - num;
            require(
                ((salePrice * num) + (earlyNum * earlySalePrice)) == msg.value,
                "Incorrect ETH value sent"
            );
        }
        _;
    }

    ///@notice This modifier ensures that the minter is not being credited for affiliate rewards.
    ///@dev Not effective using crossmint - but parameters are not as easily manipulated in that situation.
    modifier affiliateNotSender(address _affiliate, address _secondary) {
        require(_affiliate != msg.sender, "Affiliate cannot be sender.");
        require(_secondary != msg.sender, "Affiliate cannot be sender.");
        _;
    }

    ///@notice This modifier controls withdrawl of affiliate owed funds.
    ///@dev unlockTime set in constructor.
    modifier withdrawUnlocked() {
        require(
            block.timestamp >= unlockTime,
            "affiliate withdrawl period is still active, funds cannot be withdrawn."
        );
        _;
    }

    ///@notice constructor to set contract upon deployment.
    ///@dev sets name, symbol, unlockTime, and locks sales.
    constructor() ERC1155("") {
        name = "Affiliate DAO";
        symbol = "AFFILIATE";
        setUnlockTime(90);
        lockSales();
    }

    // ============ Public Write Functions ============

    ///@notice mint function with primary and secondary affiliate tracking.
    ///@dev Calculates and stores rewards for each affiliate.
    ///@dev Emits AffMint Event which is indexed in off-chain affiliate tracking software.
    ///@param affiliate Address of primary affiliate.
    ///@param secondaryAffiliate Address of secondary affiliate.
    ///@param clickid Anique string passed through contract and utilized by off-chain tracking software.
    function affiliateMint(
        uint256 quantity,
        address affiliate,
        address secondaryAffiliate,
        string calldata clickid
    )
        external
        payable
        affiliateNotSender(affiliate, secondaryAffiliate)
        nonReentrant
        isCorrectPayment(quantity)
        canMint(quantity)
    {
        unchecked {
            totalSupplyMember += quantity;
        }
        _mint(msg.sender, 1, quantity, "");
        uint256 primaryReward = (msg.value * AFFILIATE_REWARD_PRIMARY) /
            AFFILIATE_REWARD_DENOMINATOR;
        uint256 secondaryReward = (msg.value * AFFILIATE_REWARD_SECONDARY) /
            AFFILIATE_REWARD_DENOMINATOR;
        unchecked {
            userTotalRewards[affiliate] += primaryReward;
            userTotalRewards[secondaryAffiliate] += secondaryReward;
            totalRewards += (primaryReward + secondaryReward);
        }
        emit AffMint(quantity, clickid);
    }

    ///@notice Mint function with only a primary affiliate.
    ///@dev Zero address fed into affiliateNotSender modifier for secondary affiliate.
    ///@dev Emits AffMint Event which is indexed in off-chain affiliate tracking software.
    function primaryOnlyMint(
        uint256 quantity,
        address affiliate,
        string calldata clickid
    )
        external
        payable
        affiliateNotSender(affiliate, address(0))
        nonReentrant
        isCorrectPayment(quantity)
        canMint(quantity)
    {
        unchecked {
            totalSupplyMember += quantity;
        }
        _mint(msg.sender, 1, quantity, "");
        uint256 primaryReward = (msg.value * AFFILIATE_REWARD_PRIMARY) /
            AFFILIATE_REWARD_DENOMINATOR;
        unchecked {
            userTotalRewards[affiliate] += primaryReward;
            totalRewards += primaryReward;
        }
        emit AffMint(quantity, clickid);
    }

    ///@notice mint function with no affiliates attached.
    ///@dev No data related to affiliate is stored on-chain, and no event is emitted.
    function nonAffiliateMint(uint256 quantity)
        external
        payable
        nonReentrant
        isCorrectPayment(quantity)
        canMint(quantity)
    {
        unchecked {
            totalSupplyMember += quantity;
        }
        _mint(msg.sender, 1, quantity, "");
    }

    ///@notice Mint function to allow credit card payments via Cross Mint
    ///@dev msg.sender is crossmint minting account, token minted to minter.
    ///@dev Must input both affiliate addresses even if no affiliate. Zero address will be used for no data.
    function crossmintMint(
        uint256 quantity,
        address minter,
        address affiliate,
        address secondaryAffiliate,
        string calldata clickid
    ) external payable isCorrectPayment(quantity) canMint(quantity) {
        require(
            msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
            "This function is for Crossmint only."
        );
        unchecked {
            totalSupplyMember += quantity;
        }
        _mint(minter, 1, quantity, "");
        if (affiliate != address(0)) {
            uint256 primaryReward = (msg.value * AFFILIATE_REWARD_PRIMARY) /
                AFFILIATE_REWARD_DENOMINATOR;
            unchecked {
                userTotalRewards[affiliate] += primaryReward;
                totalRewards += primaryReward;
            }
        }
        if (secondaryAffiliate != address(0)) {
            uint256 secondaryReward = (msg.value * AFFILIATE_REWARD_SECONDARY) /
                AFFILIATE_REWARD_DENOMINATOR;
            unchecked {
                userTotalRewards[secondaryAffiliate] += secondaryReward;
                totalRewards += secondaryReward;
            }
        }
        emit AffMint(quantity, clickid);
    }

    ///@notice Claim function for affiliates to claim rewards.
    ///@dev Does not reduce total rewards, instead increases claimed rewards.
    function collectAffiliateRewards() external nonReentrant {
        uint256 balance = userTotalRewards[msg.sender] - userRewardsClaimed[msg.sender];
        claimedRewards += balance;
        userRewardsClaimed[msg.sender] += balance;
        payable(msg.sender).transfer(balance);
    }

    // ============ Read Functions ============

    ///@notice Calculates unclaimed affiliate rewards for param affiliate.
    function getUnclaimedAffiliateReward(address affiliate) external view returns (uint256) {
        return userTotalRewards[affiliate] - userRewardsClaimed[affiliate];
    }

    ///@notice Calculates total unclaimed rewards for the contract.
    ///@dev Public
    function getUnclaimedRewards() public view returns (uint256) {
        return totalRewards - claimedRewards;
    }

    ///@notice return URI for token
    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI[_id];
    }

    ///@notice withdraws all funds to msg.sender. Cannot be called if unlockTime has not passed.
    function withdraw() public onlyOwner withdrawUnlocked {
        uint256 balance = address(this).balance;
        (bool callSuccess, ) = payable(vault).call{value: balance}("");
        require(callSuccess, "Call failed");
    }

    ///@notice withdraws all funds minus unclaimed affiliate rewards to msg.sender.
    function withdrawMinusRewards() external onlyOwner {
        uint256 balance = address(this).balance - getUnclaimedRewards();
        (bool callSuccess, ) = payable(vault).call{value: balance}("");
        require(callSuccess, "Call failed");
    }

    ///@notice standard setApprovalForAll with addition of a locking mechanism
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(!saleLock, "Sales are currently locked, you cannot approve this contract");
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    // ============ Owner Restricted Functions ============

    ///@notice Basic owner minting function. For Member tokens only.
    function ownerMint(uint256 quantity) external nonReentrant onlyOwner canMint(quantity) {
        totalSupplyMember += quantity;
        _mint(msg.sender, 1, quantity, "");
    }

    ///@notice Airdrop function for Mentor Tokens.
    function mentorAirdrop(address[] calldata addresses) external onlyOwner {
        require(
            MENTOR_MAX_SUPPLY >= totalSupplyMentor + addresses.length,
            "Cannot exceed max supply"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], 0, 1, "");
        }
        totalSupplyMentor += addresses.length;
    }

    ///@notice Sets tokenURI for individual token
    ///@dev No base URI; each token set individually
    function setURI(string memory _uri, uint256 tokenId) external onlyOwner {
        tokenURI[tokenId] = _uri;
    }

    ///@notice sets time to unlock access to affiliate rewards by contract owner
    function setUnlockTime(uint256 _days) public onlyOwner {
        require((block.timestamp + (_days * 1 days)) > unlockTime);
        unlockTime = block.timestamp + (_days * 1 days);
    }

    ///@notice Locks token sales until unlocked by contract owner. Can only be called once.
    ///@dev Controls sales by disabling approvals. Tokens can still be transferred.
    function lockSales() public onlyOwner {
        require(!permaLock, "The ability to lock sales has been permanently turned off");
        saleLock = true;
        permaLock = true;
    }

    ///@notice unlocks token sales
    function unlockSales() external onlyOwner {
        saleLock = false;
    }

    ///@notice toggles isPublicSaleActive
    function toggleSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    ///@notice reduce supply if necessary
    function reduceMaxSupply(uint256 maxSupply) external onlyOwner {
        require(
            maxSupply >= totalSupplyMember && maxSupply < memberMaxSupply,
            "You cannot reduce max supply below current supply, or raise it above the current max supply"
        );
        memberMaxSupply = maxSupply;
    }

    ///@notice adjust pricing if necessary
    ///@dev enter _type 0 to adjust earlySalePrice, else salePrice will be adjusted
    function updatePrice(uint256 price, uint256 _type) external onlyOwner {
        if (_type == 0) earlySalePrice = price;
        else salePrice = price;
    }
}