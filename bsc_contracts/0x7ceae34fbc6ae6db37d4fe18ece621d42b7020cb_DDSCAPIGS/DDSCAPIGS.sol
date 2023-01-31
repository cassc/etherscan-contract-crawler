/**
 *Submitted for verification at BscScan.com on 2023-01-31
*/

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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: ddscapigs.sol



pragma solidity ^0.8.0;



// DYNAMIC DECENTRALIZED SUPPLY CONTROL ALGORITHM
contract DDSCAPIGS is Ownable {

    IERC20 public token = IERC20(0x9a3321E1aCD3B9F6debEE5e042dD2411A1742002);

    uint256 public tokenPerBlock = 7500000000000000;
    uint256 public maxEmissionRate = 30000000000000000;
    uint256 public emissionStartBlock = 22686700;
    uint256 public emissionEndBlock = type(uint256).max;
    address public masterchef = 0x8536178222fC6Ec5fac49BbfeBd74CA3051c638f;
    bool public isUnderATL = false;
    bool public underATLemissions = false;
    // Dynamic emissions
    uint256 public topPriceInCents    = 22300;  // 8$
    uint256 public bottomPriceInCents = 5500;  // 1$
    uint256 public ATLChangePercent = 33;
    address allowedAddress;
    enum EmissionRate {SLOW, MEDIUM, FAST, FASTEST}
    EmissionRate public ActiveEmissionIndex = EmissionRate.SLOW;

    event UpdateDDSCAPriceRange(uint256 topPrice, uint256 bottomPrice);
    event updatedDDSCAMaxEmissionRate(uint256 maxEmissionRate);
    event SetFarmStartBlock(uint256 startBlock);
    event SetFarmEndBlock(uint256 endBlock);

    constructor() {
    }

    // Called externally by bot
    function checkIfUpdateIsNeededPre(uint256 priceInCents) external {
        require(msg.sender == allowedAddress);
        if(!underATLemissions){
            isUnderATL = priceInCents < bottomPriceInCents;
        }
    }

    function checkIfUpdateIsNeeded(uint256 priceInCents) public view returns(bool, EmissionRate) {
        EmissionRate _emissionRate;


        bool isOverATH = priceInCents > topPriceInCents;
        // if price is over ATH, set to fastest

        if (isOverATH){
            _emissionRate = EmissionRate.FASTEST;
        } else {
            _emissionRate = getEmissionStage(priceInCents);
        }
        
        if(isUnderATL && !underATLemissions){
            return(true, _emissionRate);
        }

        // No changes, no need to update
        if (_emissionRate == ActiveEmissionIndex){
            return(false, _emissionRate);
        }

        // Means its a downward movement, and it changed a stage
        if (_emissionRate < ActiveEmissionIndex){
            return(true, _emissionRate);
        }

        // Check if its a upward movement
        if (_emissionRate > ActiveEmissionIndex){
            if(underATLemissions && ActiveEmissionIndex == EmissionRate.SLOW){
                _emissionRate = EmissionRate(uint256(_emissionRate) - 1);
                return(true, _emissionRate);
            }

            uint256 athExtra = 0;
            if (isOverATH){
                athExtra = 1;
            }

            // Check if it moved up by two stages
            if ((uint256(_emissionRate) + athExtra) - uint256(ActiveEmissionIndex) >= 2){
                // price has moved 2 ranges from current, so update
                _emissionRate = EmissionRate(uint256(_emissionRate) + athExtra - 1 );
                return(true, _emissionRate);
            }
        }
        return(false, _emissionRate);

    }

    function updateEmissions(EmissionRate _newEmission) public {
        require(msg.sender ==  masterchef); 
        if(isUnderATL){
            isUnderATL = false;
            ActiveEmissionIndex = _newEmission;
            tokenPerBlock = (maxEmissionRate / 4) * (uint256(EmissionRate.SLOW) + 1);
            tokenPerBlock = ((tokenPerBlock * (100 - ATLChangePercent)) / 100);
            underATLemissions = true;
            return;
        }
        ActiveEmissionIndex = _newEmission;
        tokenPerBlock = (maxEmissionRate / 4) * (uint256(_newEmission) + 1);
        underATLemissions = false;
    }

    function setallowedAddress(address _allowedAddress) external onlyOwner {
        require(_allowedAddress != address(0), 'zero address');
        allowedAddress = _allowedAddress;
    }
    

    function getEmissionStage(uint256 _currentPriceCents) public view returns (EmissionRate){

        if (_currentPriceCents > topPriceInCents){
            return EmissionRate.FASTEST;
        }

        // Prevent function from underflowing when subtracting currentPriceCents - bottomPriceInCents
        if (_currentPriceCents < bottomPriceInCents){
            _currentPriceCents = bottomPriceInCents;
        }
        uint256 percentageChange = ((_currentPriceCents - bottomPriceInCents ) * 1000) / (topPriceInCents - bottomPriceInCents);
        percentageChange = 1000 - percentageChange;

        if (percentageChange <= 250){
            return EmissionRate.FASTEST;
        }
        if (percentageChange <= 500 && percentageChange > 250){
            return EmissionRate.FAST;
        }
        if (percentageChange <= 750 && percentageChange > 500){
            return EmissionRate.MEDIUM;
        }

        return EmissionRate.SLOW;
    }

    function setATLChangePercent(uint256 _percent) external onlyOwner {
        ATLChangePercent = _percent;
    }

    function updateDDSCAPriceRange(uint256 _topPrice, uint256 _bottomPrice) external onlyOwner {
        require(_topPrice > _bottomPrice, "top < bottom price");
        topPriceInCents = _topPrice;
        bottomPriceInCents = _bottomPrice;
        emit UpdateDDSCAPriceRange(topPriceInCents, bottomPriceInCents);
    }

    function updateDDSCAMaxEmissionRate(uint256 _maxEmissionRate) external onlyOwner {
        require(_maxEmissionRate > 0, "_maxEmissionRate !> 0");
        require(_maxEmissionRate <= 10 ether, "_maxEmissionRate !");
        maxEmissionRate = _maxEmissionRate;
        emit updatedDDSCAMaxEmissionRate(_maxEmissionRate);
    }

    function _setFarmStartBlock(uint256 _newStartBlock) external {
        require(msg.sender ==  masterchef); 
        require(_newStartBlock > block.number, "must be in the future");
        require(block.number < emissionStartBlock, "farm has already started");
        emissionStartBlock = _newStartBlock;
        emit SetFarmStartBlock(_newStartBlock);
    }

    function setFarmEndBlock(uint256 _newEndBlock) external onlyOwner {
        require(_newEndBlock > block.number, "must be in the future");
        emissionEndBlock = _newEndBlock;
        emit SetFarmEndBlock(_newEndBlock);
    }
    
    function updateMcAddress(address _mcAddress) external onlyOwner {
        masterchef = _mcAddress;
    }
}