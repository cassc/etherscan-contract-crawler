// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '../../../openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '../../../openzeppelin-upgradeable/security/PausableUpgradeable.sol';
import '../../../openzeppelin-upgradeable/access/OwnableUpgradeable.sol';
import '../../../openzeppelin-upgradeable/proxy/utils/Initializable.sol';
import '../../../openzeppelin/token/ERC20/utils/SafeERC20.sol';
import '../../../openzeppelin/token/ERC721/IERC721Receiver.sol';
import './VeERC20Upgradeable.sol';
import './Whitelist.sol';
import '../interfaces/IMasterChefV3.sol';
import '../libraries/Math.sol';
import '../interfaces/IVeToken.sol';
import '../interfaces/IMasterChefNFT.sol';
import '../interfaces/IFeeVault.sol';

/// @title VeToken
/// @notice Platypus Venom: the staking contract for PTP, as well as the token used for governance.
/// Note Venom does not seem to hurt the Platypus, it only makes it stronger.
/// Allows depositing/withdraw of token and staking/unstaking ERC721.
/// Here are the rules of the game:
/// If you stake token, you generate veToken at the current `generationRate` until you reach `maxCap`
/// If you unstake any amount of token, you loose all of your veToken.
/// ERC721 staking does not affect generation nor cap for the moment, but it will in a future upgrade.
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Platypus is sufficiently
/// distributed and the community can show to govern itself.
contract VeToken is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    VeERC20Upgradeable,
    IVeToken
{
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount; // token staked by user
        uint256 lastRelease; // time of last veToken claim or first deposit if user has not claimed yet
        // the id of the currently staked nft
        // important: the id is offset by +1 to handle tokenID = 0
        uint256 stakedNftId;
    }

    /// @notice the toen token
    IERC20 public token;

    /// @notice the masterchef contract
    IMasterChefV3 public masterchef;

    /// @notice the NFT contract
    IMasterChefNFT public nft;

    /// @dev Magic value for onERC721Received
    /// Equals to bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    /// @notice max veToken to staked token ratio
    /// Note if user has 10 token staked, they can only have a max of 10 * maxCap veToken in balance
    uint256 public maxCap;

    /// @notice the rate of veToken generated per second, per token staked
    uint256 public generationRate;

    /// @notice invVvoteThreshold threshold.
    /// @notice voteThreshold is the tercentage of cap from which votes starts to count for governance proposals.
    /// @dev inverse of the threshold to apply.
    /// Example: th = 5% => (1/5) * 100 => invVoteThreshold = 20
    /// Example 2: th = 3.03% => (1/3.03) * 100 => invVoteThreshold = 33
    /// Formula is invVoteThreshold = (1 / th) * 100
    uint256 public invVoteThreshold;

    /// @notice whitelist wallet checker
    /// @dev contract addresses are by default unable to stake token, they must be previously whitelisted to stake token 
    Whitelist public whitelist;

    /// @notice user info mapping
    mapping(address => UserInfo) public users;
    IFeeVault public feeVault;

    /// @notice events describing staking, unstaking and claiming
    event Staked(address indexed user, uint256 indexed amount);
    event Unstaked(address indexed user, uint256 indexed amount);
    event Claimed(address indexed user, uint256 indexed amount);
    event ClaimedWETH(address indexed user, uint256 indexed amount);

    /// @notice events describing NFT staking and unstaking
    event StakedNft(address indexed user, uint256 indexed nftId);
    event UnstakedNft(address indexed user, uint256 indexed nftId);

    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20 _token,
        IMasterChefV3 _masterchef,
        IMasterChefNFT _nft,
        IFeeVault _feeVault
    ) public initializer {
        require(address(_token) != address(0), 'zero address');

        // Initialize vePTP
        __ERC20_init_unchained(_name, _symbol);
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        // set generationRate (veToken per sec per token staked)
        generationRate = 3888888888888;

        // set maxCap
        maxCap = 100;

        // set inv vote threshold
        // invVoteThreshold = 20 => th = 5
        invVoteThreshold = 20;

        // set master platypus
        masterchef = _masterchef;

        // set token 
        token = _token;

        // set nft, can be zero address at first
        nft = _nft;
        feeVault = _feeVault;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice sets masterPlatpus address
    /// @param _masterchef the new masterchef address
    function setMasterChef(IMasterChefV3 _masterchef) external onlyOwner {
        require(address(_masterchef) != address(0), 'zero address');
        masterchef = _masterchef;
    }

    /// @notice sets NFT contract address
    /// @param _nft the new NFT contract address
    function setNftAddress(IMasterChefNFT _nft) external onlyOwner {
        require(address(_nft) != address(0), 'zero address');
        nft = _nft;
    }

    /// @notice sets whitelist address
    /// @param _whitelist the new whitelist address
    function setWhitelist(Whitelist _whitelist) external onlyOwner {
        require(address(_whitelist) != address(0), 'zero address');
        whitelist = _whitelist;
    }

    /// @notice sets maxCap
    /// @param _maxCap the new max ratio
    function setMaxCap(uint256 _maxCap) external onlyOwner {
        require(_maxCap != 0, 'max cap cannot be zero');
        maxCap = _maxCap;
    }

    /// @notice sets generation rate
    /// @param _generationRate the new max ratio
    function setGenerationRate(uint256 _generationRate) external onlyOwner {
        require(_generationRate != 0, 'generation rate cannot be zero');
        generationRate = _generationRate;
    }

    /// @notice sets invVoteThreshold
    /// @param _invVoteThreshold the new var
    /// Formula is invVoteThreshold = (1 / th) * 100
    function setInvVoteThreshold(uint256 _invVoteThreshold) external onlyOwner {
        // onwner should set a high value if we do not want to implement an important threshold
        require(_invVoteThreshold != 0, 'invVoteThreshold cannot be zero');
        invVoteThreshold = _invVoteThreshold;
    }

    function setFeeVault(IFeeVault _feeVault) external onlyOwner {
        feeVault = _feeVault;
    }

    /// @notice checks wether user _addr has token staked
    /// @param _addr the user address to check
    /// @return true if the user has token in stake, false otherwise
    function isUser(address _addr) public view override returns (bool) {
        return users[_addr].amount > 0;
    }

    /// @notice returns staked amount of token for user
    /// @param _addr the user address to check
    /// @return staked amount of token
    function getStakedToken(address _addr) external view override returns (uint256) {
        return users[_addr].amount;
    }

    /// @dev explicity override multiple inheritance
    function totalSupply() public view override(VeERC20Upgradeable, IVeERC20) returns (uint256) {
        return super.totalSupply();
    }

    /// @dev explicity override multiple inheritance
    function balanceOf(address account) public view override(VeERC20Upgradeable, IVeERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    /// @notice deposits PTP into contract
    /// @param _amount the amount of token to deposit
    function deposit(uint256 _amount) external override nonReentrant whenNotPaused {
        require(_amount > 0, 'amount to deposit cannot be zero');

        // assert call is not coming from a smart contract
        // unless it is whitelisted
        _assertNotContract(msg.sender);

        if (isUser(msg.sender)) {
            // if user exists, first, claim his vePTP
            _claimWETH(msg.sender);
            _claim(msg.sender);
            // then, increment his holdings
            users[msg.sender].amount += _amount;
        } else {
            // add new user to mapping
            users[msg.sender].lastRelease = block.timestamp;
            users[msg.sender].amount = _amount;
        }

        // Request token from user
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /// @notice asserts addres in param is not a smart contract.
    /// @notice if it is a smart contract, check that it is whitelisted
    /// @param _addr the address to check
    function _assertNotContract(address _addr) private view {
        if (_addr != tx.origin) {
            require(
                address(whitelist) != address(0) && whitelist.check(_addr),
                'Smart contract depositors not allowed'
            );
        }
    }

    /// @notice claims accumulated vePTP
    function claim() external override nonReentrant whenNotPaused {
        require(isUser(msg.sender), 'user has no stake');
        _claimWETH(msg.sender);
        _claim(msg.sender);
    }

    function _claimWETH(address _addr) private {
        uint256 amount = claimableWETH(_addr);
        // update last release time
        if (amount > 0) {
            emit ClaimedWETH(_addr, amount);
            feeVault.distribute(msg.sender, amount);
        }
    }

    function claimableWETH(address _addr) public view returns (uint256) {
        require(_addr != address(0), 'zero address');
        UserInfo storage user = users[_addr];
        // get seconds elapsed since last claim
        uint256 secondsElapsed = block.timestamp - user.lastRelease;
        uint256 pending = Math.wmul(user.amount, secondsElapsed * feeVault.generationRateETH());
        return pending;
    }

    /// @dev private claim function
    /// @param _addr the address of the user to claim from
    function _claim(address _addr) private {
        uint256 amount = _claimable(_addr);

        // update last release time
        users[_addr].lastRelease = block.timestamp;

        if (amount > 0) {
            emit Claimed(_addr, amount);
            _mint(_addr, amount);
        }
    }

    /// @notice Calculate the amount of vePTP that can be claimed by user
    /// @param _addr the address to check
    /// @return amount of vePTP that can be claimed by user
    function claimable(address _addr) external view returns (uint256) {
        require(_addr != address(0), 'zero address');
        return _claimable(_addr);
    }

    /// @dev private claim function
    /// @param _addr the address of the user to claim from
    function _claimable(address _addr) private view returns (uint256) {
        UserInfo storage user = users[_addr];

        // get seconds elapsed since last claim
        uint256 secondsElapsed = block.timestamp - user.lastRelease;

        // calculate pending amount
        // Math.mwmul used to multiply wad numbers
        uint256 pending = Math.wmul(user.amount, secondsElapsed * generationRate);

        // get user's vePTP balance
        uint256 userVeTokenBalance = balanceOf(_addr);

        // user vePTP balance cannot go above user.amount * maxCap
        uint256 maxVeTokenCap = user.amount * maxCap;

        // first, check that user hasn't reached the max limit yet
        if (userVeTokenBalance < maxVeTokenCap) {
            // then, check if pending amount will make user balance overpass maximum amount
            if ((userVeTokenBalance + pending) > maxVeTokenCap) {
                return maxVeTokenCap - userVeTokenBalance;
            } else {
                return pending;
            }
        }
        return 0;
    }

    /// @notice withdraws staked token
    /// @param _amount the amount of token to unstake
    /// Note Beware! you will loose all of your vePTP if you unstake any amount of token!
    function withdraw(uint256 _amount) external override nonReentrant whenNotPaused {
        require(_amount > 0, 'amount to withdraw cannot be zero');
        require(users[msg.sender].amount >= _amount, 'not enough balance');

        // reset last Release timestamp
        users[msg.sender].lastRelease = block.timestamp;

        // update his balance before burning or sending back token
        users[msg.sender].amount -= _amount;

        // get user vePTP balance that must be burned
        uint256 userVeTokenBalance = balanceOf(msg.sender);

        _burn(msg.sender, userVeTokenBalance);

        // send back the staked token
        token.safeTransfer(msg.sender, _amount);
    }

    /// @notice hook called after token operation mint/burn
    /// @dev updates masterchef
    /// @param _account the account being affected
    /// @param _newBalance the newVeTokenBalance of the user
    function _afterTokenOperation(address _account, uint256 _newBalance) internal override {
        masterchef.updateFactor(_account, _newBalance);
    }

    /// @notice This function is called when users stake NFTs
    /// When Platypus NFT sent via safeTransferFrom(), we regard this action as staking the NFT
    /// Note that transferFrom() is ignored by this function
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external override nonReentrant whenNotPaused returns (bytes4) {
        require(msg.sender == address(nft), 'only platypus NFT can be received');
        require(isUser(_from), 'user has no stake');

        // User has previously staked some NFT, try to unstake it first
        if (users[_from].stakedNftId != 0) {
            _unstakeNft(_from);
        }

        users[_from].stakedNftId = _tokenId + 1;

        emit StakedNft(_from, _tokenId);

        return ERC721_RECEIVED;
    }

    /// @notice unstakes current user nft
    function unstakeNft() external override nonReentrant whenNotPaused {
        _unstakeNft(msg.sender);
    }

    /// @notice private function used to unstake nft
    /// @param _addr the address of the nft owner
    function _unstakeNft(address _addr) private {
        uint256 stakedNftId = users[_addr].stakedNftId;
        require(stakedNftId > 0, 'No NFT is staked');
        uint256 nftId = stakedNftId - 1;

        nft.safeTransferFrom(address(this), _addr, nftId, '');

        users[_addr].stakedNftId = 0;
        emit UnstakedNft(_addr, nftId);
    }

    /// @notice gets id of the staked nft
    /// @param _addr the addres of the nft staker
    /// @return id of the staked nft by _addr user
    /// if the user haven't stake any nft, tx reverts
    function getStakedNft(address _addr) external view override returns (uint256) {
        uint256 stakedNftId = users[_addr].stakedNftId;
        require(stakedNftId > 0, 'not staking');
        return stakedNftId - 1;
    }

    /// @notice get votes for vePTP
    /// @dev votes should only count if account has > threshold% of current cap reached
    /// @dev invVoteThreshold = (1/threshold%)*100
    /// @return the valid votes
    function getVotes(address _account) external view virtual override returns (uint256) {
        uint256 veTokenBalance = balanceOf(_account);

        // check that user has more than voting treshold of maxCap and has token in stake
        if (veTokenBalance * invVoteThreshold > users[_account].amount * maxCap && isUser(_account)) {
            return veTokenBalance;
        } else {
            return 0;
        }
    }
}