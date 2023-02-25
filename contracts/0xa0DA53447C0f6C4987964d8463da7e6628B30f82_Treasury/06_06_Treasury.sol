// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IErrorsTokenomics.sol";
import "./interfaces/IOLAS.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IServiceRegistry.sol";
import "./interfaces/ITokenomics.sol";

/*
* In this contract we consider both ETH and OLAS tokens.
* For ETH tokens, there are currently about 121 million tokens.
* Even if the ETH inflation rate is 5% per year, it would take 130+ years to reach 2^96 - 1 of ETH total supply.
* Lately the inflation rate was lower and could actually be deflationary.
*
* For OLAS tokens, the initial numbers will be as follows:
*  - For the first 10 years there will be the cap of 1 billion (1e27) tokens;
*  - After 10 years, the inflation rate is capped at 2% per year.
* Starting from a year 11, the maximum number of tokens that can be reached per the year x is 1e27 * (1.02)^x.
* To make sure that a unit(n) does not overflow the total supply during the year x, we have to check that
* 2^n - 1 >= 1e27 * (1.02)^x. We limit n by 96, thus it would take 220+ years to reach that total supply.
*
* We then limit each time variable to last until the value of 2^32 - 1 in seconds.
* 2^32 - 1 gives 136+ years counted in seconds starting from the year 1970.
* Thus, this counter is safe until the year 2106.
*
* The number of blocks cannot be practically bigger than the number of seconds, since there is more than one second
* in a block. Thus, it is safe to assume that uint32 for the number of blocks is also sufficient.
*
* In conclusion, this contract is only safe to use until 2106.
*/

