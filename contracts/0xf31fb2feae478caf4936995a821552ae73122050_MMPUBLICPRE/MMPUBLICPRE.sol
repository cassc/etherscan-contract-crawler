/**
 *Submitted for verification at Etherscan.io on 2023-10-09
*/

//SPDX-License-Identifier: MIT

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/security/Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IERC20_Extended {
    function name() external view returns (string memory);

    function decimals() external view returns (uint256);
}

interface AggregatorV3Interface_EXT {
    function latestAnswer() external view returns (uint256);
}

contract MMPUBLICPRE is Pausable, Ownable {
    uint256 private _priceInUSD;
    address[] private _supportedTokensList;
    address private _treasaryWallet;

    uint256 private _totalTokensSold;
    uint256 private _totalETHCollected;
    uint256 private _totalUSDCollected;

    uint256 private _minContributionInUSD;

    bool private _isTransacting;

    address private _priceOracleAddressNative;

    address private _presaleTokenContract;

    mapping(address => bool) private _mappingSupportedTokens;

    constructor(
        uint256 priceInUSD_,
        address treasaryWallet_,
        address nativePriceOracle_,
        address presaleTokenContract_
    ) {
        _priceInUSD = priceInUSD_;
        _treasaryWallet = treasaryWallet_;
        _minContributionInUSD = 50 * 1 ether;
        _priceOracleAddressNative = nativePriceOracle_;
        _presaleTokenContract = presaleTokenContract_;
    }

    receive() external payable {}

    event BuyWithNative(
        address userAddress,
        uint256 valueInWei,
        uint256 tokenSold,
        uint256 priceInUSD
    );
    event BuyWithToken(
        address userAddress,
        address tokenContract,
        uint256 valueInWei,
        uint256 tokenSold,
        uint256 priceInUSD
    );

    modifier noReetency() {
        require(!_isTransacting, "Transaction in progress");
        _isTransacting = true;
        _;
        _isTransacting = false;
    }

    function getPresaleAnalytics()
        external
        view
        returns (
            uint256 totalTokensSold,
            uint256 totalETHCollected,
            uint256 totalUSDValue
        )
    {
        totalTokensSold = _totalTokensSold;
        totalETHCollected = _totalETHCollected;
        totalUSDValue = _totalUSDCollected;
    }

    function getPresaleTokenContract() external view returns (address) {
        return _presaleTokenContract;
    }

    function setPresaleTokenContract(address _contractAddress)
        external
        onlyOwner
    {
        _presaleTokenContract = _contractAddress;
    }

    function getPriceOracleNative() external view returns (address) {
        return _priceOracleAddressNative;
    }

    function setPriceOracleNative(address _contractAddress) external onlyOwner {
        _priceOracleAddressNative = _contractAddress;
    }

    function getMinContributionUSD() external view returns (uint256) {
        return _minContributionInUSD;
    }

    function setMinContributionUSD(uint256 _valueInWei) external onlyOwner {
        _minContributionInUSD = _valueInWei;
    }

    function getPresalePricePerUSD() external view returns (uint256) {
        return _priceInUSD;
    }

    function setPricePerUSD(uint256 priceInUSD_) external onlyOwner {
        _priceInUSD = priceInUSD_;
    }

    function getTreasaryWallet() external view returns (address) {
        return _treasaryWallet;
    }

    function setTreasaryWallet(address treasaryWallet_) external onlyOwner {
        _treasaryWallet = treasaryWallet_;
    }

    function getSupportedTokensList() external view returns (address[] memory) {
        return _supportedTokensList;
    }

    function addSupportedToken(address tokenContract_) external onlyOwner {
        bool isTokenSupported = _mappingSupportedTokens[tokenContract_];
        require(
            !isTokenSupported,
            "Token already added in supported tokens list"
        );

        _mappingSupportedTokens[tokenContract_] = true;
        _supportedTokensList.push(tokenContract_);
    }

    function removeSupportedToken(address tokenContract_) external onlyOwner {
        bool isTokenSupported = _mappingSupportedTokens[tokenContract_];
        require(
            isTokenSupported,
            "Token already removed or not added in supported tokens list"
        );

        _mappingSupportedTokens[tokenContract_] = false;

        address[] memory supportedTokensList = _supportedTokensList;

        for (uint256 i; i < supportedTokensList.length; ++i) {
            if (_supportedTokensList[i] == tokenContract_) {
                _supportedTokensList[i] = _supportedTokensList[
                    _supportedTokensList.length - 1
                ];
                _supportedTokensList.pop();
            }
        }
    }

    function _getPriceFromOracle(address oracleAddress_)
        private
        view
        returns (uint256 valueInUSD)
    {
        (
            ,
            /* uint80 roundID */
            int256 answer, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = AggregatorV3Interface(oracleAddress_).latestRoundData();

        valueInUSD = _toWeiFromDecimals(
            uint256(answer),
            AggregatorV3Interface(oracleAddress_).decimals()
        );
    }

    function getETHPrice() external view returns (uint256) {
        return _getPriceFromOracle(_priceOracleAddressNative);
    }

    function getTokenByETH(uint256 _msgValue)
        external
        view
        returns (uint256 valueInTokens)
    {
        uint256 msgValueUSD = (_getPriceFromOracle(_priceOracleAddressNative) *
            _msgValue) / 1 ether;
        valueInTokens = (msgValueUSD / _priceInUSD) * 1 ether;
    }

    function buyWithToken(address tokenContract_, uint256 valueInWei_)
        external
        noReetency
        whenNotPaused
    {
        address msgSender = msg.sender;

        require(
            _mappingSupportedTokens[tokenContract_],
            "Token is not supported"
        );
        uint256 msgValueInWei = _toWei(tokenContract_, valueInWei_);
        require(
            msgValueInWei >= _minContributionInUSD,
            "Value less then min contribution"
        );

        IERC20(tokenContract_).transferFrom(
            msgSender,
            _treasaryWallet,
            valueInWei_
        );

        uint256 valueInTokens = ((msgValueInWei * 1 ether) / _priceInUSD);

        IERC20(_presaleTokenContract).transfer(
            msgSender,
            _toWei(_presaleTokenContract, valueInTokens)
        );

        _totalTokensSold += valueInTokens;
        _totalUSDCollected += msgValueInWei;

        emit BuyWithToken(
            msgSender,
            tokenContract_,
            valueInWei_,
            valueInTokens,
            _priceInUSD
        );
    }

    function buyWithNative() external payable noReetency whenNotPaused {
        address msgSender = msg.sender;
        uint256 msgValue = msg.value;
        uint256 msgValueUSD = (_getPriceFromOracle(_priceOracleAddressNative) *
            msgValue) / 1 ether;

        require(
            msgValueUSD >= _minContributionInUSD,
            "Value less then min contribution"
        );

        payable(_treasaryWallet).transfer(address(this).balance);

        uint256 valueInTokens = ((msgValueUSD * 1 ether) / _priceInUSD);

        IERC20(_presaleTokenContract).transfer(
            msgSender,
            _toWei(_presaleTokenContract, valueInTokens)
        );

        _totalTokensSold += valueInTokens;
        _totalUSDCollected += msgValueUSD;
        _totalETHCollected += msgValue;

        emit BuyWithNative(msgSender, msgValue, valueInTokens, _priceInUSD);
    }

    function _toWeiFromDecimals(uint256 valueInTokens_, uint256 from_)
        private
        pure
        returns (uint256 valueInWei)
    {
        valueInWei = (valueInTokens_ * 1 ether) / 10**from_;
    }

    function _toWei(address tokenContract_, uint256 valueInTokens_)
        private
        view
        returns (uint256 valueInWei)
    {
        valueInWei = ((valueInTokens_ * 1 ether) /
            10**IERC20_Extended(tokenContract_).decimals());
    }

    function _toTokenDecimals(address tokenContract_, uint256 valueInWei_)
        private
        view
        returns (uint256 valueInToken)
    {
        valueInToken =
            (valueInWei_ * 10**IERC20_Extended(tokenContract_).decimals()) /
            1 ether;
    }

    function withdrawTokens(address _tokenContract, uint256 _valueInWei)
        external
        noReetency
        onlyOwner
    {
        IERC20(_tokenContract).transfer(owner(), _valueInWei);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}