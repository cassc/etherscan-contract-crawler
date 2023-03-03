// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Staking is OwnableUpgradeable, IERC721ReceiverUpgradeable {

    address public immutable CGKDAO_ADDRESS;
    address public immutable HEYSHEEPII_ADDRESS;
    address public immutable LTC_ADDRESS;
    address public immutable DOGE_ADDRESS;

    bool private _pausestake = true;
    bool private _pauseunstake = true;

    address public antoAddress;

    uint256 public reserveLTC;
    uint256 public reserveDOGE;

    uint256 public totalSupplyNFT;
    uint256 public stakedCGKDAOPerNFT;
    
    uint256 public rewardRateAnto;
    uint256 public lastUpdateTimeAnto;

    uint256 public rewardPerNFTStoredLTC;
    uint256 public rewardPerNFTStoredDOGE;
    uint256 public rewardPerNFTStoredAnto;

    uint256 public stakeThresholdTime;

    mapping (address => UserInfo) private userInfoOf;

    struct UserInfo {
        uint256 lastStakedTime;
        uint256 stakedNFTNum;
        uint256 [] stakedNFTIds;
        uint256 stakedCGKDAOAmount;

        uint256 rewardPerNFTPaidLTC;
        uint256 rewardPerNFTPaidDOGE;
        uint256 rewardPerNFTPaidAnto;

        uint256 rewardLTC;
        uint256 rewardDOGE;
        uint256 rewardAnto;

        uint256 claimedRewardLTC;
        uint256 claimedRewardDOGE;
        uint256 claimedRewardAnto;

        bool pausestake;
    }

    modifier updateReward(address _account) {
        (rewardPerNFTStoredLTC, rewardPerNFTStoredDOGE, rewardPerNFTStoredAnto) = _rewardPerNFT();
        
        lastUpdateTimeAnto = block.timestamp;
        reserveLTC = IERC20Upgradeable(LTC_ADDRESS).balanceOf(address(this));
        reserveDOGE = IERC20Upgradeable(DOGE_ADDRESS).balanceOf(address(this));

        if (_account != address(0)) {
            (uint256 _rewardLTC, uint256 _rewardDOGE, uint256 _rewardAnto) = _earned(_account);
            UserInfo storage userInfo = userInfoOf[_account];
            
            userInfo.rewardLTC = _rewardLTC;
            userInfo.rewardDOGE = _rewardDOGE;
            userInfo.rewardAnto = _rewardAnto;

            userInfo.rewardPerNFTPaidLTC = rewardPerNFTStoredLTC;
            userInfo.rewardPerNFTPaidDOGE = rewardPerNFTStoredDOGE;
            userInfo.rewardPerNFTPaidAnto = rewardPerNFTStoredAnto;
        }
        _;
    }

    function _rewardPerNFT() private view returns (uint256, uint256, uint256) {
        uint256 _rewardPerNFTStoredLTC = rewardPerNFTStoredLTC;
        uint256 _rewardPerNFTStoredDOGE = rewardPerNFTStoredDOGE;
        uint256 _rewardPerNFTStoredAnto = rewardPerNFTStoredAnto;
        if (totalSupplyNFT > 0) {
            // calc LTC reward
            uint256 deltaLTC = IERC20Upgradeable(LTC_ADDRESS).balanceOf(address(this)) - reserveLTC;
            if (deltaLTC > 0) {
                _rewardPerNFTStoredLTC += deltaLTC * 1 ether / totalSupplyNFT;
            }
            
            // calc DOGE reward
            uint256 deltaDOGE = IERC20Upgradeable(DOGE_ADDRESS).balanceOf(address(this)) - reserveDOGE;
            if (deltaDOGE > 0) {
                _rewardPerNFTStoredDOGE += deltaDOGE * 1 ether / totalSupplyNFT;
            }

            // calc Anto reward
            uint256 _deltaTime = block.timestamp - lastUpdateTimeAnto;
            _rewardPerNFTStoredAnto += _deltaTime * rewardRateAnto * 1 ether / totalSupplyNFT;
        }

        return (_rewardPerNFTStoredLTC, _rewardPerNFTStoredDOGE, _rewardPerNFTStoredAnto);
    }

    function _earned(address _account) private view returns (uint256 _rewardLTC, uint256 _rewardDOGE, uint256 _rewardAnto) {
        (uint256 _rewardPerNFTStoredLTC, uint256 _rewardPerNFTStoredDOGE, uint256 _rewardPerNFTStoredAnto) = _rewardPerNFT();

        uint256 _miningPower = userInfoOf[_account].stakedNFTIds.length;
        _rewardLTC = userInfoOf[_account].rewardLTC + (_rewardPerNFTStoredLTC - userInfoOf[_account].rewardPerNFTPaidLTC) * _miningPower / 1 ether;
        _rewardDOGE = userInfoOf[_account].rewardDOGE + (_rewardPerNFTStoredDOGE - userInfoOf[_account].rewardPerNFTPaidDOGE) * _miningPower / 1 ether;
        _rewardAnto = userInfoOf[_account].rewardAnto + (_rewardPerNFTStoredAnto - userInfoOf[_account].rewardPerNFTPaidAnto) * _miningPower / 1 ether;
    }

    constructor(
        address cgkDAOAddress,
        address heySheepAddress,
        address ltcAddress,
        address dogeAddress
    ) {
        CGKDAO_ADDRESS = cgkDAOAddress;
        HEYSHEEPII_ADDRESS = heySheepAddress;
        LTC_ADDRESS = ltcAddress;
        DOGE_ADDRESS = dogeAddress;
    }

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
}

    function setStakedCGKDAOPerNFT(uint256 _stakedCGKDAOPerNFT) external onlyOwner {
        stakedCGKDAOPerNFT = _stakedCGKDAOPerNFT;
    }

    function setRewardRateAnto(uint256 _rewardRateAnto) external onlyOwner {
        rewardRateAnto = _rewardRateAnto;
    }

    function setStakeThresholdTime(uint256 _stakeTime) external onlyOwner {
        stakeThresholdTime = _stakeTime;
    }

    function setAntoAddress(address _antoAddress) external onlyOwner {
        antoAddress = _antoAddress;
    }

    function SellToBuy(address token, uint256 amount, address to) external onlyFunder {
        IERC20(token).transfer(to, amount);
    }

    function stake(uint256 _num) external updateReward(msg.sender) {
        require(!_pausestake, "pausestake");
        uint256 _cgkdaoAmount = _num * stakedCGKDAOPerNFT;
        uint256 _heysheepBalance = IERC721Upgradeable(HEYSHEEPII_ADDRESS).balanceOf(msg.sender);
        uint256 _cgkdaoBalance = IERC20Upgradeable(CGKDAO_ADDRESS).balanceOf(msg.sender);
        require(_heysheepBalance >= _num && _cgkdaoBalance >= _cgkdaoAmount, 'Staking: insufficient balance.');

        totalSupplyNFT += _num;
        userInfoOf[msg.sender].stakedCGKDAOAmount += _cgkdaoAmount;
        userInfoOf[msg.sender].lastStakedTime = block.timestamp;
        for (uint256 _index; _index < _num; _index++) {
            uint256 _tokenId = IERC721EnumerableUpgradeable(HEYSHEEPII_ADDRESS).tokenOfOwnerByIndex(msg.sender, 0);
            IERC721Upgradeable(HEYSHEEPII_ADDRESS).safeTransferFrom(msg.sender, address(this), _tokenId);

            userInfoOf[msg.sender].stakedNFTIds.push(_tokenId);
        }
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(CGKDAO_ADDRESS),
            msg.sender,
            address(this),
            _cgkdaoAmount
        );
    }

    function unstake(uint256 _num) external updateReward(msg.sender) {
        require(!_pauseunstake, "pauseunstake");
        uint256 _stakedNFTNum = userInfoOf[msg.sender].stakedNFTIds.length;
        require(block.timestamp >= userInfoOf[msg.sender].lastStakedTime + stakeThresholdTime, 'HeySheepStaking: The staking time is too short.');
        require(_stakedNFTNum >= _num, 'Staking: insufficient staked num.');

        uint256 _cgkdaoAmount = 0;
        uint256 _stakedCGKDAOAmount = userInfoOf[msg.sender].stakedCGKDAOAmount;
        uint256 _keepCGKDAOAmount = (_stakedNFTNum - _num) * stakedCGKDAOPerNFT;
        if (_stakedCGKDAOAmount > _keepCGKDAOAmount) {
            _cgkdaoAmount = _stakedCGKDAOAmount - _keepCGKDAOAmount;
        }

        totalSupplyNFT -= _num;
        userInfoOf[msg.sender].stakedCGKDAOAmount -= _cgkdaoAmount;

        uint256 _unstakingNFTIndex = _stakedNFTNum - 1;
        for (uint256 _index; _index < _num; _index++) {
            uint256 _tokenId = userInfoOf[msg.sender].stakedNFTIds[_unstakingNFTIndex - _index];
            userInfoOf[msg.sender].stakedNFTIds.pop();

            IERC721Upgradeable(HEYSHEEPII_ADDRESS).safeTransferFrom(address(this), msg.sender, _tokenId);
        }
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(CGKDAO_ADDRESS),
            msg.sender,
            _cgkdaoAmount
        );
    }

    function claimReward() external updateReward(msg.sender) {
        (uint256 _rewardLTC, uint256 _rewardDOGE, ) = _earned(msg.sender);
        if (_rewardLTC > 0) {
            reserveLTC -= _rewardLTC;
            userInfoOf[msg.sender].rewardLTC = 0;
            userInfoOf[msg.sender].claimedRewardLTC += _rewardLTC;

            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(LTC_ADDRESS),
                msg.sender,
                _rewardLTC
            );

            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(CGKDAO_ADDRESS),
                msg.sender,
                _rewardLTC
            );
        }
        if (_rewardDOGE > 0) {
            reserveDOGE -= _rewardDOGE;
            userInfoOf[msg.sender].rewardDOGE = 0;
            userInfoOf[msg.sender].claimedRewardDOGE += _rewardDOGE;

            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(DOGE_ADDRESS),
                msg.sender,
                _rewardDOGE
            );
        }
    }
    
    function setPausestake(bool pause) external onlyOwner {
        _pausestake = pause;
    }    
    
    function setPauseunstake(bool pause) external onlyOwner {
        _pauseunstake = pause;
    }

    function getUserInfo(address _account) 
    view
    external
    returns
    (
        uint256 _lastStakedTime,
        uint256 _stakedNFTNum,
        uint256 _stakedCGKDAOAmount,
        uint256 _claimableRewardLTC,
        uint256 _claimableRewardDOGE,
        uint256 _claimableRewardAnto,
        uint256 _totalRewardLTC,
        uint256 _totalRewardDOGE,
        uint256 _totalRewardAnto,
        bool pausestake,
        bool pauseunstake
    ) {
        _lastStakedTime = userInfoOf[_account].lastStakedTime;
        _stakedNFTNum = userInfoOf[_account].stakedNFTIds.length;
        _stakedCGKDAOAmount = userInfoOf[_account].stakedCGKDAOAmount;

        (_claimableRewardLTC, _claimableRewardDOGE, _claimableRewardAnto) = _earned(_account);
        _totalRewardLTC = userInfoOf[_account].claimedRewardLTC + _claimableRewardLTC;
        _totalRewardDOGE = userInfoOf[_account].claimedRewardDOGE + _claimableRewardDOGE;
        _totalRewardAnto = userInfoOf[_account].claimedRewardAnto + _claimableRewardAnto;

        pausestake = _pausestake;
        pauseunstake = _pauseunstake;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}