/// @title Treasury - Smart contract for managing OLAS Treasury
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
/// Invariant does not support a failing call() function while transferring ETH when using the CEI pattern:
/// revert TransferFailed(address(0), address(this), to, tokenAmount);
/// invariant {:msg "broken conservation law"} address(this).balance == ETHFromServices + ETHOwned;
contract Treasury is IErrorsTokenomics {
    event OwnerUpdated(address indexed owner);
    event TokenomicsUpdated(address indexed tokenomics);
    event DepositoryUpdated(address indexed depository);
    event DispenserUpdated(address indexed dispenser);
    event DepositTokenFromAccount(address indexed account, address indexed token, uint256 tokenAmount, uint256 olasAmount);
    event DonateToServicesETH(address indexed sender, uint256[] serviceIds, uint256[] amounts, uint256 donation);
    event Withdraw(address indexed token, address indexed to, uint256 tokenAmount);
    event EnableToken(address indexed token);
    event DisableToken(address indexed token);
    event ReceiveETH(address indexed sender, uint256 amount);
    event UpdateTreasuryBalances(uint256 ETHOwned, uint256 ETHFromServices);
    event PauseTreasury();
    event UnpauseTreasury();
    event MinAcceptedETHUpdated(uint256 amount);

    // A well-known representation of an ETH as address
    address public constant ETH_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // Owner address
    address public owner;
    // ETH received from services
    // Even if the ETH inflation rate is 5% per year, it would take 130+ years to reach 2^96 - 1 of ETH total supply
    uint96 public ETHFromServices;

    // OLAS token address
    address public olas;
    // ETH owned by treasury
    // Even if the ETH inflation rate is 5% per year, it would take 130+ years to reach 2^96 - 1 of ETH total supply
    uint96 public ETHOwned;

    // Tkenomics contract address
    address public tokenomics;
    // Minimum accepted donation value
    uint96 public minAcceptedETH = 0.065 ether;

    // Depository contract address
    address public depository;
    // Contract pausing
    uint8 public paused = 1;
    // Reentrancy lock
    uint8 internal _locked;
    
    // Dispenser contract address
    address public dispenser;

    // Token address => token reserves
    mapping(address => uint256) public mapTokenReserves;
    // Token address => enabled / disabled status
    mapping(address => bool) public mapEnabledTokens;

    /// @dev Treasury constructor.
    /// @param _olas OLAS token address.
    /// @param _tokenomics Tokenomics address.
    /// @param _depository Depository address.
    /// @param _dispenser Dispenser address.
    constructor(address _olas, address _tokenomics, address _depository, address _dispenser) payable {
        owner = msg.sender;
        _locked = 1;

        // Check for at least one zero contract address
        if (_olas == address(0) || _tokenomics == address(0) || _depository == address(0) || _dispenser == address(0)) {
            revert ZeroAddress();
        }

        olas = _olas;
        tokenomics = _tokenomics;
        depository = _depository;
        dispenser = _dispenser;

        // Assign an initial contract address ETH balance
        // If msg.value is passed in the constructor, it is already accounted for in the address balance
        // This way the balance also accounts for possible transfers before the contract was created
        ETHOwned = uint96(address(this).balance);
    }

    /// @dev Receives ETH.
    /// #if_succeeds {:msg "we do not touch the balance of developers" } old(ETHFromServices) == ETHFromServices;
    /// #if_succeeds {:msg "conservation law"} old(ETHOwned) + msg.value + old(ETHFromServices) <= type(uint96).max && ETHOwned == old(ETHOwned) + msg.value
    /// ==> address(this).balance == ETHFromServices + ETHOwned;
    /// #if_succeeds {:msg "any paused"} paused == 1 || paused == 2;
    receive() external payable {
        if (msg.value < minAcceptedETH) {
            revert LowerThan(msg.value, minAcceptedETH);
        }

        uint256 amount = ETHOwned;
        amount += msg.value;
        // Check for the overflow values, specifically when fuzzing, since practically these amounts are not realistic
        if (amount + ETHFromServices > type(uint96).max) {
            revert Overflow(amount, type(uint96).max);
        }
        ETHOwned = uint96(amount);
        emit ReceiveETH(msg.sender, msg.value);
    }

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Changes various managing contract addresses.
    /// @param _tokenomics Tokenomics address.
    /// @param _depository Depository address.
    /// @param _dispenser Dispenser address.
    function changeManagers(address _tokenomics, address _depository, address _dispenser) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Change Tokenomics contract address
        if (_tokenomics != address(0)) {
            tokenomics = _tokenomics;
            emit TokenomicsUpdated(_tokenomics);
        }
        // Change Depository contract address
        if (_depository != address(0)) {
            depository = _depository;
            emit DepositoryUpdated(_depository);
        }
        // Change Dispenser contract address
        if (_dispenser != address(0)) {
            dispenser = _dispenser;
            emit DispenserUpdated(_dispenser);
        }
    }

    /// @dev Changes minimum accepted ETH amount by the Treasury.
    /// @param _minAcceptedETH New minimum accepted ETH amount.
    /// #if_succeeds {:msg "Min accepted ETH"} minAcceptedETH > 0 && minAcceptedETH <= type(uint96).max;
    function changeMinAcceptedETH(uint256 _minAcceptedETH) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero value
        if (_minAcceptedETH == 0) {
            revert ZeroValue();
        }

        // Check for the overflow value
        if (_minAcceptedETH > type(uint96).max) {
            revert Overflow(_minAcceptedETH, type(uint96).max);
        }

        minAcceptedETH = uint96(_minAcceptedETH);
        emit MinAcceptedETHUpdated(_minAcceptedETH);
    }

    /// @dev Allows the depository to deposit LP tokens for OLAS.
    /// @notice Only depository contract can call this function.
    /// @param account Account address making a deposit of LP tokens for OLAS.
    /// @param tokenAmount Token amount to get OLAS for.
    /// @param token Token address.
    /// @param olasMintAmount Amount of OLAS token issued.
    /// #if_succeeds {:msg "we do not touch the total eth balance"} old(address(this).balance) == address(this).balance;
    /// #if_succeeds {:msg "any paused"} paused == 1 || paused == 2;
    /// #if_succeeds {:msg "OLAS balances"} IToken(olas).balanceOf(msg.sender) == old(IToken(olas).balanceOf(msg.sender)) + olasMintAmount;
    /// #if_succeeds {:msg "OLAS supply"} IToken(olas).totalSupply() == old(IToken(olas).totalSupply()) + olasMintAmount;
    function depositTokenForOLAS(address account, uint256 tokenAmount, address token, uint256 olasMintAmount) external {
        // Check for the depository access
        if (depository != msg.sender) {
            revert ManagerOnly(msg.sender, depository);
        }

        // Check if the token is authorized by the registry
        if (!mapEnabledTokens[token]) {
            revert UnauthorizedToken(token);
        }

        // Increase the amount of LP token reserves
        uint256 reserves = mapTokenReserves[token] + tokenAmount;
        mapTokenReserves[token] = reserves;

        // Uniswap allowance implementation does not revert with the accurate message, need to check before the transfer is engaged
        if (IToken(token).allowance(account, address(this)) < tokenAmount) {
            revert InsufficientAllowance(IToken(token).allowance((account), address(this)), tokenAmount);
        }

        // Transfer tokens from account to treasury and add to the token treasury reserves
        // We assume that authorized LP tokens in the protocol are safe as they are enabled via the governance
        // UniswapV2ERC20 realization has a standard transferFrom() function that returns a boolean value
        bool success = IToken(token).transferFrom(account, address(this), tokenAmount);
        if (!success) {
            revert TransferFailed(token, account, address(this), tokenAmount);
        }

        // Mint specified number of OLAS tokens corresponding to tokens bonding deposit
        // The olasMintAmount is guaranteed by the product supply limit, which is limited by the effectiveBond
        IOLAS(olas).mint(msg.sender, olasMintAmount);

        emit DepositTokenFromAccount(account, token, tokenAmount, olasMintAmount);
    }

    /// @dev Deposits service donations in ETH.
    /// @notice Each provided service Id must be deployed at least once, otherwise its components and agents are undefined.
    /// @notice If a specific service is terminated with agent Ids being updated, incentives will be issued to its old
    ///         configuration component / agent owners until the service is re-deployed when new agent Ids are accounted for.
    /// @param serviceIds Set of service Ids.
    /// @param amounts Set of corresponding amounts deposited on behalf of each service Id.
    /// #if_succeeds {:msg "we do not touch the owners balance"} old(ETHOwned) == ETHOwned;
    /// #if_succeeds {:msg "updated ETHFromServices"} old(ETHFromServices) + msg.value + old(ETHOwned) <= type(uint96).max && ETHFromServices == old(ETHFromServices) + msg.value
    /// ==> address(this).balance == ETHFromServices + ETHOwned;
    /// #if_succeeds {:msg "any paused"} paused == 1 || paused == 2;
    function depositServiceDonationsETH(uint256[] memory serviceIds, uint256[] memory amounts) external payable {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Check that the amount donated has at least a practical minimal value
        if (msg.value < minAcceptedETH) {
            revert LowerThan(msg.value, minAcceptedETH);
        }

        // Check for the same length of arrays
        uint256 numServices = serviceIds.length;
        if (amounts.length != numServices) {
            revert WrongArrayLength(numServices, amounts.length);
        }

        uint256 totalAmount;
        for (uint256 i = 0; i < numServices; ++i) {
            if (amounts[i] == 0) {
                revert ZeroValue();
            }
            totalAmount += amounts[i];
        }

        // Check if the total transferred amount corresponds to the sum of amounts from services
        if (msg.value != totalAmount) {
            revert WrongAmount(msg.value, totalAmount);
        }

        // Accumulate received donation from services
        uint256 donationETH = ETHFromServices + msg.value;
        // Check for the overflow values, specifically when fuzzing, since realistically these amounts are assumed to be not possible
        if (donationETH + ETHOwned > type(uint96).max) {
            revert Overflow(donationETH, type(uint96).max);
        }
        ETHFromServices = uint96(donationETH);
        emit DonateToServicesETH(msg.sender, serviceIds, amounts, msg.value);

        // Track service donations on the Tokenomics side
        ITokenomics(tokenomics).trackServiceDonations(msg.sender, serviceIds, amounts, msg.value);

        _locked = 1;
    }

    /// @dev Allows owner to transfer tokens from treasury reserves to a specified address.
    /// @param to Address to transfer funds to.
    /// @param tokenAmount Token amount to get reserves from.
    /// @param token Token or ETH address.
    /// @return success True if the transfer is successful.
    /// #if_succeeds {:msg "we do not touch the balance of developers"} old(ETHFromServices) == ETHFromServices;
    /// #if_succeeds {:msg "updated ETHOwned"} token == ETH_TOKEN_ADDRESS ==> ETHOwned == old(ETHOwned) - tokenAmount;
    /// #if_succeeds {:msg "ETH balance"} token == ETH_TOKEN_ADDRESS ==> address(this).balance == old(address(this).balance) - tokenAmount;
    /// #if_succeeds {:msg "updated token reserves"} token != ETH_TOKEN_ADDRESS ==> mapTokenReserves[token] == old(mapTokenReserves[token]) - tokenAmount;
    /// #if_succeeds {:msg "any paused"} paused == 1 || paused == 2;
    function withdraw(address to, uint256 tokenAmount, address token) external returns (bool success) {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check that the withdraw address is not treasury itself
        if (to == address(this)) {
            revert TransferFailed(token, address(this), to, tokenAmount);
        }

        // Check for the zero withdraw amount
        if (tokenAmount == 0) {
            revert ZeroValue();
        }

        // ETH address is taken separately, and all the LP tokens must be validated with corresponding token reserves
        if (token == ETH_TOKEN_ADDRESS) {
            uint256 amountOwned = ETHOwned;
            // Check if treasury has enough amount of owned ETH
            if (amountOwned >= tokenAmount) {
                // This branch is used to transfer ETH to a specified address
                amountOwned -= tokenAmount;
                ETHOwned = uint96(amountOwned);
                emit Withdraw(ETH_TOKEN_ADDRESS, to, tokenAmount);
                // Send ETH to the specified address
                (success, ) = to.call{value: tokenAmount}("");
                if (!success) {
                    revert TransferFailed(ETH_TOKEN_ADDRESS, address(this), to, tokenAmount);
                }
            } else {
                // Insufficient amount of treasury owned ETH
                revert LowerThan(tokenAmount, amountOwned);
            }
        } else {
            // Only approved token reserves can be used for redemptions
            if (!mapEnabledTokens[token]) {
                revert UnauthorizedToken(token);
            }
            // Decrease the global LP token reserves record
            uint256 reserves = mapTokenReserves[token];
            if (reserves >= tokenAmount) {
                reserves -= tokenAmount;
                mapTokenReserves[token] = reserves;

                emit Withdraw(token, to, tokenAmount);
                // Transfer LP tokens
                // We assume that LP tokens enabled in the protocol are safe by default
                // UniswapV2ERC20 realization has a standard transfer() function
                success = IToken(token).transfer(to, tokenAmount);
                if (!success) {
                    revert TransferFailed(token, address(this), to, tokenAmount);
                }
            }  else {
                // Insufficient amount of LP tokens
                revert LowerThan(tokenAmount, reserves);
            }
        }
    }

    /// @dev Withdraws ETH and / or OLAS amounts to the requested account address.
    /// @notice Only dispenser contract can call this function.
    /// @notice Reentrancy guard is on a dispenser side.
    /// @notice Zero account address is not possible, since the dispenser contract interacts with msg.sender.
    /// @param account Account address.
    /// @param accountRewards Amount of account rewards.
    /// @param accountTopUps Amount of account top-ups.
    /// @return success True if the function execution is successful.
    /// #if_succeeds {:msg "we do not touch the owners balance"} old(ETHOwned) == ETHOwned;
    /// #if_succeeds {:msg "updated ETHFromServices"} accountRewards > 0 && ETHFromServices >= accountRewards ==> ETHFromServices == old(ETHFromServices) - accountRewards;
    /// #if_succeeds {:msg "ETH balance"} accountRewards > 0 && ETHFromServices >= accountRewards ==> address(this).balance == old(address(this).balance) - accountRewards;
    /// #if_succeeds {:msg "updated OLAS balances"} accountTopUps > 0 ==> IToken(olas).balanceOf(account) == old(IToken(olas).balanceOf(account)) + accountTopUps;
    /// #if_succeeds {:msg "OLAS supply"} IToken(olas).totalSupply() == old(IToken(olas).totalSupply()) + accountTopUps;
    /// #if_succeeds {:msg "unpaused"} paused == 1;
    function withdrawToAccount(address account, uint256 accountRewards, uint256 accountTopUps) external
        returns (bool success)
    {
        // Check if the contract is paused
        if (paused == 2) {
            revert Paused();
        }

        // Check for the dispenser access
        if (dispenser != msg.sender) {
            revert ManagerOnly(msg.sender, dispenser);
        }

        uint256 amountETHFromServices = ETHFromServices;
        // Send ETH rewards, if any
        if (accountRewards > 0 && amountETHFromServices >= accountRewards) {
            amountETHFromServices -= accountRewards;
            ETHFromServices = uint96(amountETHFromServices);
            emit Withdraw(ETH_TOKEN_ADDRESS, account, accountRewards);
            (success, ) = account.call{value: accountRewards}("");
            if (!success) {
                revert TransferFailed(address(0), address(this), account, accountRewards);
            }
        }

        // Send OLAS top-ups
        if (accountTopUps > 0) {
            // Tokenomics has already accounted for the account's top-up amount,
            // thus the the mint does not break the inflation schedule
            IOLAS(olas).mint(account, accountTopUps);
            success = true;
            emit Withdraw(olas, account, accountTopUps);
        }
    }

    /// @dev Re-balances treasury funds to account for the treasury reward for a specific epoch.
    /// @param treasuryRewards Treasury rewards.
    /// @return success True, if the function execution is successful.
    /// #if_succeeds {:msg "we do not touch the total eth balance"} old(address(this).balance) == address(this).balance;
    /// #if_succeeds {:msg "conservation law"} old(ETHFromServices + ETHOwned) == ETHFromServices + ETHOwned;
    /// #if_succeeds {:msg "unpaused"} paused == 1;
    function rebalanceTreasury(uint256 treasuryRewards) external returns (bool success) {
        // Check if the contract is paused
        if (paused == 2) {
            revert Paused();
        }

        // Check for the tokenomics contract access
        if (msg.sender != tokenomics) {
            revert ManagerOnly(msg.sender, tokenomics);
        }

        // Collect treasury's own reward share
        success = true;
        if (treasuryRewards > 0) {
            uint256 amountETHFromServices = ETHFromServices;
            if (amountETHFromServices >= treasuryRewards) {
                // Update ETH from services value
                amountETHFromServices -= treasuryRewards;
                // Update treasury ETH owned values
                uint256 amountETHOwned = ETHOwned;
                amountETHOwned += treasuryRewards;
                // Assign back to state variables
                ETHOwned = uint96(amountETHOwned);
                ETHFromServices = uint96(amountETHFromServices);
                emit UpdateTreasuryBalances(amountETHOwned, amountETHFromServices);
            } else {
                // There is not enough amount from services to allocate to the treasury
                success = false;
            }
        }
    }

    /// @dev Drains slashed funds from the service registry.
    /// @return amount Drained amount.
    /// #if_succeeds {:msg "correct update total eth balance"} address(this).balance == old(address(this).balance) + amount;
    /// #if_succeeds {:msg "conservation law"} ETHFromServices + ETHOwned == old(ETHFromServices + ETHOwned) + amount;
    ///if_succeeds {:msg "slashed funds check"} IServiceRegistry(ITokenomics(tokenomics).serviceRegistry()).slashedFunds() >= minAcceptedETH
    /// ==> old(IServiceRegistry(ITokenomics(tokenomics).serviceRegistry()).slashedFunds()) == amount;
    function drainServiceSlashedFunds() external returns (uint256 amount) {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Get the service registry contract address
        address serviceRegistry = ITokenomics(tokenomics).serviceRegistry();

        // Check if the amount of slashed funds are at least the minimum required amount to receive by the Treasury
        uint256 slashedFunds = IServiceRegistry(serviceRegistry).slashedFunds();
        if (slashedFunds < minAcceptedETH) {
            revert LowerThan(slashedFunds, minAcceptedETH);
        }

        // Call the service registry drain function
        amount = IServiceRegistry(serviceRegistry).drain();
    }

    /// @dev Enables an LP token to be bonded for OLAS.
    /// @param token Token address.
    function enableToken(address token) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address token
        if (token == address(0)) {
            revert ZeroAddress();
        }

        // Authorize the token
        if (!mapEnabledTokens[token]) {
            mapEnabledTokens[token] = true;
            emit EnableToken(token);
        }
    }

    /// @dev Disables an LP token from the ability to bond for OLAS.
    /// @param token Token address.
    function disableToken(address token) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        if (mapEnabledTokens[token]) {
            // The reserves of a token must be zero in order to disable it
            if (mapTokenReserves[token] > 0) {
                revert NonZeroValue();
            }
            mapEnabledTokens[token] = false;
            emit DisableToken(token);
        }
    }

    /// @dev Gets information about token being enabled for bonding.
    /// @param token Token address.
    /// @return enabled True if token is enabled.
    function isEnabled(address token) external view returns (bool enabled) {
        enabled = mapEnabledTokens[token];
    }

    /// @dev Pauses the contract.
    function pause() external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        paused = 2;
        emit PauseTreasury();
    }

    /// @dev Unpauses the contract.
    function unpause() external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        paused = 1;
        emit UnpauseTreasury();
    }
}