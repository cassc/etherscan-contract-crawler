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
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../interfaces/INonfungiblePositionManager.sol";
import "../interfaces/IQuoter.sol";
import "../interfaces/ILLCGift.sol";
import "../interfaces/IWETH.sol";
import "../utils/Errors.sol";

contract LLCMPWRMigration is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    /// @dev uniswap liquidity pool fee
    uint24 private constant poolFee = 3000;
    /// @dev
    /// TODO 180 days
    uint256 private constant LOCK_PERIOD = 180 days;
    /// @dev at least 2 ethers should be deposited
    /// TODO 2 ETH
    uint256 private constant MIN_ETH_AMOUNT = 2 ether;
    /// @dev APR % of 100
    uint256 private constant APR = 15;
    /// @dev MPWR token
    IERC20Upgradeable public mpwrToken;
    /// @dev WETH token
    IWETH public wethToken;
    /// @dev LLC token
    IERC721Upgradeable public llcToken;
    /// @dev Uniswap Quoter smart contract
    IQuoter public quoter;
    /// @dev uniswap non fungible position manager
    INonfungiblePositionManager public nonfungiblePositionManager;
    /// @dev total staked count
    uint256 public totalStaked;
    /// @dev stop/unstop deposit
    bool public canDeposit;
    /// @dev tick lower value
    int24 private tickLower;
    /// @dev tick upper value
    int24 private tickUpper;

    /// @dev represents the deposit of an NFT
    struct Deposit {
        address owner;
        uint256 id;
        uint256 ethAmount;
        uint256 mpwrAmount;
        uint256 reward;
        uint256 llcId;
        uint256 timestamp;
    }

    /// @dev user status of all rounds
    mapping(address => uint256) private status;
    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;

    /* ==================== EVENTS ==================== */

    event StakeLP(address indexed owner, uint256 depositId, uint256 tokenId, uint256 llcId, uint256 reward);

    event Withdraw(address indexed owner, uint256 depositId, uint256 tokenId, uint256 llcId, uint256 reward);

    event Receive(address indexed sender, uint256 amount);

    /* ==================== METHODS ==================== */

    /* ==================== METHODS ==================== */

    /**
     * initialize the contract
     *
     * @param _wethToken WETH contract address
     * @param _mpwrToken MPWR token contract address
     * @param _quoter Address of uniswap quoter contract
     * @param _position Uniswap LP position
     */
    function initialize(
        address _wethToken,
        address _mpwrToken,
        address _llcToken,
        address _quoter,
        address _position
    ) external initializer {
        __Context_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        if (_mpwrToken == address(0) || _wethToken == address(0) || _llcToken == address(0)) revert ZeroAddress();

        wethToken = IWETH(_wethToken);
        mpwrToken = IERC20Upgradeable(_mpwrToken);
        llcToken = IERC721Upgradeable(_llcToken);
        quoter = IQuoter(_quoter);
        nonfungiblePositionManager = INonfungiblePositionManager(_position);
        tickLower = -85200;
        tickUpper = -23040;
        canDeposit = true;
    }

    /**
     * @dev deposit ETH and LLC token to generate LP
     *
     * @param llcId LLC token id
     */
    function deposit(uint256 llcId) external payable whenNotPaused nonReentrant {
        // check if it is open to deposit
        if (!canDeposit) revert InvalidRound();
        // check if user is owner of LLC token
        if (llcToken.ownerOf(llcId) != _msgSender()) revert InvalidOwner();
        // check if deposited eth amount is bigger than minimun amount
        if (msg.value < MIN_ETH_AMOUNT) revert InvalidAmount();

        // convert eth to weth
        wethToken.deposit{ value: (msg.value) }();

        // transfer LLC token to this smart contract
        llcToken.transferFrom(_msgSender(), address(this), llcId);

        // get MPWR token amount equal to eth amount
        uint256 mpwrInAmount = quoter.quoteExactInputSingle(
            address(wethToken),
            address(mpwrToken),
            poolFee,
            msg.value,
            0
        );

        // create a new lp position wrapped in a NFT
        (uint256 tokenId, , uint256 ethOutAmount, uint256 mpwrOutAmount) = _mintPosition(msg.value, mpwrInAmount);

        // calculate reward
        uint256 reward = _reward(ethOutAmount);

        // store the lp owner data
        uint256 depositId = totalStaked++;
        deposits[depositId] = Deposit({
            owner: _msgSender(),
            id: tokenId,
            reward: reward,
            ethAmount: ethOutAmount,
            mpwrAmount: mpwrOutAmount,
            llcId: llcId,
            timestamp: block.timestamp
        });

        // refund rest WETH
        if (ethOutAmount < msg.value) {
            IWETH(wethToken).approve(address(nonfungiblePositionManager), 0);
            IWETH(wethToken).transfer(_msgSender(), msg.value - ethOutAmount);
        }

        emit StakeLP(_msgSender(), depositId, tokenId, llcId, reward);
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
        if (staking.timestamp + LOCK_PERIOD > block.timestamp) revert Locked();

        // withdraw eth reward
        uint256 reward = rewardOf(depositId);
        (bool sent, ) = _msgSender().call{ value: reward }("");
        if (!sent) revert InvalidTransfer();

        // transfer LLC token to staker
        llcToken.transferFrom(address(this), _msgSender(), staking.llcId);

        // transfer LP nft to staker
        nonfungiblePositionManager.transferFrom(address(this), _msgSender(), staking.id);

        emit Withdraw(_msgSender(), depositId, staking.id, staking.llcId, staking.reward);
    }

    /* ==================== VIEW METHODS ==================== */

    function depositCountOfOwner(address _owner) public view returns (uint256 count) {
        for (uint256 i = 0; i < totalStaked; i++) {
            if (deposits[i].owner == _owner) {
                count++;
            }
        }
    }

    /**
     * @dev returns an array of token IDs owned by `owner`.
     *
     * @param _owner address of LP token owner
     * @return array of Deposit struct id
     */
    function depositsOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 length;
        uint256 count = depositCountOfOwner(_owner);
        uint256[] memory result = new uint256[](count);

        for (uint256 i = 0; i < totalStaked; i++) {
            if (deposits[i].owner == _owner) {
                result[length++] = i;
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
     * @dev returns the MPWR token balance of this contract
     *
     * @return ethAmount and mpwrAmount in this contract
     */
    function balancesOf()
        external
        view
        returns (
            uint256 ethAmount,
            uint256 mpwrAmount,
            uint256 wethAmount
        )
    {
        ethAmount = address(this).balance;
        mpwrAmount = mpwrToken.balanceOf(address(this));
        wethAmount = wethToken.balanceOf(address(this));
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev returns eth reward base on input amount
     * @param ethAmount deposited ETH amount
     */
    function _reward(uint256 ethAmount) internal pure returns (uint256 reward) {
        reward = (ethAmount * APR * 180) / 365 / 100;
    }

    /**
     * @dev mint LP nft from uniswap position manager
     *
     * @param ethAmount ETH amount
     * @param mpwrAmount MPWR amount
     */
    function _mintPosition(uint256 ethAmount, uint256 mpwrAmount)
        internal
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 ethAmountInPosition,
            uint256 mpwrAmountInPosition
        )
    {
        // Approve the position manager
        wethToken.approve(address(nonfungiblePositionManager), ethAmount);
        mpwrToken.approve(address(nonfungiblePositionManager), mpwrAmount);

        // The values for tickLower and tickUpper may not work for all tick spacings.
        // Setting amount0Min and amount1Min to 0 is unsafe.
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: address(mpwrToken),
            token1: address(wethToken),
            fee: poolFee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: mpwrAmount,
            amount1Desired: ethAmount,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });

        // Fee tier 0.3% must already be created and initialized in order to mint
        (tokenId, liquidity, mpwrAmountInPosition, ethAmountInPosition) = nonfungiblePositionManager.mint(params);
    }

    /* ==================== CALLBACK ==================== */

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev possible to deposit ETH as reward
     */
    receive() external payable {
        emit Receive(_msgSender(), msg.value);
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
     * @dev owner can withdraw MPWR token
     */
    function withdrawETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    /**
     * @dev owner can withdraw MPWR token
     */
    function withdrawMPWR(address to) external onlyOwner {
        uint256 mpwrAmount = mpwrToken.balanceOf(address(this));
        mpwrToken.safeTransfer(to, mpwrAmount);
    }

    /**
     * @dev owner can withdraw WETH
     */
    function withdrawWETH(address to) external onlyOwner {
        wethToken.transfer(to, wethToken.balanceOf(address(this)));
    }

    /**
     * @dev owner can set tick value range
     */
    function setTicks(int24 lower, int24 upper) external onlyOwner {
        tickLower = lower;
        tickUpper = upper;
    }

    /**
     * @dev pause/unpause deposit
     */
    function setStatus(bool _status) external onlyOwner {
        canDeposit = _status;
    }
}