// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VeERC20Upgradeable.sol";
import "./Whitelist.sol";
import "./interfaces/IMasterOh.sol";
import "./libraries/Math.sol";
import "./interfaces/IVeOh.sol";
import "./interfaces/IOhNFT.sol";

/// @title VeOh
/// @notice Vote-Escrowed Oh: the staking contract for OH, as well as the token used for governance.
/// Allows depositing/withdraw of oh and staking/unstaking ERC721.
/// Here are the rules of the game:
/// If you stake oh, you generate veOh at the current `generationRate` until you reach `maxCap`
/// If you unstake any amount of oh, you loose all of your veOh.
/// ERC721 staking does not affect generation nor cap for the moment, but it will in a future upgrade.
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Oh is sufficiently
/// distributed and the community can show to govern itself.
contract VeOh is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, VeERC20Upgradeable, IVeOh {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount; // oh staked by user
        uint256 lastRelease; // time of last veOh claim or first deposit if user has not claimed yet
        // the id of the currently staked nft
        // important: the id is offset by +1 to handle tokenID = 0
        uint256 stakedNftId;
    }

    /// @notice the oh token
    IERC20 public oh;

    /// @notice the masterOh contract
    IMasterOh public masterOh;

    /// @notice the NFT contract
    IOhNFT public nft;

    /// @dev Magic value for onERC721Received
    /// Equals to bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    /// @notice max veOh to staked oh ratio
    /// Note if user has 10 oh staked, they can only have a max of 10 * maxCap veOh in balance
    uint256 public maxCap;

    /// @notice the rate of veOh generated per second, per oh staked
    uint256 public generationRate;

    /// @notice invVvoteThreshold threshold.
    /// @notice voteThreshold is the tercentage of cap from which votes starts to count for governance proposals.
    /// @dev inverse of the threshold to apply.
    /// Example: th = 5% => (1/5) * 100 => invVoteThreshold = 20
    /// Example 2: th = 3.03% => (1/3.03) * 100 => invVoteThreshold = 33
    /// Formula is invVoteThreshold = (1 / th) * 100
    uint256 public invVoteThreshold;

    /// @notice whitelist wallet checker
    /// @dev contract addresses are by default unable to stake oh, they must be previously whitelisted to stake oh
    Whitelist public whitelist;

    /// @notice user info mapping
    mapping(address => UserInfo) public users;

    /// @notice events describing staking, unstaking and claiming
    event Staked(address indexed user, uint256 indexed amount);
    event Unstaked(address indexed user, uint256 indexed amount);
    event Claimed(address indexed user, uint256 indexed amount);

    /// @notice events describing NFT staking and unstaking
    event StakedNft(address indexed user, uint256 indexed nftId);
    event UnstakedNft(address indexed user, uint256 indexed nftId);

    function initialize(
        IERC20 _oh,
        IMasterOh _masterOh,
        IOhNFT _nft
    ) public initializer {
        require(address(_masterOh) != address(0), "zero address");
        require(address(_oh) != address(0), "zero address");

        // Initialize veOH
        __ERC20_init("Vote-Escrowed Oh", "veOH");
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        // set generationRate (veOh per sec per oh staked)
        generationRate = 3888888888888;

        // set maxCap
        maxCap = 100;

        // set inv vote threshold
        // invVoteThreshold = 20 => th = 5
        invVoteThreshold = 20;

        // set master oh
        masterOh = _masterOh;

        // set oh
        oh = _oh;

        // set nft, can be zero address at first
        nft = _nft;
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
    /// @param _masterOh the new masterOh address
    function setMasterOh(IMasterOh _masterOh) external onlyOwner {
        require(address(_masterOh) != address(0), "zero address");
        masterOh = _masterOh;
    }

    /// @notice sets NFT contract address
    /// @param _nft the new NFT contract address
    function setNftAddress(IOhNFT _nft) external onlyOwner {
        require(address(_nft) != address(0), "zero address");
        nft = _nft;
    }

    /// @notice sets whitelist address
    /// @param _whitelist the new whitelist address
    function setWhitelist(Whitelist _whitelist) external onlyOwner {
        require(address(_whitelist) != address(0), "zero address");
        whitelist = _whitelist;
    }

    /// @notice sets maxCap
    /// @param _maxCap the new max ratio
    function setMaxCap(uint256 _maxCap) external onlyOwner {
        require(_maxCap != 0, "max cap cannot be zero");
        maxCap = _maxCap;
    }

    /// @notice sets generation rate
    /// @param _generationRate the new max ratio
    function setGenerationRate(uint256 _generationRate) external onlyOwner {
        require(_generationRate != 0, "generation rate cannot be zero");
        generationRate = _generationRate;
    }

    /// @notice sets invVoteThreshold
    /// @param _invVoteThreshold the new var
    /// Formula is invVoteThreshold = (1 / th) * 100
    function setInvVoteThreshold(uint256 _invVoteThreshold) external onlyOwner {
        // onwner should set a high value if we do not want to implement an important threshold
        require(_invVoteThreshold != 0, "invVoteThreshold cannot be zero");
        invVoteThreshold = _invVoteThreshold;
    }

    /// @notice checks wether user _addr has oh staked
    /// @param _addr the user address to check
    /// @return true if the user has oh in stake, false otherwise
    function isUser(address _addr) public view override returns (bool) {
        return users[_addr].amount > 0;
    }

    /// @notice returns staked amount of oh for user
    /// @param _addr the user address to check
    /// @return staked amount of oh
    function getStakedOh(address _addr) external view override returns (uint256) {
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

    /// @notice deposits OH into contract
    /// @param _amount the amount of oh to deposit
    function deposit(uint256 _amount) external override nonReentrant whenNotPaused {
        require(_amount > 0, "amount to deposit cannot be zero");

        // assert call is not coming from a smart contract
        // unless it is whitelisted
        _assertNotContract(msg.sender);

        if (isUser(msg.sender)) {
            // if user exists, first, claim his veOH
            _claim(msg.sender);
            // then, increment his holdings
            users[msg.sender].amount += _amount;
        } else {
            // add new user to mapping
            users[msg.sender].lastRelease = block.timestamp;
            users[msg.sender].amount = _amount;
        }

        // Request Oh from user
        oh.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /// @notice asserts addres in param is not a smart contract.
    /// @notice if it is a smart contract, check that it is whitelisted
    /// @param _addr the address to check
    function _assertNotContract(address _addr) private view {
        if (_addr != tx.origin) {
            require(address(whitelist) != address(0) && whitelist.check(_addr), "Smart contract depositors not allowed");
        }
    }

    /// @notice claims accumulated veOH
    function claim() external override nonReentrant whenNotPaused {
        require(isUser(msg.sender), "user has no stake");
        _claim(msg.sender);
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

    /// @notice Calculate the amount of veOH that can be claimed by user
    /// @param _addr the address to check
    /// @return amount of veOH that can be claimed by user
    function claimable(address _addr) external view returns (uint256) {
        require(_addr != address(0), "zero address");
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

        // get user's veOH balance
        uint256 userVeOhBalance = balanceOf(_addr);

        // user veOH balance cannot go above user.amount * maxCap
        uint256 maxVeOhCap = user.amount * maxCap;

        // first, check that user hasn't reached the max limit yet
        if (userVeOhBalance < maxVeOhCap) {
            // then, check if pending amount will make user balance overpass maximum amount
            if ((userVeOhBalance + pending) > maxVeOhCap) {
                return maxVeOhCap - userVeOhBalance;
            } else {
                return pending;
            }
        }
        return 0;
    }

    /// @notice withdraws staked oh
    /// @param _amount the amount of oh to unstake
    /// Note Beware! you will loose all of your veOH if you unstake any amount of oh!
    function withdraw(uint256 _amount) external override nonReentrant whenNotPaused {
        require(_amount > 0, "amount to withdraw cannot be zero");
        require(users[msg.sender].amount >= _amount, "not enough balance");

        // reset last Release timestamp
        users[msg.sender].lastRelease = block.timestamp;

        // update his balance before burning or sending back oh
        users[msg.sender].amount -= _amount;

        // get user veOH balance that must be burned
        uint256 userVeOhBalance = balanceOf(msg.sender);

        _burn(msg.sender, userVeOhBalance);

        // send back the staked oh
        oh.safeTransfer(msg.sender, _amount);
    }

    /// @notice hook called after token operation mint/burn
    /// @dev updates masterOh
    /// @param _account the account being affected
    /// @param _newBalance the newVeOhBalance of the user
    function _afterTokenOperation(address _account, uint256 _newBalance) internal override {
        masterOh.updateFactor(_account, _newBalance);
    }

    /// @notice This function is called when users stake NFTs
    /// When Oh NFT sent via safeTransferFrom(), we regard this action as staking the NFT
    /// Note that transferFrom() is ignored by this function
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external override nonReentrant whenNotPaused returns (bytes4) {
        require(msg.sender == address(nft), "only oh NFT can be received");
        require(isUser(_from), "user has no stake");

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
        require(stakedNftId > 0, "No NFT is staked");
        uint256 nftId = stakedNftId - 1;

        nft.safeTransferFrom(address(this), _addr, nftId, "");

        users[_addr].stakedNftId = 0;
        emit UnstakedNft(_addr, nftId);
    }

    /// @notice gets id of the staked nft
    /// @param _addr the addres of the nft staker
    /// @return id of the staked nft by _addr user
    /// if the user haven't stake any nft, tx reverts
    function getStakedNft(address _addr) external view returns (uint256) {
        uint256 stakedNftId = users[_addr].stakedNftId;
        require(stakedNftId > 0, "not staking");
        return stakedNftId - 1;
    }

    /// @notice get votes for veOH
    /// @dev votes should only count if account has > threshold% of current cap reached
    /// @dev invVoteThreshold = (1/threshold%)*100
    /// @return the valid votes
    function getVotes(address _account) external view virtual override returns (uint256) {
        uint256 veOhBalance = balanceOf(_account);

        // check that user has more than voting treshold of maxCap and has oh in stake
        if (veOhBalance * invVoteThreshold > users[_account].amount * maxCap && isUser(_account)) {
            return veOhBalance;
        } else {
            return 0;
        }
    }
}