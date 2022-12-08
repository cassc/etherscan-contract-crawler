//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../interfaces/INonfungiblePositionManager.sol";
import "../interfaces/ILLCGift.sol";
import "../interfaces/IWETH.sol";
import "../utils/Errors.sol";

contract AGOVLPStaking is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    /// @dev uniswap liquidity pool fee
    uint24 private constant poolFee = 3000;
    /// @dev at least 2 ethers should be deposited
    uint256 public constant MIN_ETH_AMOUNT = 2 ether;
    /// @dev keccak256("AGOV LP STAKING")
    uint256 private constant NAME_HASH = 0x41963fde314a645377028b1adf3bcbda1c1b9a87ea74a79cfa0308ddd78f3379;
    /// @dev address of AGOV token
    address public agovToken;
    /// @dev addres of MPWR token
    address public mpwrToken;
    /// @dev address of ETH token
    address public wethToken;
    /// @dev address of LLC gift contract
    address public llcGift;
    /// @dev address of validator
    address private validator;
    /// @dev current on going round
    uint256 public currentRound;
    /// @dev total staked count
    uint256 public totalStaked;
    /// @dev uniswap non fungible position manager
    INonfungiblePositionManager public nonfungiblePositionManager;
    /// @dev uniswap tick math min value
    int24 private constant MIN_TICK = -887272;
    /// @dev uniswap tick math max value
    int24 private constant MAX_TICK = -MIN_TICK;
    /// @dev uniswap tick math spacing
    int24 private constant TICK_SPACING = 60;

    /// @dev represents the deposit of an NFT
    struct Deposit {
        address owner;
        uint256 id;
        uint256 ethAmount;
        uint256 agovAmount;
        uint256 lock;
        uint256 reward;
        uint256 llc;
        uint256 timestamp;
    }

    /// @dev user status of all rounds
    mapping(address => uint256) private status;
    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;

    /* ==================== EVENTS ==================== */

    event StakeLP(address indexed owner, uint256 depositId, uint256 tokenId, uint256 roundId);

    event Withdraw(address indexed owner, uint256 stakeId, uint256 tokenId, uint256 llcAmount, uint256 reward);

    /* ==================== METHODS ==================== */

    /**
     * initialize the contract
     *
     * @param _wethToken WETH contract address
     * @param _agovToken Address of AGOV token contract
     * @param _mpwrToken MPWR token contract address
     * @param _llcGift LLC gift contract address
     * @param _validator Address of validator wallet
     * @param _position Uniswap LP position
     */
    function initialize(
        address _wethToken,
        address _agovToken,
        address _mpwrToken,
        address _llcGift,
        address _validator,
        address _position
    ) external initializer {
        __Context_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        if (_agovToken == address(0) || _mpwrToken == address(0)) revert ZeroAddress();

        wethToken = _wethToken;
        agovToken = _agovToken;
        mpwrToken = _mpwrToken;
        llcGift = _llcGift;
        validator = _validator;
        nonfungiblePositionManager = INonfungiblePositionManager(_position);
    }

    /**
     * @dev deposit ETH and generate LP
     *
     * @param agovInAmount AGOV token amount which was deposited from klaytn
     * @param round current on going round number
     * @param lock lock up period 90 or 180
     * @param mpwrOutAmount MPWR token reward
     * @param timestamp timestamp to verify the signature
     * @param signature signature is generated from LL backend.
     */
    function deposit(
        address user,
        uint256 agovInAmount,
        uint256 round,
        uint256 lock,
        uint256 mpwrOutAmount,
        uint256 timestamp,
        bytes memory signature
    ) external payable whenNotPaused nonReentrant {
        if (user != _msgSender()) revert InvalidCaller();
        if (currentRound != round || currentRound == 0) revert InvalidRound();
        if (msg.value < MIN_ETH_AMOUNT) revert InvalidAmount();

        // check if user already participated in current round
        uint256 userRound = status[_msgSender()];
        uint256 taken = (userRound >> (round - 1)) % 2;
        if (taken == 1) revert AlreadyTaken();

        // update storage with user's round status
        userRound += (1 << (round - 1));
        status[_msgSender()] = userRound;

        // verify if the agov amount is correct
        if (!_verify(_msgSender(), round, agovInAmount, lock, mpwrOutAmount, timestamp, signature))
            revert FailedVerify();

        // convert eth to weth
        IWETH(wethToken).deposit{ value: (msg.value) }();

        // create a new lp position wrapped in a NFT
        (uint256 tokenId, , uint256 ethOutAmount, uint256 agovOutAmount) = _mintPosition(msg.value, agovInAmount);

        // set the owner and data for position
        uint256 depositId = totalStaked++;
        uint256 llc = ((lock == 180 days ? 2 : 1) * msg.value) / 1 ether;
        deposits[depositId] = Deposit({
            owner: user,
            id: tokenId,
            reward: mpwrOutAmount,
            lock: lock,
            ethAmount: ethOutAmount,
            agovAmount: agovOutAmount,
            llc: llc,
            timestamp: block.timestamp
        });

        // refund rest WETH
        if (ethOutAmount < msg.value) {
            IWETH(wethToken).approve(address(nonfungiblePositionManager), 0);
            IWETH(wethToken).transfer(_msgSender(), msg.value - ethOutAmount);
        }

        emit StakeLP(user, depositId, tokenId, round);
    }

    /**
     * @dev withdraw LP nft, mpwr rewards and LLC
     *
     * @param depositId id of stored Deposit array
     */
    function withdraw(uint256 depositId) external whenNotPaused nonReentrant {
        Deposit memory staking = deposits[depositId];

        // check tokenId is belong to sender
        if (staking.owner != _msgSender()) revert InvalidOwner();

        // check if the token is in lock period
        if (staking.timestamp + staking.lock > block.timestamp) revert Locked();

        // withdraw mpwr reward
        uint256 reward = rewardOf(depositId);
        IERC20Upgradeable(mpwrToken).transfer(_msgSender(), reward);

        // transfer LP nft to staker
        nonfungiblePositionManager.transferFrom(address(this), _msgSender(), staking.id);

        // update llc reward amount in gift contract
        uint256 llcReward = staking.llc + staking.lock / 90 days;
        _addLLCReward(_msgSender(), llcReward);

        emit Withdraw(_msgSender(), depositId, staking.id, llcReward, reward);
    }

    /* ==================== VIEW METHODS ==================== */

    /**
     * @dev returns an array of token IDs owned by `owner`.
     *
     * @param _owner address of LP token owner
     * @return array of Deposit struct id
     */
    function depositsOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 count;
        uint256[] memory result = new uint256[](currentRound);

        for (uint256 i = 0; i < totalStaked && count < currentRound; i++) {
            if (deposits[i].owner == _owner) {
                result[count++] = i;
            }
        }
        return result;
    }

    /**
     * @dev returns reward of a single LP token
     *
     * @param depositId Deposit struct id
     * @return reward of a selected depositId
     */
    function rewardOf(uint256 depositId) public view returns (uint256 reward) {
        reward = deposits[depositId].reward;
    }

    /**
     * @dev returns LLC reard amount of a single LP token
     *
     * @param depositId Deposit struct id
     */
    function rewardOfLLC(uint256 depositId) external view returns (uint256) {
        return deposits[depositId].llc;
    }

    /**
     * @dev returns the AGOV token balance of this contract
     *
     * @return agovAmount and mpwrAmount in this contract
     */
    function balancesOf()
        external
        view
        returns (
            uint256 agovAmount,
            uint256 mpwrAmount,
            uint256 wethAmount
        )
    {
        agovAmount = IERC20Upgradeable(agovToken).balanceOf(address(this));
        mpwrAmount = IERC20Upgradeable(mpwrToken).balanceOf(address(this));
        wethAmount = IWETH(wethToken).balanceOf(address(this));
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev add user to llc reward contract with claimable amount
     *
     * @param who llc reward claimer address
     * @param llcReward new llc reward amount
     */
    function _addLLCReward(address who, uint256 llcReward) internal {
        ILLCGift llc = ILLCGift(llcGift);
        uint256 claimableLLCs = llc.claimers(who) + llcReward;
        llc.addClaimer(who, claimableLLCs);
    }

    /**
     * @dev mint LP nft from uniswap position manager
     *
     * @param ethAmount ETH amount
     * @param agovAmount AGOV amount
     */
    function _mintPosition(uint256 ethAmount, uint256 agovAmount)
        internal
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 ethAmountInPosition,
            uint256 agovAmountInPosition
        )
    {
        // Approve the position manager
        IWETH(wethToken).approve(address(nonfungiblePositionManager), ethAmount);
        IERC20Upgradeable(agovToken).approve(address(nonfungiblePositionManager), agovAmount);

        // The values for tickLower and tickUpper may not work for all tick spacings.
        // Setting amount0Min and amount1Min to 0 is unsafe.
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: wethToken,
            token1: agovToken,
            fee: poolFee,
            tickLower: 70020,
            tickUpper: 116100,
            amount0Desired: ethAmount,
            amount1Desired: agovAmount,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });

        // Fee tier 0.3% must already be created and initialized in order to mint
        (tokenId, liquidity, ethAmountInPosition, agovAmountInPosition) = nonfungiblePositionManager.mint(params);
    }

    /**
     * @dev verify if the signature is right and available to mint
     *
     * @param _who owner of LP nft
     * @param _round round of current running migration
     * @param _amountIn AGOV token amount which was deposited from klaytn
     * @param _lock lock up period
     * @param _amountOut MPWR token reward amount
     * @param _timestamp timestamp to verify the signature
     * @param _signature signature is generated from off-chain backend
     */
    function _verify(
        address _who,
        uint256 _round,
        uint256 _amountIn,
        uint256 _lock,
        uint256 _amountOut,
        uint256 _timestamp,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 signedHash = keccak256(
            abi.encodePacked(_who, NAME_HASH, _round, _amountIn, _lock, _amountOut, _timestamp)
        );
        bytes32 messageHash = signedHash.toEthSignedMessageHash();
        address messageSender = messageHash.recover(_signature);

        if (messageSender != validator) return false;

        return true;
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev owner can update merkle tree root
     *
     * @param _validator validator address
     */
    function setValidator(address _validator) external onlyOwner {
        validator = _validator;
    }

    /**
     * @dev owner can set new on-going round number
     *
     * @param _round new round number
     */
    function setCurrentRound(uint256 _round) external onlyOwner {
        currentRound = _round;
    }

    /**
     * @dev owner can unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev owner can withdraw AGOV token
     */
    function withdrawAgov(address to) external onlyOwner {
        IERC20Upgradeable agov = IERC20Upgradeable(agovToken);
        uint256 agovAmount = agov.balanceOf(address(this));
        agov.safeTransfer(to, agovAmount);
    }

    /**
     * @dev owner can withdraw MPWR token
     */
    function withdrawMPWR(address to) external onlyOwner {
        IERC20Upgradeable mpwr = IERC20Upgradeable(mpwrToken);
        uint256 mpwrAmount = mpwr.balanceOf(address(this));
        mpwr.safeTransfer(to, mpwrAmount);
    }

    /**
     * @dev owner can withdraw WETH
     */
    function withdrawWETH(address to) external onlyOwner {
        IWETH weth = IWETH(wethToken);
        weth.transfer(to, weth.balanceOf(address(this)));
    }

    /**
     * @dev owner can set llc gift contract address
     */
    function setGiftContract(address gift) external onlyOwner {
        llcGift = gift;
    }
}