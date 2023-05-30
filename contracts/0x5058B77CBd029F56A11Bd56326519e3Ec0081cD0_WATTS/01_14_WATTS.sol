// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WATTS is AccessControl, Ownable, ERC20 {
    using ECDSA for bytes32;

    /** CONTRACTS */
    IERC721 public slotieNFT;
    IERC721 public slotieJrNFT;

    /** ROLES */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    /** GENERAL */
    uint256 public deployedTime = block.timestamp;
    uint256 public lockPeriod = 90 days;
    event setLockPeriodEvent(uint256 indexed lockperiod);
    event setDeployTimeEvent(uint256 indexed deployTime);

    /** ADDITIONAL ERC-20 FUNCTIONALITY */
    mapping(address => uint256) private _claimableBalances;
    uint256 private _claimableTotalSupply;

    /** === SLOTIE === */

    /** CLAIMING */
    uint256 public slotieIssuanceRate = 10 * 10**18; // 10 per day
    uint256 public slotieIssuancePeriod = 1 days; 
    uint256 public slotieClaimStart = 1644624000; // 12 feb 00:00:00 UTC
    uint256 public slotieDeployTime = 1638877989; // 7 dec 11:53:09 UTC
    uint256 public slotieEarnPeriod = lockPeriod - (deployedTime - slotieDeployTime); // lock period minus time since slotie deploy
    uint256 public slotieClaimEndTime = deployedTime + slotieEarnPeriod;
    
    mapping(address => uint256) slotieAddressToAccumulatedWATTs; // accumulated watts before 12 feb 00:00
    mapping(address => uint256) slotieAddressToLastClaimedTimeStamp; // last time a claimed happened for a user

    /**  GIVEAWAYS */    
    bytes32 public slotiePreClaimMerkleProof = "";
    bytes32 public slotieEHRMerkleProof = "";
    mapping(address => uint256) public slotieAddressToPreClaim; // whether an address claimed their initial claim or not
    mapping(address => uint256) public slotieAddressToEHRNonce; // safeguard against reusing proofs attack

    /** EVENTS */
    event ClaimedRewardFromSlotie(address indexed user, uint256 reward, uint256 timestamp);
    event AccumulatedRewardFromSlotie(address indexed user, uint256 reward, uint256 timestamp);
    event setSlotieNFTEvent(address indexed slotieNFT);

    event setSlotieIssuanceRateEvent(uint256 indexed issuanceRate);
    event setSlotieIssuancePeriodEvent(uint256 indexed issuancePeriod);
    event setSlotieClaimStartEvent(uint256 indexed slotieClaimStart);
    event setSlotieEarnPeriodEvent(uint256 indexed slotieEarnPeriod);
    event setSlotieClaimEndTimeEvent(uint256 indexed slotieClaimEndTime);

    event setSlotiePreClaimMerkleProofEvent(bytes32 indexed slotiePreClaimMerkleProof);
    event setSlotieEHRMerkleProofEvent(bytes32 indexed slotieEHRMerkleProof);


    /** === SLOTIE JR. === */

    /** CLAIMING */
    uint256 public slotieJrIssuanceRate = 10 * 10**18; // 10 per day
    uint256 public slotieJrIssuancePeriod = 1 days;
    //uint256 public slotieJrClaimStart = 1644620400;
    uint256 public slotieJrDeployTime; // will be set as soon as slotie jr is deployed
    uint256 public slotieJrEarnPeriod = lockPeriod; // earn period is 3 months
    uint256 public slotieJrClaimEndTime;
    mapping(address => uint256) slotieJrAddressToLastClaimedTimeStamp;

    /**  GIVEAWAYS */    
    bytes32 public slotieJrEHRMerkleProof = "";
    mapping(address => uint256) public slotieJrAddressToEHRNonce; // safeguard against reusing proofs attack

    /** EVENTS */
    event ClaimedRewardFromSlotieJr(address indexed user, uint256 reward, uint256 timestamp);
    event setSlotieJrNFTEvent(address indexed slotieJrNFT);

    event setSlotieJrIssuanceRateEvent(uint256 indexed issuanceRate);
    event setSlotieJrIssuancePeriodEvent(uint256 indexed issuancePeriod);
    //event setSlotieJrClaimStart(uint256 indexed slotieJrClaimStart);
    event setSlotieJrDeployTimeEvent(uint256 indexed slotieJrDeployTime);
    event setSlotieJrEarnPeriodEvent(uint256 indexed slotieJrEarnPeriod);
    event setSlotieJrClaimEndTimeEvent(uint256 indexed slotieJrClaimEndTime);

    event setSlotieJrEHRMerkleProofEvent(bytes32 indexed slotieEHRMerkleProof);

    /** ANTI BOT */
    uint256 public blackListPeriod = 15 minutes;
    uint256 public blackListPeriodStart;
    mapping(address => bool) public isBlackListed;
    mapping(address=> bool) public isDex;

    /** MODIFIERS */
    modifier slotieCanClaim() {
        require(slotieNFT.balanceOf(msg.sender) > 0, "NOT A SLOTIE HOLDER");
        require(block.timestamp >= slotieClaimStart, "SLOTIE CLAIM LOCKED");
        require(address(slotieNFT) != address(0), "SLOTIE NFT NOT SET");
        _;
    }

    modifier slotieJrCanClaim() {
        require(slotieJrNFT.balanceOf(msg.sender) > 0, "NOT A SLOTIE JR HOLDER");
        require(address(slotieJrNFT) != address(0), "SLOTIE JR NFT NOT SET");
        _;
    }

    modifier notBlackListed(address from) {
        require(!isBlackListed[from], "ACCOUNT BLACKLISTED");
        _;
    }

    constructor(
        address _slotieNFT
    ) ERC20("WATTS", "$WATTS") Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        slotieNFT = IERC721(_slotieNFT);
    }

    /** OVERRIDE ERC-20 */
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) + _claimableBalances[account];
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() + _claimableTotalSupply;
    }

    /** CLAIMING */
    function _slotieClaim(address recipient, uint256 preClaimAmount, uint256 ehrAmount, uint256 nonce, bytes32[] memory preClaimProof, bytes32[] memory ehrProof) internal {
        uint256 preClaimApplicable;
        uint256 ehrApplicable;

        if (preClaimProof.length > 0 && preClaimAmount != 0) {
            bytes32 leaf = keccak256(abi.encodePacked(recipient, preClaimAmount));
            require(MerkleProof.verify(preClaimProof, slotiePreClaimMerkleProof, leaf), "SLOTIE INVALID PRE CLAIM PROOF");
            require(slotieAddressToPreClaim[recipient] == 0, "SLOTIE PRE CLAIM ALREADY DONE");
            slotieAddressToPreClaim[recipient] = 1;
            preClaimApplicable = 1;
        } 
        
        if (ehrProof.length > 0 && ehrAmount != 0) {
            bytes32 leaf = keccak256(abi.encodePacked(recipient, ehrAmount, nonce));
            require(nonce == slotieAddressToEHRNonce[recipient], "SLOTIE INCORRECT NONCE");
            require(MerkleProof.verify(ehrProof, slotieEHRMerkleProof, leaf), "SLOTIE INVALID EHR PROOF");
            slotieAddressToEHRNonce[recipient] = slotieAddressToEHRNonce[recipient] + 1;
            ehrApplicable = 1;
        }

        uint256 balance = slotieNFT.balanceOf(recipient);
        uint256 lastClaimed = slotieAddressToLastClaimedTimeStamp[recipient];  
        uint256 accumulatedWatts = slotieAddressToAccumulatedWATTs[recipient];
        uint256 currentTime = block.timestamp;

        if (currentTime >= slotieClaimEndTime) {
            currentTime = slotieClaimEndTime; // we can only claim up to slotieClaimEndTime
        }

        if (deployedTime > lastClaimed) {
            lastClaimed = deployedTime; // we start from time of deployment
        } else if (lastClaimed == slotieClaimEndTime) {
            lastClaimed = currentTime; // if we claimed all we set reward to zero
        }
        
        uint256 reward = (currentTime - lastClaimed) * slotieIssuanceRate * balance / slotieIssuancePeriod;

        if (currentTime >= slotieClaimStart && accumulatedWatts != 0) {
            reward = reward + accumulatedWatts;
            delete slotieAddressToAccumulatedWATTs[recipient];
        }

        if (preClaimApplicable != 0) {
            reward = reward + preClaimAmount;
        }

        if (ehrApplicable != 0) {
            reward = reward + ehrAmount;
        }

        slotieAddressToLastClaimedTimeStamp[recipient] = currentTime;
        if (reward > 0) {            
            if (currentTime < slotieClaimStart) {
                slotieAddressToAccumulatedWATTs[recipient] = slotieAddressToAccumulatedWATTs[recipient] + reward;
                emit AccumulatedRewardFromSlotie(recipient, reward, currentTime);
            } else {
                _mintClaimable(recipient, reward);
                emit ClaimedRewardFromSlotie(recipient, reward, currentTime);
            }
        }            
    }    

    function _slotieJrClaim(address recipient, uint256 giftAmount, uint256 nonce, bytes32[] memory proof) internal {
        uint256 giftApplicable;
        if (proof.length > 0) {
            bytes32 leaf = keccak256(abi.encodePacked(recipient, giftAmount, nonce));
            require(nonce == slotieJrAddressToEHRNonce[recipient], "SLOTIE JR INCORRECT NONCE");
            require(MerkleProof.verify(proof, slotieJrEHRMerkleProof, leaf), "SLOTIE JR INVALID EHR PROOF");
            slotieJrAddressToEHRNonce[recipient] = slotieJrAddressToEHRNonce[recipient] + 1;
            giftApplicable = 1;
        }

        uint256 balance = slotieJrNFT.balanceOf(recipient);
        uint256 lastClaimed = slotieJrAddressToLastClaimedTimeStamp[recipient];
        uint256 currentTime = block.timestamp;

        if (currentTime >= slotieJrClaimEndTime) {
            currentTime = slotieJrClaimEndTime; // we can only claim up to slotieJrClaimEndTime
        }

        if (slotieJrDeployTime > lastClaimed) {
            lastClaimed = slotieJrDeployTime; // we start from time of deployment
        } else if (lastClaimed == slotieJrClaimEndTime) {
            lastClaimed = currentTime; // if we claimed all we set reward to zero
        }
        
        uint256 reward = (currentTime - lastClaimed) * slotieJrIssuanceRate * balance / slotieJrIssuancePeriod;

        if (giftApplicable != 0) {
            reward = reward + giftApplicable;
        }

        slotieJrAddressToLastClaimedTimeStamp[recipient] = currentTime;
        if (reward > 0) {
            _mintClaimable(recipient, reward);
            emit ClaimedRewardFromSlotieJr(recipient, reward, currentTime);
        }     
    }

    function slotieGetClaimableBalance(address recipient, uint256 preClaimAmount, uint256 ehrAmount, uint256 nonce, bytes32[] memory preClaimProof, bytes32[] memory ehrProof) external view returns (uint256) {
        require(address(slotieNFT) != address(0), "SLOTIE NFT NOT SET");

        uint256 preClaimApplicable;
        uint256 ehrApplicable;

        if (preClaimProof.length > 0 && preClaimAmount != 0) {
            bytes32 leaf = keccak256(abi.encodePacked(recipient, preClaimAmount));
            preClaimApplicable = MerkleProof.verify(preClaimProof, slotiePreClaimMerkleProof, leaf) && slotieAddressToPreClaim[recipient] == 0 ? 1 : 0;
        } 
        
        if (ehrProof.length > 0 && ehrAmount != 0) {
            bytes32 leaf = keccak256(abi.encodePacked(recipient, ehrAmount, nonce));
            ehrApplicable = MerkleProof.verify(ehrProof, slotieEHRMerkleProof, leaf) && nonce == slotieAddressToEHRNonce[recipient] ? 1 : 0;
        }

        uint256 balance = slotieNFT.balanceOf(recipient);
        uint256 lastClaimed = slotieAddressToLastClaimedTimeStamp[recipient];  
        uint256 accumulatedWatts = slotieAddressToAccumulatedWATTs[recipient];
        uint256 currentTime = block.timestamp;

        if (currentTime >= slotieClaimEndTime) {
            currentTime = slotieClaimEndTime;
        }

        if (deployedTime > lastClaimed) {
            lastClaimed = deployedTime;
        } else if (lastClaimed == slotieClaimEndTime) {
            lastClaimed = currentTime;
        }
        
        uint256 reward = (currentTime - lastClaimed) * slotieIssuanceRate * balance / slotieIssuancePeriod;

        if (accumulatedWatts != 0) {
            reward = reward + accumulatedWatts;
        }

        if (preClaimApplicable != 0) {
            reward = reward + preClaimAmount;
        }

        if (ehrApplicable != 0) {
            reward = reward + ehrAmount;
        }

        return reward;
    }

    function slotieJrGetClaimableBalance(address recipient, uint256 giftAmount, uint256 nonce, bytes32[] memory proof) external view returns (uint256) {
        require(address(slotieJrNFT) != address(0), "SLOTIE JR NFT NOT SET");

        uint256 giftApplicable;
        if (proof.length > 0) {
            bytes32 leaf = keccak256(abi.encodePacked(recipient, giftAmount, nonce));
            giftApplicable = MerkleProof.verify(proof, slotieJrEHRMerkleProof, leaf) && nonce == slotieJrAddressToEHRNonce[recipient] ? 1 : 0;
        }

        uint256 balance = slotieJrNFT.balanceOf(recipient);
        uint256 lastClaimed = slotieJrAddressToLastClaimedTimeStamp[recipient];
        uint256 currentTime = block.timestamp;

        if (currentTime >= slotieJrClaimEndTime) {
            currentTime = slotieJrClaimEndTime;
        }

        if (slotieJrDeployTime > lastClaimed) {
            lastClaimed = slotieJrDeployTime;
        } else if (lastClaimed == slotieJrClaimEndTime) {
            lastClaimed = currentTime;
        }
        
        uint256 reward = (currentTime - lastClaimed) * slotieJrIssuanceRate * balance / slotieJrIssuancePeriod;

        if (giftApplicable != 0) {
            reward = reward + giftApplicable;
        }

        return reward;
    }

    function slotieClaim(uint256 preClaimAmount, uint256 ehrAmount, uint256 nonce, bytes32[] memory preClaimProof, bytes32[] memory ehrProof) external slotieCanClaim {
        _slotieClaim(msg.sender, preClaimAmount, ehrAmount, nonce, preClaimProof, ehrProof);
    }

    function slotieJrClaim(uint256 giftAmount, uint256 nonce, bytes32[] calldata proof) external slotieJrCanClaim {
        _slotieJrClaim(msg.sender, giftAmount, nonce, proof);
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(slotieNFT), "ONLY CALLABLE FROM SLOTIE");
        bytes32[] memory empty;

        if (from != address(0)) {
            _slotieClaim(from, 0, 0, 0, empty, empty);
        }

        if (to != address(0)) {
            _slotieClaim(to, 0, 0, 0, empty, empty);
        }
    }

    function slotieJrUpdateReward(address from, address to) external {
        require(msg.sender == address(slotieJrNFT), "ONLY CALLABLE FROM SLOTIE JR");
        bytes32[] memory empty;

        if (from != address(0)) {
            _slotieJrClaim(from, 0, 0, empty);
        }
        
        if (to != address(0)) {
            _slotieJrClaim(to, 0, 0, empty);
        }
    }

    /** TRANSFERS */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override notBlackListed(from) {
        if (from != address(0)) {
            uint256 claimableBalanceSender = _claimableBalances[from];
            if (block.timestamp >= deployedTime + lockPeriod && claimableBalanceSender != 0) {
                _burnClaimable(from, claimableBalanceSender);
                _mint(from, claimableBalanceSender);
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override notBlackListed(sender) notBlackListed(recipient) {
        if(
            block.timestamp >= blackListPeriodStart && 
            block.timestamp < blackListPeriodStart + blackListPeriod && 
           !isDex[recipient] &&
           recipient != address(0)) {
            isBlackListed[recipient] = true; // black list buyers that are not dex and buy in blacklist period
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    /** VIEW */
    function seeClaimableBalanceOfUser(address user) external view onlyOwner returns(uint256) {
        return _claimableBalances[user];
    }

    function seeClaimableTotalSupply() external view onlyOwner returns(uint256) {
        return _claimableTotalSupply;
    }

    /** ROLE BASED */    
    function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyRole(BURNER_ROLE) {
        _burn(_from, _amount);
    }

    function _mintClaimable(address _to, uint256 _amount) internal {
        require(_to != address(0), "ERC20-claimable: mint to the zero address");

        _claimableBalances[_to] += _amount;
        _claimableTotalSupply += _amount;
    }

    function mintClaimable(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mintClaimable(_to, _amount);
    }

    function _burnClaimable(address _from, uint256 _amount) internal {
        require(_from != address(0), "ERC20-claimable: burn from the zero address");

        uint256 accountBalance = _claimableBalances[_from];
        require(accountBalance >= _amount, "ERC20-claimable: burn amount exceeds balance");
        unchecked {
            _claimableBalances[_from] = accountBalance - _amount;
        }
        _claimableTotalSupply -= _amount;
    }

    function burnClaimable(address _from, uint256 _amount) public onlyRole(BURNER_ROLE) {
        _burnClaimable(_from,  _amount);
    }


    /** OWNER */
    function setSlotieNFT(address newSlotieNFT) external onlyOwner {
        slotieNFT = IERC721(newSlotieNFT);
        emit setSlotieNFTEvent(newSlotieNFT);
    }

    function setSlotieJrNFT(address newSlotieJrNFT) external onlyOwner {
        slotieJrNFT = IERC721(newSlotieJrNFT);
        emit setSlotieJrNFTEvent(newSlotieJrNFT);
    }

    function setDeployTime(uint256 newDeployTime) external onlyOwner {
        deployedTime = newDeployTime;
        emit setDeployTimeEvent(newDeployTime);
    }

    function setLockPeriod(uint256 newLockPeriod) external onlyOwner {
        lockPeriod = newLockPeriod;
        emit setLockPeriodEvent(newLockPeriod);
    }

    /** Slotie Claim variables */
    function setSlotieIssuanceRate(uint256 newSlotieIssuanceRate) external onlyOwner {
        slotieIssuanceRate = newSlotieIssuanceRate;
        emit setSlotieIssuanceRateEvent(newSlotieIssuanceRate);
    }

    function setSlotieIssuancePeriod(uint256 newSlotieIssuancePeriod) external onlyOwner {
        slotieIssuancePeriod = newSlotieIssuancePeriod;
        emit setSlotieIssuancePeriodEvent(newSlotieIssuancePeriod);
    }

    function setSlotieClaimStart(uint256 newSlotieClaimStart) external onlyOwner {
        slotieClaimStart = newSlotieClaimStart;
        emit setSlotieClaimStartEvent(newSlotieClaimStart);
    }

    function setSlotieEarnPeriod(uint256 newSlotieEarnPeriod) external onlyOwner {
        slotieEarnPeriod = newSlotieEarnPeriod;       
        emit setSlotieEarnPeriodEvent(newSlotieEarnPeriod);
    }

    function setSlotieClaimEndTime(uint256 newSlotieClaimEndTime) external onlyOwner {
        slotieClaimEndTime = newSlotieClaimEndTime;
        emit setSlotieClaimEndTimeEvent(newSlotieClaimEndTime);
    }

    function setSlotiePreClaimMerkleProof(bytes32 newSlotiePreClaimMerkleProof) external onlyOwner {
        slotiePreClaimMerkleProof = newSlotiePreClaimMerkleProof;
        emit setSlotiePreClaimMerkleProofEvent(newSlotiePreClaimMerkleProof);
    }

    function setSlotieEHRMerkleProof(bytes32 newSlotieEHRMerkleProof) external onlyOwner {
        slotieEHRMerkleProof = newSlotieEHRMerkleProof;
        emit setSlotieEHRMerkleProofEvent(newSlotieEHRMerkleProof);
    }

    function setSlotieDeployTimeAndClaimEndTime(uint256 newDeployTime, uint256 newSlotieClaimEndTime) external onlyOwner {
        deployedTime = newDeployTime;
        slotieClaimEndTime = newSlotieClaimEndTime;
        emit setDeployTimeEvent(newDeployTime);
        emit setSlotieClaimEndTimeEvent(newSlotieClaimEndTime);
    }

    /** Slotie Jr. Claim variables */
    function setSlotieJrIssuanceRate(uint256 newSlotieJrIssuanceRate) external onlyOwner {
        slotieJrIssuanceRate = newSlotieJrIssuanceRate;
        emit setSlotieJrIssuanceRateEvent(newSlotieJrIssuanceRate);
    }

    function setSlotieJrIssuancePeriod(uint256 newSlotieJrIssuancePeriod) external onlyOwner {
        slotieJrIssuancePeriod = newSlotieJrIssuancePeriod;
        emit setSlotieJrIssuancePeriodEvent(newSlotieJrIssuancePeriod);
    }

    function setSlotieJrDeployTime(uint256 newSlotieJrDeployTime) external onlyOwner {
        slotieJrDeployTime = newSlotieJrDeployTime;
        emit setSlotieJrDeployTimeEvent(newSlotieJrDeployTime);
    }

    function setSlotieJrEarnPeriod(uint256 newSlotieJrEarnPeriod) external onlyOwner {
        slotieJrEarnPeriod = newSlotieJrEarnPeriod;
        emit setSlotieJrEarnPeriodEvent(newSlotieJrEarnPeriod);
    }

    function setSlotieJrClaimEndTime(uint256 newSlotieJrClaimEndTime) external onlyOwner {
        slotieJrClaimEndTime = newSlotieJrClaimEndTime;
        emit setSlotieJrClaimEndTimeEvent(newSlotieJrClaimEndTime);
    }

    function setSlotieJrEHRMerkleProof(bytes32 newSlotieJrEHRMerkleProof) external onlyOwner {
        slotieJrEHRMerkleProof = newSlotieJrEHRMerkleProof;
        emit setSlotieJrEHRMerkleProofEvent(newSlotieJrEHRMerkleProof);
    }

    function setSlotieJrDeployTimeAndClaimEndTime(uint256 newSlotieJrDeployTime, uint256 newSlotieJrClaimEndTime) external onlyOwner {
        slotieJrDeployTime = newSlotieJrDeployTime;        
        slotieJrClaimEndTime = newSlotieJrClaimEndTime;
        emit setSlotieJrDeployTimeEvent(newSlotieJrDeployTime);
        emit setSlotieJrClaimEndTimeEvent(newSlotieJrClaimEndTime);
    }

    /** ANTI SNIPE */
    function setBlackListPeriodStart(uint256 newBlackListPeriodStart) external onlyOwner {
        blackListPeriodStart = newBlackListPeriodStart;
    }

    function setBlackListPeriod(uint256 newBlackListPeriod) external onlyOwner {
        blackListPeriod = newBlackListPeriod;
    }

    function setIsBlackListed(address _address, bool _isBlackListed) external onlyOwner {
        isBlackListed[_address] = _isBlackListed;
    }

    function setIsDex(address _address, bool _isDex) external onlyOwner {
        isDex[_address] = _isDex;
    }
}