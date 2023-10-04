/**
 *Submitted for verification at Etherscan.io on 2023-09-27
*/

// SPDX-License-Identifier: MIT

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: LinqStaQing.sol


//If you are here to forQ the code for this Qontract, good lucQ figuring out how to keep track of your MilQ

//With Love, LinQ & Aevum DeFi - Creating a New Paradigm in DeFi.

pragma solidity ^0.8.0;



interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface iLinq{
    function claim() external;
}

contract MilQFarm is Ownable, ReentrancyGuard {

    IERC20 private linQ;
    IERC20 private milQ;
    IERC20 private glinQ;
    iLinq public ILINQ;
    IUniswapV2Router02 private uniswapRouter;

    constructor(address _linqAddress, address _milQAddress, address _glinQAddress, address _oddysParlour, address _uniswapRouterAddress) {    
        linQ = IERC20(_linqAddress);
        ILINQ = iLinq(_linqAddress);
        milQ = IERC20(_milQAddress);
        glinQ = IERC20(_glinQAddress);
        oddysParlour = _oddysParlour;
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    }   
   
    bool private staQingPaused = true;

    address public oddysParlour;

    address private swapLinq = 0x3e34eabF5858a126cb583107E643080cEE20cA64;
   
    uint256 public daisys = 0; 

    uint256 public bessies = 0;

    uint256 public linQers = 0;

    uint256 public milQers = 0;

    uint256 public vitaliksMilkShipped = 0;

    uint256 public vitaliksMilkQompounded = 0;

    uint256 private daisysToOddysParlour = 15;

    uint256 private bessiesToOddysParlour = 15;

    uint256 public daisysMilkProduced = 0;

    uint256 public bessiesMilkProduced = 0;

    uint256 public daisysRentalTime;

    uint256 public bessiesRentalTime;

    uint256 public roundUpDaisysTime;

    uint256 public roundUpBessiesTime;

    uint256 public totalVitaliksMilkShipments = 0;

    uint256 public MilqShipments = 0;

    uint256 private minLinQ = 10000000000000000000;

    uint256 private minMilQ = 1000000000000000000;

    uint256 public totalMilQClaimed = 0;

    uint256 private highClaimThreshold = 5000000000000000000;

    event highClaim(address User, uint256 Amount);

    function sethighClaimThreshold(uint256 weiAmount) public onlyOwner {
        highClaimThreshold = weiAmount;
    }

    uint256 private lowBalanceThreshold = 10000000000000000000;

    event lowBalance(uint256 time, uint256 balance);

    function setLowBalanceThreshold(uint256 weiAmount) public onlyOwner {
        lowBalanceThreshold = weiAmount;
    }

    event rewardChange(uint256 index ,uint256 newBessies, uint256 newDaisys);

    event Qompound(address user, uint256 _ethAmount, uint256 boughtAmount);

    event newStaQe(address user, uint256 linq, uint256 milq);

    struct LinQerParlour {
        uint256 daisys;
        uint256 rentedDaisysSince;
        uint256 rentedDaisysTill;
        uint256 vitaliksMilkShipped;
        uint256 lastShippedVitaliksMilk;
        uint256 vitaliksMilkClaimable;
        uint256 QompoundedMilk;
        uint256 daisysOwnedSince;
        uint256 daisysOwnedTill;
        bool hasDaisys;
        bool ownsDaisys;
        bool owedMilk;
        uint256 shipmentsRecieved;
    }

    struct LpClaim {
        uint256 lastClaimed;
        uint256 totalClaimed;
    }

    struct MilQerParlour {
        uint256 bessies;
        uint256 rentedBessiesSince;
        uint256 rentedBessiesTill;
        uint256 milQClaimed;
        uint256 vitaliksMilkShipped;
        uint256 lastShippedVitaliksMilk;
        uint256 vitaliksMilkClaimable;
        uint256 bessiesOwnedSince;
        uint256 bessiesOwnedTill;
        bool hasBessies;
        bool ownsBessies;
        bool owedMilk;
        uint256 shipmentsRecieved;
    }

    struct MilQShipment {
        uint256 blockTimestamp;
        uint256 MilQShipped;
        uint256 totallinQStaked;
        uint256 rewardPerlinQ;
    }

    struct VitaliksMilkShipment {
        uint256 timestamp;
        uint256 daisysOutput;
        uint256 bessiesOutput;
    }

    mapping(address => LpClaim) public LpClaims;
    mapping(address => LinQerParlour) public LinQerParlours;
    mapping(address => MilQerParlour) public MilQerParlours;
    mapping(uint256 => MilQShipment) public MilQShipments;
    mapping(uint256 => VitaliksMilkShipment) public VitaliksMilkShipments;

    function rushOddyFee(uint256 _daisysToOddysParlour, uint256 _bessiesToOddysParlour) public onlyOwner{
        require(_daisysToOddysParlour + _bessiesToOddysParlour <= 60);        
        daisysToOddysParlour = _daisysToOddysParlour;
        bessiesToOddysParlour = _bessiesToOddysParlour;
    }

    function zeroFees() public onlyOwner {
        daisysToOddysParlour = 0;
        bessiesToOddysParlour = 0;
    }

    function setOddysParlour(address _oddysParlour) public onlyOwner {
        oddysParlour = _oddysParlour;
    }

    function setGlinQAddress(IERC20 _glinQ) public onlyOwner {
        glinQ = _glinQ;
    }   

    function prepShipment(uint256 _daisysOutput, uint256 _bessiesOutput) public onlyOwner {
        totalVitaliksMilkShipments ++;
        uint256 index = totalVitaliksMilkShipments;
        VitaliksMilkShipments[index] = VitaliksMilkShipment(block.timestamp, _daisysOutput, _bessiesOutput);
        emit rewardChange(index, _daisysOutput, _bessiesOutput);
    }

    function getprepShipment(uint256 index) public view returns (uint256, uint256, uint256) {
        require(index < totalVitaliksMilkShipments);
        VitaliksMilkShipment memory shipment = VitaliksMilkShipments[index];
        return (shipment.timestamp, shipment.daisysOutput, shipment.bessiesOutput);
    }

    function pauseStaQing(bool _state) public onlyOwner {
        staQingPaused = _state;
    }

    function removeVitaliksMilk(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount);
        payable(oddysParlour).transfer(amount);
    }

    function withdrawERC20(address _ERC20, uint256 _Amt) external onlyOwner {
        IERC20(_ERC20).transfer(msg.sender, _Amt);
    }

    function changeDaisysRentalTime(uint256 _daisysRentalTime) external onlyOwner {
        daisysRentalTime = _daisysRentalTime;
    }

    function changeBessiesRentalTime(uint256 _bessiesRentalTime) external onlyOwner {
        bessiesRentalTime = _bessiesRentalTime;
    }

    function changeRoundUpDaisysTime(uint256 _roundUpDaisysTime) external onlyOwner {
        roundUpDaisysTime = _roundUpDaisysTime;
    }

    function changeRoundUpBessiesTime(uint256 _roundUpBessiesTime) external onlyOwner {
        roundUpBessiesTime = _roundUpBessiesTime;
    }

    function changeMinLinQ(uint256 _minLinQ) external onlyOwner {
        minLinQ = _minLinQ;
    }

    function changeMinMilQ(uint256 _minMilQ) external onlyOwner {
        minMilQ = _minMilQ;
    }

    function staQe(uint256 _amountLinQ, uint256 _amountMilQ, uint256 _token) external {
        require(!staQingPaused);
        require(_token == 0 || _token == 1);

        if (LinQerParlours[msg.sender].hasDaisys == true || MilQerParlours[msg.sender].hasBessies == true ) {
            howMuchMilkV3();
        }

        if (_token == 0) {
            require(_amountLinQ >= minLinQ);
            
            if (LinQerParlours[msg.sender].hasDaisys == true) {
                uint256 milQToClaim = checkEstMilQRewards(msg.sender);
                
                if (milQToClaim > 0) {
                    shipLinQersMilQ();
                }
                
                getMoreDaisys(_amountLinQ);
            }        

            if (LinQerParlours[msg.sender].hasDaisys == false){
                firstStaQeLinQ(_amountLinQ);
            }      
        }

        if (_token == 1) { 
            require(_amountMilQ >= minMilQ);
            if (MilQerParlours[msg.sender].hasBessies == true){
                getMoreBessies(_amountMilQ);
            } 

            if (MilQerParlours[msg.sender].hasBessies == false){
                firstStaQeMilQ(_amountMilQ);
            }
        }
        emit newStaQe(msg.sender,_amountLinQ, _amountMilQ);
    }

    function getMoreDaisys(uint256 amountLinQ) internal {
        
        linQ.approve(address(this), amountLinQ);
        linQ.transferFrom(msg.sender, address(this), amountLinQ);
        
        if (LinQerParlours[msg.sender].ownsDaisys == true) {
            glinQ.transfer(msg.sender, amountLinQ);
        } 

        LinQerParlours[msg.sender].daisys += amountLinQ;
        daisys += amountLinQ; 
    }

    function getMoreBessies(uint256 amountMilQ) internal {
        milQ.approve(address(this), amountMilQ);
        milQ.transferFrom(msg.sender, address(this), amountMilQ);
        MilQerParlours[msg.sender].bessies += amountMilQ;
        bessies += amountMilQ;    
    }
   
    function firstStaQeLinQ(uint256 amountLinQ) internal {
        linQ.approve(address(this), amountLinQ);
        linQ.transferFrom(msg.sender, address(this), amountLinQ);
        LinQerParlours[msg.sender].daisys += amountLinQ;
        LinQerParlours[msg.sender].rentedDaisysSince = block.timestamp;
        LinQerParlours[msg.sender].rentedDaisysTill = block.timestamp + daisysRentalTime; 
        LinQerParlours[msg.sender].daisysOwnedSince = 0;
        LinQerParlours[msg.sender].daisysOwnedTill = 32503680000;
        LinQerParlours[msg.sender].hasDaisys = true;
        LinQerParlours[msg.sender].ownsDaisys = false;
        LinQerParlours[msg.sender].vitaliksMilkShipped = 0;
        LinQerParlours[msg.sender].QompoundedMilk = 0;
        LinQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
        LinQerParlours[msg.sender].shipmentsRecieved = totalVitaliksMilkShipments;
        LinQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        LinQerParlours[msg.sender].owedMilk = true;
        LpClaims[msg.sender].lastClaimed = totalMilQClaimed;
        LpClaims[msg.sender].totalClaimed = 0;
        daisys += amountLinQ;
        linQers ++;
    }

    function firstStaQeMilQ(uint256 amountMilQ) internal {
        milQ.approve(address(this), amountMilQ);
        milQ.transferFrom(msg.sender, address(this), amountMilQ);
        MilQerParlours[msg.sender].bessies += amountMilQ;
        MilQerParlours[msg.sender].rentedBessiesSince = block.timestamp;
        MilQerParlours[msg.sender].rentedBessiesTill = block.timestamp + bessiesRentalTime;
        MilQerParlours[msg.sender].hasBessies = true;
        MilQerParlours[msg.sender].bessiesOwnedSince = 0;
        MilQerParlours[msg.sender].bessiesOwnedTill = 32503680000;
        MilQerParlours[msg.sender].ownsBessies = false;
        MilQerParlours[msg.sender].vitaliksMilkShipped = 0;
        MilQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
        MilQerParlours[msg.sender].shipmentsRecieved = totalVitaliksMilkShipments;
        MilQerParlours[msg.sender].milQClaimed = 0;
        MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        MilQerParlours[msg.sender].owedMilk = true;
        bessies += amountMilQ;
        milQers ++;
    }

    function ownCows(uint256 _cow) external {
        require(!staQingPaused);
        require( _cow == 0 || _cow == 1);

        if (_cow == 0) {
            require(LinQerParlours[msg.sender].ownsDaisys == false);
            require(LinQerParlours[msg.sender].hasDaisys == true);
            require(LinQerParlours[msg.sender].rentedDaisysTill < block.timestamp);
            require(glinQ.transfer(msg.sender, LinQerParlours[msg.sender].daisys));
            LinQerParlours[msg.sender].ownsDaisys = true;
            LinQerParlours[msg.sender].daisysOwnedSince = LinQerParlours[msg.sender].rentedDaisysTill;
            LinQerParlours[msg.sender].owedMilk = true;
        }    

        if (_cow == 1) {
            require(MilQerParlours[msg.sender].ownsBessies == false);
            require(MilQerParlours[msg.sender].hasBessies == true);
            require(MilQerParlours[msg.sender].rentedBessiesTill < block.timestamp);
            MilQerParlours[msg.sender].ownsBessies = true;
            MilQerParlours[msg.sender].bessiesOwnedSince = MilQerParlours[msg.sender].rentedBessiesTill;
            MilQerParlours[msg.sender].owedMilk = true;
        }
    }

    function roundUpCows(uint256 _cow) external {
        require(!staQingPaused);
        require(_cow == 0 && LinQerParlours[msg.sender].ownsDaisys == true || _cow == 1 && MilQerParlours[msg.sender].ownsBessies == true);

            if (_cow == 0) {
                uint256 newTimestamp = block.timestamp + roundUpDaisysTime; //make this time variable    
                LinQerParlours[msg.sender].daisysOwnedTill = newTimestamp;
            }

            if (_cow == 1) {
                uint256 newTimestamp = block.timestamp + roundUpBessiesTime; 
                MilQerParlours[msg.sender].bessiesOwnedTill = newTimestamp;
            }
    }

    function unstaQe(uint256 _amtLinQ, uint256 _amtMilQ, uint256 _token) external { 
        require(!staQingPaused); 
        require(_token == 0 || _token == 1); 
        uint256 totalMilk = viewHowMuchMilk(msg.sender); 
 
        if (totalMilk > 0) {   
            shipMilk(); 
        } 
 
        if (_token == 0) { 
            require(_amtLinQ > 0); 
            require(LinQerParlours[msg.sender].daisys >= _amtLinQ);
            require(LinQerParlours[msg.sender].hasDaisys == true); 
            unstaQeLinQ(_amtLinQ); 
        } 
 
        if (_token == 1) { 
            require(_amtMilQ > 0); 
            require(MilQerParlours[msg.sender].bessies >= _amtMilQ);
            require(MilQerParlours[msg.sender].hasBessies == true); 
            unstaQeMilQ(_amtMilQ); 
        }     
    }

    function unstaQeLinQ(uint256 amtLinQ) internal {        
        if (LinQerParlours[msg.sender].ownsDaisys == true) {
            glinQ.approve(address(this), amtLinQ);
            glinQ.transferFrom(msg.sender, address(this), amtLinQ);
        }

        uint256 amtToClaim = checkEstMilQRewards(msg.sender);
        
        if (amtToClaim > 0) {
            shipLinQersMilQ();
        }

        uint256 transferLinQ;
        uint256 dToOddysParlour;

            if (LinQerParlours[msg.sender].daisysOwnedTill < block.timestamp && LinQerParlours[msg.sender].ownsDaisys == true){
                linQ.transfer(msg.sender, amtLinQ);
                LinQerParlours[msg.sender].daisys -= amtLinQ; 
            }

            if (LinQerParlours[msg.sender].rentedDaisysTill < block.timestamp && LinQerParlours[msg.sender].ownsDaisys == false){
                linQ.transfer(msg.sender, amtLinQ);
                LinQerParlours[msg.sender].daisys -= amtLinQ; 
            }

            if (LinQerParlours[msg.sender].daisysOwnedTill > block.timestamp && LinQerParlours[msg.sender].ownsDaisys == true){
                dToOddysParlour = (amtLinQ * daisysToOddysParlour / 100);
                transferLinQ = (amtLinQ - dToOddysParlour);
                linQ.transfer(msg.sender, transferLinQ);
                linQ.transfer(oddysParlour, dToOddysParlour);
                LinQerParlours[msg.sender].daisys -= amtLinQ;          
            }

            if (LinQerParlours[msg.sender].rentedDaisysTill > block.timestamp && LinQerParlours[msg.sender].ownsDaisys == false){
                dToOddysParlour = (amtLinQ * daisysToOddysParlour / 100);
                transferLinQ = (amtLinQ - dToOddysParlour);
                linQ.transfer(msg.sender, transferLinQ);
                linQ.transfer(oddysParlour, dToOddysParlour);
                LinQerParlours[msg.sender].daisys -= amtLinQ;  
            }   

            if (LinQerParlours[msg.sender].daisys < minLinQ) {
                LinQerParlours[msg.sender].daisys = 0;
                LinQerParlours[msg.sender].rentedDaisysSince = 0;
                LinQerParlours[msg.sender].rentedDaisysTill = 0;
                LinQerParlours[msg.sender].vitaliksMilkShipped = 0;
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = 0;
                LinQerParlours[msg.sender].vitaliksMilkClaimable = 0;
                LinQerParlours[msg.sender].QompoundedMilk = 0;
                LinQerParlours[msg.sender].daisysOwnedSince = 0;
                LinQerParlours[msg.sender].daisysOwnedTill = 0;
                LinQerParlours[msg.sender].hasDaisys = false;
                LinQerParlours[msg.sender].ownsDaisys = false;
                LinQerParlours[msg.sender].owedMilk = false;
                LinQerParlours[msg.sender].shipmentsRecieved = 0;
                linQers --;
            }       
    }

    function unstaQeMilQ(uint256 amtMilQ) internal {
        uint256 transferMilQ;
        uint256 bToOddysParlour;

            if (MilQerParlours[msg.sender].bessiesOwnedTill <= block.timestamp && MilQerParlours[msg.sender].ownsBessies == true){
                transferMilQ = amtMilQ;
                milQ.transfer(msg.sender, transferMilQ);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].rentedBessiesTill <= block.timestamp && MilQerParlours[msg.sender].ownsBessies == false){
                transferMilQ = amtMilQ;
                milQ.transfer(msg.sender, transferMilQ);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].bessiesOwnedTill > block.timestamp && MilQerParlours[msg.sender].ownsBessies == true){
                bToOddysParlour = (amtMilQ * bessiesToOddysParlour / 100);
                transferMilQ = (amtMilQ - bToOddysParlour);
                milQ.transfer(msg.sender, transferMilQ);
                milQ.transfer(oddysParlour, bToOddysParlour);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].rentedBessiesTill > block.timestamp && MilQerParlours[msg.sender].ownsBessies == false){
                bToOddysParlour = (amtMilQ * bessiesToOddysParlour / 100);
                transferMilQ = (amtMilQ - bToOddysParlour);
                milQ.transfer(msg.sender, transferMilQ);
                milQ.transfer(oddysParlour, bToOddysParlour);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].bessies < minMilQ) {
                MilQerParlours[msg.sender].bessies = 0;
                MilQerParlours[msg.sender].rentedBessiesSince = 0;
                MilQerParlours[msg.sender].rentedBessiesTill = 0;
                MilQerParlours[msg.sender].milQClaimed = 0;
                MilQerParlours[msg.sender].vitaliksMilkShipped = 0;
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = 0;
                MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
                MilQerParlours[msg.sender].bessiesOwnedSince = 0;
                MilQerParlours[msg.sender].bessiesOwnedTill = 0;
                MilQerParlours[msg.sender].hasBessies = false;
                MilQerParlours[msg.sender].ownsBessies = false;
                MilQerParlours[msg.sender].owedMilk = false;
                MilQerParlours[msg.sender].shipmentsRecieved = 0;
                milQers --;
            }
    }

    function howMuchMilkV3() internal {
        uint256 milkFromDaisys = 0;
        uint256 milkFromBessies = 0;
        if (LinQerParlours[msg.sender].ownsDaisys == true && LinQerParlours[msg.sender].daisysOwnedTill > block.timestamp) {
            if (LinQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = LinQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                    LinQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    LinQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }
            
            if (LinQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }

        if (LinQerParlours[msg.sender].ownsDaisys == false && LinQerParlours[msg.sender].hasDaisys == true && LinQerParlours[msg.sender].rentedDaisysTill > block.timestamp) {
            if (LinQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = LinQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                    LinQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    LinQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }
            
            if (LinQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }

        if (LinQerParlours[msg.sender].ownsDaisys == true && LinQerParlours[msg.sender].daisysOwnedTill <= block.timestamp && LinQerParlours[msg.sender].owedMilk == true) {
            if(LinQerParlours[msg.sender].shipmentsRecieved < totalVitaliksMilkShipments) { 
                for (uint256 i = LinQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {

                    if (LinQerParlours[msg.sender].daisysOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                        LinQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        LinQerParlours[msg.sender].shipmentsRecieved ++;
                    }
            
                    if (LinQerParlours[msg.sender].daisysOwnedTill <= VitaliksMilkShipments[i+1].timestamp) {
                        uint256 time = LinQerParlours[msg.sender].daisysOwnedTill - LinQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        LinQerParlours[msg.sender].lastShippedVitaliksMilk = LinQerParlours[msg.sender].daisysOwnedTill;
                        LinQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }
            }

            if (LinQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (LinQerParlours[msg.sender].daisysOwnedTill - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = LinQerParlours[msg.sender].daisysOwnedTill;
                LinQerParlours[msg.sender].owedMilk = false;
            } 
        }

        if (LinQerParlours[msg.sender].ownsDaisys == false && LinQerParlours[msg.sender].hasDaisys == true && LinQerParlours[msg.sender].rentedDaisysTill <= block.timestamp && LinQerParlours[msg.sender].owedMilk == true) {
            if(LinQerParlours[msg.sender].shipmentsRecieved < totalVitaliksMilkShipments){
                for (uint256 i = LinQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    if (LinQerParlours[msg.sender].rentedDaisysTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                        LinQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        LinQerParlours[msg.sender].shipmentsRecieved ++;
                    }
         
                    if (LinQerParlours[msg.sender].rentedDaisysTill <= VitaliksMilkShipments[i+1].timestamp && LinQerParlours[msg.sender].owedMilk == true){
                        uint256 time = LinQerParlours[msg.sender].rentedDaisysTill - LinQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        LinQerParlours[msg.sender].lastShippedVitaliksMilk = LinQerParlours[msg.sender].rentedDaisysTill;
                        LinQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }  
            }

            if (LinQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (LinQerParlours[msg.sender].rentedDaisysTill - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = LinQerParlours[msg.sender].rentedDaisysTill;
                LinQerParlours[msg.sender].owedMilk = false;
            }       
        }

        if (MilQerParlours[msg.sender].ownsBessies == true && MilQerParlours[msg.sender].bessiesOwnedTill > block.timestamp) {
            if (MilQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                    MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    MilQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments) {
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }

        if (MilQerParlours[msg.sender].ownsBessies == false && MilQerParlours[msg.sender].hasBessies == true && MilQerParlours[msg.sender].rentedBessiesTill > block.timestamp && MilQerParlours[msg.sender].owedMilk == true) {
            if (MilQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                    MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    MilQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }
        
        if (MilQerParlours[msg.sender].ownsBessies == true && MilQerParlours[msg.sender].bessiesOwnedTill <= block.timestamp && MilQerParlours[msg.sender].owedMilk == true) { 
            if (MilQerParlours[msg.sender].shipmentsRecieved < totalVitaliksMilkShipments) {
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[msg.sender].bessiesOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        MilQerParlours[msg.sender].shipmentsRecieved ++;
                    }
            
                    if (MilQerParlours[msg.sender].bessiesOwnedTill <= VitaliksMilkShipments[i+1].timestamp){
                        uint256 time = MilQerParlours[msg.sender].bessiesOwnedTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].bessiesOwnedTill;
                        MilQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[msg.sender].bessiesOwnedTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].bessiesOwnedTill;
                MilQerParlours[msg.sender].owedMilk = false;
            }    
        }
  
        if (MilQerParlours[msg.sender].ownsBessies == false && MilQerParlours[msg.sender].hasBessies == true && MilQerParlours[msg.sender].rentedBessiesTill <= block.timestamp  && MilQerParlours[msg.sender].owedMilk == true) {
            if(MilQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments){
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[msg.sender].rentedBessiesTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        MilQerParlours[msg.sender].shipmentsRecieved ++;
                    }
        
                    if (MilQerParlours[msg.sender].rentedBessiesTill <= VitaliksMilkShipments[i+1].timestamp){
                        uint256 time = MilQerParlours[msg.sender].rentedBessiesTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].rentedBessiesTill;
                        MilQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }  
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[msg.sender].rentedBessiesTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].rentedBessiesTill;
                MilQerParlours[msg.sender].owedMilk = false;
            }       
        }

        LinQerParlours[msg.sender].vitaliksMilkClaimable += milkFromDaisys;
        MilQerParlours[msg.sender].vitaliksMilkClaimable += milkFromBessies;
        daisysMilkProduced += milkFromDaisys;
        bessiesMilkProduced += milkFromBessies;      
    }

    function viewHowMuchMilk(address user) public view returns (uint256 Total) {
        uint256 daisysShipped = LinQerParlours[user].shipmentsRecieved;
        uint256 daisysTimeShipped = LinQerParlours[user].lastShippedVitaliksMilk;
        uint256 bessiesShipped = MilQerParlours[user].shipmentsRecieved;
        uint256 bessiesTimeShipped = MilQerParlours[user].lastShippedVitaliksMilk;
        uint256 milkFromDaisys = 0;
        uint256 milkFromBessies = 0;

        if (LinQerParlours[user].ownsDaisys == true && LinQerParlours[user].daisysOwnedTill > block.timestamp) {
            if (daisysShipped != totalVitaliksMilkShipments) {
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                    daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    daisysShipped ++;
                }
            }
            
            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - daisysTimeShipped);
            }
        }

        if (LinQerParlours[user].ownsDaisys == false && LinQerParlours[user].hasDaisys == true && LinQerParlours[user].rentedDaisysTill > block.timestamp) {
            if (daisysShipped != totalVitaliksMilkShipments) {
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                    daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    daisysShipped ++;
                }
            }
            
            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - daisysTimeShipped);
            }
        }

        if (LinQerParlours[user].ownsDaisys == true && LinQerParlours[user].daisysOwnedTill <= block.timestamp && LinQerParlours[user].owedMilk == true) {
            if(daisysShipped < totalVitaliksMilkShipments) { 
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {

                    if (LinQerParlours[user].daisysOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                        daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        daisysShipped ++;
                    }
            
                    if (LinQerParlours[user].daisysOwnedTill <= VitaliksMilkShipments[i+1].timestamp) {
                        uint256 time = LinQerParlours[user].daisysOwnedTill - daisysTimeShipped;
                        milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        break;   
                    }   
                }
            }

            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (LinQerParlours[user].daisysOwnedTill - daisysTimeShipped);
            } 
        }

        if (LinQerParlours[user].ownsDaisys == false && LinQerParlours[user].hasDaisys == true && LinQerParlours[user].rentedDaisysTill <= block.timestamp && LinQerParlours[user].owedMilk == true) {
            if(daisysShipped < totalVitaliksMilkShipments){
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {
                    if (LinQerParlours[user].rentedDaisysTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                        daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        daisysShipped ++;
                    }
         
                    if (LinQerParlours[user].rentedDaisysTill <= VitaliksMilkShipments[i+1].timestamp && LinQerParlours[user].owedMilk == true){
                        uint256 time = LinQerParlours[user].rentedDaisysTill - daisysTimeShipped;
                        milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        break;   
                    }   
                }  
            }

            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (LinQerParlours[user].rentedDaisysTill - daisysTimeShipped);
            }       
        }

        if (MilQerParlours[user].ownsBessies == true && MilQerParlours[user].bessiesOwnedTill > block.timestamp) {
            if (bessiesShipped != totalVitaliksMilkShipments) {
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                    bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    bessiesShipped ++;
                }
            }

            if (bessiesShipped == totalVitaliksMilkShipments) {
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - bessiesTimeShipped);
            }
        }

        if (MilQerParlours[user].ownsBessies == false && MilQerParlours[user].hasBessies == true && MilQerParlours[user].rentedBessiesTill > block.timestamp && MilQerParlours[user].owedMilk == true) {
            if (bessiesShipped != totalVitaliksMilkShipments) {
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                    bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    bessiesShipped ++;
                }
            }

            if (bessiesShipped == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - bessiesTimeShipped);
            }

        }

        if (MilQerParlours[user].ownsBessies == true && MilQerParlours[user].bessiesOwnedTill <= block.timestamp) { 
            if (bessiesShipped != totalVitaliksMilkShipments) {
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[user].bessiesOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                        bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        bessiesShipped ++;
                    }
            
                    if (MilQerParlours[user].bessiesOwnedTill <= VitaliksMilkShipments[i+1].timestamp && MilQerParlours[user].owedMilk == true){
                        uint256 time = MilQerParlours[user].bessiesOwnedTill - bessiesTimeShipped;
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        break;   
                    }   
                }
            }

            if (bessiesShipped == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[user].bessiesOwnedTill - bessiesTimeShipped);
            }    
        }

        if (MilQerParlours[user].ownsBessies == false && MilQerParlours[user].hasBessies == true && MilQerParlours[user].rentedBessiesTill <= block.timestamp) {
            if(bessiesShipped != totalVitaliksMilkShipments){
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[user].rentedBessiesTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                        bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        bessiesShipped ++;
                    }
        
                    if (MilQerParlours[user].rentedBessiesTill <= VitaliksMilkShipments[i+1].timestamp && MilQerParlours[user].owedMilk == true){
                        uint256 time = MilQerParlours[user].rentedBessiesTill - bessiesTimeShipped;
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        break;   
                    }   
                }  
            }

            if (bessiesShipped == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[user].rentedBessiesTill - bessiesTimeShipped);
            }       
        }

        Total = milkFromDaisys + milkFromBessies; 
        return (Total);       
    }

    function QompoundLinQ(uint256 slippage) external {  
        if (LinQerParlours[msg.sender].hasDaisys == true){
            shipLinQersMilQ();
        }

        howMuchMilkV3();  
  
        uint256 linqAmt = LinQerParlours[msg.sender].vitaliksMilkClaimable; 
        uint256 milqAmt = MilQerParlours[msg.sender].vitaliksMilkClaimable; 
        uint256 _ethAmount = linqAmt + milqAmt; 
  
        address[] memory path = new address[](2);  
        path[0] = uniswapRouter.WETH();  
        path[1] = swapLinq;  
  
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(_ethAmount, path);  
        uint256 minLinQAmount = amountsOut[1];   
  
      
        uint256 beforeBalance = IERC20(linQ).balanceOf(address(this));  
        uint256 amountSlip = (minLinQAmount * slippage) / 100;  
        uint256 amountAfterSlip = minLinQAmount - amountSlip;  
  
      
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _ethAmount}(  
            amountAfterSlip,  
            path,  
            address(this),  
            block.timestamp  
        );  
  
        uint256 afterBalance = IERC20(linQ).balanceOf(address(this));  
  
        uint256 boughtAmount = afterBalance - beforeBalance;

        if (LinQerParlours[msg.sender].ownsDaisys == true) {
            glinQ.transfer(msg.sender, boughtAmount);
        }

        if (LinQerParlours[msg.sender].hasDaisys == true) { 
            LinQerParlours[msg.sender].daisys += boughtAmount;  
            LinQerParlours[msg.sender].QompoundedMilk += _ethAmount;  
            LinQerParlours[msg.sender].vitaliksMilkClaimable = 0; 
            MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        }

        if (LinQerParlours[msg.sender].hasDaisys == false) {
            LinQerParlours[msg.sender].daisys += boughtAmount;
            LinQerParlours[msg.sender].rentedDaisysSince = block.timestamp;
            LinQerParlours[msg.sender].rentedDaisysTill = block.timestamp + daisysRentalTime; 
            LinQerParlours[msg.sender].daisysOwnedSince = 0;
            LinQerParlours[msg.sender].daisysOwnedTill = 32503680000;
            LinQerParlours[msg.sender].hasDaisys = true;
            LinQerParlours[msg.sender].ownsDaisys = false;
            LinQerParlours[msg.sender].vitaliksMilkShipped = 0;
            LinQerParlours[msg.sender].QompoundedMilk = 0;
            LinQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            LinQerParlours[msg.sender].shipmentsRecieved = totalVitaliksMilkShipments;
            LinQerParlours[msg.sender].vitaliksMilkClaimable = 0;
            LinQerParlours[msg.sender].owedMilk = true;
            LpClaims[msg.sender].lastClaimed = totalMilQClaimed;
            LpClaims[msg.sender].totalClaimed = 0;
            MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
            daisys += boughtAmount;
            linQers ++;
        }

        daisys += boughtAmount;
        vitaliksMilkQompounded += _ethAmount;
        emit Qompound(msg.sender, _ethAmount, boughtAmount);
    }
        
    function shipMilk() public {   
          
        howMuchMilkV3();

        uint256 linq = LinQerParlours[msg.sender].vitaliksMilkClaimable;
        uint256 lp = MilQerParlours[msg.sender].vitaliksMilkClaimable;
        uint256 amount = linq + lp;

        require(address(this).balance >= amount);

        payable(msg.sender).transfer(amount);

        LinQerParlours[msg.sender].vitaliksMilkShipped += linq;
        MilQerParlours[msg.sender].vitaliksMilkShipped += lp;
        LinQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        vitaliksMilkShipped += amount;

        if (amount > highClaimThreshold){
            emit highClaim(msg.sender,amount);
        }

        if(address(this).balance < lowBalanceThreshold){
            emit lowBalance(block.timestamp,address(this).balance);
        }    
    }

    function shipFarmMilQ() external onlyOwner {

        uint256 beforeBalance = IERC20(milQ).balanceOf(address(this)); 

        ILINQ.claim();

        uint256 afterBalance = IERC20(milQ).balanceOf(address(this));

        uint256 claimed = afterBalance - beforeBalance;

         uint256 PerLinQ = (claimed * 10**18) / daisys;

        uint256 index = MilqShipments;

        MilQShipments[index] = MilQShipment(block.timestamp, claimed, daisys,PerLinQ);

        MilqShipments++;

        totalMilQClaimed += claimed;
    }

    function shipLinQersMilQ() public {  
        uint256 CurrrentDis = totalMilQClaimed - LpClaims[msg.sender].lastClaimed;  
        uint256 tokensStaked = LinQerParlours[msg.sender].daisys;  
         uint256 divDaisys = daisys / 10**18; 
        uint256 percentOwned = ((tokensStaked * 100) / divDaisys); 
        uint256 userDistro = CurrrentDis * (percentOwned / 100); 
        uint256 userDistroAmount = userDistro / 10**18; 
        milQ.transfer(msg.sender, userDistroAmount); 
  
        MilQerParlours[msg.sender].milQClaimed += userDistroAmount;
        LpClaims[msg.sender].lastClaimed = totalMilQClaimed;  
        LpClaims[msg.sender].totalClaimed += userDistroAmount;  
    }  
  
    function checkEstMilQRewards(address user) public view returns (uint256){  
        uint256 CurrrentDis = totalMilQClaimed - LpClaims[user].lastClaimed;  
        uint256 tokensStaked = LinQerParlours[user].daisys;  
        uint256 divDaisys = daisys / 10**18; 
        uint256 percentOwned = ((tokensStaked * 100) / divDaisys); 
        uint256 userDistro = CurrrentDis * (percentOwned / 100); 
        uint256 userDistroAmount = userDistro / 10**18; 
 
        return userDistroAmount;  
    }

    receive() external payable {}
}