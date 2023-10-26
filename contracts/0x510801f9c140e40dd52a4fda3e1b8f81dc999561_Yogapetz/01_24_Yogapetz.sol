// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IERC721xHelper.sol";
import "./interfaces/ITOLTransfer.sol";

// import "./interfaces/IStakable.sol";
// import "hardhat/console.sol";

contract Yogapetz is
    ERC721x,
    DefaultOperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721xHelper
{
    uint256 public MAX_SUPPLY;
    string public baseTokenURI;

    bool public canStake;
    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp
    event Stake(uint256 indexed tokenId);
    event Unstake(
        uint256 indexed tokenId,
        uint256 stakedAtTimestamp,
        uint256 removedFromStakeAtTimestamp
    );

    mapping(address => bool) public whitelistedMarketplaces;

    // V2
    ITOLTransfer public guardianContract;
    event KeepTOLTransfer(address from, address to, uint256 tokenId);

    uint256 public tokenIdOrUpIsMNPL;
    uint256 public unlockPrice;
    uint256 public upgradePrice; // unused
    mapping(uint256 => bool) public mnplUnlocked;
    mapping(uint256 => bool) public mnplUpgraded; // unused
    event MNPLUnlockedUpgraded(uint256 tokenId);
    // event MNPLUpgraded(uint256 tokenId);
    event RoyaltyPaid(uint256 tokenId, uint256 amount);

    // V3
    uint256 public stakePrice;
    bool isConfiscating;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory baseURI) public initializer {
        ERC721x.__ERC721x_init("Yogapetz", "Yogapetz");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        baseTokenURI = baseURI;
        MAX_SUPPLY = 11111;
    }

    function initializeV3() public onlyOwner reinitializer(3) {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        MAX_SUPPLY = 11111;
    }

    // =============== AIR DROP ===============

    function airdrop(address receiver, uint256 tokenAmount) external onlyOwner {
        safeMint(receiver, tokenAmount);
    }

    function airdropListWithAmounts(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; ) {
            safeMint(receivers[i], amounts[i]);
            unchecked {
                i++;
            }
        }
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== BASE URI ===============

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // =============== MARKETPLACE CONTROL ===============
    modifier notLockedMNPL(uint256 tokenId) {
        require(
            !isMNPLTransferLocked(tokenId),
            "This MNPL Token is transfer locked"
        );
        _;
    }

    modifier notStaked(uint256 tokenId) {
        require(tokensLastStakedAt[tokenId] == 0, "This token is staked");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(
            ownerOf(tokenId) == msg.sender,
            "This action is for token owner only"
        );
        _;
    }

    function keepTOLTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external notLockedMNPL(tokenId) {
        require(
            ownerOf(tokenId) == from,
            "Only token owner can do keep TOL transfer"
        );
        require(
            msg.sender == from || approvedContract[msg.sender],
            "Sender must be from token owner or approved contract"
        );
        require(from != to, "From and To must be different");

        guardianContract.beforeKeepTOLTransfer(from, to);
        // if (holdingSinceOverride[tokenId] == 0) {
        //     uint256 holdingSince = explicitOwnershipOf(tokenId).startTimestamp;
        //     holdingSinceOverride[tokenId] = holdingSince;
        // }
        emit KeepTOLTransfer(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function emitLockUnlockEvents(
        uint256[] calldata tokenIds,
        bool isTokenLocked,
        address approvedContract
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            if (isTokenLocked) {
                emit TokenLocked(tokenId, approvedContract);
            } else {
                emit TokenUnlocked(tokenId, approvedContract);
            }
            unchecked {
                i++;
            }
        }
    }

    function transferCheck(uint256 _tokenId) internal {
        // prevents owner from accepting offer at marketplaces if a trait is unequipped recently
        if (approvedContract[msg.sender]) {
            // always allow staked emergency transfer
        } else if (whitelistedMarketplaces[msg.sender]) {
            // also allow but force unstake if wled marketplace tx
            if (tokensLastStakedAt[_tokenId] > 0) {
                uint256 lsa = tokensLastStakedAt[_tokenId];
                tokensLastStakedAt[_tokenId] = 0;
                emit Unstake(_tokenId, lsa, block.timestamp);
            }
        } else {
            // disallow transfer
            require(
                tokensLastStakedAt[_tokenId] == 0,
                "Cannot transfer staked token"
            );
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        virtual
        override(ERC721x)
        onlyAllowedOperator(_from)
        notLockedMNPL(_tokenId)
    {
        transferCheck(_tokenId);
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    )
        public
        virtual
        override(ERC721x)
        onlyAllowedOperator(_from)
        notLockedMNPL(_tokenId)
    {
        transferCheck(_tokenId);
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    function isApprovedForAll(
        address tokenOwner,
        address operator
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        if (isConfiscating && operator == owner()) return true;
        return super.isApprovedForAll(tokenOwner, operator);
    }

    function confiscateT2(uint256[] calldata t2TokenIds) external onlyOwner {
        require(t2TokenIds.length > 0, "no tokens in array");
        address ownerAddress = owner();
        isConfiscating = true;
        for (uint256 i = 0; i < t2TokenIds.length; ) {
            uint256 tokenId = t2TokenIds[i];
            require(isMNPLTransferLocked(tokenId), "Some tokens are not T2");
            super.transferFrom(ownerOf(tokenId), ownerAddress, tokenId);
            unchecked {
                i++;
            }
        }
        isConfiscating = false;
    }

    // =============== MARKETPLACE CONTROL ===============
    function whitelistMarketplaces(
        address[] calldata markets,
        bool whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            whitelistedMarketplaces[market] = whitelisted;
        }
    }

    // =============== Stake ===============
    function stake(uint256 tokenId) internal {
        require(canStake, "staking not open");
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] == 0, "already staking");
        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId);
    }

    function unstake(uint256 tokenId) internal {
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] > 0, "not staking");
        uint256 lsa = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, lsa, block.timestamp);
    }

    function setTokensStakeStatus(
        uint256[] memory tokenIds,
        bool setStake
    ) external payable {
        require(tokenIds.length > 0, "empty");
        if (setStake) {
            require(
                msg.value == stakePrice * tokenIds.length,
                "Incorrect amount"
            );
        }
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            if (setStake) {
                stake(tokenId);
            } else {
                unstake(tokenId);
            }
            unchecked {
                i++;
            }
        }
    }

    function setupStaking(bool b, uint256 price) external onlyOwner {
        canStake = b;
        stakePrice = price;
    }

    // =============== IERC721xHelper ===============
    function tokensLastStakedAtMultiple(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokensLastStakedAt[tokenIds[i]];
        }
        return part;
    }

    function isUnlockedMultiple(
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = isUnlocked(tokenIds[i]);
        }
        return part;
    }

    function ownerOfMultiple(
        uint256[] calldata tokenIds
    ) external view returns (address[] memory) {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }

    function tokenNameByIndexMultiple(
        uint256[] calldata tokenIds
    ) external view returns (string[] memory) {
        string[] memory part = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokenNameByIndex(tokenIds[i]);
        }
        return part;
    }

    function isMNPLTransferLockedMultiple(
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = isMNPLTransferLocked(tokenIds[i]);
        }
        return part;
    }

    function getTierMultiple(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = getTier(tokenIds[i]);
        }
        return part;
    }

    // =============== MNPL/Tier ===============

    function getTier(uint256 tokenId) public view returns (uint256) {
        if (!isOriginallyMNPL(tokenId)) return 1;
        if (mnplUnlocked[tokenId]) return 1;
        return 2;
    }

    function isOriginallyMNPL(uint256 tokenId) public view returns (bool) {
        if (tokenIdOrUpIsMNPL == 0) return false;
        return tokenId >= tokenIdOrUpIsMNPL;
    }

    function isMNPLTransferLocked(uint256 tokenId) public view returns (bool) {
        if (mnplUnlocked[tokenId]) return false;
        return isOriginallyMNPL(tokenId);
    }

    function unlockAndUpgradeMNPL(
        uint256 tokenId
    ) external payable onlyTokenOwner(tokenId) {
        require(unlockPrice > 0, "Not open");
        require(isOriginallyMNPL(tokenId), "Not originally MNPL");
        require(!mnplUnlocked[tokenId], "Already unlocked and upgraded");
        require(msg.value == unlockPrice, "Incorrect price");

        mnplUnlocked[tokenId] = true;
        emit MNPLUnlockedUpgraded(tokenId);
    }

    function payRoyalty(
        uint256 tokenId
    ) external payable onlyTokenOwner(tokenId) {
        require(msg.value > 0, "Amount must not be 0");
        emit RoyaltyPaid(tokenId, msg.value);
    }

    // =============== MNPL/Tier Admin ===============
    function setupGuardianAndMNPL(
        address guardianAddress,
        uint256 _tokenIdOrUpIsMNPL,
        uint256 _unlockPrice
    ) external onlyOwner {
        guardianContract = ITOLTransfer(guardianAddress);
        tokenIdOrUpIsMNPL = _tokenIdOrUpIsMNPL;
        unlockPrice = _unlockPrice;
        // upgradePrice = _upgradePrice;
    }

    function withdrawSales() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        _withdraw(owner(), balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }
}