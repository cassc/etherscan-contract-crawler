// SPDX-License-Identifier: UNLICENSED

/**
 * ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗    ██╗      █████╗ ██████╗ ███████╗
 * ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║    ██║     ██╔══██╗██╔══██╗██╔════╝
 * ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║    ██║     ███████║██████╔╝███████╗
 * ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║    ██║     ██╔══██║██╔══██╗╚════██║
 * ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║    ███████╗██║  ██║██████╔╝███████║
 * ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
 *
 * Moon Labs LLC reserves all rights on this code.
 * You may not, except otherwise with prior permission and express written consent by Moon Labs LLC, copy, download, print, extract, exploit,
 * adapt, edit, modify, republish, reproduce, rebroadcast, duplicate, distribute, or publicly display any of the content, information, or material
 * on this smart contract for non-personal or commercial purposes, except for any other use as permitted by the applicable copyright law.
 *
 * This is for ERC20 tokens and should NOT be used for Uniswap LP tokens or ANY other token protocol.
 *
 * Website: https://www.moonlabs.site/
 */

/**
 * @title A token vesting contract for NON-Rebasing ERC20 tokens
 * @author Moon Labs LLC
 * @notice This contract's intended purpose is for token owners to create ERC20 token locks for future or current holders that are immutable by the
 * lock creator. Lock creators may choose to create standard or linear locks. Tokens locked in this contract remain locked until their respective
 * unlock date without ANY exceptions. This contract is not suited to handle rebasing tokens or tokens in which a wallet's supply changes based on
 * total supply.
 */

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IDEXRouter.sol";

interface IMoonLabsReferral {
    function checkIfActive(string calldata code) external view returns (bool);

    function getAddressByCode(
        string memory code
    ) external view returns (address);

    function addRewardsEarned(string calldata code, uint commission) external;
}

interface IMoonLabsWhitelist {
    function getIsWhitelisted(
        address _address,
        bool pair
    ) external view returns (bool);
}

