/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function distributeTokens(address to, uint tokens, uint256 lockingPeriod) external returns (bool);
}


interface IPancakeRouter02 {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
}


pragma solidity 0.8.12;

contract KingdomCoin_LaunchPad is Ownable, ReentrancyGuard {
    address private constant router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public kingdomCoin;
    struct UserStorage {
        uint256 amountDeposited;
        uint256 amountInPrice;
        uint256 amountClaimed;
        uint256 nextClaimAmount;
        uint256 nextClaimTime;
    }

    uint256 public price;
    uint256 public expectedTotalLockFunds;
    uint256 public lockedFunds;
    uint256 public maxLockForEachUser;
    uint256 public minLockForEachUser;

    uint256 public claimTime;
    uint256 public distributionPeriod;
    bool    public saleActive;  

    address[] private users;

    mapping(address => bool) public userAlreadyLocked;  
    mapping (address => bool) public isAllowed;
    mapping(address => UserStorage) public userStorage;
    
    // Emitted when tokens are sold
    event Sale(address indexed account, uint indexed price, uint tokensGot);
    event Claim(address indexed sender, uint256 amount, uint256 time);
    event UpdateMaxAndMinAmount(uint256 newMax, uint256 newMin);
    event Expectedlocked(uint256 newTotal);
    event ClaimTime(uint256 newTotal);
    event PriceUpdate(uint256 newPrice);
    event TokenAdded(address indexed token, bool status);
 
    // _swapTokenFrom: token address to swap for;
    // _swapTokenTo: Rigel default token address;
    // _price: amount of $swapTokenTo (How much will one $swapTokenTo cost);
    // expectedLockedValue: amount of the swap token that is expected to be locked on the contract;
    // _specialPoolC: rigel special pool contract.
    constructor(address _kingdomCoin) {
        saleActive = true;
        kingdomCoin = _kingdomCoin;
        claimTime = 1 hours;
        distributionPeriod = 4;
    }
    
    // owner to set the expected locking amount
    function expectedTotalLockfund(uint256 total) external onlyOwner {
        expectedTotalLockFunds = total;
        emit Expectedlocked(total);
    }

    function updateClaimTime(uint256 newClaimTime) external onlyOwner {
        claimTime = newClaimTime;
        emit ClaimTime(newClaimTime);
    }

    function setMinAndMaxLockFund(uint256 newMinimum, uint256 newMaximum) external onlyOwner {
        maxLockForEachUser = newMaximum;
        minLockForEachUser = newMinimum;
        emit UpdateMaxAndMinAmount(newMaximum, newMinimum);
    }

    function setAllowablToken(address token, bool status) external onlyOwner {
        require(token != address(0), "Invalid token address");
        isAllowed[token] = status;
        emit TokenAdded(token, status);
    }

    // Change the token price
    // Note: Set the price respectively considering the decimals of busd
    // Example: If the intended price is 0.01 per token, call this function with the result of 0.01 * 10**18 (_price = intended price * 10**18; calc this in a calculator).
    function tokenPrice(uint _price) external onlyOwner {
        price = _price;
        emit PriceUpdate(_price);
    }

    // Buy tokens function
    function lockFund(address _token, uint256 _tokenAmount) public payable nonReentrant() {
        uint256 amountLocked = userStorage[_msgSender()].amountDeposited;
        require(isAllowed[_token], "Invalid Token");        
        // Check if sale is active and user tries to buy atleast 1 token
        require(saleActive, "swapTokenTo: SALE HAS ENDED.");
        
        uint256 amountInBUSD;
        if(_token == address(0) && msg.value != 0) {
            address[] memory pairs = new address[](2);
            pairs[0] = IPancakeRouter02(router).WETH();
            pairs[1] = busd;
            uint[] memory amounts = IPancakeRouter02(router).getAmountsOut(msg.value, pairs);
            amountInBUSD = amounts[1];
        } else {
            IERC20(_token).transferFrom(_msgSender(), address(this), _tokenAmount);
            amountInBUSD = _tokenAmount;
        }  

        if (amountLocked == 0) {
            require(amountInBUSD >= minLockForEachUser, "Can't lock below minimum amount");
        } else {
            require(amountLocked +  amountInBUSD <= maxLockForEachUser, "Can't lock below minimum amount");
        }
              
        // all amounts are represented in BUSD
        uint256 outputAmount = calculateOutputAmount(amountInBUSD);

        userStorage[_msgSender()].amountDeposited += amountLocked;
        userStorage[_msgSender()].amountInPrice += outputAmount;
        userStorage[_msgSender()].nextClaimTime = block.timestamp + claimTime;
        // locking of funds should stop before claim start in other to ensure the 'next claim amount' computes correctly
        userStorage[_msgSender()].nextClaimAmount = amountLocked + outputAmount / distributionPeriod;
        
        // store user
        if(!userAlreadyLocked[_msgSender()]) {
            users.push(_msgSender());
            userAlreadyLocked[_msgSender()] = true;
        } 
        
        lockedFunds += amountInBUSD;
        require(lockedFunds <= expectedTotalLockFunds, "Rigel: Expected amount has been locked");
        emit Sale(_msgSender(), price, amountInBUSD);
    }


    function claimKingdomCoin() external {
        require(!saleActive, "sales still ongoing");
        uint256 nxtClaimAmount = userStorage[_msgSender()].nextClaimAmount;
        require(userStorage[_msgSender()].amountClaimed < userStorage[_msgSender()].amountInPrice, "Already claimed");
        userStorage[_msgSender()].nextClaimTime += block.timestamp + claimTime;
        userStorage[_msgSender()].amountClaimed += nxtClaimAmount;
        IERC20(kingdomCoin).transfer(msg.sender, nxtClaimAmount);
        emit Claim(msg.sender, nxtClaimAmount, block.timestamp);
    }

    function getUserslength() external view returns(uint256) {
        return users.length;
    }

    function getUserAtindexed( uint256 i) external view returns(address) {
        // get all users should be made with libraries
        return users[i];
    }

    function calculateOutputAmount(uint256 _amountInBUSD) public view returns(uint256) {
        return _amountInBUSD * price / 1 ether;
    }
    
    // Start the sale again - can be called anytime again
    function saleState(bool status) external onlyOwner{
        // Enable the sale
        saleActive = status;        
    }

    // Withdraw (accidentally) to the contract sent eth
    function withdrawBNB() external payable onlyOwner {
        payable(owner()).transfer(payable(address(this)).balance);
    }
    
    // Withdraw (accidentally) to the contract sent ERC20 tokens except swapTokenTo
    function withdrawIERC20(address _token) external onlyOwner {
        uint _tokenBalance = IERC20(_token).balanceOf(address(this));        
        IERC20(_token).transfer(owner(), _tokenBalance);
    }

}