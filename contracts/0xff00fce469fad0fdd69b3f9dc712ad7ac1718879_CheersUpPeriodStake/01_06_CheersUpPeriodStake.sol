// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

/**
 * @title CheersUpPeriodStake
 * @author BaseLabs
 */
contract CheersUpPeriodStake is Ownable, ReentrancyGuard {
    event StakeStarted(uint256 indexed tokenId, address indexed account);
    event StakeStopped(uint256 indexed tokenId, address indexed account);
    event StakeInterrupted(uint256 indexed tokenId);
    event StakeConfigChanged(StakeConfig config);
    event TransferUnstakingToken(uint256 indexed tokenId, address indexed account);
    event StakingTokenTransfered(address indexed from, address indexed to, uint256 indexed tokenId);
    event Withdraw(address indexed account, uint256 amount);

    struct StakeStatus {
        address owner;
        uint256 lastStartTime;
        uint256 total;
    }
    struct StakeConfig {
        uint256 startTime;
        uint256 endTime;
    }
    struct StakeReward {
        bool isStaking;
        uint256 total;
        uint256 current;
        address owner;
    }
    string public name = "Cheers UP Period Stake";
    string public symbol = "CUPS";
    StakeConfig public stakeConfig;
    address public cheersUpPeriodContractAddress;
    mapping(uint256 => StakeStatus) private _stakeStatuses;
    IERC721 cheersUpPeriodContract;

    constructor(address cheersUpPeriodContractAddress_, StakeConfig memory stakeConfig_) {
        require(cheersUpPeriodContractAddress_ != address(0), "cheers up period contract address is required");
        cheersUpPeriodContractAddress = cheersUpPeriodContractAddress_;
        cheersUpPeriodContract = IERC721(cheersUpPeriodContractAddress);
        stakeConfig = stakeConfig_;
    }

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice _stake is used to set the stake state of NFT.
     * @param owner_ the owner of the token
     * @param tokenId_ the tokenId of the token
     */
    function _stake(address owner_, uint256 tokenId_) internal {
        require(isStakeEnabled(), "stake is not allowed");
        StakeStatus storage status = _stakeStatuses[tokenId_];
        require(status.lastStartTime == 0, "token is staking");
        status.owner = owner_;
        status.lastStartTime = block.timestamp;
        emit StakeStarted(tokenId_, owner_);
    }

    /**
     * @notice unstake is used to release the stake state of a batch of tokenId.
     * @param tokenIds_ the tokenIds to operate
     */
    function unstake(uint256[] calldata tokenIds_) external nonReentrant {
        for (uint256 i; i < tokenIds_.length; i++) {
            _unstake(tokenIds_[i]);
        }
    }

    /**
     * @notice _unstake is used to release the stake status of a token.
     * @param tokenId_ the tokenId to operate
     */
    function _unstake(uint256 tokenId_) internal {
        StakeStatus storage status = _stakeStatuses[tokenId_];
        require(status.lastStartTime > 0, "token is not staking");
        require(status.owner == msg.sender || owner() == msg.sender, "not the owner");
        cheersUpPeriodContract.safeTransferFrom(address(this), status.owner, tokenId_);
        status.total += block.timestamp - status.lastStartTime;
        status.lastStartTime = 0;
        status.owner = address(0);
        emit StakeStopped(tokenId_, msg.sender);
    }

    /**
     * @notice safeTransferWhileStaking is used to transfer NFT ownership in the staked state.
     * @param to_ the address to which the `token owner` will be transferred
     * @param tokenId_ the tokenId to operate
     */
    function safeTransferWhileStaking(address to_, uint256 tokenId_) external nonReentrant {
        StakeStatus storage status = _stakeStatuses[tokenId_];
        require(status.lastStartTime > 0, "token is not staking");
        require(status.owner == msg.sender, "not the owner");
        status.owner = to_;
        emit StakingTokenTransfered(msg.sender, to_, tokenId_);
    }


    /***********************************|
    |             Getter                |
    |__________________________________*/

    /**
     * @notice getStakeReward is used to get the stake status of the token.
     * @param tokenId_ tokenId
     */
    function getStakeReward(uint256 tokenId_) external view returns (StakeReward memory) {
        StakeStatus memory status = _stakeStatuses[tokenId_];
        StakeReward memory reward;
        if (status.lastStartTime != 0) {
            reward.isStaking = true;
            reward.owner = status.owner;
            reward.current = block.timestamp - status.lastStartTime;
        }
        reward.total = status.total + reward.current;
        return reward;
    }
    
    /**
     * @notice isStakeEnabled is used to return whether the stake has been enabled.
     */
    function isStakeEnabled() public view returns (bool) {
        if (stakeConfig.endTime > 0 && block.timestamp > stakeConfig.endTime) {
            return false;
        }
        return stakeConfig.startTime > 0 && block.timestamp > stakeConfig.startTime;
    }

    /***********************************|
    |              Admin                |
    |__________________________________*/

    /**
     * @notice setStakeConfig is used to modify the stake configuration.
     * @param config_ the stake config
     */
    function setStakeConfig(StakeConfig calldata config_) external onlyOwner {
        stakeConfig = config_;
        emit StakeConfigChanged(stakeConfig);
    }

    /**
     * @notice interruptStake is used to forcibly interrupt NFTs in the stake state
     * and return them to their original owners.
     * This process is under the supervision of the community.
     * caution: Because safeTransferFrom is called for refund (when the target address is a contract,  its onERC721Received logic will be triggered), 
     * be sure to set a reasonable GasLimit before calling this method, or check adequately if the target address is a malicious contract to 
     * prevent bear the high gas cost accidentally.
     * @param tokenIds_ the tokenId list
     */
    function interruptStake(uint256[] calldata tokenIds_) external onlyOwner {
        for (uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            _unstake(tokenId);
            emit StakeInterrupted(tokenId);
        }
    }

    /**
     * @notice transferUnstakingTokens is used to return the NFT that was mistakenly transferred into the contract to the original owner.
     * This contract realizes the stake feature through "safeTransferFrom".
     * This method is used to prevent some users from mistakenly using transferFrom (instead of safeTransferFrom) to transfer NFT into the contract.
     * caution: Because safeTransferFrom is called for refund (when the target address is a contract,  its onERC721Received logic will be triggered), 
     * be sure to set a reasonable GasLimit before calling this method, or check adequately if the target address is a malicious contract to 
     * prevent bear the high gas cost accidentally.
     * @param contractAddress_ contract address of NFT
     * @param tokenIds_ the tokenId list
     * @param accounts_ the address list
     */
    function transferUnstakingTokens(address contractAddress_, uint256[] calldata tokenIds_, address[] calldata accounts_) external onlyOwner {
        require(tokenIds_.length == accounts_.length, "tokenIds_ and accounts_ length mismatch");
        require(tokenIds_.length > 0, "no tokenId");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            address account = accounts_[i];
            if (address(this) == contractAddress_) {
                require(_stakeStatuses[tokenId].lastStartTime == 0, "token is staking");
            }
            IERC721(contractAddress_).safeTransferFrom(address(this), account, tokenId);
            emit TransferUnstakingToken(tokenId, account);
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
    |               Hook                |
    |__________________________________*/

    /**
     * @notice onERC721Received is a hook function, which is the key to implementing the stake feature.
     * When the user calls the safeTransferFrom method to transfer the NFT to the current contract, 
     * onERC721Received will be called, and the stake state is modified at this time.
     */
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory
    ) public returns (bytes4) {
        require(msg.sender == cheersUpPeriodContractAddress, "this contract is not allowed");
        _stake(_from, _tokenId);
        return this.onERC721Received.selector;
    }
}