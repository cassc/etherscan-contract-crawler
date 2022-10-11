// SPDX-License-Identifier: MIT

// Forked from Goose that was forked from Pancake that was forked from Sushi ...

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTMasterChefUpgradeable_V2 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721EnumerableUpgradeable {
    IERC721Upgradeable nftToken; // Address of nft token contract.
    uint256 lastRewardBlock; // Last block number that reward distribution occurs.
    uint256 accTokenPerShare; // Accumulated rewards per share, times 1e12. See below.
    address public rewardWallet; //Wallet that holds reward tokens

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    IERC20Upgradeable public rewardToken;
    uint256 public rewardTokenPerBlock;
    uint256 public startBlock;
    uint256 public totalLocked;
    bool public paused;

    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

/*
    function initialize(
        address _rewardToken, //reward token
        address _nftToken, //deposit token
        address _rewardWallet,
        uint256 _rewardTokenPerBlock,
        uint256 _startBlock,
        bool _paused
    ) external initializer {
        __ERC721_init("Staked NFT", "SNFT");
        __Ownable_init();

        rewardToken = IERC20Upgradeable(_rewardToken);
        rewardTokenPerBlock = _rewardTokenPerBlock;
        startBlock = _startBlock;
        // Moved from add in MC
        nftToken = IERC721Upgradeable(_nftToken); //deposit token address
        lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        accTokenPerShare = 0;
        rewardWallet = _rewardWallet;
        paused = _paused;
    }
    */

    // View function to see pending rewards on frontend.
    function pendingRewardToken(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _accTokenPerShare = accTokenPerShare;

        uint256 nftSupply = nftToken.balanceOf(address(this));
        if (block.number > lastRewardBlock && nftSupply != 0) {
            uint256 multiplier = block.number - lastRewardBlock;
            uint256 tokenReward = multiplier * rewardTokenPerBlock;

            _accTokenPerShare =
                _accTokenPerShare +
                (tokenReward * 1e12) /
                nftSupply;
        }
        return (user.amount * _accTokenPerShare) / 1e12 - user.rewardDebt;
    }

    // Update reward variables of the given pool to be up-to-date.
    function update() public {

        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 nftSupply = nftToken.balanceOf(address(this));

        if (nftSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number - lastRewardBlock;
        uint256 tokenReward = multiplier * rewardTokenPerBlock;

        rewardToken.transferFrom(rewardWallet, address(this), tokenReward);

        accTokenPerShare = accTokenPerShare + (tokenReward * 1e12) / nftSupply;

        lastRewardBlock = block.number;
    }

    // WARNING!! Be careful of gas spending. 
    function deposit(uint256[] memory _tokenIds) public  nonReentrant{
        require(!paused, "Contract is paused");
        UserInfo storage user = userInfo[msg.sender];
        update();

        if (user.amount > 0) {
            uint256 pendingToken = (user.amount * accTokenPerShare) /
                1e12 -
                user.rewardDebt;

            if (pendingToken > 0) {
                safeTokenTransfer(msg.sender, pendingToken);
            }
        } 

        for(uint i =0; i< _tokenIds.length; i++){
            nftToken.transferFrom(address(msg.sender), address(this), _tokenIds[i]);
            user.amount = user.amount + 1;

            if (_exists(_tokenIds[i])) {
                // transfer wrapped NFT token from this contract to msg.sender
                this.transferFrom(address(this), address(msg.sender), _tokenIds[i]);
            } else {
                //mint the wrapped token since it doesnt exist
                _mint(msg.sender, _tokenIds[i]);
            }
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / 1e12;
        totalLocked += _tokenIds.length;
        emit Deposit(msg.sender,_tokenIds.length);

    }

    // Withdraw LP tokens from MasterChef.

    function withdraw(uint256[] memory _tokenIds) public nonReentrant {
        require(!paused, "Contract is paused");
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _tokenIds.length, 'withdraw: insufficient balance');

        update();
        uint256 pendingToken = (user.amount * accTokenPerShare) /
            1e12 -
            user.rewardDebt;

        if (pendingToken > 0) {
            safeTokenTransfer(msg.sender, pendingToken);
        }

        for(uint i =0; i< _tokenIds.length; i++){
            user.amount = user.amount - 1;
            transferFrom(address(msg.sender), address(this),_tokenIds[i]); //return wrapped NFT
            nftToken.transferFrom(address(this), address(msg.sender), _tokenIds[i]);
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / 1e12;
        totalLocked -= _tokenIds.length;
        emit Withdraw(msg.sender, _tokenIds.length);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    // Call repeatedly to remove multiple NFTs
    function emergencyWithdraw() public nonReentrant {
        require(!paused, "Contract is paused");
        UserInfo memory user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        uint256 id = tokenOfOwnerByIndex(msg.sender, 0);
        transferFrom(address(msg.sender), address(this), id);
        nftToken.transferFrom(address(this), address(msg.sender), id);
    
        totalLocked = totalLocked - 1;
        emit EmergencyWithdraw(msg.sender, amount);
    }

    // Safe transfer function, just in case if rounding error causes pool to not have enough reward tokens.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardTokenBal) {
            rewardToken.transfer(_to, rewardTokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _rewardTokenPerBlock) public onlyOwner {
        rewardTokenPerBlock = _rewardTokenPerBlock;
    }

    function pauseOrUnpause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function changeRewardWallet(address _rewardWallet) public onlyOwner {
        rewardWallet = _rewardWallet;
    }

    function changeStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
        lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
    }

    function changeDepositToken(address _nftToken) public onlyOwner {
        nftToken = IERC721Upgradeable(_nftToken); 
    }

    function changeRewardToken(address _rewardToken) public onlyOwner {
        rewardToken = IERC20Upgradeable(_rewardToken);
    }

}