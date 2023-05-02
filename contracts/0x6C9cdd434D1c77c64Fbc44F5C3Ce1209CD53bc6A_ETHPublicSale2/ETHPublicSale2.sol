/**
 *Submitted for verification at Etherscan.io on 2023-04-28
*/

/**
 *Submitted for verification at Etherscan.io on 2023-04-26
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


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


// File contracts/ETHPublicSale.sol


pragma solidity ^0.8.9;


/// @title Public Sale
contract ETHPublicSale2 is Ownable {

    mapping(address => uint256) public participants;

    mapping(address => int256) public participantTokens; 

    int256 internal constant PRECISION = 1 ether;

    int256 internal constant DECIMALS = 10**8;

    int256 public  BUY_PRICE; //buy price in format 1 base token = amount of buy token, 1 ETH = 0.01 Token
    uint256 public  SOFTCAP; //soft cap
    uint256 public  HARDCAP; //hard cap
    uint256 public  MIN_ETH_PER_WALLET; //min base token per wallet
    uint256 public  MAX_ETH_PER_WALLET; //max base token per wallet
    uint256 public  SALE_LENGTH; //sale length in seconds

    enum STATUS {
        QUED,
        ACTIVE,
        SUCCESS,
        FAILED
    }

    uint256 public totalCollected; //total ETH collected
    int256 public totalSold; //total sold tokens

    uint256 public startTime; //start time for presale
    uint256 public endTime; //end time for presale

    bool forceFailed; //force failed, emergency
    
    AggregatorV3Interface internal priceFeed;

    event buyToken(address recipient, int256 tokensSold, uint256 value, int256 amountInUSD, int256 price);
    event Refund(address recipient, uint256 ETHToRefund);
    event ForceFailed();
    event Withdraw(address recipient, uint256 amount);
    event SaleTokenChanged(address saleToken);
    constructor(
        int256 _buyPrice,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minETHPerWallet,
        uint256 _maxETHPerWallet,
        uint256 _startTime,
        uint256 _buyLengh,
        address _priceFeed
    ) {
        BUY_PRICE = _buyPrice;
        SOFTCAP = _softCap;
        HARDCAP = _hardCap;
        MIN_ETH_PER_WALLET = _minETHPerWallet;
        MAX_ETH_PER_WALLET = _maxETHPerWallet;
        SALE_LENGTH = _buyLengh; //2 days, 48 hours

        startTime = _startTime;
        endTime = _startTime + SALE_LENGTH;

        priceFeed = AggregatorV3Interface(
            _priceFeed
        );
    }

    receive() external payable {
        buy();
    }
    
    /// @notice buy
    /// @dev before this, need approve
    function buy() public payable {
        uint256 _amount = msg.value;

        require(status() == STATUS.ACTIVE, "PublicSale: sale is not started yet or ended");
        require(_amount >= MIN_ETH_PER_WALLET, "PublicSale: insufficient purchase amount");
        require(_amount <= MAX_ETH_PER_WALLET, "PublicSale: reached purchase amount");
        require(participants[_msgSender()] < MAX_ETH_PER_WALLET, "PublicSale: the maximum amount of purchases has been reached");

        uint256 newTotalCollected = totalCollected + _amount;

        if (HARDCAP < newTotalCollected) {
            // Refund anything above the hard cap
            uint256 diff = newTotalCollected - HARDCAP;
            _amount = _amount - diff;
        }

        if (_amount >= MAX_ETH_PER_WALLET - participants[_msgSender()]) {
            _amount = MAX_ETH_PER_WALLET - participants[_msgSender()];
        }

        // Save participants eth
        participants[_msgSender()] = participants[_msgSender()] + _amount;
        
        // 2* 10^18 * 182221 * 10^6 / 10^8 = 364442 * 10^16
        int256 price = getLatestPrice();

        int256 amountInUSD = int256(_amount) * price / DECIMALS;
        int256 tokensSold = amountInUSD * PRECISION / BUY_PRICE;

        // Save participant tokens
        participantTokens[_msgSender()] = participantTokens[_msgSender()] + tokensSold;

        // Update total ETH
        totalCollected = totalCollected + _amount;

        // Update tokens sold
        totalSold = totalSold + tokensSold;


        if (_amount < msg.value) {
            //refund
            _deliverFunds(_msgSender(), msg.value - _amount, "Cant send ETH");
        }

        emit buyToken(_msgSender(), tokensSold, _amount, amountInUSD, price);
    }

    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    /// @notice refund base tokens
    /// @dev only if sale status is failed
    function refund() external {
        require(status() == STATUS.FAILED, "PublicSale: sale is failed");

        require(participants[_msgSender()] > 0, "PublicSale: no tokens for refund");

        uint256 ETHToRefund = participants[_msgSender()];

        participants[_msgSender()] = 0;

        _withdraw(_msgSender(), ETHToRefund);

        emit Refund(_msgSender(), ETHToRefund);
    }


    ///@notice withdraw all ETH
    ///@param _recipient address
    ///@dev from owner
    function withdraw(address _recipient) external virtual onlyOwner {
        require(status() == STATUS.SUCCESS, "PublicSale: failed or active");
        _withdraw(_recipient, address(this).balance);
    }

    /// @notice force fail contract
    /// @dev in other world, emergency exit
    function forceFail() external onlyOwner {
        forceFailed = true;
        emit ForceFailed();
    }

    /// sale status
    function status() public view returns (STATUS) {
        if (forceFailed) {
            return STATUS.FAILED;
        }
        if ((block.timestamp > endTime) && (totalCollected < SOFTCAP)) {
            return STATUS.FAILED; // FAILED - SOFTCAP not met by end time
        }

        if (totalCollected >= HARDCAP) {
            return STATUS.SUCCESS; // SUCCESS - HARDCAP met
        }

        if ((block.timestamp > endTime) && (totalCollected >= SOFTCAP)) {
            return STATUS.SUCCESS; // SUCCESS - endblock and soft cap reached
        }
        if ((block.timestamp >= startTime) && (block.timestamp <= endTime)) {
            return STATUS.ACTIVE; // ACTIVE - deposits enabled
        }

        return STATUS.QUED; // QUED - awaiting start time
    }


    ///@notice get token amount
    ///@param _account account
    function getTokenAmount(address _account) public view returns (int256 tokenAmount) {
        tokenAmount = participantTokens[_account];
    }

    function _withdraw(address _recipient, uint256 _amount) internal virtual {
        require(_recipient != address(0x0), "PublicSale: address is zero");
        require(_amount <= address(this).balance, "PublicSale: not enought ETH balance");

        _deliverFunds(_recipient, _amount, "PublicSale: Cant send ETH");
    }

    function _deliverFunds(
        address _recipient,
        uint256 _value,
        string memory _message
    ) internal {
        if (_value > address(this).balance) {
            _value = address(this).balance;
        }

        (bool sent, ) = payable(_recipient).call{value: _value}("");

        require(sent, _message);

        emit Withdraw(_recipient, _value);
    }

}