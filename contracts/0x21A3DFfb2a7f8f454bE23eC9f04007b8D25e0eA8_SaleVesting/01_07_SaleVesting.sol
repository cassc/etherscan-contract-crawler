// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITokenSale.sol";

pragma solidity 0.8.17;

contract SaleVesting is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    struct VestingProgram {
        uint256 startTime; // vesting start time timestamp
        uint256 endTime; // vesting end time timestamp
        uint256 cliffDuration; // cliff period duration in seconds
        uint256 duration; // vesting duration in seconds
        uint256 vestingAmount; // total vested amount
        uint256 unvestedAmount; // total unvested amount
        uint256 startUnlockPercentage; // start unlock percentage
        uint256 unlockPercentage; // period unlock percentage
        uint256 periodDuration; // unlock period duration in seconds
        uint256 vestingType; // 0 - presale, 1 - mainsale, 2 - private-sale
        bool isEnded; // active vesting if true, if false vesting is end
    }

    struct User {
        uint256 lastUnvesting; // last  unvest timestamp
        uint256 totalVested; // total user vested amount
        uint256 totalUnvested; // total user unvested amount
        bool isGetStartUnlockAmount; // received or not received the initial unlocked funds
    }

    address public tokenSale; // tokenSale contract address
    address public vestingToken; // planetex token address
    uint256 public vestingProgramsCounter; // quantity of vesting programs
    uint256 public immutable PRECISSION = 10000; // precission for math operation
    bool public isInitialized = false; // if true, the contract is initialized, if false, then not

    mapping(uint256 => VestingProgram) public vestingPrograms; // return VestingProgram info
    mapping(address => mapping(uint256 => User)) public userInfo; // return user info
    mapping(address => mapping(uint256 => bool)) public isVester; // bool if true then user is vesting member else not a member

    //// @errors

    //// @dev - cannot unvest 0;
    error ZeroAmountToUnvest(string err);
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
    /// @dev - address to the zero;
    error ZeroAddress(string err);
    //// @dev - cannot rescue 0;
    error RescueZeroValue(string err);
    //// @dev - cannot initialized contract again
    error ContractIsInited(string err);
    //// @dev - cannot call methods if contract not inited
    error ContractIsNotInited(string err);

    ////@notice emitted when the user has joined the vesting program
    event Vest(address user, uint256 vestAmount, uint256 vestingProgramId);
    ////@notice emitted when the user gets ownership of the tokens
    event Unvest(
        address user,
        uint256 unvestedAmount,
        uint256 vestingProgramId
    );
    /// @notice Transferring funds from the wallet еther of the selected token contract to the specified wallet
    event RescueToken(
        address indexed to,
        address indexed token,
        uint256 amount
    );

    function initialize(
        address _tokenSale, // tokenSale contract address
        address _vestingToken, // planetex token contract address
        uint256[] memory _durations, // array of vesting durations in seconds
        uint256[] memory _cliffDurations, // array of cliff period durations in the seconds
        uint256[] memory _startUnlockPercentages, // array of start unlock percentages
        uint256[] memory _unlockPercentages, // array of unlock percentages every unlock period
        uint256[] memory _totalSupplyPercentages, // array of percentages of tokens from totalSupply
        uint256[] memory _vestingTypes, // array of vesting types. 0 - pre_sale; 1 - main_sale; 2 - private_sale
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
        if (_tokenSale == address(0) || _vestingToken == address(0)) {
            revert ZeroAddress("Vesting: Zero address");
        }
        tokenSale = _tokenSale;
        vestingToken = _vestingToken;
        uint256 totalSupply = IERC20(_vestingToken).totalSupply();
        for (uint256 i; i <= _durations.length - 1; i++) {
            VestingProgram storage vestingProgram = vestingPrograms[i];
            vestingProgram.startTime =
                ITokenSale(_tokenSale).getRoundEndTime(i) + // set token sale round end time
                _cliffDurations[i];
            vestingProgram.endTime = vestingProgram.startTime + _durations[i];
            vestingProgram.duration = _durations[i];
            vestingProgram.cliffDuration = _cliffDurations[i];
            vestingProgram.vestingAmount =
                (_totalSupplyPercentages[i] * totalSupply) /
                PRECISSION;
            vestingProgram.startUnlockPercentage = _startUnlockPercentages[i];
            vestingProgram.unlockPercentage = _unlockPercentages[i];
            vestingProgram.periodDuration = _periodDurations[i];
            vestingProgram.vestingType = _vestingTypes[i];
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
        if (isVester[userAddress][vestingId]) {
            (
                unvestedAmount,
                lastUserUnvesting,
                totalUserUnvested,
                totalUnvested,
                payStartUnlock
            ) = _getUnvestedAmountRegisterUser(vestingId, userAddress);
        } else {
            (
                unvestedAmount,
                lastUserUnvesting,
                totalUserUnvested,
                totalUnvested,
                payStartUnlock
            ) = _getUnvestedAmountNonRegisterUser(vestingId, userAddress);
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
        User storage user = userInfo[userAddress][vestingId];
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];

        if (block.timestamp <= vestingProgram.startTime) {
            revert VestingNotStarted("Vesting: Not started");
        }

        if (!isVester[userAddress][vestingId]) {
            _vest(vestingId, userAddress, vestingProgram.startTime);
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
    @dev The function calculates the available amount of funds 
    for unvest for a certain user. Called if the user is already registered in the vesting program
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    @return unvestedAmount available amount of funds for unvest for a certain user.
    @return lastUserUnvesting timestamp when user do last unvest.
    @return totalUserUnvested the sum of all funds received user after unvest.
    @return totalUnvested the entire amount of funds of the vesting program that was withdrawn from vesting
    @return payStartUnlock indicates whether the starting unlocked funds have been received
    */
    function _getUnvestedAmountRegisterUser(
        uint256 vestingId,
        address userAddress
    )
        internal
        view
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

    /**
    @dev The function calculates the available amount of funds 
    for unvest for a certain user. Called if the user is not registered in the vesting program
    @param vestingId vesting program id.
    @param userAddress user wallet address.
    @return unvestedAmount available amount of funds for unvest for a certain user.
    @return lastUserUnvesting timestamp when user do last unvest.
    @return totalUserUnvested the sum of all funds received user after unvest.
    @return totalUnvested the entire amount of funds of the vesting program that was withdrawn from vesting
    @return payStartUnlock indicates whether the starting unlocked funds have been received
    */
    function _getUnvestedAmountNonRegisterUser(
        uint256 vestingId,
        address userAddress
    )
        internal
        view
        returns (
            uint256 unvestedAmount,
            uint256 lastUserUnvesting,
            uint256 totalUserUnvested,
            uint256 totalUnvested,
            bool payStartUnlock
        )
    {
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];
        uint256 userTotalVested = ITokenSale(tokenSale).userBalance(
            userAddress,
            vestingId
        );
        if (block.timestamp < vestingProgram.startTime) {
            revert VestingNotStarted("Vesting: Not started");
        }
        if (userTotalVested == 0) {
            revert NotVester("Vesting: Not a vester");
        }

        if (block.timestamp < vestingProgram.endTime) {
            uint256 userVestingTime = block.timestamp -
                vestingProgram.startTime;
            uint256 payouts = userVestingTime / vestingProgram.periodDuration;
            unvestedAmount =
                ((userTotalVested * vestingProgram.unlockPercentage) /
                    PRECISSION) *
                payouts;
            if (vestingProgram.startUnlockPercentage > 0) {
                unvestedAmount += ((userTotalVested *
                    vestingProgram.startUnlockPercentage) / PRECISSION);
                payStartUnlock = true;
            }
            lastUserUnvesting =
                vestingProgram.startTime +
                (vestingProgram.periodDuration * payouts);
            totalUserUnvested = unvestedAmount;
            totalUnvested = vestingProgram.unvestedAmount + unvestedAmount;
        } else {
            unvestedAmount = userTotalVested;
            if (unvestedAmount > 0) {
                lastUserUnvesting = vestingProgram.endTime;
                totalUserUnvested = userTotalVested;
                totalUnvested = vestingProgram.unvestedAmount + unvestedAmount;
            }
        }
    }

    function _vest(
        uint256 vestingId,
        address userAddress,
        uint256 vestingProgramStartTime
    ) internal {
        User storage user = userInfo[userAddress][vestingId];
        uint256 vestedAmount = ITokenSale(tokenSale).userBalance(
            userAddress,
            vestingId
        );

        if (vestedAmount > 0) {
            isVester[userAddress][vestingId] = true;
            user.totalVested = vestedAmount;
            user.totalUnvested = 0;
            user.lastUnvesting = vestingProgramStartTime;
            user.isGetStartUnlockAmount = false;
            emit Vest(userAddress, vestedAmount, vestingId);
        } else {
            revert NotVester("Vesting: Zero balance");
        }
    }
}