// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IMembershipNFT.sol";
import "./interfaces/IReferralHandler.sol";
import "./interfaces/IDepositBox.sol";
import "./interfaces/IRebaserNew.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract NFTFactory {

    address public admin;
    address public tierManager;
    address public taxManager;
    address public rebaser;
    address public token;
    address public handlerImplementation;
    address public depositBoxImplementation;
    address public rewarder;
    mapping(uint256 => address) NFTToHandler;
    mapping(address => uint256) HandlerToNFT;
    mapping(uint256 => address) NFTToDepositBox;
    mapping(address => bool) handlerStorage;
    mapping(address => uint256) claimedEpoch;
    IMembershipNFT public NFT;
    string public tokenURI;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewURI(string OldTokenURI,string NewTokenURI);
    event NewRewarder(address oldRewarder, address newRewarder);
    event NewNFT(address oldNFT, address NewNFT);
    event NewRebaser(address oldRebaser, address newRebaser);
    event NewToken(address oldToken, address newToken);
    event NewTaxManager(address oldTaxManager, address newTaxManager);
    event NewTierManager(address oldTierManager, address newTierManager);

    event NewIssuance(uint256 id, address handler, address depositBox);
    event LevelChange(address handler, uint256 oldTier, uint256 newTier);
    event SelfTaxClaimed(address indexed handler, uint256 amount, uint256 timestamp);
    event RewardClaimed(address indexed handler, uint256 amount, uint256 timestamp);
    event DepositClaimed(address indexed handler, uint256 amount, uint256 timestamp);

    modifier onlyAdmin() { // Change this to a list with ROLE library
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(address _handlerImplementation, address _depositBoxImplementation, string memory _tokenURI) {
        admin = msg.sender;
        handlerImplementation = _handlerImplementation;
        depositBoxImplementation = _depositBoxImplementation;
        tokenURI = _tokenURI;
    }

    function getHandlerForUser(address user) external view returns (address) {
        uint256 tokenID = NFT.belongsTo(user);
        if(tokenID != 0) // Incase user holds no NFT
            return NFTToHandler[tokenID];
        return address(0);
    }

    function getHandler(uint256 tokenID) external view returns (address) {
        return NFTToHandler[tokenID];
    }

    function getDepositBox(uint256 tokenID) external view returns (address) {
        return NFTToDepositBox[tokenID];
    }

    function isHandler(address _handler) public view returns (bool) {
        return handlerStorage[_handler];
    }

    function addHandler(address _handler) public onlyAdmin { // For adding handlers for Staking pools and Protocol owned Pools
        handlerStorage[_handler] = true;
    }

    function alertLevel(uint256 oldTier, uint256 newTier) external { // All the handlers notify the Factory incase there is a change in levels
        require(isHandler(msg.sender) == true);
        emit LevelChange(msg.sender, oldTier, newTier);
    }

    function alertSelfTaxClaimed(uint256 amount, uint256 timestamp) external { // All the handlers notify the Factory when the claim self tax
        require(isHandler(msg.sender) == true);
        emit SelfTaxClaimed(msg.sender, amount, timestamp);
    }

    function alertReferralClaimed(uint256 amount, uint256 timestamp) external { // All the handlers notify the Factory when the claim referral Reward
        require(isHandler(msg.sender) == true);
        emit RewardClaimed(msg.sender, amount, timestamp);
    }

    function alertDepositClaimed(uint256 amount, uint256 timestamp) external { // All the handlers notify the Factory when the claim referral Reward
        require(isHandler(msg.sender) == true);
        emit DepositClaimed(msg.sender, amount, timestamp);
    }


    function getRebaser() external view returns(address) {
        return rebaser;  // Get address of the Rebaser contract
    }

    function getAdmin() external view returns(address) {
        return admin;
    }

    function getToken()  external view returns(address){
        return token;
    }

    function getTaxManager() external view returns(address) {
        return taxManager;
    }

    function getRewarder() external view returns(address) {
        return rewarder;
    }

    function getTierManager() external view returns(address) {
        return tierManager;
    }

    function getEpoch(address user) external view returns (uint256) {
        return claimedEpoch[user];
    }

    function setAdmin(address account) public onlyAdmin {
        address oldAdmin = admin;
        admin = account;
        emit NewAdmin(oldAdmin, account);
    }

    function setDefaultURI(string memory _tokenURI) onlyAdmin public {
        string memory oldURI = tokenURI;
        tokenURI = _tokenURI;
        emit NewURI(oldURI, _tokenURI);
    }

    function setRewarder(address _rewarder) onlyAdmin public {
        address oldRewarder = rewarder;
        rewarder = _rewarder;
        emit NewRewarder(oldRewarder, _rewarder);
    }

    function setNFTAddress(address _NFT) onlyAdmin external {
        address oldNFT = address(NFT);
        NFT = IMembershipNFT(_NFT); // Set address of the NFT contract
        emit NewNFT(oldNFT, _NFT);
    }

    function setRebaser(address _rebaser) onlyAdmin external {
        address oldRebaser = rebaser;
        rebaser = _rebaser; // Set address of the Rebaser contract
         emit NewRebaser(oldRebaser, _rebaser);
    }

    function setToken(address _token) onlyAdmin external {
        address oldToken = token;
        token = _token; // Set address of the Token contract
        emit NewToken(oldToken, _token);
    }

    function setTaxManager(address _taxManager) onlyAdmin external {
        address oldManager = taxManager;
        taxManager = _taxManager;
        emit NewTaxManager(oldManager, _taxManager);
    }

    function setTierManager(address _tierManager) onlyAdmin external {
        address oldManager = tierManager;
        tierManager = _tierManager;
        emit NewTierManager(oldManager, _tierManager);
    }

    function registerUserEpoch(address user) external {
        require(msg.sender == address(NFT));
        uint256 epoch = IRebaser(rebaser).getPositiveEpochCount();
        if(claimedEpoch[user] == 0)
            claimedEpoch[user] = epoch;
    }

    function updateUserEpoch(address user, uint256 epoch) external {
        require(msg.sender == rewarder);
        claimedEpoch[user] = epoch;
    }

    function mint(address referrer) external returns (address) { //Referrer is address of NFT handler of the guy above
        uint256 nftID = NFT.issueNFT(msg.sender, tokenURI);
        uint256 epoch = IRebaser(rebaser).getPositiveEpochCount(); // The handlers need to only track positive rebases
        IReferralHandler handler = IReferralHandler(Clones.clone(handlerImplementation));
        require(address(handler) != referrer, "Cannot be its own referrer");
        require(handlerStorage[referrer] == true || referrer == address(0), "Referrer should be a valid handler");
        handler.initialize(token, referrer, address(NFT), nftID);
        if(claimedEpoch[msg.sender] == 0)
            claimedEpoch[msg.sender] = epoch;
        IDepositBox depositBox =  IDepositBox(Clones.clone(depositBoxImplementation));
        depositBox.initialize(address(handler), nftID, token);
        handler.setDepositBox(address(depositBox));
        NFTToHandler[nftID] = address(handler);
        NFTToDepositBox[nftID] = address(depositBox);
        HandlerToNFT[address(handler)] = nftID;
        handlerStorage[address(handler)] = true;
        handlerStorage[address(depositBox)] = true; // Required to allow it fully transfer the collected rewards without limit
        addToReferrersAbove(1, address(handler));
        emit NewIssuance(nftID, address(handler), address(depositBox));
        return address(handler);
    }

    //TODO: Refactor reuable code
    function mintToAddress(address referrer, address recipient, uint256 tier) external onlyAdmin returns (address) { //Referrer is address of NFT handler of the guy above
        uint256 nftID = NFT.issueNFT(recipient, tokenURI);
        uint256 epoch = IRebaser(rebaser).getPositiveEpochCount(); // The handlers need to only track positive rebases
        IReferralHandler handler = IReferralHandler(Clones.clone(handlerImplementation));
        require(address(handler) != referrer, "Cannot be its own referrer");
        require(handlerStorage[referrer] == true || referrer == address(0), "Referrer should be a valid handler");
        handler.initialize(token, referrer, address(NFT), nftID);
        if(claimedEpoch[recipient] == 0)
            claimedEpoch[recipient] = epoch;
        IDepositBox depositBox =  IDepositBox(Clones.clone(depositBoxImplementation));
        depositBox.initialize(address(handler), nftID, token);
        handler.setDepositBox(address(depositBox));
        NFTToHandler[nftID] = address(handler);
        NFTToDepositBox[nftID] = address(depositBox);
        HandlerToNFT[address(handler)] = nftID;
        handlerStorage[address(handler)] = true;
        handlerStorage[address(depositBox)] = true; // Required to allow it fully transfer the collected rewards without limit
        addToReferrersAbove(1, address(handler));
        handler.setTier(tier);
        emit NewIssuance(nftID, address(handler), address(depositBox));
        return address(handler);
    }

    function addToReferrersAbove(uint256 _tier, address _handler) internal {
        if(_handler != address(0)) {
            address first_ref = IReferralHandler(_handler).referredBy();
            if(first_ref != address(0)) {
                IReferralHandler(first_ref).addToReferralTree(1, _handler, _tier);
                address second_ref = IReferralHandler(first_ref).referredBy();
                if(second_ref != address(0)) {
                    IReferralHandler(second_ref).addToReferralTree(2, _handler, _tier);
                    address third_ref = IReferralHandler(second_ref).referredBy();
                    if(third_ref != address(0)) {
                        IReferralHandler(third_ref).addToReferralTree(3, _handler, _tier);
                        address fourth_ref = IReferralHandler(third_ref).referredBy();
                        if(fourth_ref != address(0))
                            IReferralHandler(fourth_ref).addToReferralTree(4, _handler, _tier);
                    }
                }
            }
        }
    }
}