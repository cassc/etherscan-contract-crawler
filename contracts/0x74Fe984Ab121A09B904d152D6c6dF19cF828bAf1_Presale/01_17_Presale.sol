// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./JoyToken.sol";
import "./xJoyToken.sol";
import "./interfaces/IUSDT.sol";

import "./interfaces/IUniswapV2Pair.sol";
import "./libraries/UniswapV2Library.sol";

error SALE_NOT_LIVE();
error STILL_VESTING();
error WRONG_VESTING_TYPE();
error NOTHING_TO_WITHDRAW();
error COINS_NOT_SET();
error ONLY_OWNER();
error WRONG_ADDRESS();
error PAIR_NOT_SET();
error MIN_ONE_CENT();

contract Presale is AccessControl {
    /**
     * VESTING TYPES
     * Initialy there will be 5 vesting levels defined by the constructor
     * 0 - SEED
     * 1 - PRESALE
     * 2 - TEAM
     * 3 - PARTNERS
     * 4 - STAR
     *
     * It's not becoming an enum to allow users to set different vesting  level after the release
     */

    struct VestingInfo {
        uint256 releasePercentBasisPoints; // Release percent basis points (1% = 100, 100% = 10000)
        uint256 cliff; // Cliff for release start time
        uint256 releaseStep; // How often percent step is applied
        uint256 vestingCloseTimeline; // How much time has to pass to finish vesting
    }

    struct DepositInfo {
        uint256 vestingType; // Tier of the type of vesting
        uint256 depositedAmount; // How many Coins amount the user has deposited.
        uint256 purchasedAmount; // How many JOY tokens the user has purchased.
        uint256 depositTime; // Deposited time
    }

    struct PurchaserInfo {
        uint256 firstDepositTime; // When user made his first deposit
        uint256 firstUnlockTime; // Timestamp when unlock will start
        uint256 vestingTimeFinish; // Timestamp when vesting for the purchaser will be closed
        uint256 withdrawnAmount; // Amount of JOY tokens already withdrawn by the purchaser
        DepositInfo[] deposits; // List of all deposits of the purchaser
    }

    JoyToken public joyToken;
    XJoyToken public xJoyToken;

    VestingInfo[] public vestingList;
    uint256 public currentVestingType;
    uint256 public totalPurchasers;
    address public treasuryAddress;
    address public USDC_Address = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public USDT_Address = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public owner;
    bool public sale;

    mapping(uint256 => address) public purchaserAddress;
    mapping(address => PurchaserInfo) public purchaserList;

    event TokensPurchased(address indexed purchaser, uint256 coinAmount, uint256 tokenAmount);
    event TokensWithdrawn(address indexed purchaser, uint256 tokenAmount);
    event VestingTypeAdded(uint256 indexed level);
    event VestingTypeChanged(uint256 indexed level);

    modifier onSale() {
        if (!sale) revert SALE_NOT_LIVE();
        _;
    }

    modifier notVested(address userAddr) {
        if (!checkVestingPeriod(userAddr)) revert STILL_VESTING();
        _;
    }

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyOwner() {
        if (owner != _msgSender()) revert ONLY_OWNER();
        _;
    }

    constructor(
        JoyToken _joyToken,
        XJoyToken _xJoyToken,
        VestingInfo[] memory _vestingInfo,
        uint256 _initialVestingType,
        address _treasuryAddress
    ) {
        joyToken = _joyToken;
        xJoyToken = _xJoyToken;
        treasuryAddress = _treasuryAddress;
        owner = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i; i < _vestingInfo.length;) {
            vestingList.push(_vestingInfo[i]);
            unchecked {
                i++;
            }
        }

        currentVestingType = _initialVestingType;
        startSale(false);
    }

    /**
     * Adding new admin to the contract
     * @param _admin - New admin to be added to administrator list
     */
    function addAdmin(address _admin) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * Removing admin from token administrators list
     * @param _admin - Admin to be removed from admin list
     */
    function removeAdmin(address _admin) external onlyAdmin {
        if (_admin == owner) revert ONLY_OWNER();
        _revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * Team Multisig Safe Vault
     * @param _newOwner - Contract owner address
     */
    function changeOwnership(address _newOwner) public onlyOwner {
        if (owner == _newOwner || _newOwner == address(0)) revert WRONG_ADDRESS();
        _revokeRole(DEFAULT_ADMIN_ROLE, owner);
        owner = _newOwner;
        _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
    }

    /**
     * Update Treasury
     * @param _treasuryAddress - New treasury multisig
     */
    function updateTreasury(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    /**
     * Start (or stop) the sale from happening
     * @param _start - Flag if sale should be started.
     */
    function startSale(bool _start) public onlyAdmin {
        sale = _start;
    }

    /**
     * Checks if given address has finished vesting.
     * @param _address - Address of the account being checked
     * @return True if given address is still locked. False otherwise.
     */
    function isLocked(address _address) public view returns (bool) {
        return block.timestamp < purchaserList[_address].vestingTimeFinish;
    }

    /**
     * Checks if given address is still being vested.
     * @param _address - Address of the account being checked.
     * @return True if given account is being vested anymore. False otherwise.
     */
    function checkVestingPeriod(address _address) public view returns (bool) {
        return block.timestamp > purchaserList[_address].firstUnlockTime;
    }

    /**
     * Adding new vesting type for vesting list.
     *
     * @param _vestingType - Struct defining new vesting level
     */

    function addVestingType(VestingInfo memory _vestingType) external onlyAdmin {
        uint256 index = vestingList.length;

        vestingList.push(_vestingType);

        emit VestingTypeAdded(index);
    }

    /**
     * Change vesting type.
     *
     * Switching vesting type to new level.
     * ATTENTION!: Vesting type can be only moved FORWARD so no going back to previous vestings
     *
     * @param _vestingType - Index of vesting to be switched to
     */
    function switchVesting(uint256 _vestingType) external onlyAdmin {
        if (_vestingType >= vestingList.length || _vestingType <= currentVestingType) {
            revert WRONG_VESTING_TYPE();
        }

        currentVestingType = _vestingType;
        emit VestingTypeChanged(_vestingType);
    }

    /**
     * Sets purchase and vesting information of given purchaser.
     *
     * Addresses added to this list will be blacklisted from moving XJoy tokens.
     * This is done to block trading these and use them only as a vesting token to retrieve Joy tokens after vesting period.
     * This contract will be listed as whitelisted contract to move tokens back at the end of the vesting season.
     * @param _addr - Address matched to information being set
     * @param _vestingIndex - Index of a vested address
     * @param _depositedTime - Timestamp of the deposit
     * @param _purchasedAmount - Amount of tokens purchased
     * @param _withdrawnAmount - Amount of tokens already withdrawn by the user
     */
    function addPurchase(
        address _addr,
        uint256 _vestingIndex,
        uint256 _depositedTime,
        uint256 _depositedAmount,
        uint256 _purchasedAmount,
        uint256 _withdrawnAmount
    ) external onlyAdmin {
        internalAddPurchase(_addr, _vestingIndex, _depositedTime, _depositedAmount, _purchasedAmount, _withdrawnAmount);
    }

    /**
     * Deliver vested tokens to list of users
     * @param _purchaserAddress - Addresses that should be vested
     * @param _purchaserList  - List of purchasers
     * @param _transferToken - Should addresses receive tokens on top of being marked as vested
     */
    function addPurchasers(address[] memory _purchaserAddress, DepositInfo[] memory _purchaserList, bool _transferToken)
        public
        onlyAdmin
    {
        for (uint256 i; i < _purchaserAddress.length;) {
            addPurchaser(
                _purchaserAddress[i],
                _purchaserList[i].vestingType,
                _purchaserList[i].depositTime,
                _purchaserList[i].depositedAmount,
                _purchaserList[i].purchasedAmount,
                _transferToken
            );
            unchecked {
                i++;
            }
        }
    }

    /**
     * Add purchaser vesting schedule
     * @param _purchaserAddr - Address of the user to be vested
     * @param _vestingIndex - Index of the vested user
     * @param _depositedTime - Time of the deposit
     * @param _depositedAmount - Amount of the deposit
     * @param _purchasedAmount - Amount of tokens purchased
     * @param _transferToken - Should tokens be transfered
     */
    function addPurchaser(
        address _purchaserAddr,
        uint256 _vestingIndex,
        uint256 _depositedTime,
        uint256 _depositedAmount,
        uint256 _purchasedAmount,
        bool _transferToken
    ) public onlyAdmin {
        internalAddPurchase(_purchaserAddr, _vestingIndex, _depositedTime, _depositedAmount, _purchasedAmount, 0);
        if (_transferToken) {
            xJoyToken.transfer(_purchaserAddr, _purchasedAmount);
        }
    }

    /**
     * Lists all deposit history for given user
     * @param _address - purchaser to get deposit history of
     * @return An array of all deposit structures for given purchaser
     */
    function depositHistory(address _address) external view returns (DepositInfo[] memory) {
        return purchaserList[_address].deposits;
    }

    /**
     * Depositing a coin for xJoy token.
     * @param _coinAmount - Amount of tokens being deposited
     * @param _coinIndex  - Index of the coin in contracts list
     */
    function deposit(uint256 _coinAmount, uint256 _coinIndex) external onSale {
        internalDeposit(_msgSender(), _coinAmount, _coinIndex, currentVestingType, block.timestamp);
    }

    /**
     * Withdrawing Joy tokens after vesting.
     * Amounts are automatically calculated based on current vesting plan and time.
     */
    function withdraw() external notVested(_msgSender()) {
        uint256 withdrawalAmount = calcWithdrawalAmount(_msgSender());
        uint256 xJoyTokenAmount = xJoyToken.balanceOf(address(_msgSender()));
        uint256 withdrawAmount = withdrawalAmount;

        if (withdrawAmount > xJoyTokenAmount) {
            withdrawAmount = xJoyTokenAmount;
        }

        if (withdrawAmount <= 0) revert NOTHING_TO_WITHDRAW();

        xJoyToken.transferFrom(_msgSender(), address(this), withdrawAmount);
        joyToken.transfer(_msgSender(), withdrawAmount);

        purchaserList[_msgSender()].withdrawnAmount += withdrawAmount;

        emit TokensWithdrawn(_msgSender(), withdrawAmount);
    }

    /**
     * Checks withdrawal limit for the address
     * @param _userAddr - Address that is checked for current limit
     * @return The amount of tokens address can currently withdraw
     */
    function calcWithdrawalAmount(address _userAddr) public view returns (uint256) {
        PurchaserInfo storage purchaserInfo = purchaserList[_userAddr];

        uint256 allowedAmount = 0;
        for (uint256 i = 0; i < purchaserInfo.deposits.length;) {
            DepositInfo storage theDeposit = purchaserInfo.deposits[i];
            VestingInfo storage vesting = vestingList[theDeposit.vestingType];
            uint256 cliff = theDeposit.depositTime + vesting.cliff;
            if (block.timestamp > cliff) {
                if (block.timestamp > cliff + vesting.vestingCloseTimeline) {
                    allowedAmount += theDeposit.purchasedAmount;
                } else {
                    uint256 stepSize = (theDeposit.purchasedAmount * vesting.releasePercentBasisPoints) / 100000;
                    uint256 stepsElapsed = (block.timestamp - cliff) / vesting.releaseStep + 1;
                    uint256 value = stepsElapsed * stepSize;
                    if (value > theDeposit.purchasedAmount) {
                        value = theDeposit.purchasedAmount;
                    }
                    allowedAmount += value;
                }
            }
            unchecked {
                i++;
            }
        }

        return allowedAmount - purchaserInfo.withdrawnAmount;
    }

    /**
     * Withdraws all coins transfered as deposits to owner.
     * @param _treasury - Treasury address to move all coins to.
     */
    function withdrawAllCoins(address _treasury) public onlyOwner {
        IERC20Metadata USDC = IERC20Metadata(USDC_Address);
        IUSDT USDT = IUSDT(USDT_Address);
        uint256 usdcAmount = USDC.balanceOf(address(this));
        uint256 usdtAmount = USDT.balanceOf(address(this));
        if (usdcAmount > 0) USDC.transfer(_treasury, usdcAmount);
        if (usdtAmount > 0) USDT.transfer(_treasury, usdtAmount);
    }

    /**
     * Withdraws all XJoy tokens to owner.
     * @param _treasury - Treasury address that should receive all xJoy tokens.
     */
    function withdrawAllxJoyTokens(address _treasury) public onlyOwner {
        uint256 tokenAmount = xJoyToken.balanceOf(address(this));
        xJoyToken.transfer(_treasury, tokenAmount);
    }

    /**
     * Withdraws all Joy tokens to owner.
     * @param _treasury - Treasury address that should receive all Joy tokens.
     */
    function withdrawAllJoyTokens(address _treasury) public onlyOwner {
        uint256 tokenAmount = joyToken.balanceOf(address(this));
        joyToken.transfer(_treasury, tokenAmount);
    }

    /**
     * Performs real deposit in the contract.
     * @param _address - An address of the depositor
     * @param _coinAmount - Amount of coins being deposited
     * @param _coinIndex - Index of the coin being deposited
     * @param _vestingIndex - Index of the vesting
     * @param _depositTime - Time when deposit took place
     */
    function internalDeposit(
        address _address,
        uint256 _coinAmount,
        uint256 _coinIndex,
        uint256 _vestingIndex,
        uint256 _depositTime
    ) internal {
        if (_vestingIndex >= vestingList.length) {
            revert WRONG_VESTING_TYPE();
        }
        if (_coinIndex > 1) revert COINS_NOT_SET();

        if (_coinIndex == 0) {
            IERC20Metadata USDC = IERC20Metadata(USDC_Address);
            USDC.transferFrom(_address, treasuryAddress, _coinAmount);
        } else if (_coinIndex == 1) {
            IUSDT USDT = IUSDT(USDT_Address);
            USDT.transferFrom(_address, treasuryAddress, _coinAmount);
        }

        uint256 joyAmountStar = pairInfo(_coinAmount);
        xJoyToken.transfer(_address, joyAmountStar);

        internalAddPurchase(_address, _vestingIndex, _depositTime, _coinAmount, joyAmountStar, 0);
        emit TokensPurchased(_address, _coinAmount, joyAmountStar);
    }

    function internalAddPurchase(
        address _addr,
        uint256 _vestingIndex,
        uint256 _depositedTime,
        uint256 _depositedAmount,
        uint256 _purchasedAmount,
        uint256 _withdrawnAmount
    ) internal {
        if (_vestingIndex >= vestingList.length) {
            revert WRONG_VESTING_TYPE();
        }
        PurchaserInfo storage purchaserInfo = purchaserList[_addr];
        if (purchaserInfo.firstDepositTime == 0) {
            purchaserInfo.firstDepositTime = _depositedTime;
            purchaserAddress[totalPurchasers] = _addr;
            totalPurchasers += 1;
            xJoyToken.addToBlacklist(_addr);
        }

        // Get information about this vesting type
        VestingInfo storage vInfo = vestingList[uint256(_vestingIndex)];

        // calculate when vesting will finish
        uint256 vestingFinish = _depositedTime + vInfo.cliff + vInfo.vestingCloseTimeline;
        if (purchaserInfo.vestingTimeFinish < vestingFinish) {
            purchaserInfo.vestingTimeFinish = vestingFinish;
        }

        // Calculate new vestings cliff date
        uint256 unlockTime = _depositedTime + vInfo.cliff;
        if (purchaserInfo.firstUnlockTime > unlockTime || purchaserInfo.firstUnlockTime == 0) {
            purchaserInfo.firstUnlockTime = unlockTime;
        }

        // Update global amount of withdrawn amount by purchaser
        purchaserInfo.withdrawnAmount += _withdrawnAmount;

        // Last but not least - we need to add history of purchase
        purchaserInfo.deposits.push(DepositInfo(_vestingIndex, _depositedAmount, _purchasedAmount, _depositedTime));
    }

    function pairInfo(uint256 _joyAmount) public view returns (uint256 joyAmountStar) {
        if (_joyAmount < 1e4) revert MIN_ONE_CENT();
        address FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(FACTORY_ADDRESS, address(joyToken), USDC_Address));
        if (address(pair) == address(0)) revert PAIR_NOT_SET();
        (uint256 reserves0, uint256 reserves1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) =
            USDC_Address == pair.token0() ? (reserves1, reserves0) : (reserves0, reserves1);
        uint256 numerator = 1e6 * reserveA; // Joy Reserve
        uint256 denominator = reserveB; // USDC Reserve
        uint256 amountOutCents = (numerator / denominator) / 1e2; // 1 cent of USDC
        uint256 joyAmountInJoy = _joyAmount / 1e4; // 1 cent of JOY
        uint256 joyAmountInCalcInCents = joyAmountInJoy * amountOutCents; // Total Joy in cents
        joyAmountStar = joyAmountInCalcInCents + ((joyAmountInCalcInCents / 100) * 55); // 55% Discount
    }
}