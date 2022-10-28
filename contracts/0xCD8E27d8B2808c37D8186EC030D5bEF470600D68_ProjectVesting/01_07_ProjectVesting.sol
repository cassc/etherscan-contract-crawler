// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITokenSale.sol";

pragma solidity 0.8.17;

contract ProjectVesting is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    struct VestingProgram {
        uint256 startTime; // vesting start time timestamp
        uint256 endTime; // vesting end time timestamp
        uint256 cliffDuration; // cliff period duration in seconds
        uint256 duration; // vesting duration in seconds
        uint256 vestingAmount; // total vested amount
        uint256 unvestedAmount; // total unvested amount
        uint256 unlockPercentage; // period unlock percentage
        uint256 periodDuration; // unlock period duration in seconds
        uint256 vestingType; //0 - team;  1 - treasury
        bool isEnded; // active vesting if true, if false vesting is end
    }

    struct User {
        uint256 lastUnvesting; // last  unvest timestamp
        uint256 totalVested; // total user vested amount
        uint256 totalUnvested; // total user unvested amount
    }

    address public vestingToken; // planetex token address
    address public tokenSale; // tokenSale contract address
    uint256 public vestingProgramsCounter; // quantity of vesting programs
    uint256 public immutable PRECISSION = 10000; // precission for math operation
    bool public isInitialized = false; // if true, the contract is initialized, if false, then not

    mapping(uint256 => VestingProgram) public vestingPrograms; // return VestingProgram info (0 - team, 1 - treasury)
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
    //// @dev - Cannot rescue 0;
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
        address _vestingToken, // planetex token contract address
        address _tokenSale, // tokenSale contract address
        uint256[] memory _durations, // array of vesting durations in seconds
        uint256[] memory _cliffDurations, // array of cliff period durations in the seconds
        uint256[] memory _unlockPercentages, // array of unlock percentages every unlock period
        uint256[] memory _totalSupplyPercentages, // array of percentages of tokens from totalSupply
        uint256[] memory _vestingTypes, // array of vesting types. 0 - team; 1 - treasury;
        uint256[] memory _periodDurations, // array of unlock period durations in secconds
        address[] memory _vesters // array of vesters adresses (0 - team address, 1 - treasury address)
    ) external onlyOwner isInited {
        if (
            _durations.length != _cliffDurations.length ||
            _durations.length != _unlockPercentages.length ||
            _durations.length != _totalSupplyPercentages.length ||
            _durations.length != _vestingTypes.length ||
            _durations.length != _periodDurations.length ||
            _durations.length != _vesters.length
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
            vestingProgram.startTime =
                ITokenSale(_tokenSale).getRoundStartTime(0) +
                _cliffDurations[i];
            vestingProgram.endTime = vestingProgram.startTime + _durations[i];
            vestingProgram.duration = _durations[i];
            vestingProgram.cliffDuration = _cliffDurations[i];
            vestingProgram.vestingAmount =
                (_totalSupplyPercentages[i] * totalSupply) /
                PRECISSION;
            vestingProgram.unlockPercentage = _unlockPercentages[i];
            vestingProgram.periodDuration = _periodDurations[i];
            vestingProgram.vestingType = _vestingTypes[i];
            vestingProgram.unvestedAmount = 0;
            vestingProgram.isEnded = false;

            User storage userVestInfo = userInfo[_vesters[i]][i];
            userVestInfo.lastUnvesting = vestingProgram.startTime;
            userVestInfo.totalVested = vestingProgram.vestingAmount;
            userVestInfo.totalUnvested = vestingProgram.unvestedAmount;
            isVester[_vesters[i]][i] = true;
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
    */
    function getUserUnvestedAmount(uint256 vestingId, address userAddress)
        public
        view
        notInited
        returns (
            uint256 unvestedAmount,
            uint256 lastUserUnvesting,
            uint256 totalUserUnvested,
            uint256 totalUnvested
        )
    {
        User storage user = userInfo[userAddress][vestingId];
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];

        if (block.timestamp < vestingProgram.startTime) {
            revert VestingNotStarted("Vesting: Not started");
        }

        if (user.totalVested == 0) {
            revert NotVester("Vesting: Not a vester");
        }

        if (block.timestamp < vestingProgram.endTime) {
            uint256 userVestingTime = block.timestamp - user.lastUnvesting;
            uint256 payouts = userVestingTime / vestingProgram.periodDuration;
            unvestedAmount =
                ((user.totalVested * vestingProgram.unlockPercentage) /
                    PRECISSION) *
                payouts;
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
        User storage user = userInfo[userAddress][vestingId];
        VestingProgram storage vestingProgram = vestingPrograms[vestingId];

        if (block.timestamp <= vestingProgram.startTime) {
            revert VestingNotStarted("Vesting: Not started");
        }

        if (!isVester[userAddress][vestingId]) {
            revert NotVester("Vesting: Zero balance");
        }

        (
            uint256 unvestedAmount,
            uint256 lastUserUnvesting,
            uint256 totalUserUnvested,
            uint256 totalUnvested
        ) = getUserUnvestedAmount(vestingId, userAddress);

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
}