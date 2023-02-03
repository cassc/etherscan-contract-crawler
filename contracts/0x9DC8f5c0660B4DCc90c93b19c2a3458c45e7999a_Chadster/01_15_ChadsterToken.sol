// SPDX-License-Identifier: MIT

/**
 * $CHADSTER
 *
 * Website: https://www.chadster.xyz/
 * Twitter: https://twitter.com/ChadsterInu
 * Tg: https://t.me/chadsterinu
 */

pragma solidity 0.8.7;

import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Router02.sol";
import "IERC721A.sol";

import "Address.sol";
import "Ownable.sol";
import "ERC20.sol";
import "ERC721Holder.sol";
import "Pausable.sol";


contract Chadster is ERC20, Ownable, Pausable, ERC721Holder  {

    struct NftStake {
        uint256 startBlock;
        uint256 id;
    }

    struct UserStake {
        mapping(uint256 => NftStake) stakes;
        uint256[] stakedNfts;
    }

    // Optimize variables for packing
    bool private _inSwap = false;
    bool private _tradeOpen = false;
    bool private _swapEnabled = false;

    address public _marketingWallet;
    IUniswapV2Router02 public router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC721A private _NFT;

    uint256 private _buyFee = 30;
    uint256 private _sellFee = 30;

    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;

    uint256 private _stakingReward;

    uint256 private _stakingbReward =  1 * 10 ** 18;

    uint256[] private _rarityModifierPerBlock;

    mapping(address => bool) public pairs;
    mapping(address => bool) public exempts;
    mapping(address => UserStake) private _stakes;

    event LimitsUpdated(uint256 indexed maxTx, uint256 indexed maxWallet);
    event FeesUpdated(uint256 indexed buyFee, uint256 indexed sellFee);
    event PairAdded(address indexed pair);

    constructor() ERC20("Chadster", "CHADSTER"){
        address admin = _msgSender();
        _marketingWallet = admin;

        uint256 supply = 100_000_000 * 10 ** 18;
        uint256 forLiquidity = supply / 2;
        uint256 forStaking = supply - forLiquidity;
        _stakingReward = forStaking;

        // Set limits
        maxTxAmount = (20 * supply) / 1000;
        maxWalletAmount = (20 * supply) / 1000;

        // Setup fee exempts
        exempts[address(this)] = true;
        exempts[admin] = true;
        exempts[_marketingWallet] = true;

        // Mint the total supply, by 50-50 goes for liquidity and the other half for staking reward
        _mint(address(this), forStaking);
        _mint(admin, forLiquidity);

        // Pause staking
        _pause();
    }

    /**********************************************************
     * Modifiers
    ***********************************************************/
    modifier withSwap() {
        _swapEnabled = true;
        if(!_inSwap) {
            _inSwap = true;
            _;
            _inSwap = false;
        }
    }

    /**********************************************************
     * Admin functions
    ***********************************************************/
    /**
     * @dev Enable trading
     */
    function openTrading() external onlyOwner() {
        _tradeOpen = true;
    }

    /**
     * @dev Remove contract limits
     */
    function removeLimits() external onlyOwner {
        uint256 supply = totalSupply();
        maxTxAmount = supply;
        maxWalletAmount = supply;

        emit LimitsUpdated(maxTxAmount, maxWalletAmount);
    }

    /**
     * @dev Update max TX and max wallet
     */
    function setLimits(uint256 maxTxPercentage, uint256 maxWalletPercentage) external onlyOwner {
        require(maxTxPercentage >= 10, "too low"); // Minimum 1%
        require(maxWalletPercentage >= 10, "too low"); // Minimum 1%

        uint256 supply = totalSupply();
        maxTxAmount = (maxTxPercentage * supply) / 1000;
        maxWalletAmount = (maxWalletPercentage * supply) / 1000;

        emit LimitsUpdated(maxTxAmount, maxWalletAmount);
    }

    /**
     * @dev Reduce taxes
     */
    function setFees(uint256 buyTaxPercentage, uint256 sellTaxPercentage) external onlyOwner {
        require(buyTaxPercentage <= 150, "too high"); // Maximum 15%
        require(sellTaxPercentage <= 150, "too high"); // Maximum 15%

        _buyFee = buyTaxPercentage;
        _sellFee = sellTaxPercentage;

        emit FeesUpdated(buyTaxPercentage, sellTaxPercentage);
    }

    /**
     * @dev Register new trading pair
     */
    function registerPair(address newPair) external onlyOwner {
        pairs[newPair] = true;

        emit PairAdded(newPair);
    }

    /**
     * @dev Send stucked ETH from wallet
    */
    function manualSend() external {
        _sendEth();
    }

    /**
     * @dev Initiate a manual swap of tax tokens
    */
    function manualSwap() external {
        _convertToEth(balanceOf(address(this)) - _stakingReward);
    }

    /**
     * @dev Set the NFT address
    */
    function setNft(address nftAddress) external onlyOwner {
        _NFT = IERC721A(nftAddress);
    }

    /**
     * @dev Update the staking parameters
    */
    function setStakeModifiers(uint256 stakingReward, uint256[] memory rarityModifier) external onlyOwner {
        _stakingReward = stakingReward;
        for (uint256 i = 0; i < rarityModifier.length; ++i) {
            _rarityModifierPerBlock[i] = rarityModifier[i];
        }
    }

    /**
     * @dev Toggle pause for staking
    */
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**********************************************************
     * Internal functions
    ***********************************************************/

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "too less");
        
        uint256 fees = 0;
        if (!(exempts[to] || exempts[from] || exempts[tx.origin])) {
            if (!_tradeOpen) {
                require(exempts[from], "not open yet");
            }
            if (pairs[from] && to != address(router) && !exempts[to]) {
                require(amount <= maxTxAmount, "tx limit");
                require((balanceOf(to) + amount) <= maxWalletAmount, "wallet limit");
            }
            if (pairs[to]) {
                uint256 tokens = balanceOf(address(this)) - _stakingReward;
                if (tokens > 0 && _swapEnabled) {
                    _convertToEth(tokens);
                }
                fees = (amount * _sellFee) / 1000;
            } else if (pairs[from]) {
                fees = (amount * _buyFee) / 1000;
            } else {}
            
            if (fees > 0) {
                super._transfer(from, address(this), fees);        
            }
        }

        super._transfer(from, to, amount - fees);
    }

    function _convertToEth(uint256 amount) private withSwap {
        if (amount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, _marketingWallet, block.timestamp);
        _sendEth();
    }

    function _sendEth() private {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(_marketingWallet).transfer(balance);
        }
    }

    /**********************************************************
     * Stake and earn functions
    ***********************************************************/

    event NftStaked(address indexed owner, uint256 indexed id);
    event NftWithdrawn(address indexed owner, uint256 indexed id);
    event RewardClaimed(address indexed owner, uint256 indexed id, uint256 amount);

    /**
     * @dev Stake nft
    */
    function stake(uint256 id) external whenNotPaused {
        address sender = _msgSender();
        UserStake storage stakeInfo = _stakes[sender];

        require(_NFT.ownerOf(id) == sender, "not owner");
        // Try to transfer the token ID, if not approved safeTransferFrom will revert
        _NFT.safeTransferFrom(sender, address(this), id);

        // Store the staking data
        stakeInfo.stakes[id].id = id;
        stakeInfo.stakes[id].startBlock = block.number;

        stakeInfo.stakedNfts.push(id);

        emit NftStaked(sender, id);
    }

    /**
     * @dev Withdraw staked nft
    */
    function withdraw(uint256 id) external whenNotPaused {
        address sender = _msgSender();
        UserStake storage stakeInfo = _stakes[sender];

        NftStake memory nftInfo = stakeInfo.stakes[id];
        // Prevent unstaking of other users nft
        require(nftInfo.id == id && nftInfo.startBlock != 0, "not found");
        // Remove the unstaked NFT from the list
        for(uint256 i = 0; i < stakeInfo.stakedNfts.length; ++i) {
            if (i == id) {
                stakeInfo.stakedNfts[i] = stakeInfo.stakedNfts[stakeInfo.stakedNfts.length - 1];
                stakeInfo.stakedNfts.pop();
            }
        }
        // Transfer pending rewards
        claimReward(id);
        // Remove the NFT from the mapping
        stakeInfo.stakes[id].id = 0;
        stakeInfo.stakes[id].startBlock = 0;

        emit NftWithdrawn(sender, id);
    }

    /**
     * @dev Collect pending rewards
    */
    function claimReward(uint256 id) public whenNotPaused {
        address sender = _msgSender();
        UserStake storage stakeInfo = _stakes[sender];
        NftStake memory nftInfo = stakeInfo.stakes[id];
        // Prevent claiming reward of other users
        require(nftInfo.id == id && nftInfo.startBlock != 0, "not found");
        // Get reward amount
        uint256 reward = pendingReward(sender, id);        
        // Reset startBlock
        stakeInfo.stakes[id].startBlock = block.number;
        if (reward > 0) {
            // Transfer reward
            transfer(sender, reward);
            _stakingReward -= reward;
            emit RewardClaimed(sender, id, reward);
        }
    }

    /**
     * @dev Check how much pending reward
    */
    function pendingReward(address user, uint256 id) public view returns(uint256)  {
        UserStake storage stakeInfo = _stakes[user];
        uint256 currentBlock = block.number;
        uint256 startBlock = stakeInfo.stakes[id].startBlock;   
        uint256 multiplier = 0;
        
        // Calculate rarity
        for (uint256 i = 0; i < _rarityModifierPerBlock.length; ++i ) {
            if (id % (i + 1) == 0) {
                multiplier += _rarityModifierPerBlock[i];
            }            
        }
        multiplier = _stakingbReward * (multiplier / 2);
        uint256 possibleReward = (currentBlock - startBlock) * multiplier;
        return possibleReward > _stakingReward ? _stakingReward : possibleReward;
    }

    /**
     * @dev Return with the list of staked NFTs
    */
    function getStakedNfts(address user) external view returns(uint256[] memory) {
        UserStake storage stakeInfo = _stakes[user];
        return stakeInfo.stakedNfts;
    }
}