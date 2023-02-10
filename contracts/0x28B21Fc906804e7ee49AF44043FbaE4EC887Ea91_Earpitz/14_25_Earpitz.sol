// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { ERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import { ERC721ABurnableUpgradeable } from "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import { ERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { DefaultOperatorFiltererUpgradeable } from "./DefaultOperatorFiltererUpgradeable.sol";

contract Earpitz is 
    ERC721AUpgradeable, 
    ERC721ABurnableUpgradeable, 
    ERC721AQueryableUpgradeable, 
    DefaultOperatorFiltererUpgradeable,
    UUPSUpgradeable, 
    OwnableUpgradeable {

    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    modifier directOnly {
        require(msg.sender == tx.origin);
        _;
    }

    enum Status {
        CLOSED,
        RESERVE,
        PAUSED
    }

    struct UserAmount {
        address user;
        uint96 amount;
    }

    struct StakingData {
        uint128 stakedAt;
        uint128 unstakedAt;
    }

    // Mint settings
    struct MintSettings {
        bool waitlistEnabled;
        uint24 maxWaitlistReservationPerUser;
        uint32 maxWhitelistSupply;
        uint96 whitelistPrice;
        uint96 waitlistPrice;
    }

    // Supply
    uint256 public constant MAX_SUPPLY = 8188;
    uint256 public whitelistReservationCount;
    uint256 public waitlistReservationCount;

    // Mint settings
    address public FairAuction;
    MintSettings public mintSettings;
    
    // Waitlist
    UserAmount[] public waitlist;

    // Staking
    mapping(uint256 => StakingData) public tokenToStakingData;

    // Mutable states
    Status public status;
    string public baseURI;
    bool public operatorFilteringEnabled;
    bool public stakingEnabled;
    address public signer;
    address public secondaryAddress;
    uint256 public secondaryPercentage;

    // Events
    event WhitelistReservation(address indexed user, uint256 amount, uint256 userTotalReservation, uint256 totalWhitelistReservation);
    event WaitlistReservation(address indexed user, uint256 amount, uint256 userIndex, uint256 userTotalReservation, uint256 totalWaitlistReservation);
    event WhitelistClaim(address indexed user, uint256 mint, uint256 totalMinted);
    event WaitlistClaim(address indexed user, uint256 mint, uint256 totalMinted);
    event WaitlistRefund(address indexed user, uint256 amount, uint256 totalRefunded);
    event Stake(address indexed maker, uint256 indexed tokenId);
    event Unstake(address indexed maker, uint256 indexed tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializerERC721A initializer {
        __ERC721A_init("Earpitz", "EARPITZ");
        __Ownable_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();
        mintSettings.waitlistEnabled = true;
        operatorFilteringEnabled = true;
        signer = 0x13dC6B0FAf1dcD754A7337C47476741aF123e53F;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function whitelistReserve(uint32 amount, uint32 maxAmount, bytes calldata signature) external payable directOnly {
        // Verify status
        require(status == Status.RESERVE, "Reservation is not live");
        
        // Verify price has been set
        uint256 _whitelistPrice = mintSettings.whitelistPrice;
        require(_whitelistPrice > 0, "Whitelist price is not set");

        // Verify maximum whitelist supply has been set
        uint256 _maxWhitelistSupply = mintSettings.maxWhitelistSupply;
        require(_maxWhitelistSupply > 0, "Max whitelist supply is not set");

        // Verify ECDSA signature
        require(_verifySignature(keccak256(abi.encode(msg.sender, maxAmount)), signature), "Signature does not match");

        // Verify amount is not zero
        require (amount > 0, "Amount must be larger than 0");

        // Verify the ETH amount sent
        require(msg.value == amount * _whitelistPrice, "Invalid ETH sent");

        // Verify user does not reserve over their allocation
        uint64 aux = _getAux(msg.sender);
        uint32 whitelistReserved = uint32(aux);
        require(whitelistReserved + amount <= maxAmount, "Max user whitelist reservation has been reached");

        // Verify reservation count does not go over maximum reservation
        uint256 _whitelistReservationCount = whitelistReservationCount;
        require(_whitelistReservationCount + amount <= _maxWhitelistSupply, "Reservation is full");
        
        // Update reservation data for user and whitelistReservationCount
        _setAux(msg.sender, (aux & 0xffffffff00000000) + (whitelistReserved + amount));
        whitelistReservationCount = (_whitelistReservationCount += amount);

        // If maximum supply is reached, close
        if (_whitelistReservationCount == _maxWhitelistSupply) {
            status = Status.CLOSED;
        }

        emit WhitelistReservation(msg.sender, amount, whitelistReserved + amount, _whitelistReservationCount);
    }

    function waitlistReserve(uint32 amount) external payable directOnly {
        // Verify status
        require(status == Status.RESERVE, "Reservation is not live");

        // Verify waitlist enabled
        require(mintSettings.waitlistEnabled, "Waitlist is not enabled");

        // Verify price has been set
        uint256 _waitlistPrice = mintSettings.waitlistPrice;
        require(_waitlistPrice > 0, "Waitlist price is not set");

        // Verify maximum whitelist supply has been set
        uint256 _maxWhitelistSupply = mintSettings.maxWhitelistSupply;
        require(_maxWhitelistSupply > 0, "Max whitelist supply is not set");

        // Verify maximum waitlist reservation per user has been set
        uint256 _maxWaitlistReservationPerUser = mintSettings.maxWaitlistReservationPerUser;
        require(_maxWaitlistReservationPerUser > 0, "Max waitlist reservation per user is not set");

        // Verify amount is not zero
        require (amount > 0, "Amount must be larger than 0");

        // Verify the ETH amount sent
        require(msg.value == amount * _waitlistPrice, "Invalid ETH sent");

        // Verify user does not reserve over maximum allowed
        uint64 aux = _getAux(msg.sender);
        uint32 waitlistReserved = uint32(aux >> 32);
        require(waitlistReserved + amount <= _maxWaitlistReservationPerUser, "Max user waitlist reservation has been reached");

        // Verify total reservation count does not go over maximum reservation
        uint256 _whitelistReservationCount = whitelistReservationCount;
        uint256 _waitlistReservationCount = waitlistReservationCount;
        require (_whitelistReservationCount + _waitlistReservationCount + amount <= _maxWhitelistSupply, "Reservation is full");

        // Update reservation data for user and waitlistReservationCount
        _setAux(msg.sender, (aux & 0xffffffff) + (uint64(waitlistReserved + amount) << 32));
        waitlistReservationCount = (_waitlistReservationCount += amount);

        // Push user to Waitlist
        waitlist.push(UserAmount({ user: msg.sender, amount: uint96(amount) }));

        emit WaitlistReservation(msg.sender, amount, waitlist.length, waitlistReserved + amount, _waitlistReservationCount);
    }

    // Stake (?)

    function stake(uint256[] calldata tokenIds) external {
        unchecked {
            require(stakingEnabled, "Staking is not live");
            uint256 len = tokenIds.length;
            for (uint256 i = 0; i < len; ++i) {
                uint256 tokenId = tokenIds[i];
                require(msg.sender == ownerOf(tokenId) || msg.sender == owner(), "Caller is not allowed");
                require(tokenToStakingData[tokenId].stakedAt <= tokenToStakingData[tokenId].unstakedAt, "Token is already staked");
                tokenToStakingData[tokenId].stakedAt = uint128(block.timestamp);
                emit Stake(msg.sender, tokenId);
            }
        }
    }

    function unstake(uint256[] calldata tokenIds) external {
        unchecked {
            uint256 len = tokenIds.length;
            for (uint256 i = 0; i < len; ++i) {
                uint256 tokenId = tokenIds[i];
                require(msg.sender == ownerOf(tokenId) || msg.sender == owner(), "Caller is not allowed");
                StakingData memory sd = tokenToStakingData[tokenId];
                require(sd.stakedAt > sd.unstakedAt, "Token is not staked");
                tokenToStakingData[tokenId].unstakedAt = uint128(block.timestamp);
                emit Unstake(msg.sender, tokenId);
            }
        }
    }

    // Owner functions

    // Admin process
    function adminProcessWhitelistClaim(address[] calldata users) external onlyOwner {
        unchecked {
            uint256 len = users.length;
            for (uint256 i = 0; i < len; ++i) {
                address user = users[i];
                require (user != address(0), "Address 0");

                // Fetch total amount of reservation for user
                uint64 aux = _getAux(user);
                uint32 amountToMint = uint32(aux);

                // Set user whitelist reservation to 0
                _setAux(user, aux & 0xffffffff00000000);

                // Mint
                require(amountToMint > 0, "User does not have any mint");
                _mint(user, amountToMint);

                emit WhitelistClaim(user, amountToMint, _totalMinted());
            }
        }
    }

    function adminProcessWaitlistRefund(UserAmount[] calldata waitlistData) external onlyOwner {
        unchecked {
            uint256 len = waitlistData.length;
            uint256 totalRefund;
            for (uint256 i = 0; i < len; ++i) {
                address user = waitlistData[i].user;
                uint96 amount = waitlistData[i].amount;
                require(user != address(0) && amount > 0, "Invalid entry");
                
                uint256 amountToRefund = amount * mintSettings.waitlistPrice;
                _sendETH(user, amountToRefund);
                emit WaitlistRefund(user, amount, totalRefund += amountToRefund);
            }
        }
    }

    function adminProcessWaitlistClaim(UserAmount[] calldata waitlistData) external onlyOwner {
        unchecked {
            uint256 len = waitlistData.length;
            for (uint256 i = 0; i < len; ++i) {
                address user = waitlistData[i].user;
                uint96 amount = waitlistData[i].amount;
                require(user != address(0) && amount > 0, "Invalid entry");

                _mint(user, amount);
                emit WaitlistClaim(user, amount, _totalMinted());
            }
        }
    }

    // Airdrop
    function airdrop(UserAmount[] calldata airdropData) external {
        unchecked {
            require(msg.sender == owner() || msg.sender == FairAuction, "Not authorized");
            uint256 len = airdropData.length;
            for (uint256 i = 0; i < len; ++i) {
                _mint(airdropData[i].user, airdropData[i].amount);
            }
        }
        require (_totalMinted() <= MAX_SUPPLY, "Oversupply");
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setWaitlistEnabled(bool _status) external onlyOwner {
        mintSettings.waitlistEnabled = _status;
    }

    function setMaxWaitlistReservationPerUser(uint24 _amount) external onlyOwner {
        mintSettings.maxWaitlistReservationPerUser = _amount;
    }

    function setMaxWhitelistSupply(uint32 _supply) external onlyOwner {
        mintSettings.maxWhitelistSupply = _supply;
    }

    function setWhitelistPrice(uint96 _price) external onlyOwner {
        mintSettings.whitelistPrice = _price;
    }

    function setWaitlistPrice(uint96 _price) external onlyOwner {
        mintSettings.waitlistPrice = _price;
    }

    function setFairAuctionAddress(address _address) external onlyOwner {
        FairAuction = _address;
    }

    function setStakingEnabled(bool _status) external onlyOwner {
        stakingEnabled = _status;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setOperatorFilteringEnabled(bool _enabled) external onlyOwner {
        operatorFilteringEnabled = _enabled;
    }

    function setSecondaryAddress(address _address) external onlyOwner {
        secondaryAddress = _address;
    }

    function setSecondaryPercentage(uint256 _percentage) external onlyOwner {
        secondaryPercentage = _percentage;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(secondaryAddress != address(0), "Secondary address is not set");
        require(secondaryPercentage > 0, "Secondary percentage is not set");
        _sendETH(msg.sender, (100 - secondaryPercentage) * amount / 100);
        _sendETH(secondaryAddress, (secondaryPercentage) * amount / 100);
    }

    function deposit() external onlyOwner payable { }

    // Internal
    function _sendETH(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{ value: _amount }("");
        require(success, "Transfer failed");
    }

    function _verifySignature(bytes32 hash, bytes calldata signature) internal view returns(bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }

    function _startTokenId() internal view virtual override(ERC721AUpgradeable) returns (uint256) {
        return 1;
    }

    // View
    function getWhitelistReserved(address user) public view returns (uint256) {
        return uint256(uint32(_getAux(user)));
    }

    function getWaitlistReserved(address user) public view returns (uint256) {
        return uint256(uint32(_getAux(user) >> 32));
    }

    function getWaitlistLength() public view returns (uint256) {
        return waitlist.length;
    }

    function getWaitlistParticipants(uint256 start, uint256 end) external view returns (UserAmount[] memory) {
        UserAmount[] memory arr = new UserAmount[](end - start + 1);
        for (uint256 i = start; i <= end; ++i) {
            arr[i - start] = waitlist[i];
        }
        return arr;
    }

    function getWaitlistIndexOf(address user) external view returns(uint256[] memory) {
        uint256 count;
        uint256 len = waitlist.length;
        uint256 currentIndex;
        for (uint256 i = 0; i < len; ++i) {
            if (waitlist[i].user == user) { 
                count++; 
            }
        }
        uint256[] memory indexes = new uint256[](count);
        for (uint256 i = 0; i < len; ++i) {
            if (waitlist[i].user == user) { 
                indexes[currentIndex++] = i;
            }
        }
        return indexes;
    }

    function tokenURI(uint tokenId) public view override(ERC721AUpgradeable, IERC721AUpgradeable) returns(string memory) {
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    // Override _beforeTokenTransfers hook to disable transfers if contract is paused
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(status != Status.PAUSED, "Contract is paused");
    }

    // Override approval and transfer functions to include OperatorFilterer modifier
    function approve(address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(to, operatorFilteringEnabled) {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator, operatorFilteringEnabled) {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.transferFrom(from, to, tokenId);
        require(tokenToStakingData[tokenId].stakedAt <= tokenToStakingData[tokenId].unstakedAt, "Token is staked");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId);
        require(tokenToStakingData[tokenId].stakedAt <= tokenToStakingData[tokenId].unstakedAt, "Token is staked");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId, _data);
        require(tokenToStakingData[tokenId].stakedAt <= tokenToStakingData[tokenId].unstakedAt, "Token is staked");
    }

}