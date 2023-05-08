/**
 *Submitted for verification at BscScan.com on 2023-05-07
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

// File: Wager.sol


pragma solidity ^0.8.0;




contract OracleWhitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "not whitelisted");
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return success = true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }


    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return success = true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

}


contract PeerToPeerBet is ReentrancyGuard, OracleWhitelist {

    struct Bet {
        // string bet;
        address payable party1;
        address payable party2;
        address oracle;
        uint256 amount;
        uint256 fee;
        bool finalized;
        bool resolved;
        bool collected;
        bool[2] selfDirected;
        address payable winner;
        address oracleProposedBy;
    }

    event NewBet(uint256 indexed id, address indexed party1, address indexed party2, uint256 amount, address oracle);
    event BetResolved(uint256 indexed id, address winner, uint256 amount);
    event ILost(uint256 indexed id, address loser);
    event OracleProposed(uint256 indexed id, address proposer, address oracle);

    uint256 public currentBetId;
    mapping (uint256 => Bet) public bets;
    mapping (uint256 => string) public betString;

    uint256 public feePercentage = 1;
    address public LWIToken;

    constructor() {
        currentBetId = 0;
        LWIToken = 0xf571f1D93cAF35527E35403aDDB26d27F2deFe4A;
    }

    function createBet(string memory _bet, bool _selfDirected) external payable {
        require(msg.value >  10**16, "Bet amount must be greater than 0.");

        if (_selfDirected) {
            require(msg.value <= 10**17, "Bets without oracles must be less than 0.1 BNB.");
        }
        
        //Dev Fee
        uint256 fee = 0;
        fee = msg.value * feePercentage / 100;

        payable(owner()).transfer(fee);

        Bet memory bet = Bet({
            party1: payable(msg.sender),
            party2: payable(address(0)),
            oracle: address(0),
            amount: msg.value,
            fee: fee,
            finalized: false,
            resolved: false,
            collected: false,
            selfDirected:[_selfDirected, false],
            winner: payable(address(0)),
            oracleProposedBy: payable(address(0))
        });
        bets[currentBetId] = bet;
        betString[currentBetId]= _bet;
        emit NewBet(currentBetId, msg.sender, address(0), msg.value, address(0));
        currentBetId++;
    }

    function joinBet(uint256 betId) external payable {
        Bet storage bet = bets[betId];
        require(!bet.resolved, "Bet has already been resolved.");
        require(bet.party2 == address(0), "Bet is already full.");
        require(msg.sender != bet.party1, "Cannot enter a bet with yourself.");

       
        require(msg.value == bet.amount, "BNB amount must match the bet amount.");

        //Dev Fee
        uint256 fee = 0;
        fee = bet.amount * feePercentage / 100;

        payable(owner()).transfer(fee);
        
        bet.party2 = payable(msg.sender);
        emit    NewBet(betId, bet.party1, address(0), bet.amount, address(0));
    }

    function proposeOracle(uint256 betId, address oracle) external {
        Bet storage bet = bets[betId];
        require(!bet.resolved, "Bet has already been resolved.");
        require(!bet.finalized, "Oracle has already been assigned.");
        require(bet.party1 == msg.sender || bet.party2 == msg.sender, "Only the parties can propose a oracle.");
        require(oracle != address(0) && oracle != bet.party1 && oracle != bet.party2, "Invalid oracle address.");
        require(whitelist[oracle], "Oracle address not whitelisted");
        bet.oracle = oracle;
        bet.oracleProposedBy = msg.sender;
        
        emit OracleProposed(betId, msg.sender, oracle);
    }


    function approveOracle(uint256 betId, address _oracle) external {
        Bet storage bet = bets[betId];
        require(!bet.resolved, "Bet has already been resolved.");
        require(!bet.finalized, "Oracle has already been assigned.");
        require(bet.party1 == msg.sender || bet.party2 == msg.sender, "Only the parties can assign a oracle.");
        require(bet.oracleProposedBy != msg.sender, "The same player cannot propose and assign the oracle.");
        require(bet.oracle == _oracle, "The oracle assigned must be the same as the one proposed to finalize bet.");
        require(_oracle != address(0) && _oracle != bet.party1 && _oracle != bet.party2, "Invalid oracle address.");

        // bet.oracle = oracle;
        bet.finalized = true;
        emit NewBet(betId, bet.party1, bet.party2, bet.amount, bet.oracle);
    }

    function readyUp(uint256 betId) external {
        Bet storage bet = bets[betId];
        require(bet.party1 == msg.sender || bet.party2 == msg.sender, "Only the parties can ready up.");
        require(!bet.finalized, "Bet has already been finalized and locked!");
        if (bet.selfDirected[0] == true && msg.sender == bet.party2) {
            bet.selfDirected[1] = true;
            bet.finalized = true;
        } else if (bet.selfDirected[1] == true && msg.sender == bet.party1){
            bet.selfDirected[0] = true;
            bet.finalized = true;
        } else if (msg.sender == bet.party1){
            bet.selfDirected[0] = true;
        } else if (msg.sender == bet.party2){
            bet.selfDirected[1] = true;
        }

    }

    function iLost(uint256 betId) external {
        Bet storage bet = bets[betId];
        require(bet.finalized, "Bet has not been finalized. Ready up or assign an oracle");
        require(!bet.resolved, "Bet has already been resolved!");
        require(bet.party1 == msg.sender || bet.party2 == msg.sender, "Only one of the parties can say if they lost.");
        address _winner = address(0);
        if (bet.party1 == msg.sender) {
            _winner = bet.party2;
        } else{
            _winner = bet.party1;
        }

        bet.resolved = true;
        bet.winner = payable(_winner);
        uint256 amount = (bet.amount - bet.fee) * 2;

        emit BetResolved(betId, _winner, amount); //Celebrate!
        emit ILost(betId, msg.sender);

    }

    function transferToken(address _token, uint256 _amount, address _to) internal {
		IERC20(_token).transfer(_to, _amount);
	}

    function transferStuckToken(address _token, uint256 _amount, address _to) external onlyOwner {
		IERC20(_token).transfer(_to, _amount);
	}

    function calculateOracleReward(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this)) / 10000;
    }

    function resolveBet(uint256 betId, address _winner) external onlyWhitelisted {
        Bet storage bet = bets[betId];
        require(!bet.resolved, "Bet has already been resolved.");
        require(msg.sender == bet.oracle, "Only the oracle can resolve the bet.");

        bet.resolved = true;
        bet.winner = payable(_winner);
        uint256 amount = (bet.amount - bet.fee) * 2;
    
        emit BetResolved(betId, _winner, amount); //Celebrate!

        transferToken(LWIToken, calculateOracleReward(LWIToken), bet.oracle);

    }


    function getParticipantBets(address partyAddress) external view returns (uint256[] memory) {
        uint256[] memory betIds = new uint256[](currentBetId);
        uint256 count = 0;
        for (uint256 i = 0; i < currentBetId; i++) {
            Bet storage bet = bets[i];
            if (bet.party1 == partyAddress || bet.party2 == partyAddress) {
                betIds[count] = i;
                count++;
            }
        }

        uint256[] memory filteredBetIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredBetIds[i] = betIds[i];
        }

        return filteredBetIds;
    }

    function getOracleBets(address oracleAddress) external view returns (uint256[] memory) {
        uint256[] memory betIds = new uint256[](currentBetId);
        uint256 count = 0;
        for (uint256 i = 0; i < currentBetId; i++) {
            Bet storage bet = bets[i];
            if (bet.oracle == oracleAddress) {
                betIds[count] = i;
                count++;
            }
        }

        uint256[] memory filteredBetIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredBetIds[i] = betIds[i];
        }

        return filteredBetIds;
    }

    function withdrawBNBFromBet(uint256 betId) external nonReentrant  {
        Bet storage bet = bets[betId];
        require(!bet.collected, "Bet has already been collected.");
        require((msg.sender == bet.party1 || msg.sender == bet.party2), "Must be in bet to withdraw.");

        require(!(bet.finalized && !bet.resolved), "Bet has not been resolved.");
        uint amount = bet.amount - bet.fee;
        if (!bet.finalized) {
            require(address(this).balance >= amount, "Insufficient contract balance1.");
            payable(msg.sender).transfer(amount);

            if (bet.party2 != payable(address(0))){
                require(address(this).balance >= amount, "Insufficient contract balance2.");
                payable(bet.party2).transfer(amount);
            }
            string memory currentBetString = betString[currentBetId];
            bet.amount = 0;
            bet.party1 = payable(address(0));
            bet.party2 = payable(address(0));
            if (payable(msg.sender) == bet.party1) {
                betString[currentBetId] = string.concat("CANCELLED BY Party1", currentBetString);
            } else {
                betString[currentBetId] = string.concat("CANCELLED BY Party2", currentBetString);
            }
        }

        if (bet.resolved) {
            require(msg.sender == bet.winner, "You did not win this bet.");
            require(address(this).balance >= amount*2, "Insufficient contract balance.");
            payable(msg.sender).transfer(amount*2);
            bet.collected = true;
        } 
        

    }

    function ownerCancelBet(uint256 betId) external onlyOwner nonReentrant {
        Bet storage bet = bets[betId];
        require(!bet.collected, "Bet has already been collected.");
        uint amount = bet.amount - bet.fee;
        require(address(this).balance >= amount, "Insufficient contract balance1.");
        payable(bet.party1).transfer(amount);

        if (bet.party2 != payable(address(0))){
            require(address(this).balance >= amount, "Insufficient contract balance2.");
            payable(bet.party2).transfer(amount);
        }
        string memory currentBetString = betString[currentBetId];
        bet.amount = 0;
        bet.party1 = payable(address(0));
        bet.party2 = payable(address(0));
        betString[currentBetId] = string.concat("CANCELLED BY OWNER", currentBetString);
            
    }

}