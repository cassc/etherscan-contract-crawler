// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITokenSale.sol";

pragma solidity 0.8.17;

contract MarketingAndAdvisorsVesting is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    struct VestingProgram {
        uint256 startTime; // user vesting program start time timestamp
        uint256 endTime; // user vesting program end time timestamp
        uint256 cliffDuration; // cliff period duration in seconds
        uint256 duration; // vesting duration in seconds
        uint256 vestingAmount; // total vested amount
        uint256 totalActiveVested; // total active vested amount
        uint256 unvestedAmount; // total unvested amount
        uint256 startUnlockPercentage; // start unlock percentage
        uint256 unlockPercentage; // period unlock percentage
        uint256 periodDuration; // unlock period duration in seconds
        uint256 vestingType; // 0 - airdrop, 1 - advisors
        bool isEnded; // active vesting if true, if false vesting is end
    }

    struct User {
        uint256 lastUnvesting; // last  unvest timestamp
        uint256 totalVested; // total user vested amount
        uint256 totalUnvested; // total user unvested amount
        bool isGetStartUnlockAmount; // received or not received the initial unlocked funds
    }

    address public vestingToken; // planetex token address
    address public tokenSale; // tokenSale contract address
    uint256 public vestingProgramsCounter; // quantity of vesting programs
    uint256 public immutable PRECISSION = 10000; // precission for math operation
    bool public isInitialized = false; // if true, the contract is initialized, if false, then not

    mapping(uint256 => VestingProgram) public vestingPrograms; // return VestingProgram info (0 - airdrop, 1 - advisors)
    mapping(address => mapping(uint256 => User)) public userInfo; // return user info
    mapping(address => mapping(uint256 => bool)) public isVester; // bool if true then user is vesting member else not a member

    //// @errors

    //// @dev - cannot unvest 0;
    error ZeroAmountToUnvest(string err);
    //// @dev - cannot 0
    error ZeroAmount(string err);
    //// @dev - unequal length of arrays
    error InvalidArrayLengths(string err);
    /// @dev - user is not a member of the vesting program
    error NotVester(string err);
    //// @dev - vesting program is ended
    error VestingIsEnd(string err);
    //// @dev - vesting program not started
    error VestingNotStarted(string err);
    //// @dev - there is no vesting program with this id
    error VestingProgramNotFound(string err);
    //// @dev - address to the zero;
    error ZeroAddress(string err);
    //// @dev - not enough tokens in balance
    error TokensNotEnough(string err);
    //// @dev - user is not a vester
    error IsVester(string err);
    //// @dev - Cannot rescue 0;
    error RescueZeroValue(string err);
    //// @dev - cannot initialized contract again
    error ContractIsInited(string err);
    //// @dev - cannot call methods if contract not inited
    error ContractIsNotInited(string err);

    ////@notice emitted when the user has joined the vesting program
    event Vest(
        address indexed user,
        uint256 indexed vestAmount,
        uint256 indexed vestingProgramId
    );
    ////@notice emitted when the user gets ownership of the tokens
    event Unvest(
        address indexed user,
        uint256 indexed unvestedAmount,
        uint256 indexed vestingProgramId
    );
    /// @notice Transferring funds from the wallet еther of the selected token contract to the specified wallet
    event RescueToken(
        address indexed to,
        address indexed token,
        uint256 indexed amount
    );

    function initialize(
        address _vestingToken, // planetex token contract address
        address _tokenSale, // tokenSale contract address
        uint256[] memory _durations, // array of vesting durations in seconds
        uint256[] memory _cliffDurations, // array of cliff period durations in the seconds
        uint256[] memory _startUnlockPercentages, // array of start unlock percentages
        uint256[] memory _unlockPercentages, // array of unlock percentages every unlock period
        uint256[] memory _totalSupplyPercentages, // array of percentages of tokens from totalSupply
        uint256[] memory _vestingTypes, // array of vesting types. 0 - airdrop; 1 - advisors;
        uint256[] memory _periodDurations // array of unlock period durations in secconds
    ) external onlyOwner isInited {
        if (
            _durations.length != _cliffDurations.length ||
            _durations.length != _startUnlockPercentages.length ||
            _durations.length != _unlockPercentages.length ||
            _durations.length != _totalSupplyPercentages.length ||
            _durations.length != _vestingTypes.length ||
            _durations.length != _periodDurations.length
        ) {
            revert InvalidArrayLengths("Vesting: Invalid array lengths");
        }
        if (_vestingToken == address(0) || _tokenSale == address(0)) {
            revert ZeroAddress("Vesting: Zero address");
        }
        vestingToken = _vestingToken;
        uint256 totalSupply = IERC20(_vestingToken).totalSupply();
        for (uint256 i; i <= _durations.length - 1; i++) {
            VestingProgram storage vestingProgram = vestingPrograms[i];
            vestingProgram.duration = _durations[i];
            vestingProgram.startTime =
                ITokenSale(_tokenSale).getRoundStartTime(0) +
                _cliffDurations[i];
            vestingProgram.endTime = vestingProgram.startTime + _durations[i];
            vestingProgram.cliffDuration = _cliffDurations[i];
            vestingProgram.vestingAmount =
                (_totalSupplyPercentages[i] * totalSupply) /
                PRECISSION;
            vestingProgram.startUnlockPercentage = _startUnlockPercentages[i];
            vestingProgram.unlockPercentage = _unlockPercentages[i];
            vestingProgram.periodDuration = _periodDurations[i];
            vestingProgram.vestingType = _vestingTypes[i];
            vestingProgram.totalActiveVested = 0;
            vestingProgram.unvestedAmount = 0;
            vestingProgram.isEnded = false;
        }
        isInitialized = true;
        vestingProgramsCounter = _durations.length - 1;
    }

    /**
    @dev The modifier checks whether the vesting program has not expired.
    @param vestingId vesting program id.
    */
    modifier isEnded(uint256 vestingId) {
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];
        if (vestingId > vestingProgramsCounter) {
            revert VestingProgramNotFound("Vesting: Program not found");
        }
        if (vestingProgram.isEnded) {
            revert VestingIsEnd("Vesting: Vesting is end");
        }
        _;
    }

    /**
    @dev The modifier checks whether the contract has been initialized.
    Prevents reinitialization.
    */
    modifier isInited() {
        if (isInitialized) {
            revert ContractIsInited("Vesting: Already initialized");
        }
        _;
    }

    /**
    @dev The modifier checks if the contract has been initialized. 
    Prevents functions from being called before the contract is initialized.
    */
    modifier notInited() {
        if (!isInitialized) {
            revert ContractIsNotInited("Vesting: Not inited");
        }
        _;
    }

    //// External functions

    /**
    @dev the function adds a new user to the vesting program.
    Only owner can call it.
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    @param vestAmount user vest amount.
    */
    function vest(
        uint256 vestingId,
        address userAddress,
        uint256 vestAmount
    ) external notInited isEnded(vestingId) onlyOwner {
        _vest(vestingId, userAddress, vestAmount);
    }

    /**
    @dev the function adds a new user`s to the vesting program.
    Only owner can call it.
    @param vestingId vesting program id.
    @param userAddresses array of user wallet addresses.
    @param vestAmounts array of user vest amounts.
    */
    function vestUsers(
        uint256 vestingId,
        address[] memory userAddresses,
        uint256[] memory vestAmounts
    ) external notInited isEnded(vestingId) onlyOwner {
        if (userAddresses.length != vestAmounts.length) {
            revert InvalidArrayLengths("Vesting: Invalid array lengths");
        }
        for (uint256 i; i <= userAddresses.length - 1; i++) {
            _vest(vestingId, userAddresses[i], vestAmounts[i]);
        }
    }

    /**
    @dev The function withdraws unlocked funds for the specified user. 
    Anyone can call instead of the user.
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    */
    function unvestFor(uint256 vestingId, address userAddress)
        external
        notInited
        isEnded(vestingId)
    {
        _unvest(vestingId, userAddress);
    }

    /**
    @dev The function performs the withdrawal of unlocked funds.
    @param vestingId vesting program id.
    */
    function unvest(uint256 vestingId) external notInited isEnded(vestingId) {
        _unvest(vestingId, msg.sender);
    }

    /// @notice Transferring funds from the wallet of the selected token contract to the specified wallet
    /// @dev Used for the owner to withdraw funds
    /// @param to Address owner (Example)
    /// @param tokenAddress Token address from which tokens will be transferred
    /// @param amount Amount of transferred tokens
    function rescue(
        address to,
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0) || tokenAddress == address(0)) {
            revert ZeroAddress("Vesting: Cannot rescue to the zero address");
        }
        if (amount == 0) {
            revert RescueZeroValue("Vesting: Cannot rescue 0");
        }
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit RescueToken(to, address(tokenAddress), amount);
    }

    //// Public functions

    /**
    @dev The function calculates the available amount of funds 
    for unvest for a certain user.
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    @return unvestedAmount available amount of funds for unvest for a certain user.
    @return lastUserUnvesting timestamp when user do last unvest.
    @return totalUserUnvested the sum of all funds received user after unvest.
    @return totalUnvested the entire amount of funds of the vesting program that was withdrawn from vesting
    @return payStartUnlock indicates whether the starting unlocked funds have been received
    */
    function getUserUnvestedAmount(uint256 vestingId, address userAddress)
        public
        view
        notInited
        returns (
            uint256 unvestedAmount,
            uint256 lastUserUnvesting,
            uint256 totalUserUnvested,
            uint256 totalUnvested,
            bool payStartUnlock
        )
    {
        User storage user = userInfo[userAddress][vestingId];
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];

        if (!isVester[userAddress][vestingId]) {
            revert NotVester("SaleVesting: Not a vester");
        }

        if (block.timestamp < vestingProgram.startTime) {
            revert VestingNotStarted("Vesting: Not started");
        }

        if (block.timestamp < vestingProgram.endTime) {
            uint256 userVestingTime = block.timestamp - user.lastUnvesting;
            uint256 payouts = userVestingTime / vestingProgram.periodDuration;
            unvestedAmount =
                ((user.totalVested * vestingProgram.unlockPercentage) /
                    PRECISSION) *
                payouts;
            if (vestingProgram.startUnlockPercentage > 0) {
                if (!user.isGetStartUnlockAmount) {
                    unvestedAmount += ((user.totalVested *
                        vestingProgram.startUnlockPercentage) / PRECISSION);
                    payStartUnlock = true;
                }
            }
            lastUserUnvesting =
                user.lastUnvesting +
                (vestingProgram.periodDuration * payouts);
            totalUserUnvested = user.totalUnvested + unvestedAmount;
            totalUnvested = vestingProgram.unvestedAmount + unvestedAmount;
        } else {
            unvestedAmount = user.totalVested - user.totalUnvested;
            if (unvestedAmount > 0) {
                lastUserUnvesting = vestingProgram.endTime;
                totalUserUnvested = user.totalVested;
                totalUnvested = vestingProgram.unvestedAmount + unvestedAmount;
            }
        }
    }

    //// Internal functions

    /**
    @dev The function withdraws unlocked funds for the specified user. 
    Anyone can call instead of the user.
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    */
    function _unvest(uint256 vestingId, address userAddress) internal {
        if (userAddress == address(0)) {
            revert ZeroAddress("Vesting: Zero address");
        }
        if (!isVester[userAddress][vestingId]) {
            revert NotVester("Vesting: Not a vester");
        }
        User storage user = userInfo[userAddress][vestingId];
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];

        if (block.timestamp < vestingProgram.startTime) {
            revert VestingNotStarted("Vesting: Not started");
        }

        if (
            vestingProgram.unvestedAmount == vestingProgram.vestingAmount ||
            user.totalVested == user.totalUnvested
        ) {
            revert VestingIsEnd("Vesting: Vesting is end");
        }

        (
            uint256 unvestedAmount,
            uint256 lastUserUnvesting,
            uint256 totalUserUnvested,
            uint256 totalUnvested,
            bool payStartUnlock
        ) = getUserUnvestedAmount(vestingId, userAddress);

        if (!user.isGetStartUnlockAmount) {
            user.isGetStartUnlockAmount = payStartUnlock;
        }

        user.lastUnvesting = lastUserUnvesting;
        user.totalUnvested = totalUserUnvested;

        if (unvestedAmount == 0) {
            revert ZeroAmountToUnvest("Vesting: Zero unvest amount");
        } else {
            if (
                unvestedAmount + vestingProgram.unvestedAmount >=
                vestingProgram.vestingAmount
            ) {
                unvestedAmount =
                    vestingProgram.vestingAmount -
                    vestingProgram.unvestedAmount;
            }
            vestingProgram.unvestedAmount = totalUnvested;
            IERC20(vestingToken).safeTransfer(userAddress, unvestedAmount);
            emit Unvest(userAddress, unvestedAmount, vestingId);
        }

        if (vestingProgram.unvestedAmount == vestingProgram.vestingAmount) {
            vestingProgram.isEnded = true;
        }
    }

    /**
    @dev the function adds a new user to the vesting program.
    Only owner can call it.
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    @param vestAmount user vest amount.
    */
    function _vest(
        uint256 vestingId,
        address userAddress,
        uint256 vestAmount
    ) internal {
        User storage user = userInfo[userAddress][vestingId];
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];
        if (
            vestAmount >
            vestingProgram.vestingAmount - vestingProgram.totalActiveVested
        ) {
            revert TokensNotEnough("Vesting: Tokens not enough");
        }
        if (userAddress == address(0)) {
            revert ZeroAddress("Vesting: Zero address");
        }
        if (vestAmount == 0) {
            revert ZeroAmount("Vesting: Zero amount");
        }
        if (isVester[userAddress][vestingId]) {
            revert IsVester("Vesting: Already in vesting");
        }
        isVester[userAddress][vestingId] = true;
        vestingProgram.totalActiveVested += vestAmount;
        user.totalVested = vestAmount;
        user.totalUnvested = 0;
        user.lastUnvesting = vestingProgram.startTime;
        user.isGetStartUnlockAmount = false;
        emit Vest(userAddress, vestAmount, vestingId);
    }
}