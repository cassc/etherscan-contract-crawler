// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ERC721 Staking Smart Contract
 *
 * @author framework: andreitoma8, modified by curion for use with The Connors (theconnors.xyz)
 * 
 */

/**
    Features

    > User can stake and withdraw freely, and burn when a certain time threshold is passed
    > when a user stakes, a staking sbt is minted on another contract which displays their staking activity
    > Staking points are accumulated as: the sum of all hours staked for all connors owned by an address.
    > When a user withdraws or burns a connor, the points accrued by this connor *disappear*
    >

 */

interface IReceipt {
    function mintStakingSBT() external;
    function emitMetadataUpdate() external;
}

contract CONNORS_STAKING is Ownable, ReentrancyGuard, Pausable {

    IERC721 public nftCollection;
    IReceipt public receiptContract;
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public lockTimestamp;
    uint256 constant SECONDS_IN_HOUR = 3600;
    uint256 public constant timeToPointsNum = 1;
    uint256 public constant timeToPointsDenom = 3600; //for converting seconds staked to hours (seconds * (1/3600))
    uint256 public burnThresholdPercentage = 100; //percentage of stakers who can burn their tokens, 100 = 100% (for testing)
    uint256 public burnThresholdTimeInSeconds = 120; //time in seconds -- testing = 120 seconds
    bool public ranksAreLocked;

    struct Staker {
        uint256[] stakedTokenIds;
        uint256[] burnedTokenIds;
        uint256[] stakeTimestamp;
        uint256 numSetbacks;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;
    address[] public stakersArray;
    mapping(address => uint256) public stakerToArrayIndex;
    mapping(uint256 => uint256) public tokenIdToArrayIndex;
    mapping(address => bool) public userHasStakedBefore;
    mapping(uint256 => address) public tokenIdToBurnerAddress;
    mapping(uint256 => string) public tokenIdToBtcAddress;


    error ForwardFailed();

    constructor(address _nftCollection, address _receiptAddress) {
        nftCollection = IERC721(_nftCollection);
        receiptContract = IReceipt(_receiptAddress);   
    }

    receive () external payable {}
    fallback() external payable {} //when msg.data is not empty

    /**
     * @notice Function used to stake ERC721 Tokens.
     * @param _tokenIds - The array of Token Ids to stake.
     * @dev Each Token Id must be approved for transfer by the user before calling this function.
     */
    function stake(uint256[] calldata _tokenIds) external whenNotPaused nonReentrant {
        require(_tokenIds.length > 0, "You must stake at least one token");

        Staker storage staker = stakers[msg.sender];

        if (staker.stakedTokenIds.length == 0 && userHasStakedBefore[msg.sender] == false) {
            stakersArray.push(msg.sender);
            stakerToArrayIndex[msg.sender] = stakersArray.length - 1;
            userHasStakedBefore[msg.sender] = true;
        }

        for (uint256 i; i < _tokenIds.length; ++i) {
            require(nftCollection.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake tokens you don't own!");

            nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);

            staker.stakedTokenIds.push(_tokenIds[i]);
            staker.stakeTimestamp.push(block.timestamp);
            tokenIdToArrayIndex[_tokenIds[i]] = staker.stakedTokenIds.length - 1;
            stakerAddress[_tokenIds[i]] = msg.sender;
        }

        stakers[msg.sender] = staker;

        /// @notice only mint new staking receipt if the user hasn't already started staking in the past. 
        if(IERC721(address(receiptContract)).balanceOf(msg.sender) == 0){
            receiptContract.mintStakingSBT();
        } 

        receiptContract.emitMetadataUpdate();

    }

    /**
     * @notice Function used to withdraw ERC721 Tokens.
     * @param _tokenIds - The array of Token Ids to withdraw.
     */
    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.stakedTokenIds.length > 0, "You have no tokens staked");

        for (uint256 i; i < _tokenIds.length; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);

            uint256 index = tokenIdToArrayIndex[_tokenIds[i]];
            uint256 lastTokenIndex = staker.stakedTokenIds.length - 1;
            if (index != lastTokenIndex) {
                staker.stakedTokenIds[index] = staker.stakedTokenIds[lastTokenIndex];
                tokenIdToArrayIndex[staker.stakedTokenIds[index]] = index;
                staker.stakeTimestamp[index] = staker.stakeTimestamp[lastTokenIndex];
            }
            staker.stakedTokenIds.pop();
            staker.stakeTimestamp.pop(); //also remove the timestamps to keep both arrays of ids/timestamps at the same length...

            delete stakerAddress[_tokenIds[i]];


            nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        stakers[msg.sender] = staker;

    }

    function burn(uint256[] calldata _tokenIds, string memory _btcAddress) external nonReentrant {
        // remove input token Ids from the staker's stakedTokenIds array
        Staker storage staker = stakers[msg.sender];
        require(staker.stakedTokenIds.length > 0, "You have no tokens staked");
        require(getUserTimeStaked(msg.sender) >= burnThresholdTimeInSeconds, "You do not meet burn criteria");

        for (uint256 i; i < _tokenIds.length; ++i) {
            require(stakerAddress[_tokenIds[i]] == msg.sender);

            uint256 index = tokenIdToArrayIndex[_tokenIds[i]];
            uint256 lastTokenIndex = staker.stakedTokenIds.length - 1;
            if (index != lastTokenIndex) {
                staker.stakedTokenIds[index] = staker.stakedTokenIds[lastTokenIndex];
                tokenIdToArrayIndex[staker.stakedTokenIds[index]] = index;
                staker.stakeTimestamp[index] = staker.stakeTimestamp[lastTokenIndex];
            }
            staker.stakedTokenIds.pop();
            staker.stakeTimestamp.pop();

            delete stakerAddress[_tokenIds[i]];

            //add this token ID to burnedTokenIds array
            staker.burnedTokenIds.push(_tokenIds[i]);

            nftCollection.transferFrom(address(this), burnAddress, _tokenIds[i]);
        }

        stakers[msg.sender] = staker;

        receiptContract.emitMetadataUpdate();

        _setBtcAddressForBurnerAddressTokenIds(msg.sender, _tokenIds, _btcAddress);
        
    }

    function _setBtcAddressForBurnerAddressTokenIds(address _burnerAddress, uint256[] memory _tokenIds, string memory _btcAddress) private {
        for (uint256 i; i < _tokenIds.length; ++i) {
            tokenIdToBurnerAddress[_tokenIds[i]] = _burnerAddress;
            tokenIdToBtcAddress[_tokenIds[i]] = _btcAddress;
        }
    }


    ///@notice function to set the BTC address for burned tokens. can only be called after burning a token ID.
    function setBtcAddressForBurnedTokens(uint256[] memory _tokenIds, string memory _btcAddress) external {
        require(_tokenIds.length > 0, "You must provide at least one token ID");

        for (uint256 i; i < _tokenIds.length; ++i) {
            require(tokenIdToBurnerAddress[_tokenIds[i]] == msg.sender, "You can only set BTC address for your own burned tokens");
            tokenIdToBtcAddress[_tokenIds[i]] = _btcAddress;
        }
    }

    function userRankPercentile(address _user) public view returns (uint256) {
        uint256 userRank = getRankOfAddress(_user, getTimestampInUse());
        uint256 percentile = Math.mulDiv(userRank, 100, stakersArray.length); //outputs percentage x 100, i.e. 1.5% = 150
        return percentile;
    }

    /**
     * @notice Function used to get the info for a user: the Token Ids staked and the available rewards.
     * @param _user - The address of the user.
     */
    function userStakeInfo(address _user)
        public
        view
        returns (uint256[] memory _stakedTokenIds, uint256[] memory _stakeTimestamp)
    {
        uint256[] memory stakeTimesTemp = new uint256[](stakers[_user].stakedTokenIds.length);
        for (uint256 i; i < stakers[_user].stakedTokenIds.length; ++i) {
            stakeTimesTemp[i] = block.timestamp - stakers[_user].stakeTimestamp[i];
        }
        return (stakers[_user].stakedTokenIds, stakers[_user].stakeTimestamp);
    }

    function outputAmountStaked(address _owner) external view returns (uint256) {
        return stakers[_owner].stakedTokenIds.length;
    }   

    function outputUserStakedIds(address _owner) external view returns (uint256[] memory) {
        return stakers[_owner].stakedTokenIds;
    }

    function outputAmountBurned(address _owner) external view returns (uint256) {
        return stakers[_owner].burnedTokenIds.length;
    }

    function outputUserBurnedIds(address _owner) external view returns (uint256[] memory) {
        return stakers[_owner].burnedTokenIds;
    }

    function outputTotalPoints(address _owner) external view returns (uint256) {
        uint256 totalTimeStaked = getUserTimeStaked(_owner);
        return Math.mulDiv(totalTimeStaked, timeToPointsNum, timeToPointsDenom);
    }

    function getUserTimeStaked(address _owner) public view returns (uint256) {
        uint256 totalTimeStaked = 0;
        for (uint256 i; i < stakers[_owner].stakedTokenIds.length; ++i) {
            totalTimeStaked += getTimestampInUse() - stakers[_owner].stakeTimestamp[i];
        }
        return totalTimeStaked;
    }

    function outputRankByTimeStaked(uint256 _timestamp) public view returns (address[] memory, uint256[] memory) {
        uint256[] memory stakeTimesTemp = new uint256[](stakersArray.length);
        for (uint256 i; i < stakersArray.length; ++i) {
            Staker memory thisStaker = stakers[stakersArray[i]];

            //total stake time for this staker is the sum of all the stake times
            for(uint256 j; j < thisStaker.stakedTokenIds.length; ++j) {
                stakeTimesTemp[i] += _timestamp - thisStaker.stakeTimestamp[j];
            }
        }

        uint256[] memory sortedStakeTimes = new uint256[](stakersArray.length);
        address[] memory sortedStakersArray = new address[](stakersArray.length);
        
        for (uint256 i; i < stakersArray.length; ++i) {
            sortedStakeTimes[i] = stakeTimesTemp[i];
            sortedStakersArray[i] = stakersArray[i];
        }

        for (uint256 i; i < stakersArray.length; ++i) {
            for (uint256 j; j < stakersArray.length - 1; ++j) {
                if (sortedStakeTimes[j] < sortedStakeTimes[j + 1]) {
                    uint256 temp = sortedStakeTimes[j];
                    sortedStakeTimes[j] = sortedStakeTimes[j + 1];
                    sortedStakeTimes[j + 1] = temp;

                    address temp2 = sortedStakersArray[j];
                    sortedStakersArray[j] = sortedStakersArray[j + 1];
                    sortedStakersArray[j + 1] = temp2;
                }
            }
        }

        return(sortedStakersArray, sortedStakeTimes);
    }


    function getRankOfAddress(address _address, uint256 _timestamp) public view returns (uint256) {
        (address[] memory sortedStakersArray, ) = outputRankByTimeStaked(_timestamp);

        for(uint256 i; i < sortedStakersArray.length; ++i) {
            if(sortedStakersArray[i] == _address) {
                return i+1; //add 1 for ranks starting from 1
            }
        }

        revert("Address not found in stakers array");
    }

    function getTimestampInUse() public view returns (uint256) {
        if(ranksAreLocked){
            return lockTimestamp;
        } else {
            return block.timestamp;
        }
    }

    // setters

    function setBurnTimeThresholdInSeconds(uint256 _seconds) external onlyOwner {
        burnThresholdTimeInSeconds = _seconds;
    }

    function unlockRanks() external onlyOwner {
        ranksAreLocked = false;
    }

    function lockRanks() external onlyOwner {
        lockTimestamp = block.timestamp;
        ranksAreLocked = true;
    }

    function setNftCollection(address _nftCollection) external onlyOwner {
        nftCollection = IERC721(_nftCollection);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //=========================================================================
    // WITHDRAWALS
    //=========================================================================

    function withdrawERC20FromContract(address _to, address _token) external onlyOwner {
        bool os = IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        if(!os){ revert ForwardFailed(); }
    }

    function withdrawEthFromContract(address _withdrawAddress) external onlyOwner  {
        require(_withdrawAddress != address(0), "Payment splitter address not set");
        (bool os, ) = payable(_withdrawAddress).call{ value: address(this).balance }('');
        if(!os){ revert ForwardFailed(); }
    }

}