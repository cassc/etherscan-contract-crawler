// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IAutoMinterFactory.sol";

contract AutoMinterERC20 is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    
    // revenue supplied to the contract
    uint256 private revenue;

    // the signer address for verifying airdrops
    address private airdropSignerAddress;

    // the quantity of supply claimed in the airdrop
    uint256 private quantityClaimed;

    // the max supply to be claimed in the airdrop
    uint256 private airdropLimit;

    // the address of the staking contract
    address private stakingContract;

    // the address of the treasury, team, investor treasury fund contract
    address private fundsContract;

    // the amount that each account has claimed in the airdrop
    mapping(address => bool) public accountClaimed;
    
    // AutoMinter Factory contract to check valid collection addresses
    IAutoMinterFactory private autoMinterFactory;

    // the integer representing the current lock window
    uint256 public currentLockWindow;

    // is airdrop tradable
    bool public isAirdropTradable;

    struct LockInfo {
        uint256 lockWindow;
        uint256 totalLockAmount;
        uint256 currentLockWindowAmount;
        uint256 previousLockWindowAmount;
        uint256 lastLockWindowAmount;
        uint256 airdropAmount;
    }

    mapping(address => LockInfo) private accountLockedTokens;

    // the max supply reserved for strategic sale + liquidity provision
    uint256 private strategicLiquidityLimit;

    // the quantity of supply strategic liquidity released
    uint256 private strategicLiquidityReleased;

    constructor() {}

    function initialize(address stakingContract_, address fundsContract_, address autoMinterFactoryContract_) public virtual initializer {
        __ERC20_init("AutoMinter", "AMR");
        _transferOwnership(msg.sender);
        airdropSignerAddress = msg.sender;
        stakingContract = stakingContract_;
        fundsContract = fundsContract_;
        airdropLimit = 20000000000000000000000000;
        strategicLiquidityLimit = 2000000000000000000000000;
        autoMinterFactory = IAutoMinterFactory(autoMinterFactoryContract_);
    }
    
    /**
     * @notice Claim the initil airdropped tokens
     * @dev Claim the initial allocation of tokens by providing the correct signature
     * @param amount the amount of tokens available to mint
     * @param signature the signature required to prove airdrop rights
     */
    function claim(uint256 amount, bytes calldata signature, address to) public
    {
        // check airdrop supply for a cap on how much can be claimed in the airdrop
        require(airdropLimit >= quantityClaimed + amount);

        // wallets can only claim 1 airdrop
        require(accountClaimed[to] == false);

        // Hash the content (amount, claimant) and verify the signature from the owner address
        address signer = ECDSA.recover(
                ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(amount, to))),
                signature);

        // check signature is valid
        require(signer == owner() || signer == airdropSignerAddress, "The signature provided does not match");

        // set claimant claim status to true
        accountClaimed[to] = true;
        accountLockedTokens[to].airdropAmount = amount;

        // mint the provided number of tokens
        _mint(to, amount);
    }

    /**
     * @notice Mint new tokens
     * @dev Exchange ETH for tokens by sending revenue
     * @param to the address which tokens should be minted too
     */
    function mint(address to) payable public
    {
        // require contract caller to be a registered contract to avoid direct mints
        require(autoMinterFactory.isCollectionValid(msg.sender), "Tokens can only be minted via contracts created with AutoMinter");

        // get value exchanged for tokens (decreasing marginal amount)
        uint256 value = _getValueDeduction(msg.sender, msg.value);

        // get the new number of tokens to mint (based on allocation curve)
        uint256 currentSupply = _getTotalAllocation(revenue);
        uint256 newSupply = _getTotalAllocation(revenue + value);
        uint256 diff = newSupply - currentSupply;

        uint256 volumeRewardsQuantity = diff  * 35 / 96;
        uint256 stakingRewardsQuantity = diff  * 17 / 96;
        uint256 fundsQuantity = diff  * 46 / 96;

        // lock new volume reward tokens
        _updateLockedTokens(to, volumeRewardsQuantity);

        // mint tokens based on new allocation (getAllocation)
        _mint(to, volumeRewardsQuantity);
        _mint(fundsContract, fundsQuantity);
        _mint(stakingContract, stakingRewardsQuantity);

        // update revenue
        revenue = revenue + value;
    }

    /**
     * @notice Transfer funds from the contract
     * @dev Transfer funds from the contract
     */
    function transferFunds() onlyOwner() public
    {
        uint256 balance = address(this).balance;

        payable(owner()).transfer(balance);
    }

    /**
     * @notice update the signer address for claimable airdrop
     * @dev the signer is the address who signs the claimable airdrop required signature
     */
    function updateSigner(address signer) onlyOwner() public
    {
        airdropSignerAddress = signer;
    }

    /**
     * @notice update the signer address for claimable airdrop
     * @dev the signer is the address who signs the claimable airdrop required signature
     */
    function updateStakingContract(address stakingContract_) onlyOwner() public
    {
        stakingContract = stakingContract_;
    }

    /**
     * @notice update the autominter factory address for validating source
     * @dev update the autominter factory address for validating source
     */
    function updateFactoryContract(address autoMinterFactoryContract_) onlyOwner() public
    {
        autoMinterFactory = IAutoMinterFactory(autoMinterFactoryContract_);
    }

    /**
     * @notice allow airdrop to be tradable
     * @dev allow airdropped tokens to be tradable and unlocked
     */
    function unlockAirdropTokens() onlyOwner() public
    {
        isAirdropTradable = true;
    }

    /**
     * @notice move the next lock window for users tokens to be unlocked
     * @dev move the next lock window period forward to unlock new tokens
     */
    function nextLockWindow() onlyOwner() public
    {
        currentLockWindow += 1;
    }
    
    /**
     * @notice check if wallet has claimed airdrop
     * @dev check if the provided wallet has already claimed the airdrop
     * @param account account to check claimed status
     */
    function hasClaimedAirdrop(address account) external view returns (bool)
    {
        return accountClaimed[account];
    }
    
    /**
     * @notice Move the strategic liquidity tokens
     * @dev The reserve of tokens reserved for liquidity provisioning and strategic sale
     * @param amount how much of the reserves to move in wei
     * @param to the address to send the reserves too
     */
    function moveStrategicLiquidityReserves(uint256 amount, address to) onlyOwner() public
    {
        airdropLimit = 20000000000000000000000000;
        
        // check airdrop supply for a cap on how much can be claimed in the airdrop
        require(strategicLiquidityLimit >= strategicLiquidityReleased + amount);

        strategicLiquidityReleased += amount;

        // mint the provided number of tokens
        _mint(to, amount);
    }


    /**
     * @notice get the number of locked tokens
     * @dev get the number of locked tokens for an account
     * @param account account to check locked token amount
     */
    function getLockedTokens(address account) external view returns (uint256)
    {
        return _getLockedTokens(account);
    }
    
    /**
     * @notice get the number of locked tokens
     * @dev get the number of locked tokens for an account
     * @param account account to check locked token amount
     */
    function _getLockedTokens(address account)  private view returns (uint256)
    {
        uint256 lockedAmount = 0;
        LockInfo storage lockInfo = accountLockedTokens[account];

        if(!isAirdropTradable){
            lockedAmount += lockInfo.airdropAmount;
        }
        
        uint256 windowsSkipped = currentLockWindow - lockInfo.lockWindow;

        if(windowsSkipped == 0){
            lockedAmount += lockInfo.currentLockWindowAmount + lockInfo.previousLockWindowAmount + lockInfo.lastLockWindowAmount;
        }
        else if(windowsSkipped == 1){
            lockedAmount += lockInfo.currentLockWindowAmount + lockInfo.previousLockWindowAmount;
        }
        else if(windowsSkipped == 2){
            lockedAmount += lockInfo.currentLockWindowAmount;
        }
        else{
            // ignore all lock measures
        }

        return lockedAmount;
    }

    /**
     * @notice update the number of locked tokens for a user
     * @dev update the number of locked tokens for a user
     * @param account account to lock tokens for
     * @param account new number of tokens to lock
     */
    function _updateLockedTokens(address account, uint256 amount) private
    {
        LockInfo storage lockInfo = accountLockedTokens[account];

        // do nothing if amount is 0 and lock window is the same
        if(lockInfo.lockWindow == currentLockWindow && amount == 0){
            return;
        }

        // if the lock window hasnt altered since the last update, update the lock amounts for the current window and total
        else if(lockInfo.lockWindow == currentLockWindow){
            accountLockedTokens[account].totalLockAmount += amount;
            accountLockedTokens[account].currentLockWindowAmount += amount;
            return;
        }

        // if the lock window has altered by 1, then unlock the oldest tokens, and move the rest
        else if(lockInfo.lockWindow + 1 == currentLockWindow){
            // update lock window
            accountLockedTokens[account].lockWindow = currentLockWindow;

            // move previous locked tokens to last
            accountLockedTokens[account].lastLockWindowAmount = lockInfo.previousLockWindowAmount;
            
            // move current tokens to previous
            accountLockedTokens[account].previousLockWindowAmount = lockInfo.currentLockWindowAmount;

            // update current locked tokens
            accountLockedTokens[account].currentLockWindowAmount = amount;

            // total count increass by new tokens, decreases by releasing the last lock window tokens
            accountLockedTokens[account].totalLockAmount += amount - lockInfo.lastLockWindowAmount;

            return;
        }

        // if the lock window has altered by 2, then unlock the oldest and previous tokens, and move the rest
        else if(lockInfo.lockWindow + 2 == currentLockWindow){
            // update lock window
            accountLockedTokens[account].lockWindow = currentLockWindow;

            // move current locked tokens to last
            accountLockedTokens[account].lastLockWindowAmount = lockInfo.currentLockWindowAmount;

            // update current locked tokens
            accountLockedTokens[account].currentLockWindowAmount = amount;

            // total count increass by new tokens, decreases by releasing the last lock window tokens and previous tokens
            accountLockedTokens[account].totalLockAmount += amount - lockInfo.lastLockWindowAmount - lockInfo.previousLockWindowAmount;

            return;
        }

        // if the lock window has altered by 3 or more, then unlock all tokens
        else{
            // update lock window
            accountLockedTokens[account].lockWindow = currentLockWindow;

            // move last locked tokens to last
            accountLockedTokens[account].lastLockWindowAmount = 0;

            // move previous locked tokens to last
            accountLockedTokens[account].previousLockWindowAmount = 0;

            // update current locked tokens
            accountLockedTokens[account].currentLockWindowAmount = amount;

            // total count increass by new tokens, decreases by releasing the last lock window tokens and previous tokens
            accountLockedTokens[account].totalLockAmount += amount;

            return;
        }
    }

    /**
     * @notice Get the number of tokens allocated based on revenue
     * @dev The allocation curve determines how many tokens are allocated in total
     * @param amount the revenue to determine the current value
     * @return uint256 the amount of tokens be exchanged
     */
    function _getTotalAllocation(uint256 amount) pure private returns (uint256)
    {
        // get the current token supply based on revenue
        uint256 supply = 20000000000000000000000000 + (980000000000000000000000000 * amount + 10000000000000000000000) / (amount + 5000000000000000000000);
        
        return supply;
    }

    /**
     * @notice Get the equivilent value of revenue paid to be exchanged for new tokens
     * @dev The more tokens are minted, the less marginally you will get next time
     * @param source the source of extraction
     * @param amount the amount to be exchanged
     * @return uint256 the equivilent value to be exchanged
     */
    function _getValueDeduction(address source, uint256 amount) pure private returns (uint256)
    {
        return amount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);

        // _updateLockedTokens(from, 0);
        require(from == address(0) || super.balanceOf(from) - _getLockedTokens(from) >= amount, "AutoMinterERC20: Transfer amount exceeds unlocked token amount");
    }
}