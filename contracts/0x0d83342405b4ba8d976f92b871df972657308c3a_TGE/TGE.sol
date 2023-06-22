/**
 *Submitted for verification at Etherscan.io on 2023-06-16
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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: Vesting.sol


// Creator: andreitoma8
pragma solidity ^0.8.4;

/**
 * @title ITransfer
 * @dev Contract interface for transfer functions.
 */
interface ITransfer {
    /**
     * @notice Transfers a specific amount of tokens to the provided address.
     * @param recipient The address to receive the tokens.
     * @param amount The amount of tokens to transfer.
     * @return true if the operation is successful, false otherwise.
     */
    function transfer(address recipient, uint amount) external returns (bool);
}



error ContractIsEnabled(bool);

/**
 * @title TGE
 * @dev Token allocation and fund release contract
 * @author Soulprime team
 */
contract TGE is Ownable, ReentrancyGuard {

    ITransfer public soulPrimeToken;

    bool public isEnabled;
    uint public startTime; 

    uint[3]  vestingAmountsPrivateSale = [uint(13_750_000 ether), uint(22_000_000 ether), uint(11_000_000 ether)];
    uint[3]  vestingDurationsPrivateSale = [90 days, 180 days, 210 days];

    uint cliffDurationWithdraw = 365 days;
    uint monthlyDurationWithdraw = 30 days;

    uint vestingAmountDevelopment = 1_312_500 ether;
    uint vestingAmountPartners = 937_500 ether;
    uint vestingAmountTeam = 1_171_875 ether;

    address public ecosystemWallet = 0x2781266444a12a20884523bdeB39a877f4418A9B; // Multisig directed to the ecosystem fund;
    address public publicSaleWallet = 0x1b9fD43fEcE39aC0E9C99451F9cb46D07Db2Bf81; // Multisig directed to the public sale fund;
    address public liquidityMMWallet = 0x19E19311034aBd58A50A26Af867686D9BD9c797c; // Multisig directed to the market maker funds;
    address public teamWallet = 0x6CAa7Dd9Cac45795681A9c4B0D5e612a9B37bD5b; // Multisig directed to the team fund;
    address public privateSaleWallet = 0xB9286cc566f1f5a469A4f0903cf7aA45CC9b1774; // Multisig directed to the private sale fund;
    address public developmentWallet = 0x7378BC2A7a2D97d8232a96B2A279Befaa24451dE; // Multisig directed to the development fund;
    address public marketingWallet = 0xf7a69d77e404027A0cF7e9C3A3f56D5992752462; // Multisig directed to the marketing fund;
    address public partnersWallet = 0x7791556F051e7fDFb3692d54D0b54a4410099c09; // Multisig directed to the partners fund;

    event contractStarted(uint timestamp); 
    event tokensWithdrawed(address wallet, uint amount);


    mapping(address => uint) public walletToVestingCounter; 

    /**
     * @dev Ensures that the contract is activated.
     */
    modifier isContractEnabled() {
        if (!isEnabled) { 
        revert ContractIsEnabled(isEnabled);
        }
        _;  
    }

    /**
     * @notice Initializes the contract and initially distributes the tokens.
     * @dev Only the owner can call this function.
     * @param _address Address of the ERC20 contract.
     */
    function startContract(address _address) public onlyOwner {
        if (isEnabled) {
            {revert ContractIsEnabled(isEnabled);}
        }
        soulPrimeToken = ITransfer(_address);
        isEnabled = true;
        startTime = block.timestamp;

        _initialTokenDistribution();

        emit contractStarted(startTime);
    }

    /**
     * @dev Performs the initial distribution of tokens.
     */
    function _initialTokenDistribution() private { 
        uint[8] memory tokenAmounts = [
            uint(140_000_000 ether),
            uint(95_000_000 ether),
            uint(60_000_000 ether),
            uint(18_750_000 ether),
            uint(8_250_000 ether),
            uint(8_750_000 ether),
            uint(6_250_000 ether),
            uint(15_000_000 ether)
        ];        
        address[8] memory wallets = [ecosystemWallet, publicSaleWallet, liquidityMMWallet, teamWallet, privateSaleWallet, developmentWallet, partnersWallet, marketingWallet];

        for (uint i = 0; i < wallets.length; i++) {
            soulPrimeToken.transfer(wallets[i], tokenAmounts[i]);
        }
    }

    /**
     * @notice Withdraws tokens from private sale
     * @dev This function is protected against reentrancy
     */
    function withdrawPrivateSaleTokens() public nonReentrant isContractEnabled {
        if(walletToVestingCounter[privateSaleWallet] == 3) {
            revert("All tokens related to this fund have been minted");
        }

        _withdrawVestedTokens(privateSaleWallet, vestingAmountsPrivateSale, vestingDurationsPrivateSale);
    }

    /**
     * @notice Withdraws tokens from development
     * @dev This function is protected against reentrancy
     */
    function withdrawDevelopmentTokens() public nonReentrant isContractEnabled {
        if(walletToVestingCounter[developmentWallet] == 20) {
            revert("All tokens related to this fund have been minted");
        }

        _withdrawVestedTokensWithCliff(developmentWallet, vestingAmountDevelopment, cliffDurationWithdraw, monthlyDurationWithdraw);
    }

    /**
     * @notice Withdraws tokens from partners
     * @dev This function is protected against reentrancy
     */
    function withdrawPartnersTokens() public nonReentrant isContractEnabled {
        if(walletToVestingCounter[partnersWallet] == 20) {
            revert("All tokens related to this fund have been minted");
        }

        _withdrawVestedTokensWithCliff(partnersWallet, vestingAmountPartners, cliffDurationWithdraw, monthlyDurationWithdraw);
    }

     /**
     * @notice Withdraws tokens from the team - after the contract initialization, it withdraws the amount of tokens monthly
     * @dev This function is protected against reentrancy
     */
    function withdrawTeamTokens() public nonReentrant isContractEnabled {
        if(walletToVestingCounter[partnersWallet] == 48) {
            revert("All tokens related to this fund have been minted");
        }

        _withdrawVestedTokensWithCliff(teamWallet, vestingAmountTeam, monthlyDurationWithdraw, monthlyDurationWithdraw);
    }

    /**
     * @dev Withdraws acquired tokens
     * @param wallet Destination wallet address
     * @param amounts Amounts for vesting periods
     * @param durations Durations of vesting periods
     */
    function _withdrawVestedTokens(address wallet, uint[3] memory amounts, uint[3] memory durations) private {
        uint currentVesting = walletToVestingCounter[wallet];

        if (startTime + durations[currentVesting] <= block.timestamp) {
            walletToVestingCounter[wallet] = currentVesting + 1;
            bool sent = soulPrimeToken.transfer(wallet, amounts[currentVesting]);
            if(!sent) {
                revert("Failed to transfer");
            }
            emit tokensWithdrawed(wallet, amounts[currentVesting]);
        } else {
            revert("Funds not yet released");
        }
    }

    /**
     * @dev Withdraws acquired tokens with a lock-up period (cliff)
     * @param wallet Destination wallet address
     * @param amount Token amount
     * @param cliffDuration Duration of the lock-up period
     * @param monthlyDuration Monthly duration after the lock-up period
     */
    function _withdrawVestedTokensWithCliff(address wallet, uint amount, uint cliffDuration, uint monthlyDuration) private {
        uint currentVesting = walletToVestingCounter[wallet];

        if (startTime + cliffDuration + (currentVesting * monthlyDuration) <= block.timestamp) {
            walletToVestingCounter[wallet] = currentVesting + 1;
            bool sent = soulPrimeToken.transfer(wallet, amount);
            if(!sent) {
                revert("Failed to transfer");
            }        
            emit tokensWithdrawed(wallet, amount);
        } else {
            revert("Funds not yet released");
        }
    }
 
}