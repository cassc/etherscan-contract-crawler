// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";

/**
 *  @title A Rewards Distributor Contract
 *  @notice A rewards distribution contract using a Merkle Tree to verify the amount and
 *          address of the user claiming ERC20 tokens
 *  @dev Functions are intended to be triggered on a specific timeframe (epoch) via a back-end
 *       service
 */
contract MerkleRewardsDistributor is Ownable, ReentrancyGuard {

    //
    // Constants ==================================================================================
    //

    uint16 public constant BPS_MAX = 10000;    

    //
    // State ======================================================================================
    //

    IERC20 public tokenContract;
    IUniswapV2Router02 public routerContract;

    bool public betweenEpochs;
    address public adminAddress;
    address public daoAddress;
    address public treasuryAddress;
    bytes32 public merkleRoot;
    /// @dev Treasury fee percentage expressed in basis points
    uint16 public treasuryFeeBps;
    uint256 public currentEpoch;
    /// @dev Cumulative amount of fees allocated to treasury during current epoch
    uint256 public treasuryFees;    
    
    uint256 public minStakeAmount = 2000 * 1e18;
    uint256 public swapTimeout = 15 minutes;

    mapping(bytes32 => bool) public claimed;

    //
    // Constructor ================================================================================
    //

    constructor(
        address _adminAddress,
        address _treasuryAddress,
        address _daoAddress,
        address tokenAddress,
        address routerAddress
    ) {
        adminAddress = _adminAddress;
        treasuryAddress = _treasuryAddress;
        daoAddress = _daoAddress;
        tokenContract = IERC20(tokenAddress);
        routerContract = IUniswapV2Router02(routerAddress);
    }

    //
    // Receive function ===========================================================================
    //

    receive() external payable {
        // Empty
    }

    //
    // Modifiers ==================================================================================
    //

    modifier claimsEnabled() {
        if(betweenEpochs) revert ClaimsDisabledUntilNextEpoch();
        _;
    }

    modifier onlyAdmin() {
        if(msg.sender != adminAddress) revert OnlyAdmin();
        _;
    }

    modifier onlyDao() {
        if(msg.sender != daoAddress) revert OnlyDao();
        _;
    }

    //
    // External functions =========================================================================
    //

    /**
     * @notice Transfers tokens to the claimer address if he was included in the Merkle Tree with
     *         the specified index
     */
    function claim(
        uint256 amountToClaim,
        bytes32[] calldata merkleProof
    ) external nonReentrant claimsEnabled {
        bytes32 leaf = toLeaf(currentEpoch, msg.sender, amountToClaim);
        /// @dev make sure the merkle proof validates the claim
        if(!MerkleProof.verify(merkleProof, merkleRoot, leaf)) revert InvalidMerkleProof();
        /// @dev cannot claim same leaf more than oncer per epoch
        if(claimed[leaf]) revert RewardAlreadyClaimed();
        
        claimed[leaf] = true;

        tokenContract.transfer(msg.sender, amountToClaim);

        emit Claimed(msg.sender, currentEpoch, amountToClaim);
    }

    function claimsDisabled() external view returns (bool) {
        return betweenEpochs;
    }

    /**
     *  @notice Ends the current epoch, marks all attributed tokens, ETH and when the epoch has ended
     */
    function endEpoch(
        uint256 epochNumber,
        uint256 ethAttributed,
        address[] memory ethSwapPath,
        uint256 ethReturnMin,
        address[] memory tokensAttributed,
        uint256[] memory amountsAttributed,
        address[][] memory swapPaths,
        uint256[] memory amountsOutMin
    ) external onlyAdmin {
        /// @dev make sure the caller knows which epoch they're ending
        if(epochNumber != currentEpoch) revert IncorrectEpoch();

        if(ethAttributed > address(this).balance) {
            revert InsufficientEthBalance(ethAttributed, address(this).balance);
        }
        
        /// @dev make sure our input arrays have matching lengths
        uint256 tokenCount = tokensAttributed.length;
        if(amountsAttributed.length != tokenCount
            || swapPaths.length != tokenCount
            || amountsOutMin.length != tokenCount
        ) revert MismatchedArrayLengths();

        /// @dev pause claims until our the next/new merkle root set
        betweenEpochs = true;

        /// @dev emit event and increment currentEpoch
        emit EpochEnded(currentEpoch, block.timestamp);

        if(ethAttributed > 0 || tokensAttributed.length > 0) {
            /// @dev Execute the token/ETH swaps
            swapMultiple(
                ethAttributed,
                ethSwapPath,
                ethReturnMin,
                tokensAttributed,
                amountsAttributed,
                swapPaths,
                amountsOutMin
            );
        }

        if(treasuryFees > 0) {
            depositTreasuryFees();
        }
    }

    function nextEpoch(bytes32 newMerkleRoot, bytes memory newMerkleCDI) external onlyAdmin {
        if(!betweenEpochs) revert InvalidRequest("Epoch in progress");
        currentEpoch += 1;
        betweenEpochs = false;
        treasuryFees = 0;
        setMerkleRoot(newMerkleRoot, newMerkleCDI);
        emit EpochStarted(currentEpoch);
    }

    function setAdminAddress(address _adminAddress) external onlyOwner {
        emit AdminAddressUpdated(adminAddress, _adminAddress);
        adminAddress = _adminAddress;
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        emit DaoAddressUpdated(daoAddress, _daoAddress);
        daoAddress = _daoAddress;
    }

    function setMinStakeAmount(uint256 _minStakeAmount) external onlyDao {
        emit MinStakeAmountUpdated(minStakeAmount, _minStakeAmount);
        minStakeAmount = _minStakeAmount;
    }

    function setRouterContract(address _routerContract) external onlyOwner {
        emit RouterContractUpdated(address(routerContract), _routerContract);
        routerContract = IUniswapV2Router02(_routerContract);
    }

    /**
     * @notice Sets the swap timeout for ERC20 token swaps via the router contract
     * @param _swapTimeout the new timeout expressed in seconds
     */
    function setSwapTimeout(uint256 _swapTimeout) external onlyOwner {
        emit SwapTimeoutUpdated(swapTimeout, _swapTimeout);
        swapTimeout = _swapTimeout;
    }

    /**
     * @notice Updates the treasury fee recipient address
     * @param _treasuryAddress the new treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        emit TreasuryAddressUpdated(treasuryAddress, _treasuryAddress);
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice Updates the treasury fee percentage
     * @param _treasuryFeeBps the fee percentage expressed in basis points e.g. 650 is 6.5%
     */
    function setTreasuryFeeBps(uint16 _treasuryFeeBps) external onlyDao {
        if(_treasuryFeeBps > BPS_MAX) revert InvalidTreasuryFee();
        emit TreasuryFeeUpdated(treasuryFeeBps, _treasuryFeeBps);
        treasuryFeeBps = _treasuryFeeBps;
    }

    //
    // Internal functions =========================================================================
    //

    /**
     * @notice Transfer cumulative treasury fees if any to `treasuryAddress`
     */
    function depositTreasuryFees() internal {
        uint256 _treasuryFees = treasuryFees;
        treasuryFees = 0;
        tokenContract.transfer(treasuryAddress, _treasuryFees);
        emit DepositedTreasuryFees(treasuryAddress, _treasuryFees);
    }

    /**
     *  @notice Calculates a leaf of the tree in bytes format (to be passed for verification).
     *      The leaf includes the epoch number which means they are unique across epochs
     *      for identical addresses and claim amounts. Leaves are double-hashed to prevent
     *      second preimage attacks, see:
     * 
     *      https://flawed.net.nz/2018/02/21/attacking-merkle-trees-with-a-second-preimage-attack/
     */
    function toLeaf(uint256 epoch, address addr, uint256 amount)
        internal
        pure
        returns (bytes32) {
        return keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(epoch, addr, amount)
                )
            )
        );
    }

    /**
     * @param newMerkleRoot the newly calculated root of the tree after all user info is updated
     *        at the end of an epoch
     * @param newMerkleCDI the new CDI on IPFS where the file to rebuild the Merkle Tree is
     *        contained
     */
    function setMerkleRoot(bytes32 newMerkleRoot, bytes memory newMerkleCDI) internal {
        merkleRoot = newMerkleRoot;
        emit MerkleProofCIDUpdated(newMerkleCDI);
    }

    /**
     *  @notice Does a bunch of swaps with all tokens in tokensIn. Also swaps ETH for tokenContract
     *          if transaction value > 0.
     *  @dev amountsOutMin array should be passed with the right minimum amounts calculated
     *       otherwise the transaction would fail.
     */
    function swapMultiple(
        uint256 ethAttributed,
        address[] memory ethSwapPath,
        uint256 ethReturnMin,
        address[] memory tokensAttributed,
        uint256[] memory amountsAttributed,
        address[][] memory swapPaths,
        uint256[] memory amountsOutMin
    ) internal {

        if (ethAttributed > 0) {
            _swapEth(ethAttributed, ethSwapPath, ethReturnMin);
        }

        address currentTokenToSwap;
        uint256 tokenAmount;

        /// @dev iterate over tokens and swap each of them
        for (uint256 i = 0; i < tokensAttributed.length;) {
            
            currentTokenToSwap = tokensAttributed[i];
            tokenAmount = amountsAttributed[i];

            if(tokenAmount > IERC20(currentTokenToSwap).balanceOf(address(this))) {
                revert InsufficientTokenBalance(
                    currentTokenToSwap,
                    tokenAmount,
                    IERC20(currentTokenToSwap).balanceOf(address(this))
                );
            }

            if(currentTokenToSwap == address(tokenContract)) {
                /// @dev no swap needs to occur in this case
                _finalizeErc20Swap(currentTokenToSwap, tokenAmount);
            }
            else {
                IERC20(currentTokenToSwap).approve(
                    address(routerContract),
                    tokenAmount
                );

                _swapErc20(tokenAmount, amountsOutMin[i], swapPaths[i]);
            }

            /// @dev gas savings, can't overflow bc constrained by our array's length
            unchecked {
                i++;
            }
        }
    }

    //
    // Private functions ==========================================================================
    //

    /**
     * @notice Possibly apply treasury fee to swapped token amount and emit swap event
     * @param tokenAmount the amount of reward tokens received from the token/Eth swap
     */
    function _applyFee(uint256 tokenAmount) private returns (uint256) {
        if(treasuryFeeBps > 0) {
            uint256 feeAmount = treasuryFeeBps * tokenAmount / BPS_MAX;
            tokenAmount -= feeAmount;
            treasuryFees += feeAmount;
            emit TreasuryFeeTaken(currentEpoch, feeAmount);
        }

        return tokenAmount;
    }

    function _finalizeErc20Swap(address tokenAddress, uint256 tokenAmount) private {
        uint256 netTokenAmount = _applyFee(tokenAmount);
        emit TokensSwapped(tokenAmount, netTokenAmount, currentEpoch, tokenAddress);
    }

    /**
     *  @dev Swaps tokens in path with the recipient being this contract
     *  @dev The optimal path relies on being accepted externally
     */
    function _swapErc20(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) private {
        uint256[] memory amounts = routerContract.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + swapTimeout
        );

        _finalizeErc20Swap(path[0], amounts[1]);
    }

    function _swapEth(uint256 ethAmount, address[] memory ethSwapPath, uint256 ethReturnMin) private {
        uint256[] memory amounts = routerContract.swapExactETHForTokens{
            value: ethAmount
        }(
            ethReturnMin,
            ethSwapPath,
            address(this),
            block.timestamp + swapTimeout
        );

        uint256 netTokenAmount = _applyFee(amounts[1]);

        emit EthSwapped(amounts[1], netTokenAmount, currentEpoch);
    }

    //
    // Errors/events ==============================================================================
    //

    error ClaimsDisabledUntilNextEpoch();
    error IncorrectEpoch();
    error InvalidEpoch();
    error InvalidMerkleProof();
    error InvalidRequest(string msg);
    error InvalidTreasuryFee();
    error InsufficientEthBalance(uint256 required, uint256 actual);
    error InsufficientTokenBalance(address token, uint256 required, uint256 actual);
    error MismatchedArrayLengths();
    error NoTokensAttributed();
    error OnlyAdmin();
    error OnlyDao();
    error RewardAlreadyClaimed();

    event AdminAddressUpdated(address indexed from, address indexed to);
    event Claimed(address indexed account, uint256 epoch, uint256 amount);
    event DaoAddressUpdated(address indexed from, address indexed to);
    event DepositedTreasuryFees(address indexed addr, uint256 amount);
    event EpochEnded(uint256 endedEpochNum, uint256 timestamp);
    event EpochStarted(uint256 epochNumber);
    event EthSwapped(uint256 swapAmountOut, uint256 receivedTokens, uint256 epoch);
    event MerkleProofCIDUpdated(bytes newMerkleCDI);
    event MinStakeAmountUpdated(uint256 from, uint256 to);
    event RouterContractUpdated(address indexed from, address indexed to);
    event SwapTimeoutUpdated(uint256 from, uint256 to);
    event TokensSwapped(uint256 swapAmountOut, uint256 receivedTokens, uint256 epoch, address indexed tokenAddress);
    event TreasuryAddressUpdated(address indexed from, address indexed to);
    event TreasuryFeeTaken(uint256 epoch, uint256 amount);
    event TreasuryFeeUpdated(uint256 from, uint256 to);
}