contract MoonLabsVesting is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        address _mlabToken,
        address _feeCollector,
        address referralAddress,
        address whitelistAddress,
        address routerAddress
    ) public initializer {
        __Ownable_init();
        mlabToken = IERC20Upgradeable(_mlabToken);
        feeCollector = _feeCollector;
        referralContract = IMoonLabsReferral(referralAddress);
        whitelistContract = IMoonLabsWhitelist(whitelistAddress);
        routerContract = IDEXRouter(routerAddress);
        ethLockPrice = .005 ether;
        burnThreshold = .25 ether;
        codeDiscount = 10;
        burnPercent = 30;
        percentLockPrice = 30;
        mlabDiscountPercent = 20;
        nonce = 0;
    }

    /*|| === STATE VARIABLES === ||*/
    uint public ethLockPrice; /// Price in WEI for each vesting instance when paying for lock with ETH
    uint public burnThreshold; /// ETH in WEI when mlabToken should be bought and sent to DEAD address
    uint public burnMeter; /// Current ETH in WEI for buying and burning mlabToken
    address public feeCollector; /// Fee collection address for paying with token percent
    uint64 public nonce; /// Unique lock identifier
    uint8 public codeDiscount; /// Discount in the percentage applied to the customer when using referral code, represented in 10s
    uint8 public burnPercent; /// Percent of each transaction sent to burnMeter, represented in 10s
    uint8 public mlabDiscountPercent; /// Percent discount of MLAB pruchases
    uint16 public percentLockPrice; /// Percent of deposited tokens taken for a lock that is paid for using tokens, represented in 10000s
    IERC20Upgradeable public mlabToken; /// Native Moon Labs token
    IDEXRouter public routerContract; /// Uniswap router
    IMoonLabsReferral public referralContract; /// Moon Labs referral contract
    IMoonLabsWhitelist public whitelistContract; /// Moon Labs whitelist contract

    /*|| === STRUCTS VARIABLES === ||*/
    struct VestingInstance {
        address tokenAddress; /// Address of locked token
        address withdrawalAddress; /// Withdrawal address
        uint depositAmount; /// Total deposit amount
        uint withdrawnAmount; /// Total withdrawn amount
        uint64 startDate; /// Date when tokens start to unlock, is Linear lock if !=0.
        uint64 endDate; /// Date when all tokens are fully unlocked
    }

    struct LockParams {
        uint depositAmount;
        uint64 startDate;
        uint64 endDate;
        address withdrawalAddress;
    }

    /*|| === MAPPINGS === ||*/
    mapping(address => uint64[]) private withdrawalToLock; /// Withdrawal address to array of locks
    mapping(address => uint64[]) private tokenToLock; /// Token address to array of locks
    mapping(uint64 => VestingInstance) private vestingInstance; /// Nonce to vesting instance

    /*|| === EVENTS === ||*/
    event LockCreated(
        address creator,
        address token,
        uint64 numOfLocks,
        uint64 nonce
    );
    event TokensWithdrawn(address owner, uint amount, uint64 nonce);
    event LockTransferred(address from, address to, uint64 nonce);
    event TokensBurned(uint amount);

    /*|| === EXTERNAL FUNCTIONS === ||*/
    /**
     * @notice Create one or multiple lock instances for a single token. Fees are in the form of MLAB.
     * @param tokenAddress Contract address of the erc20 token
     * @param locks array of LockParams struct(s) containing:
     *    ownerAddress The address of the owner wallet
     *    withdrawalAddress The address of the withdrawer
     *    depositAmount Number of tokens in the lock instance
     *    startDate Date when tokens start to unlock, is a Linear lock if !=0.
     *    endDate Date when all tokens are fully unlocked
     * @dev Since fees are not paid for in ETH, no ETH is added to the burn meter. This function supports tokens with a transfer tax, although not recommended due to potential customer confusion
     */
    function createLockMLAB(
        address tokenAddress,
        LockParams[] calldata locks
    ) external {
        /// Calculate total deposit
        uint totalDeposited = _calculateTotalDeposited(locks);

        /// Get mlab fee
        _buyWithMLAB(locks.length * ethLockPrice);

        /// Check for adequate supply in sender wallet
        require(
            totalDeposited <=
                IERC20Upgradeable(tokenAddress).balanceOf(msg.sender),
            "Token balance"
        );

        /// Transfer tokens to contract and get amount sent
        uint amountSent = _transferAndCalculate(tokenAddress, totalDeposited);

        /// Create the lock instances
        _createLocks(tokenAddress, locks, amountSent, totalDeposited);

        emit LockCreated(
            msg.sender,
            tokenAddress,
            uint64(locks.length),
            nonce - 1
        );
    }

    /**
     * @notice Create one or multiple vesting instances for a single token. Fees are in the form of % of the token deposited.
     * @param tokenAddress Contract address of the erc20 token
     * @param locks array of LockParams struct(s) containing:
     *    withdrawalAddress The address of the receiving wallet
     *    depositAmount Number of tokens in the vesting instance
     *    startDate Date when tokens start to unlock, is Linear lock if !=0.
     *    endDate Date when all tokens are fully unlocked
     * @dev Since fees are not paid for in ETH, no ETH is added to the burn meter. This function supports tokens with a transfer tax, although not recommended due to potential customer confusion
     */
    function createLockPercent(
        address tokenAddress,
        LockParams[] calldata locks
    ) external {
        /// Calculate total deposit
        uint totalDeposited = _calculateTotalDeposited(locks);

        /// Calculate token fee based off total token deposit
        uint tokenFee = MathUpgradeable.mulDiv(
            totalDeposited,
            percentLockPrice,
            10000
        );

        /// Check for adequate supply in sender wallet
        require(
            (totalDeposited + tokenFee) <=
                IERC20Upgradeable(tokenAddress).balanceOf(msg.sender),
            "Token balance"
        );

        /// Transfer tokens to contract and get amount sent
        uint amountSent = _transferAndCalculateWithFee(
            tokenAddress,
            totalDeposited,
            tokenFee
        );

        _createLocks(tokenAddress, locks, amountSent, totalDeposited);

        /// Transfer token fees to the collector address
        _transferTokensTo(tokenAddress, feeCollector, tokenFee);

        emit LockCreated(
            msg.sender,
            tokenAddress,
            uint64(locks.length),
            nonce - 1
        );
    }

    /**
     * @notice Create one or multiple vesting instances for a single token. If token is whitelisted then can be called with no value. Fees are in ETH.
     * @param tokenAddress Contract address of the erc20 token
     * @param locks array of LockParams struct(s) containing:
     *    withdrawalAddress The address of the receiving wallet
     *    depositAmount Number of tokens in the vesting instance
     *    startDate Date when tokens start to unlock, is Linear lock if !=0.
     *    endDate Date when all tokens are fully unlocked
     * @dev This function supports tokens with a transfer tax, although not recommended due to potential customer confusion
     */
    function createLockEth(
        address tokenAddress,
        LockParams[] calldata locks
    ) external payable {
        /// If not whitelisted then check for correct ETH value
        if (!whitelistContract.getIsWhitelisted(tokenAddress, false)) {
            require(
                msg.value == ethLockPrice * locks.length,
                "Incorrect price"
            );
        } else {
            require(msg.value == 0, "Incorrect price");
        }

        /// Calculate total deposit
        uint totalDeposited = _calculateTotalDeposited(locks);

        /// Check for adequate supply in sender wallet
        require(
            totalDeposited <=
                IERC20Upgradeable(tokenAddress).balanceOf(msg.sender),
            "Token balance"
        );

        /// Transfer tokens to contract and get amount sent
        uint amountSent = _transferAndCalculate(tokenAddress, totalDeposited);

        _createLocks(tokenAddress, locks, amountSent, totalDeposited);

        /// Add to burn amount in ETH to burn meter
        _handleBurns(msg.value);

        emit LockCreated(
            msg.sender,
            tokenAddress,
            uint64(locks.length),
            nonce - 1
        );
    }

    /**
     * @notice Create one or multiple vesting instances for a single token using a referral code. Fees are in ETH.
     * @param tokenAddress Contract address of the erc20 token
     * @param locks array of LockParams struct(s) containing:
     *    withdrawalAddress The address of the receiving wallet
     *    depositAmount Number of tokens in the vesting instance
     *    startDate Date when tokens start to unlock, is Linear lock if !=0.
     *    endDate Date when all tokens are fully unlocked
     * @param code Referral code used for discount
     * @dev This function supports tokens with a transfer tax, although not recommended due to potential customer confusion
     */
    function createLockWithCodeEth(
        address tokenAddress,
        LockParams[] calldata locks,
        string calldata code
    ) external payable {
        /// Check for referral valid code
        require(referralContract.checkIfActive(code), "Invalid code");

        /// Calculate referral commission
        uint commission = (ethLockPrice * codeDiscount * locks.length) / 100;

        /// Check for correct message value
        require(
            msg.value == (ethLockPrice * locks.length - commission),
            "Incorrect price"
        );

        /// Calculate total deposit
        uint totalDeposited = _calculateTotalDeposited(locks);

        /// Check for adequate supply in sender wallet
        require(
            totalDeposited <=
                IERC20Upgradeable(tokenAddress).balanceOf(msg.sender),
            "Token balance"
        );

        /// Transfer tokens to contract and get amount sent
        uint amountSent = _transferAndCalculate(tokenAddress, totalDeposited);

        _createLocks(tokenAddress, locks, amountSent, totalDeposited);

        /// Add to burn amount in ETH to burn meter
        _handleBurns(msg.value);

        /// Distribute commission
        _distributeCommission(code, commission);

        emit LockCreated(
            msg.sender,
            tokenAddress,
            uint64(locks.length),
            nonce - 1
        );
    }

    /**
     * @notice Claim specified number of unlocked tokens. Will delete the lock if all tokens are withdrawn.
     * @param _nonce Vesting instance id of the targeted lock
     * @param amount Number of tokens attempting to be withdrawn
     */
    function withdrawUnlockedTokens(uint64 _nonce, uint amount) external {
        /// Check if the amount attempting to be withdrawn is valid
        require(amount <= getClaimableTokens(_nonce), "Withdraw balance");
        /// Revert 0 withdraw
        require(amount > 0, "Withdrawn min");
        /// Check that sender is the withdraw owner of the lock
        require(
            msg.sender == vestingInstance[_nonce].withdrawalAddress,
            "Ownership"
        );

        /// Increment amount withdrawn by the amount being withdrawn
        vestingInstance[_nonce].withdrawnAmount += amount;

        /// Transfer tokens from the contract to the recipient
        _transferTokensTo(
            vestingInstance[_nonce].tokenAddress,
            msg.sender,
            amount
        );

        /// Delete vesting instance if withdrawn amount reaches deposit amount
        if (
            vestingInstance[_nonce].withdrawnAmount >=
            vestingInstance[_nonce].depositAmount
        ) _deleteVestingInstance(_nonce);

        emit TokensWithdrawn(msg.sender, amount, _nonce);
    }

    /**
     * @notice Transfer withdraw ownership of vesting instance, only callable by withdraw owner
     * @param _nonce ID of desired vesting instance
     * @param _address Address of new withdrawal address
     */
    function transferVestingOwnership(
        uint64 _nonce,
        address _address
    ) external {
        require(_address != address(0), "Zero address");
        /// Check that sender is the withdraw owner of the lock
        require(
            vestingInstance[_nonce].withdrawalAddress == msg.sender,
            "Ownership"
        );
        /// Revert same transfer
        require(_address != msg.sender, "Same transfer");

        /// Delete mapping from the old owner to nonce of vesting instance and pop
        uint64[] storage withdrawArray = withdrawalToLock[msg.sender];
        for (uint64 i = 0; i < withdrawArray.length; i++) {
            if (withdrawArray[i] == _nonce) {
                withdrawArray[i] = withdrawArray[withdrawArray.length - 1];
                withdrawArray.pop();
                break;
            }
        }

        /// Change withdraw owner in vesting instance to the new owner
        vestingInstance[_nonce].withdrawalAddress = _address;

        /// Map nonce of transferred lock to the new owner
        withdrawalToLock[_address].push(_nonce);

        emit LockTransferred(msg.sender, _address, _nonce);
    }

    /**
     * @notice Claim ETH in contract. Owner only function.
     * @dev Excludes eth in the burn meter.
     */
    function claimETH() external onlyOwner {
        require(burnMeter <= address(this).balance, "Negative widthdraw");
        uint amount = address(this).balance - burnMeter;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice Set the fee collection address. Owner only function.
     * @param _feeCollector Address of the fee collector
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "Zero Address");
        feeCollector = _feeCollector;
    }

    /**
     * @notice Set the Uniswap router address. Owner only function.
     * @param _routerAddress Address of uniswap router
     */
    function setRouter(address _routerAddress) external onlyOwner {
        require(_routerAddress != address(0), "Zero Address");
        routerContract = IDEXRouter(_routerAddress);
    }

    /**
     * @notice Set the referral contract address. Owner only function.
     * @param _referralAddress Address of Moon Labs referral address
     */
    function setReferralContract(address _referralAddress) external onlyOwner {
        require(_referralAddress != address(0), "Zero Address");
        referralContract = IMoonLabsReferral(_referralAddress);
    }

    /**
     * @notice Set the whitelist contract address. Owner only function.
     * @param _whitelistAddress Address of Moon Labs whitelist address
     */
    function setWhitelistContract(
        address _whitelistAddress
    ) external onlyOwner {
        require(_whitelistAddress != address(0), "Zero Address");
        whitelistContract = IMoonLabsWhitelist(_whitelistAddress);
    }

    /**
     * @notice Set the burn threshold in WEI. Owner only function.
     * @param _burnThreshold Amount of ETH in WEI
     */
    function setBurnThreshold(uint _burnThreshold) external onlyOwner {
        burnThreshold = _burnThreshold;
    }

    /**
     * @notice Set the price for a single vesting instance in WEI. Owner only function.
     * @param _ethLockPrice Amount of ETH in WEI
     */
    function setLockPrice(uint _ethLockPrice) external onlyOwner {
        ethLockPrice = _ethLockPrice;
    }

    /**
     * @notice Set the percentage of ETH per lock discounted on code use. Owner only function.
     * @param _codeDiscount Percentage represented in 10s
     */
    function setCodeDiscount(uint8 _codeDiscount) external onlyOwner {
        require(_codeDiscount < 100, "Percentage ceiling");
        codeDiscount = _codeDiscount;
    }

    /**
     * @notice Set the Moon Labs native token address. Owner only function.
     * @param _mlabToken native moon labs token
     */
    function setMlabToken(address _mlabToken) external onlyOwner {
        require(_mlabToken != address(0), "Zero Address");
        mlabToken = IERC20Upgradeable(_mlabToken);
    }

    /**
     * @notice Set the percentage of MLAB discounted per lock. Owner only function.
     * @param _mlabDiscountPercent Percentage represented in 10s
     */
    function setMlabDiscountPercent(
        uint8 _mlabDiscountPercent
    ) external onlyOwner {
        require(_mlabDiscountPercent < 100, "Percentage ceiling");
        mlabDiscountPercent = _mlabDiscountPercent;
    }

    /**
     * @notice Set percentage of ETH per lock sent to the burn meter. Owner only function.
     * @param _burnPercent Percentage represented in 10s
     */
    function setBurnPercent(uint8 _burnPercent) external onlyOwner {
        require(_burnPercent <= 100, "Max percent");
        burnPercent = _burnPercent;
    }

    /**
     * @notice Set the percent of deposited tokens taken for a lock that is paid for using tokens. Owner only function.
     * @param _percentLockPrice Percentage represented in 10000s
     */
    function setPercentLockPrice(uint16 _percentLockPrice) external onlyOwner {
        require(_percentLockPrice <= 10000, "Max percent");
        percentLockPrice = _percentLockPrice;
    }

    /**
     * @notice Retrieve an array of vesting IDs tied to a single withdrawal address
     * @param withdrawalAddress address of desired withdraw wallet
     * @return Array of vesting instance IDs
     */
    function getNonceFromWithdrawalAddress(
        address withdrawalAddress
    ) external view returns (uint64[] memory) {
        return withdrawalToLock[withdrawalAddress];
    }

    /**
     * @notice Retrieve an array of vesting IDs tied to a single token address
     * @param tokenAddress token address of desired ERC20 token
     * @return Array of vesting instance IDs
     */
    function getNonceFromTokenAddress(
        address tokenAddress
    ) external view returns (uint64[] memory) {
        return tokenToLock[tokenAddress];
    }

    /**
     * @notice Retrieve information of a single vesting instance
     * @param _nonce ID of desired vesting instance
     * @return token address, withdrawal address, deposit amount, withdrawn amount, start date, end date
     */
    function getInstance(
        uint64 _nonce
    ) external view returns (address, address, uint, uint, uint64, uint64) {
        return (
            vestingInstance[_nonce].tokenAddress,
            vestingInstance[_nonce].withdrawalAddress,
            vestingInstance[_nonce].depositAmount,
            vestingInstance[_nonce].withdrawnAmount,
            vestingInstance[_nonce].startDate,
            vestingInstance[_nonce].endDate
        );
    }

    /*|| === PUBLIC FUNCTIONS === ||*/
    /**
     * @notice Fetches price of mlab to WETH
     * @param amountInEth amount in ether
     */
    function getMLABFee(uint amountInEth) public view returns (uint) {
        ///  Get price quote via uniswap router
        address[] memory path = new address[](2);
        path[0] = routerContract.WETH();
        path[1] = address(mlabToken);
        uint[] memory amountOuts = routerContract.getAmountsOut(
            amountInEth,
            path
        );
        return
            MathUpgradeable.mulDiv(
                amountOuts[1],
                (100 - mlabDiscountPercent),
                100
            );
    }

    /**
     * @notice Retrieve unlocked tokens for a vesting instance
     * @param _nonce ID of desired vesting instance
     * @return Number of unlocked tokens
     */
    function getClaimableTokens(uint64 _nonce) public view returns (uint) {
        uint withdrawnAmount = vestingInstance[_nonce].withdrawnAmount;
        uint depositAmount = vestingInstance[_nonce].depositAmount;
        uint64 endDate = vestingInstance[_nonce].endDate;
        uint64 startDate = vestingInstance[_nonce].startDate;

        /// Check if the token balance is 0
        if (withdrawnAmount >= depositAmount) return 0;

        /// Check if the lock is a normal lock
        if (startDate == 0)
            return
                endDate <= block.timestamp
                    ? depositAmount - withdrawnAmount
                    : 0;

        /// If none of the above then the token is a linear lock
        return _calculateLinearWithdraw(_nonce);
    }

    /*|| === PRIVATE FUNCTIONS === ||*/
    /**
     * @notice Private function purchases with mlab
     */
    function _buyWithMLAB(uint amountInEth) private {
        /// Fee in MLAB
        uint mlabFee = getMLABFee(amountInEth);
        /// Check for adequate supply in sender wallet
        require(mlabFee <= mlabToken.balanceOf(msg.sender), "MLAB balance");

        /// Transfer tokens from sender to fee collector
        mlabToken.safeTransferFrom(msg.sender, feeCollector, mlabFee);
    }

    /**
     * @notice Create single or multiple lock instances, maps nonce to lock instance, token address to nonce, owner address to nonce. Checks for valid
     * start date, end date, and deposit amount.
     * @param tokenAddress ID of desired lock instance
     * @param amountSent actual amount of tokens sent to the smart contract
     * @param totalDeposited hypothetical amount of tokens sent to the smart contract
     * @param locks array of LockParams struct(s) containing:
     *    withdrawalAddress The address of the withdrawer
     *    depositAmount Number of tokens in the lock instance
     *    startDate Date when tokens start to unlock, is a Linear lock if !=0.
     *    endDate Date when all tokens are fully unlocked
     */
    function _createLocks(
        address tokenAddress,
        LockParams[] calldata locks,
        uint amountSent,
        uint totalDeposited
    ) private {
        uint64 _nonce = nonce;
        for (uint64 i = 0; i < locks.length; i++) {
            uint depositAmount = locks[i].depositAmount;
            uint64 startDate = locks[i].startDate;
            uint64 endDate = locks[i].endDate;
            require(startDate < endDate, "Start date");
            require(endDate < 10000000000, "End date");
            require(locks[i].depositAmount > 0, "Min deposit");
            require(locks[i].withdrawalAddress != address(0), "Zero address");

            /// Create a new Lock Instance and map to nonce
            vestingInstance[_nonce] = VestingInstance(
                tokenAddress,
                locks[i].withdrawalAddress,
                MathUpgradeable.mulDiv(
                    amountSent,
                    depositAmount,
                    totalDeposited
                ),
                0,
                startDate,
                endDate
            );
            /// Map token address to nonce
            tokenToLock[tokenAddress].push(_nonce);
            /// Map withdrawal address to nonce
            withdrawalToLock[locks[i].withdrawalAddress].push(_nonce);

            /// Increment nonce
            _nonce++;
        }
        nonce = _nonce;
    }

    /**
     * @notice claculates total deposit of given lock array
     * @param locks array of LockParams struct(s) containing:
     *    withdrawalAddress The address of the receiving wallet
     *    depositAmount Number of tokens in the vesting instance
     *    startDate Date when tokens start to unlock, is Linear lock if !=0.
     *    endDate Date when all tokens are fully unlocked
     * @return total deposit amount
     */
    function _calculateTotalDeposited(
        LockParams[] memory locks
    ) private pure returns (uint) {
        uint totalDeposited;
        for (uint32 i = 0; i < locks.length; i++) {
            totalDeposited += locks[i].depositAmount;
        }
        return totalDeposited;
    }

    /**
     * @notice transfers tokens to contract and calcualtes amount sent
     * @param tokenAddress address of the token
     * @param amount total tokens attempting to be sent
     * @return total amount sent
     */
    function _transferAndCalculate(
        address tokenAddress,
        uint amount
    ) private returns (uint) {
        /// Get balance before sending tokens
        uint previousBal = IERC20Upgradeable(tokenAddress).balanceOf(
            address(this)
        );

        /// Transfer tokens from sender to contract
        _transferTokensFrom(tokenAddress, msg.sender, amount);

        /// Calculate amount sent based off before and after balance
        return
            IERC20Upgradeable(tokenAddress).balanceOf(address(this)) -
            previousBal;
    }

    /**
     * @notice transfers tokens to contract and calcualtes amount sent with fees
     * @param tokenAddress address of the token
     * @param amount total tokens attempting to be sent
     * @param tokenFee fee taken for locking
     * @return total amount sent
     */
    function _transferAndCalculateWithFee(
        address tokenAddress,
        uint amount,
        uint tokenFee
    ) private returns (uint) {
        /// Get balance before sending tokens
        uint previousBal = IERC20Upgradeable(tokenAddress).balanceOf(
            address(this)
        );

        /// Transfer tokens from sender to contract
        _transferTokensFrom(tokenAddress, msg.sender, amount + tokenFee);

        /// Transfer token fees to the collector address
        _transferTokensTo(tokenAddress, feeCollector, tokenFee);

        /// Calculate amount sent based off before and after balance
        return
            IERC20Upgradeable(tokenAddress).balanceOf(address(this)) -
            previousBal;
    }

    /**
     * @dev Transfer tokens from address to this contract. Used for abstraction and readability.
     * @param tokenAddress token address of ERC20 to be transferred
     * @param from the address of wallet transferring the token
     * @param amount number of tokens being transferred
     */
    function _transferTokensFrom(
        address tokenAddress,
        address from,
        uint amount
    ) private {
        IERC20Upgradeable(tokenAddress).safeTransferFrom(
            from,
            address(this),
            amount
        );
    }

    /**
     * @dev Transfer tokens from this contract to an address. Used for abstraction and readability.
     * @param tokenAddress token address of ERC20 to be transferred
     * @param to address of wallet receiving the token
     * @param amount number of tokens being transferred
     */
    function _transferTokensTo(
        address tokenAddress,
        address to,
        uint amount
    ) private {
        IERC20Upgradeable(tokenAddress).safeTransfer(to, amount);
    }

    /**
     * @notice Delete a vesting instance and the mappings belonging to it.
     * @param _nonce ID of desired vesting instance
     */
    function _deleteVestingInstance(uint64 _nonce) private {
        /// Delete mapping from the withdraw owner to nonce of vesting instance and pop
        uint64[] storage withdrawArray = withdrawalToLock[msg.sender];
        for (uint64 i = 0; i < withdrawArray.length; i++) {
            if (withdrawArray[i] == _nonce) {
                withdrawArray[i] = withdrawArray[withdrawArray.length - 1];
                withdrawArray.pop();
                break;
            }
        }

        /// Delete mapping from the token address to nonce of vesting instance and pop
        uint64[] storage tokenAddress = tokenToLock[
            vestingInstance[_nonce].tokenAddress
        ];
        for (uint64 i = 0; i < tokenAddress.length; i++) {
            if (tokenAddress[i] == _nonce) {
                tokenAddress[i] = tokenAddress[tokenAddress.length - 1];
                tokenAddress.pop();
                break;
            }
        }
        /// Delete vesting instance map
        delete vestingInstance[_nonce];
    }

    /**
     * @notice Distribute ETH to the owner of the referral code
     * @param code referral code
     * @param commission amount of eth to send to referral code owner
     */
    function _distributeCommission(
        string memory code,
        uint commission
    ) private nonReentrant {
        /// Get referral code owner
        address payable to = payable(referralContract.getAddressByCode(code));
        /// Send ether to code owner
        (bool sent, ) = to.call{value: commission}("");
        if (sent) {
            /// Log rewards in the referral contract
            referralContract.addRewardsEarned(code, commission);
        }
    }

    /**
     * @notice Buy Moon Labs native token if burn threshold is met or crossed and send to the dead address
     * @param value amount added to burn meter
     */
    function _handleBurns(uint value) private {
        burnMeter += MathUpgradeable.mulDiv(value, burnPercent, 100);
        /// Check if the threshold is met
        if (burnMeter >= burnThreshold) {
            /// Buy mlabToken via Uniswap router and send to the dead address
            address[] memory path = new address[](2);
            path[0] = routerContract.WETH();
            path[1] = address(mlabToken);
            uint[] memory amounts = routerContract.swapExactETHForTokens{
                value: burnMeter
            }(
                0,
                path,
                0x000000000000000000000000000000000000dEaD,
                block.timestamp
            );
            /// Reset burn meter
            burnMeter = 0;
            emit TokensBurned(amounts[amounts.length - 1]);
        }
    }

    /**
     * @notice Calculate the number of unlocked tokens within a linear lock.
     * @param _nonce ID of desired vesting instance
     * @return unlockedTokens number of unlocked tokens
     */
    function _calculateLinearWithdraw(
        uint64 _nonce
    ) private view returns (uint) {
        uint withdrawnAmount = vestingInstance[_nonce].withdrawnAmount;
        uint depositAmount = vestingInstance[_nonce].depositAmount;
        uint64 endDate = vestingInstance[_nonce].endDate;
        uint64 startDate = vestingInstance[_nonce].startDate;
        uint64 timeBlock = endDate - startDate; /// Time from start date to end date
        uint64 timeElapsed = 0; // Time since tokens started to unlock

        if (endDate <= block.timestamp) {
            /// Set time elapsed to time block
            timeElapsed = timeBlock;
        } else if (startDate < block.timestamp) {
            /// Set time elapsed to the time elapsed
            timeElapsed = uint64(block.timestamp) - startDate;
        }

        /// Math to calculate linear unlock
        /**
    This formula will only return a negative number when the current amount is less than what can be withdrawn

      Deposit Amount x Time Elapsed
      -----------------------------   -   (Withdrawn Amount)
               Time Block
    **/
        return
            MathUpgradeable.mulDiv(depositAmount, timeElapsed, timeBlock) -
            (withdrawnAmount);
    }
}