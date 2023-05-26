// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "Ownable.sol";
import "SafeERC20.sol";
import "ECDSA.sol";


contract Harvest is Ownable {

    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    // user struct
    struct UserInfo {
        uint256 rewardDebt;         // harvested tokens
        uint256 lastBlock;
    }

    struct RewardInfo {
        address rewardToken;
        address transferFrom;
        bool isValid;
    }

    address public defaultRewardToken;

    mapping (address => mapping(address => UserInfo)) private userRewardInfo;

    // user => rewardToken => RewardInfo
    mapping (address => mapping(address => RewardInfo)) public trustedSigner;

    event NewUser(address indexed user);
    event UserHarvest(
        address indexed user,
        uint256 _amount,
        uint256 lastBlockNumber,
        uint256 currentBlockNumber,
        address rewardToken
    );

    /**
      * @param _defaultRewardToken address of default reward token
      */
    constructor(address _defaultRewardToken) {
        trustedSigner[_defaultRewardToken][msg.sender].isValid = true;
        defaultRewardToken = _defaultRewardToken;
    }

    // rewardToken => stage
    mapping(address => uint) public currentStage;
    // rewardToken => stage => timestamp end date
    mapping(address => mapping(uint => uint)) public endStageDate;
    // rewardToken => stage => user => true/false
    mapping(address => mapping(uint => mapping(address => bool))) public claimedInStage;
    /**
      * @dev main function for getting tokens
      * @param _amount amount of tokens - wei style
      * @param _lastBlockNumber last block of user activity in contract (getLastBlock)
      * @param _currentBlockNumber block number, when signature created
      * @param _msgForSign hashed data with prefix
      * @param _signature signed data
      * @param _rewardToken address of tokens, which user get
      */
    function harvest(
        uint256 _amount, 
        uint256 _lastBlockNumber, 
        uint256 _currentBlockNumber, 
        bytes32 _msgForSign, 
        bytes memory _signature,
        address _rewardToken

    ) external 
    {
        if(block.timestamp > endStageDate[_rewardToken][currentStage[_rewardToken]]) {
            //change stage
            while(block.timestamp > endStageDate[_rewardToken][currentStage[_rewardToken]]) {
                currentStage[_rewardToken]++;
            }
        }
        require(!claimedInStage[_rewardToken][currentStage[_rewardToken]][msg.sender], "claimed in this stage");
        require(_currentBlockNumber <= block.number, "Harvest::harvest: currentBlockNumber larger than lastBlock");

        //Double spend check
        require(getLastBlock(msg.sender, _rewardToken) == _lastBlockNumber, "Harvest::harvest: lastBlockNumber error");

        //1. Lets check signer
        address signedBy = _msgForSign.recover(_signature);
        require(trustedSigner[_rewardToken][signedBy].isValid == true, "Harvest::harvest: signature check failed");

        //2. Check signed msg integrety
        bytes32 actualMsg = getMsgForSign(
            _amount,
            _lastBlockNumber,
            _currentBlockNumber,
            msg.sender,
            _rewardToken
        );
        require(actualMsg.toEthSignedMessageHash() == _msgForSign,"Harvest::harvest: integrety check failed");

        //Actions

        userRewardInfo[msg.sender][_rewardToken].rewardDebt += _amount;
        userRewardInfo[msg.sender][_rewardToken].lastBlock = _currentBlockNumber;
        if (_amount > 0) {
            IERC20 ERC20Token = IERC20(_rewardToken);
            ERC20Token.safeTransferFrom(trustedSigner[_rewardToken][signedBy].transferFrom, msg.sender, _amount);
        }
        claimedInStage[_rewardToken][currentStage[_rewardToken]][msg.sender]=true;
        emit UserHarvest(msg.sender, _amount, _lastBlockNumber, _currentBlockNumber, _rewardToken);
    }

    /**
      * @dev get last block of user activity in contract
      * @param _user address of user
      * @param _rewardToken address of reward token
      * @return block number, 0 - if its new user 
      */

    function getLastBlock(address _user, address _rewardToken) public view returns(uint256) {
        return userRewardInfo[_user][_rewardToken].lastBlock;
    }

    /**
      * @dev return amount of tokens, which user claim before (during all time)
      * @param _user address of user
      * @param _rewardToken address of reward token
      * @return amount of tokens
      */

    function getRewards(address _user, address _rewardToken) public view returns(uint256) {
        return userRewardInfo[_user][_rewardToken].rewardDebt;
    }


    /**
      * @dev return hashed data
      * @param _amount amount of tokens
      * @param _lastBlockNumber last block of user activity
      * @param _currentBlockNumber current block number
      * @param _sender user address
      * @param _rewardToken address of token contract
      * @return hashed data
      */

    function getMsgForSign(
        uint256 _amount, 
        uint256 _lastBlockNumber, 
        uint256 _currentBlockNumber, 
        address _sender,
        address _rewardToken
    )
        internal pure returns(bytes32) 
    {
        return keccak256(abi.encode( _amount, _lastBlockNumber, _currentBlockNumber, _sender, _rewardToken));
    }


    ////////////////////////////////////////////////////////////
    /////////// Admin only           ////////////////////////////
    ////////////////////////////////////////////////////////////

    /**
      * @dev set signer address and other settings
      * @param _rewardToken address of token, which user can get
      * @param _signer address of signer
      * @param _transferFrom address of token keeper
      * @param _isValid true/false
      */
      
    function setTrustedSigner(
            address _rewardToken,
            address _signer,
            address _transferFrom,
            bool _isValid
            ) public onlyOwner {
        trustedSigner[_rewardToken][_signer].isValid = _isValid;
        trustedSigner[_rewardToken][_signer].transferFrom = _transferFrom;
    }

    function setEndStageDate(
            uint[] memory stage, 
            uint[] memory endDate, 
            uint _currentStage, 
            address rewardToken
            ) public onlyOwner {
        currentStage[rewardToken] = _currentStage;
        for(uint i=0;i<stage.length;i++) {
            endStageDate[rewardToken][stage[i]] = endDate[i];
        }
    }
}