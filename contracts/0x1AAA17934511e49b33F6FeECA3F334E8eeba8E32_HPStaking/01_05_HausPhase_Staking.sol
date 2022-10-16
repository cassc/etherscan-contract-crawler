// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ReentrancyGuard } from "./lib/solmate/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address _to, uint _amount) external;
}

interface IERC721 {
    function ownerOf(uint256 tokenID) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
}

contract HPStaking is ReentrancyGuard, Ownable, Pausable {
    constructor() {
        phaseRewardRate[1] = 1000;
        phaseRewardRate[2] = 400;
        phaseRewardRate[3] = 100;
    }
    
    /////////////////////////////////////////////////////////
    /// Global variables
    /////////////////////////////////////////////////////////
    IERC20 private _hausToken;
    IERC721 private _hausPhase;

    struct UserInfo {
        uint16[] balances;
        uint256 lastClaimedReward;
        uint256 totalClaimed;
    }

    mapping (address => UserInfo) private userInfo;
    mapping (uint256 => address) private tokenOwner;
    mapping (uint256 => uint256) private phaseRewardRate;

    event Staked(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed from, uint256 amount);

    /////////////////////////////////////////////////////////////////////////////
    ///  Stake/withdraw functions
    /////////////////////////////////////////////////////////////////////////////

    /// @notice            Calculates and claims the rewards for the user
    function claimRewards() external nonReentrant returns (uint) {
        uint lastClaimed = userInfo[msg.sender].lastClaimedReward;
        require(lastClaimed > 0, "ClaimRewards: You need to stake first");

        uint timeBetweenClaims = block.timestamp - lastClaimed;
        uint pendingRewards = timeBetweenClaims * _getRateForUser(msg.sender) / 86400;

        userInfo[msg.sender].lastClaimedReward = block.timestamp;
        userInfo[msg.sender].totalClaimed += pendingRewards;
        _hausToken.mint(msg.sender, pendingRewards);
        emit Claimed(msg.sender, pendingRewards);
        return pendingRewards;
    }

    /// @notice             Stakes multiple tokens for the user and claims pending tokens if there is any
    /// @param _tokenIds    target tokens
    function stakeMultiple(uint16[] calldata _tokenIds) external nonReentrant returns (uint) {
        if (userInfo[msg.sender].lastClaimedReward == 0) userInfo[msg.sender].lastClaimedReward = block.timestamp; // If this is the user's first time interacting with the contract, initialize lastClaimedReward to the current timestamp
        if (userInfo[msg.sender].balances.length > 0) _handleClaim(_getRateForUser(msg.sender));

        emit Staked(msg.sender, _tokenIds.length);
        for(uint i; i < _tokenIds.length;) {
            _stakeNft(_tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return (block.timestamp);
    }

    /// @notice             Withdraws all owned tokens by user and claim tokens for the user
    function withdrawAll() external nonReentrant {
        uint16[] memory tokenIds = userInfo[msg.sender].balances;
        require(tokenIds.length > 0, "Withdraw: Empty balance");

        uint length = tokenIds.length;
        _handleClaim(_getRateForUser(msg.sender));
        
        for(uint i; i < length;) {
            _withdrawNft(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        emit Withdraw(msg.sender, length);
    }

    /// @notice             Withdraws multiple tokens for the user and claims pending if there is any
    /// @param _tokenIds    Target tokenIDs
    function withdrawMultiple(uint16[] calldata _tokenIds) external nonReentrant {
        require(userInfo[msg.sender].balances.length > 0, "Withdraw: Empty balance");
        _handleClaim(_getRateForUser(msg.sender));

        emit Withdraw(msg.sender, _tokenIds.length);
        for(uint i; i < _tokenIds.length;) {
            _withdrawNft(_tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice      Withdraw staked tokens and give up rewards. Only use in case of emergecies
    function emergencyWithdraw() external nonReentrant whenPaused {
        uint16[] memory balance = userInfo[msg.sender].balances;
        uint256 length = balance.length;
        require(length > 0, "Withdraw: Amount must be > 0");

        // Reset internal value for user
        userInfo[msg.sender].lastClaimedReward = block.timestamp;

        emit EmergencyWithdraw(msg.sender, length);
        for(uint i; i < length;){
            _withdrawNft(balance[i]);
            unchecked {
                ++i;
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////
    ///  Internal functions
    /////////////////////////////////////////////////////////////////////////////

    /// @notice             Internal function to stake a single token for the user
    /// @param  _tokenId    Target token
    function _stakeNft(uint16 _tokenId) internal {
        require(_hausPhase.ownerOf(_tokenId) == msg.sender, "Stake: not owner of token");

        userInfo[msg.sender].balances.push(_tokenId);
        _hausPhase.transferFrom(msg.sender, address(this), _tokenId);
        tokenOwner[_tokenId] = msg.sender;
    }

    /// @notice             Internal function to withdraw a single token for the user
    /// @param _tokenId     Target token
    function _withdrawNft(uint16 _tokenId) internal {
        require(tokenOwner[_tokenId] == msg.sender, "Withdraw: not owner of token");

        _removeElement(userInfo[msg.sender].balances, _tokenId);
        delete tokenOwner[_tokenId];
        _hausPhase.transferFrom(address(this), msg.sender, _tokenId);
    }

    /// @notice             Internal function to remove element from the balance array
    /// @param _array       target array
    /// @param _element     target element of the array
    function _removeElement(uint16[] storage _array, uint256 _element) internal {
        uint256 length = _array.length;
        for (uint256 i; i < length;) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice             Internal function to get base rate for single token
    /// @param _tokenId     Target tokenId
    function _getRatePerToken(uint16 _tokenId) internal view returns(uint) {
        if (_tokenId >= 0 && _tokenId < 390) {
            return phaseRewardRate[1] * 1e18;
        } else if (_tokenId > 389 && _tokenId < 3112) {
            return phaseRewardRate[2] * 1e18;
        } else if (_tokenId > 3111) {
            return phaseRewardRate[3] * 1e18;
        } else {
            revert();
        }
    }

    /// @notice             Internal function to to get base rate for all owned tokens
    /// @param _user        Target user
    function _getRateForUser(address _user) internal view returns(uint) {
        uint16[] memory tokenIds = userInfo[_user].balances;
        uint length = tokenIds.length;
        uint totalAmount;
        for(uint i; i < length;) {
            totalAmount += _getRatePerToken(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return totalAmount;
    }

    /// @notice             Handles claiming for functions modifying the users state
    /// @param _rate        Base rate amount for the user
    function _handleClaim(uint _rate) internal {
        uint timeBetweenClaims = block.timestamp - userInfo[msg.sender].lastClaimedReward;
        uint pendingRewards = timeBetweenClaims * _rate / 86400;

        userInfo[msg.sender].lastClaimedReward = block.timestamp;
        userInfo[msg.sender].totalClaimed += pendingRewards;
        _hausToken.mint(msg.sender, pendingRewards);
        emit Claimed(msg.sender, pendingRewards);
    }

    /// @notice             Internal function to calculate pending rewards for a user
    /// @param _user        target user
    function _calculateReward(address _user) internal view returns(uint) {
        if (userInfo[_user].balances.length == 0) return 0;
        uint timeBetweenClaims = block.timestamp - userInfo[_user].lastClaimedReward;
        uint pendingRewards = timeBetweenClaims * _getRateForUser(_user) / 86400;
        return pendingRewards;
    }

    /////////////////////////////////////////////////////////////////////////////
    ///  Getter functions
    /////////////////////////////////////////////////////////////////////////////

    /// @notice             Gets total amount of staked tokens in the contract
    function getTotalStakedTokens() external view returns(uint) {
        return _hausPhase.balanceOf(address(this));
    }

    /// @notice             Gets total amount of staked tokens by the user
    /// @param _user        Target user
    function getUserBalance(address _user) external view returns(uint){
        return userInfo[_user].balances.length;
    }

    /// @notice             Gets all tokenIds staked by the user
    /// @param _user        Target user
    function getUserStakedTokens(address _user) external view returns(uint16[] memory){
        return userInfo[_user].balances;
    }

    /// @notice             Returns the daily reward rate for the user
    /// @dev                The rate is returned with decimals, so manage in the frontend accordingly
    /// @param _user        Target user
    function getUserRewardRate(address _user) external view returns(uint) {
        return _getRateForUser(_user);
    }

    /// @notice             Calculates all pending rewards for a user. More for frontend
    /// @param _user        Target user
    function calculatePendingRewards(address _user) external view returns(uint) {
        return  _calculateReward(_user);
    }

    /// @notice             Returns the total amount earned from staking (includes pending)
    /// @param _user        Target user
    function calculateTotalAndPendingRewards(address _user) external view returns(uint) {
        return userInfo[_user].totalClaimed + _calculateReward(_user);
    }

    /// @notice             Returns the amount of tokens each phase version yields daily
    /// @param  _version    Version of the hausphase
    function getPhaseRewardRate(uint _version) external view returns(uint) {
        return phaseRewardRate[_version];
    }

    /////////////////////////////////////////////////////////////////////////////
    ///  Owner functions
    /////////////////////////////////////////////////////////////////////////////

    /// @notice                     Sets the hausPhase contract
    /// @param _contract            Target ERC721 contract
    function setHausPhaseContract(address _contract) external onlyOwner {
        _hausPhase = IERC721(_contract);
    }

    /// @notice                     Sets the hausToken contract
    /// @param _contract            Target ERC20 contract
    function setHausTokenContract(address _contract) external onlyOwner {
        _hausToken = IERC20(_contract);
    }

    /// @notice                     Set the daily reward rate for hausphases
    /// @dev                        Note that changing this value will affect unclaimed rewards for every user
    /// @param _phaseVersion        The hausphase version
    /// @param _amount              The amount of hausTokens that will accumulate daily              
    function setRewardRate(uint _phaseVersion, uint _amount) external onlyOwner {
        require(_phaseVersion > 0 && _phaseVersion < 4, "Incorrect phase version");
        phaseRewardRate[_phaseVersion] = _amount;
    }

    /// @notice                     Pause contract.Allows calling emergency withdraw
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice                     Unpause contract
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}