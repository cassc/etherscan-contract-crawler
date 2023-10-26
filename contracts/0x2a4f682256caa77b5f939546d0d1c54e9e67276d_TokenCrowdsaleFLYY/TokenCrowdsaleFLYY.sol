/**
 *Submitted for verification at Etherscan.io on 2023-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ITetherToken {
    function transfer(address _to, uint _value) external;

    function transferFrom(address _from, address _to, uint _value) external;

    function balanceOf(address who) external returns (uint);

    function allowance(
        address _owner,
        address _spender
    ) external returns (uint);
}

interface ITokenVestingFLYY {
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _amount
    ) external;
}

contract TokenCrowdsaleFLYY is Ownable, ReentrancyGuard {
    IERC20 public tokenContractAddressFLYY;
    ITetherToken public tokenContractAddressUSDT;
    uint256 public tokenPriceInWEI;
    uint256 public tokenPriceInUSDT;
    uint8 private _tokenDecimals;

    uint256 private _lowerPurchasingLimitInWEI;
    uint256 private _upperPurchasingLimitInWEI;
    uint256 private _lowerPurchasingLimitInUSDT;
    uint256 private _upperPurchasingLimitInUSDT;

    ITokenVestingFLYY public vestingContractAddress;
    uint8 private _unlockedPercentageTGE;
    uint256 private _vestingStart;
    uint256 private _vestingCliff;
    uint256 private _vestingDuration;
    uint256 private _vestingSlicePeriodSeconds;

    uint256 public claimStartTimeTGE;
    mapping(address => uint256) public userBalanceOfTGE;
    mapping(address => uint256) public userClaimStartTimeTGE;

    bool public whitelistingSwitch;
    mapping(address => bool) private _isIncludedInWhitelist;

    uint256 public totalPurchasingLimitTokenCount;
    mapping(address => uint256) private _tokensPurchased;
    uint256 public totalTokenSold;

    event TokenSold(address, uint256);
    event PriceChangedInETH(uint256, uint256);
    event PriceChangedInUSDT(uint256, uint256);
    event VestingScheduleChanged(uint8, uint256, uint256, uint256, uint256);
    event WhitelistingSwitchTriggered(bool flag);

    modifier checkWhitelisting(address caller) {
        require(
            (!whitelistingSwitch || _isIncludedInWhitelist[caller]),
            "TokenCrowdsaleFLYY: calling account address must be whitelisted first OR switch off whitelisting feature"
        );
        _;
    }

    constructor() {
        tokenContractAddressUSDT = ITetherToken(
            0xdAC17F958D2ee523a2206206994597C13D831ec7
        );
        tokenPriceInUSDT = 9000;

        tokenContractAddressFLYY = IERC20(
            0xdEF36a0653D4992c3614362553C446ce41488a46
        );
        tokenPriceInWEI = 5500000000000;
        _tokenDecimals = 18;

        vestingContractAddress = ITokenVestingFLYY(
            0xDbD185b1dF18c4a69795041B4De4B5154957E6fF
        );
        _unlockedPercentageTGE = 5;
        claimStartTimeTGE = 1695571200;
        _vestingStart = 1695571200;
        _vestingCliff = 2629743;
        _vestingDuration = 15778458;
        _vestingSlicePeriodSeconds = 86400;

        whitelistingSwitch = false;

        _lowerPurchasingLimitInWEI = 30446000000000000;
        _upperPurchasingLimitInWEI = 9133681000000000000;
        _lowerPurchasingLimitInUSDT = 0;
        _upperPurchasingLimitInUSDT = 15000000000;

        totalPurchasingLimitTokenCount = 3333333000000000000000000;
    }

    function changeClaimStartTimeTGE(
        uint256 _claimStartTimeTGE
    ) external onlyOwner returns (bool) {
        claimStartTimeTGE = _claimStartTimeTGE;

        return true;
    }

    function changeVestingContractAddress(
        address newContractAddress
    ) external onlyOwner returns (bool) {
        vestingContractAddress = ITokenVestingFLYY(newContractAddress);

        return true;
    }

    function changetokenContractAddressFLYY(
        address newContractAddress
    ) external onlyOwner returns (bool) {
        tokenContractAddressFLYY = IERC20(newContractAddress);

        return true;
    }

    function changeTokenPriceInETH(
        uint256 newPrice
    ) external onlyOwner returns (bool) {
        require(
            newPrice > 0,
            "TokenCrowdsaleFLYY: token price must be greater than 0 WEI"
        );

        uint256 oldPrice = tokenPriceInWEI;
        tokenPriceInWEI = newPrice;

        emit PriceChangedInETH(oldPrice, newPrice);
        return true;
    }

    function changeTokenPriceInUSDT(
        uint256 newPrice
    ) external onlyOwner returns (bool) {
        require(
            newPrice > 0,
            "TokenCrowdsaleFLYY: token price must be greater than 0 USDT"
        );

        uint256 oldPrice = tokenPriceInUSDT;
        tokenPriceInUSDT = newPrice;

        emit PriceChangedInUSDT(oldPrice, newPrice);
        return true;
    }

    function getLowerAndUpperPurchasingLimitInETH()
        external
        view
        returns (uint256, uint256)
    {
        return (_lowerPurchasingLimitInWEI, _upperPurchasingLimitInWEI);
    }

    function getLowerAndUpperPurchasingLimitInUSDT()
        external
        view
        returns (uint256, uint256)
    {
        return (_lowerPurchasingLimitInUSDT, _upperPurchasingLimitInUSDT);
    }

    function setLowerAndUpperPurchasingLimitInETH(
        uint256 newLowerLimitInWEI,
        uint256 newUpperLimitInWEI
    ) external onlyOwner returns (bool) {
        _lowerPurchasingLimitInWEI = newLowerLimitInWEI;
        _upperPurchasingLimitInWEI = newUpperLimitInWEI;

        return true;
    }

    function setLowerAndUpperPurchasingLimitInUSDT(
        uint256 newLowerLimitInUSDT,
        uint256 newUpperLimitInUSDT
    ) external onlyOwner returns (bool) {
        _lowerPurchasingLimitInUSDT = newLowerLimitInUSDT;
        _upperPurchasingLimitInUSDT = newUpperLimitInUSDT;

        return true;
    }

    function tokensPurchased(
        address accountAddress
    ) external view returns (uint256) {
        return _tokensPurchased[accountAddress];
    }

    function setTotalPurchasingLimitTokenCount(
        uint256 newLimit
    ) external onlyOwner returns (bool) {
        totalPurchasingLimitTokenCount = newLimit;

        return true;
    }

    function resetTokensPurchasedForAccount(
        address accountAddress
    ) external onlyOwner returns (bool) {
        _tokensPurchased[accountAddress] = 0;

        return true;
    }

    function resetTotalTokensSold() external onlyOwner returns (bool) {
        totalTokenSold = 0;

        return true;
    }

    function changeVestingSchedule(
        uint8 unlockedPercentageTGE_,
        uint256 vestingStart_,
        uint256 vestingCliff_,
        uint256 vestingDuration_,
        uint256 vestingSlicePeriodSeconds_
    ) external onlyOwner returns (bool) {
        require(
            unlockedPercentageTGE_ <= 100,
            "TokenCrowdsaleFLYY: unlocked TGE percentage must not be greater than 100"
        );

        _unlockedPercentageTGE = unlockedPercentageTGE_;
        _vestingStart = vestingStart_;
        _vestingCliff = vestingCliff_;
        _vestingDuration = vestingDuration_;
        _vestingSlicePeriodSeconds = vestingSlicePeriodSeconds_;

        emit VestingScheduleChanged(
            unlockedPercentageTGE_,
            vestingStart_,
            vestingCliff_,
            vestingDuration_,
            vestingSlicePeriodSeconds_
        );
        return true;
    }

    function getVestingSchedule()
        external
        view
        returns (uint8, uint256, uint256, uint256, uint256)
    {
        return (
            _unlockedPercentageTGE,
            _vestingStart,
            _vestingCliff,
            _vestingDuration,
            _vestingSlicePeriodSeconds
        );
    }

    function buyTokenInETH()
        external
        payable
        nonReentrant
        checkWhitelisting(msg.sender)
        returns (bool)
    {
        _buyTokenInETH();

        return true;
    }

    function buyTokenInUSDT()
        external
        nonReentrant
        checkWhitelisting(msg.sender)
        returns (bool)
    {
        _buyTokenInUSDT();

        return true;
    }

    function _buyTokenInETH() private {
        uint256 sentValue = msg.value;
        require(
            sentValue > 0,
            "TokenCrowdsaleFLYY: sent ETH amount must be greater than 0"
        );
        require(
            (sentValue >= _lowerPurchasingLimitInWEI &&
                sentValue <= _upperPurchasingLimitInWEI),
            "TokenCrowdsaleFLYY: sent ETH amount must be between purchasing limit"
        );

        address buyer = _msgSender();
        uint256 contractTokenBalance = getContractBalanceFLYY();
        uint256 buyableTokens = _buyableTokensInETH();

        require(
            (_tokensPurchased[buyer] + buyableTokens) <=
                totalPurchasingLimitTokenCount,
            "TokenCrowdsaleFLYY: buyable token amount exceeds total purchasing limit for single wallet"
        );
        require(
            contractTokenBalance >= buyableTokens,
            "TokenCrowdsaleFLYY: buyable token amount exceeds crowdsale contract balance"
        );

        uint256 unlockedShareTGE = (buyableTokens * _unlockedPercentageTGE) /
            100;
        uint256 vestingShare = buyableTokens - unlockedShareTGE;

        if (unlockedShareTGE > 0) {
            userBalanceOfTGE[buyer] += unlockedShareTGE;
            userClaimStartTimeTGE[buyer] = claimStartTimeTGE;
        }

        if (vestingShare > 0) {
            _sendToVesting(buyer, vestingShare);
        }
        _tokensPurchased[buyer] += buyableTokens;
        totalTokenSold += buyableTokens;

        emit TokenSold(buyer, buyableTokens);
    }

    function _buyTokenInUSDT() private {
        uint256 sentValue = tokenContractAddressUSDT.allowance(
            _msgSender(),
            address(this)
        );
        require(
            sentValue > 0,
            "TokenCrowdsaleFLYY: approve token USDT to crowdsale contract"
        );
        require(
            (sentValue >= _lowerPurchasingLimitInUSDT &&
                sentValue <= _upperPurchasingLimitInUSDT),
            "TokenCrowdsaleFLYY: sent ETH amount must be between purchasing limit"
        );

        address buyer = _msgSender();
        uint256 contractTokenBalance = getContractBalanceFLYY();
        uint256 buyableTokens = _buyableTokensInUSDT();

        require(
            (_tokensPurchased[buyer] + buyableTokens) <=
                totalPurchasingLimitTokenCount,
            "TokenCrowdsaleFLYY: buyable token amount exceeds total purchasing limit for single wallet"
        );
        require(
            contractTokenBalance >= buyableTokens,
            "TokenCrowdsaleFLYY: buyable token amount exceeds crowdsale contract balance"
        );
        tokenContractAddressUSDT.transferFrom(
            _msgSender(),
            address(this),
            sentValue
        );

        uint256 unlockedShareTGE = (buyableTokens * _unlockedPercentageTGE) /
            100;
        uint256 vestingShare = buyableTokens - unlockedShareTGE;

        if (unlockedShareTGE > 0) {
            userBalanceOfTGE[buyer] += unlockedShareTGE;
            userClaimStartTimeTGE[buyer] = claimStartTimeTGE;
        }

        if (vestingShare > 0) {
            _sendToVesting(buyer, vestingShare);
        }
        _tokensPurchased[buyer] += buyableTokens;
        totalTokenSold += buyableTokens;

        emit TokenSold(buyer, buyableTokens);
    }

    function claimTGE() external returns (bool) {
        address beneficiary = _msgSender();
        uint256 userAmountTGE = userBalanceOfTGE[beneficiary];
        uint256 userClaimStartTimeTGE_ = userClaimStartTimeTGE[beneficiary];

        require(
            userAmountTGE > 0,
            "TokenCrowdsaleFLYY: no TGE balance exists for the caller"
        );
        require(
            block.timestamp > userClaimStartTimeTGE_,
            "TokenCrowdsaleFLYY: TGE claim start time for user has not started yet"
        );

        userBalanceOfTGE[beneficiary] -= userAmountTGE;
        tokenContractAddressFLYY.transfer(beneficiary, userAmountTGE);

        return true;
    }

    function _buyableTokensInETH() private view returns (uint256) {
        uint256 buyableTokens = (msg.value * 10 ** _tokenDecimals) /
            tokenPriceInWEI;

        return buyableTokens;
    }

    function _buyableTokensInUSDT() private returns (uint256) {
        uint256 sentValue = tokenContractAddressUSDT.allowance(
            _msgSender(),
            address(this)
        );
        uint256 buyableTokens = (sentValue * 10 ** _tokenDecimals) /
            tokenPriceInUSDT;

        return buyableTokens;
    }

    function _sendToVesting(address beneficiary, uint256 amount) private {
        if (_vestingCliff == 1 && _vestingDuration == 1) {
            require(
                tokenContractAddressFLYY.transfer(beneficiary, amount),
                "TokenCrowdsaleFLYY: token FLYY transfer to buyer not succeeded"
            );
        } else {
            require(
                tokenContractAddressFLYY.approve(
                    address(vestingContractAddress),
                    amount
                ),
                "TokenCrowdsaleFLYY: token FLYY approve to vesting contract not succeeded"
            );
            vestingContractAddress.createVestingSchedule(
                beneficiary,
                _vestingStart,
                _vestingCliff,
                _vestingDuration,
                _vestingSlicePeriodSeconds,
                amount
            );
        }
    }

    function getContractBalanceETH() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractBalanceUSDT() external returns (uint256) {
        return tokenContractAddressUSDT.balanceOf(address(this));
    }

    function withdrawBalanceETH() external onlyOwner returns (bool) {
        payable(owner()).transfer(address(this).balance);

        return true;
    }

    function withdrawBalanceUSDT() external onlyOwner returns (bool) {
        uint256 balanceUSDT = tokenContractAddressUSDT.balanceOf(address(this));
        tokenContractAddressUSDT.transfer(owner(), balanceUSDT);

        return true;
    }

    function getContractBalanceFLYY() public view returns (uint256) {
        return tokenContractAddressFLYY.balanceOf(address(this));
    }

    function withdrawBalanceFLYY(uint256 amount) external onlyOwner {
        require(
            getContractBalanceFLYY() >= amount,
            "TokenVestingFLYY: not enough withdrawable funds"
        );
        tokenContractAddressFLYY.transfer(owner(), amount);
    }

    function getCurrentTime() external view virtual returns (uint256) {
        return block.timestamp;
    }

    function whitelistingSwitchControl(
        bool flag
    ) external onlyOwner returns (bool) {
        whitelistingSwitch = flag;
        emit WhitelistingSwitchTriggered(flag);

        return true;
    }

    function excludeFromWhitelist(
        address account
    ) external onlyOwner returns (bool) {
        _isIncludedInWhitelist[account] = false;

        return true;
    }

    function includeInWhitelist(
        address account
    ) external onlyOwner returns (bool) {
        _isIncludedInWhitelist[account] = true;

        return true;
    }

    function isWhitelisted(address account) external view returns (bool) {
        return _isIncludedInWhitelist[account];
    }

    receive() external payable {
        _buyTokenInETH();
    }

    fallback() external payable {
        _buyTokenInETH();
    }
}