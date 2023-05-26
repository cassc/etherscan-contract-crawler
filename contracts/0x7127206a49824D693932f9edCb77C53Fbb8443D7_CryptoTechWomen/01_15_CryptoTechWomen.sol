// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract CryptoTechWomen is ERC721, Ownable, ReentrancyGuard, Pausable {

    using Math for uint256;

    mapping(address => uint8) public preSaleMinted; // Amounts of minted tokens by users on the presale

    uint256 public publicSaleDate;  // Timestamp of public sale start date
    uint16 public totalSupply;  // Current amount of minted tokens
    uint16 public mintCounter;  // The next token ID to be minted (not equal to totalSupply because of the give away)
    uint16 public bpsToDonationFund;    // The number of BPs to be send to the Donation Fund after the milestone reached
    uint16 public airdropCounter; // Current amount of airdropped tokens
    address public donationFundAddress; // The Donation Fund address
    address public communityFundAddress;    // The Community Fund address
    string public baseURI;  // Base URI for tokens
    string public contractURI;  // Contract URI

    bool public uriSet; // If base URI set or not


    uint256 constant public publicSalePrice = 0.07 ether;   // Token price at the public sale stage
    uint256 constant public preSalePrice = 0.06 ether;  // Token price at the pre sale stage
    uint16 public maxTotalSupply = 8888;   // Max amount of tokens available for mint in total
    uint16 constant public preSaleTokenLimit = 7000;    // Max amount of tokens available for mint at the pre sale
    uint8 constant public preSaleLimitPerUser = 2;  // Max amount of tokens available for mint at the pre sale per address
    uint8 public amountForGiveAway = 150;  // Amount of tokens reserved for give away
    uint8 constant public publicSaleLimitPerTx = 10;    // Max amount of tokens available for mint at the public sale per transaction

    uint16 constant private BPS_BASE = 10000;   // Max amount of base points (1/10000)

    bytes32 public merkleRoot;    // Merkle root for the whitelist

    Milestone[] public milestones;  // Milestones of the sale

    struct Milestone {
        uint16 triggerId;   // ID when the milestone is triggered
        bool eventEmitted;  // If event was emmited or not
    }

    event PreSaleMint(address user, uint256 amount);
    event PublicSaleMint(address user, uint256 amount);
    event SoldOut();
    event MilestoneReached(uint256 triggerId);
    event GiveAway(address[] addresses);
    
    /*
    * @param _name The name of the NFT
    * @param _symbol The symbol of the NFT
    * @param _contractURI The contract URI
    * @param _merkleRoot Merkle root for the whitelist
    * @param _publicSaleDate Timestamp of the public sale stage date
    * @param _donationFundAddress The Donation Fund address
    * @param _communityFundAddress The Community Fund address
    * @param _bpsToDonationFund Amount of BPs for the Donation Fund
    * @param _triggerIds Trigger IDs for milestones
    */
    constructor (
        string memory _name, 
        string memory _symbol, 
        string memory _contractURI,
        bytes32 _merkleRoot,
        uint256 _publicSaleDate,
        address _donationFundAddress,
        address _communityFundAddress,
        uint16 _bpsToDonationFund,
        uint16[] memory _triggerIds,
        string memory _prerevealUri
    ) 
        ERC721(_name, _symbol) 
    {
        require(_publicSaleDate > 0, "invalid publicSaleDate");
        require(uint256(_merkleRoot) > 0, "invalid MerkleRoot");
        require(_donationFundAddress != address(0), "donationFundAddress is 0");
        require(_communityFundAddress != address(0), "communityFundAddress is 0");
        require(_bpsToDonationFund <= BPS_BASE, "invalid bpsToDonationFund");
        merkleRoot = _merkleRoot;
        publicSaleDate = _publicSaleDate;
        donationFundAddress = _donationFundAddress;
        communityFundAddress = _communityFundAddress;
        bpsToDonationFund = _bpsToDonationFund;
        contractURI = _contractURI;
        for (uint256 i; i < _triggerIds.length; i++) {
            milestones.push(Milestone(_triggerIds[i], false));
        }
        baseURI = _prerevealUri;
    }

    /*
    * @notice Distrubites specified amounts of ETH to the Donation Fund and the Community Fund
    * @dev Only owner can call it
    * @param _amountToDonationFund Amount of ETH for the Donation Fund
    * @param _amountToCommunityFund Amount of ETH for the Community Fund
    */
    function distributeFunds(uint256 _amountToDonationFund, uint256 _amountToCommunityFund) external onlyOwner {
        uint256 balance = address(this).balance;
        require(_amountToDonationFund + _amountToCommunityFund <= balance, "not enough balance");
        _sendETH(payable(donationFundAddress), _amountToDonationFund);
        _sendETH(payable(communityFundAddress), _amountToCommunityFund);
    }

    /*
    * @notice Sets amount of BPs for the Donation Fund
    * @dev Only owner can call it
    * @param _bpsToDonationFund Amount of BPs
    */
    function setBpsToDonationFund(uint16 _bpsToDonationFund) external onlyOwner {
        require(_bpsToDonationFund <= BPS_BASE, "incorrect bpsToDonationFund");
        bpsToDonationFund = _bpsToDonationFund;
    }

    /*
    * @notice Sets Merkle root
    * @dev Only owner can call it
    * @param _newRoot New Merkle root
    */
    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    /*
    * @notice Sets the Donation Fund Address
    * @dev Only owner can call it
    * @param _donationFundAddress The new address of the Donation Fund
    */
    function setDonationFundAddress(address _donationFundAddress) external onlyOwner {
        require(_donationFundAddress != address(0), "donationFundAddress is 0");
        donationFundAddress = _donationFundAddress;
    }

    /*
    * @notice Sets the Community Fund Address
    * @dev Only owner can call it
    * @param _communityFundAddress The new address of the Commmunity Fund
    */
    function setCommunityFundAddress(address _communityFundAddress) external onlyOwner {
        require(_communityFundAddress != address(0), "communityFundAddress is 0");
        communityFundAddress = _communityFundAddress;
    }

    /*
    * @notice Sets the timestamp of the public sale start date
    * @dev Only owner can call it
    * @param _publicSaleDate Timestamp of the public sale start date
    */
    function setPublicSaleDate(uint256 _publicSaleDate) external onlyOwner {
        require(_publicSaleDate > 0, "incorrect publicSaleDate");
        publicSaleDate = _publicSaleDate;
    }

    /*
    * @notice Pauses contract
    * @dev Only owner can call it
    */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /*
    * @notice Unpauses contract
    * @dev Only owner can call it
    */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /*
    * @notice Mints specified amount of tokens on the pre sale and registrates 
    * the user if correct MerkleProof was submitted. Must be called if the 
    * user isn't registered yet (didn't mint tokens)
    * @dev Non reentrant
    * @param _amount Amount of tokens to mint
    * @param _proof Merkle proof for the user
    */
    function preSaleMint(
        uint256 _amount, 
        bytes32[] memory _proof
    ) 
        external 
        payable 
        nonReentrant
        whenNotPaused
    {
        require(preSaleMinted[_msgSender()] == 0, "already registered");
        require(_verify(_leaf(_msgSender()), _proof), "incorrect proof");
        _preSaleMint(_amount);
    }

    /*
    * @notice Mints specified amount of tokens on the pre sale. Must be called 
    * if the user already registered (already did mint tokens)
    * @dev Non reentrant
    * @param _amount Amount of tokens to mint
    */
    function preSaleMint(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(preSaleMinted[_msgSender()] > 0, "not registered");
        _preSaleMint(_amount);
    }

    /*
    * @notice Mints specified amount of tokens on the public sale
    * @dev Non reentrant. Emits PublicSaleMint event
    * @param _amount Amount of tokens to mint
    */
    function publicSaleMint(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(block.timestamp >= publicSaleDate, "public sale isn't started");
        require(_amount > 0 && _amount <= publicSaleLimitPerTx, "invalid amount");
        uint256 maxTotalSupply_ = maxTotalSupply;
        uint256 totalSupply_ = totalSupply;
        require(totalSupply_ + _amount <= maxTotalSupply_, "already sold out");
        require(mintCounter + _amount <= maxTotalSupply_ - amountForGiveAway, "the rest is reserved");
        _buyAndRefund(totalSupply_, _amount, publicSalePrice);
        if (totalSupply_ + _amount == maxTotalSupply_) emit SoldOut();
        emit PublicSaleMint(_msgSender(), _amount);
    }

    /*
    * @notice Mints specified IDs to specified addresses
    * @dev Only owner can call it. Lengths of arrays must be equal. 
    * @param _accounts The list of addresses to mint tokens to
    */
    function giveaway(address[] memory _accounts) external onlyOwner {
        uint256 maxTotSup = maxTotalSupply;
        uint256 currentTotalSupply = totalSupply;
        require(airdropCounter + _accounts.length <= amountForGiveAway, "limit for airdrop exceeded");
        require(currentTotalSupply + _accounts.length <= maxTotSup, "maxTotalSupply exceeded");
        uint256 counter = currentTotalSupply;
        for (uint256 i; i < _accounts.length; i++) {
            _safeMint(_accounts[i], counter);
            counter++;
        }
        airdropCounter += uint16(_accounts.length);
        totalSupply += uint16(_accounts.length);
        if (currentTotalSupply + _accounts.length == maxTotSup) emit SoldOut();  // emit SoldOut in case some tokens were airdropped after the sale
        emit GiveAway(_accounts);
    }

    /*
    * @notice Sets base URI for tokens
    * @dev Only owner can call it
    * @param _newBaseURI The new base URI
    */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        uriSet = true;
    }

    /*
    * @notice Withdraws specified amount of ETH to specified address
    * @dev Only owner can call it
    * @param _to The address of ETH receiver
    * @param _amount The amount of ETH to withdraw
    */
    function withdrawTo(address payable _to, uint256 _amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= _amount, "unsufficient balance");
        _sendETH(_to, _amount);
    }

    /*
    * @dev The main logic for the pre sale mint. Emits PreSaleMint event
    * @param _amount The amount of tokens 
    */
    function _preSaleMint(uint256 _amount) private {
        require(block.timestamp < publicSaleDate, "presale stage finished");
        require(_amount > 0, "invalid amount");
        require(preSaleMinted[_msgSender()] + _amount <= preSaleLimitPerUser, "limit per user exceeded");
        uint256 totalSupply_ = totalSupply;
        require(totalSupply_ + _amount <= preSaleTokenLimit, "presale token limit exceeded");
        _buyAndRefund(totalSupply_, _amount, preSalePrice);
        preSaleMinted[_msgSender()] += uint8(_amount);
        emit PreSaleMint(_msgSender(), _amount);
    }

    /*
    * @dev Mints tokens for the user and refunds ETH if too much was passed
    * @param _amount The amount of tokens 
    * @param _price The price for each token 
    */
    function _buyAndRefund(uint256 _totalSupply, uint256 _amount, uint256 _price) internal {
        uint256 totalCost = _amount * _price;
        require(msg.value >= totalCost, "not enough funds");
        for (uint256 i; i < _amount; i++) {
            _safeMint(_msgSender(), _totalSupply + i);
        }
        totalSupply += uint16(_amount);
        mintCounter += uint16(_amount);
        _checkMilestones(_totalSupply, _amount, _price);
        uint256 refund = msg.value - totalCost;
        if (refund > 0) {
            _sendETH(payable(_msgSender()), refund);
        }
    }

    /*
    * @dev Checks if a milestone was reached, do some logic if it was. 
    * Emits MilestoneReached event
    * @param _amount Amount of tokens to buy
    * @param _oldMintCounter The mint counter 
    * @param _price The current price of the stage 
    */
    function _checkMilestones(uint256 _oldMintCounter, uint256 _amount, uint256 _price) private {
        Milestone memory milestone = milestones[0];
        if (_oldMintCounter + _amount >= milestone.triggerId) {
            uint256 countAfterTrigger = Math.min(_oldMintCounter + _amount - milestone.triggerId, _amount);
            uint256 toPay = bpsToDonationFund * countAfterTrigger * _price / BPS_BASE;
            _sendETH(payable(donationFundAddress), toPay);
            if (!milestone.eventEmitted) {
                emit MilestoneReached(milestone.triggerId);
                milestones[0].eventEmitted = true;
            }
        } 
        milestone = milestones[1];
        if (
            !milestone.eventEmitted &&
            _oldMintCounter + _amount >= milestone.triggerId
        ) {
            emit MilestoneReached(milestone.triggerId);
            milestones[1].eventEmitted = true;
        }
    }

    /*
    * @dev sends ETH to the specified address
    * @param _to The receiver
    * @param _amount The amount of ETH to send 
    */
    function _sendETH(address payable _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "send ETH failed");
    }

    /*
    * @dev Returns the base URI
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!uriSet) return _baseURI();
        return ERC721.tokenURI(tokenId);
    }

    function setUriSet(bool status) external {
        uriSet = status;
    }


    /*
    * @dev Returns the leaf for Merkle tree
    * @param _account Address of the user
    * @param _userId ID of the user
    */
    function _leaf(address _account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_account));
    }

    /*
    * @dev Verifies if the proof is valid or not
    * @param _leaf The leaf for the user
    * @param _proof Proof for the user
    */
    function _verify(bytes32 _leaf, bytes32[] memory _proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    /*
    * @dev receive() function to let the contract accept ETH
    */
    receive() external payable{}

}