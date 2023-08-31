// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.1;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract HopeExchange is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Address of Hope
    address public hope;

    // Fee charged for each swap of Grave Yard
    uint256 public fee; 

    // Flag to disable swapping and claiming
    bool public isPaused; 
    
    // Balance of Hope for each user
    mapping(address => UserBalances) public balances;

    // Mapping of Grave Yard variants to their addresses
    mapping(address => GraveYard) public graveYards;

    // Struct of Grave yard details
    struct GraveYard {
        address variantAddress;
        uint256 exchangeRate;
        uint256 vestingSchedule;
        uint256 distributedAmount;
        uint256 graveYardMaxHope;
        uint256 maxHopePerUser;
    }
 
    // Struct of User balances
    struct UserBalances {
        bool isSuspended;
        uint256 balance;
        uint256 claimedAmount;
        uint256 vestingSchedule;
        uint256 vestingStartTime;
        uint256 lastClaimTime;
        mapping(address => uint256) graveYardDistribution;
    }

    // Event triggered when a user swaps Grave Yard
    event Swap(address indexed user, address variant, uint256 amount);

    // Event triggered when a user claims their vested Hope
    event Claim(address indexed user, uint256 amount);

    // Event triggered when a Grave Yard variant is added
    event GraveYardAdded(
        address indexed graveYard,
        uint256 exchangeRate,
        uint256 vestingSchedule
    );

    // Event triggered when a Grave Yard variant is updated
    event GraveYardUpdated(
        address indexed graveYard,
        uint256 exchangeRate,
        uint256 vestingSchedule
    );

    // Event triggered when a Grave Yard variant is removed
    event GraveYardRemoved(
        address indexed graveYard 
    );


    constructor(
        address _hope,
        uint256 _fee,  
        bool _isPaused
    ) {
        hope = _hope;
        fee = _fee;  
        isPaused = _isPaused;
    }

    /**
     * @dev Modifier to check if swapping and claiming are not paused.
     */
    modifier notPaused() {
        require(!isPaused, "Swapping and claiming are paused");
        _;
    }

    /**
     * @dev Swap Grave Yard and receive Hope in return
     */
    function swap(address variant, uint256 amount) external payable notPaused {
        GraveYard storage graveYard = graveYards[variant];
        IERC20 variantToken = IERC20(graveYard.variantAddress);
        require(
            graveYard.variantAddress != address(0),
            "Variant does not exist"
        );
        require(
            variantToken.balanceOf(msg.sender) >= amount,
            "Not enough balance"
        );

        variantToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 exchangeRate = graveYard.exchangeRate;
        uint256 graveYardDecimals = ERC20(graveYard.variantAddress).decimals();
        uint256 hopeDecimals = ERC20(hope).decimals();
        uint256 graveYardAmount = amount.mul(10**hopeDecimals).div( 10**graveYardDecimals );
        uint256 hopeReceived = graveYardAmount.mul(exchangeRate).div( 10**hopeDecimals );

        UserBalances storage userBalance = balances[msg.sender];
        require( userBalance.graveYardDistribution[variant].add(hopeReceived) <= graveYard.maxHopePerUser, "User balance exceeds to graveYardDistribution value" );
        require( graveYard.distributedAmount.add(hopeReceived) <= graveYard.graveYardMaxHope, "Hope amount exceeds to graveYardMaxHope amount" );
        require( userBalance.isSuspended == false, "Address is suspended"); 

        uint256 vestedAmount = getVestedAmount(msg.sender);
        userBalance.balance = userBalance.balance.add(hopeReceived);
        userBalance.vestingStartTime = block.timestamp;
        userBalance.lastClaimTime = block.timestamp;
        userBalance.graveYardDistribution[variant] = userBalance.graveYardDistribution[variant].add(hopeReceived);
        graveYard.distributedAmount = graveYard.distributedAmount.add(hopeReceived);
        if (fee > 0) {
            require(msg.value >= fee, "Insufficient balance to cover the fee");
        }
        if (graveYard.vestingSchedule > userBalance.vestingSchedule) {
            userBalance.vestingSchedule = graveYard.vestingSchedule;
        }
        if (vestedAmount > 0) {
            userBalance.balance = userBalance.balance.sub(vestedAmount);
            userBalance.claimedAmount = userBalance.claimedAmount.add(
                vestedAmount
            );
            IERC20(hope).safeTransfer(msg.sender, vestedAmount);
            emit Claim(msg.sender, vestedAmount);
        }

        emit Swap(msg.sender, variant, amount);
    }

    /**
     * @dev Claim vested Hope
     */
    function claim() external notPaused {
        UserBalances storage userBalance = balances[msg.sender];
        uint256 vestedAmount = getVestedAmount(msg.sender);
        require(vestedAmount > 0, "No vested amount to claim");
        require( userBalance.isSuspended == false, "Address is suspended");

        userBalance.balance = userBalance.balance.sub(vestedAmount);
        userBalance.claimedAmount = userBalance.claimedAmount.add(vestedAmount);
        userBalance.lastClaimTime = block.timestamp;

        IERC20(hope).safeTransfer(msg.sender, vestedAmount);
        emit Claim(msg.sender, vestedAmount);
    }


    /**
     * @dev Returns the amount of Hope distributed from a specific Grave Yard to the user address. 
     */
    function graveYardDistribution(address _user, address _graveYard) external view returns (uint256) {
        return balances[_user].graveYardDistribution[_graveYard];
    }

    /**
     * @dev Calculate vested amount of Hope for a user
     */
    function getVestedAmount(address user) public view returns (uint256) {
        UserBalances storage userBalance = balances[user];
        uint256 vestingSchedule = userBalance.vestingSchedule;
        uint256 userBalanceAmount = userBalance.balance;

        if (vestingSchedule > 0 && userBalanceAmount > 0) {
            uint256 vestingStartTime = userBalance.lastClaimTime;
            uint256 currentTime = block.timestamp;

            if (currentTime > vestingStartTime.add(vestingSchedule)) {
                return userBalanceAmount;
            } else {
                uint256 timeElapsed = currentTime.sub(vestingStartTime);
                return userBalanceAmount.mul(timeElapsed).div(vestingSchedule);
            }
        }
        return 0;
    }

    // Withdraws all the Token stored in this contract to the owner's address.
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Withdraws a specified token from this contract to the owner's address.
    function withdrawToken(address token) external onlyOwner {
        IERC20 tokenInstance = IERC20(token);
        uint256 balance = tokenInstance.balanceOf(address(this));
        tokenInstance.safeTransfer(owner(), balance);
    }

    /**
     * @dev Allows the owner to add a new variant of Grave Yard to the contract.
     */
    function addGraveYard(
        address _graveYard,
        uint256 _exchangeRate,
        uint256 _vestingSchedule,
        uint256 _graveYardMaxHope,
        uint256 _maxHopePerUser
    ) external onlyOwner {
        require( _graveYard != address(hope), "Grave Yard variant cannot be the same as Hope" );
        require( graveYards[_graveYard].variantAddress == address(0), "Grave Yard variant already exists" ); 

        graveYards[_graveYard] = GraveYard({
            variantAddress: _graveYard,
            exchangeRate: _exchangeRate,
            vestingSchedule: _vestingSchedule,
            graveYardMaxHope: _graveYardMaxHope,
            maxHopePerUser: _maxHopePerUser,
            distributedAmount: 0
        });
        emit GraveYardAdded(_graveYard, _exchangeRate, _vestingSchedule);
    }

    /**
     * @dev Allows the owner to update the exchange rate and vesting schedule of a Grave Yard variant.
     */
    function updateGraveYard(
        address _graveYard,
        uint256 _exchangeRate,
        uint256 _vestingSchedule,
        uint256 _graveYardMaxHope,
        uint256 _maxHopePerUser
    ) external onlyOwner { 
        require( graveYards[_graveYard].variantAddress != address(0), "Grave Yard variant does not exist" ); 

        graveYards[_graveYard].exchangeRate = _exchangeRate;
        graveYards[_graveYard].vestingSchedule = _vestingSchedule;
        graveYards[_graveYard].graveYardMaxHope = _graveYardMaxHope;
        graveYards[_graveYard].maxHopePerUser = _maxHopePerUser;
        emit GraveYardUpdated(_graveYard, _exchangeRate, _vestingSchedule);
    }
      

    /**
     * @dev Allows the owner to remove a Grave Yard variant from the contract.
     */
    function removeGraveYard(address graveYard) external onlyOwner {
        require( graveYards[graveYard].variantAddress != address(0), "Grave Yard variant does not exist" );
        delete graveYards[graveYard]; 
        emit GraveYardRemoved(graveYard);
    }

    /**
     * @dev Suspends a specific user by address. 
     */
    function suspendUser( address _address, bool _isSuspended) external onlyOwner {
       balances[_address].isSuspended = _isSuspended;  
    } 

    /**
     * @dev Updates the fee for each swap.
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
 
 
}
