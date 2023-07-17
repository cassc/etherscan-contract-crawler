// SPDX-License-Identifier: MIT
/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     (@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(   @@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@             @@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@(            @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@(         @@(         @@(            @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@          @@          @@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @           @           @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@(            @@@         @@@         @@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@(     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/INil.sol";
import "./interfaces/IVestedNil.sol";
import "./interfaces/INilStaking.sol";

contract VestedNil is AccessControl, ERC20, ReentrancyGuard, IVestedNil {
    using SafeERC20 for INil;

    event Claim(address indexed claimer, uint256 initialAmount);

    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    /// @dev The identifier of the role which allows accounts to mint tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    uint16[] public cumulativeScheduleInBPS;
    uint256 public immutable timePeriodInSeconds;
    uint256 public immutable startTime;

    mapping(address => uint128) public claimedByAccount;

    INil public immutable nil;
    INilStaking public nilStaking;

    constructor(
        INil nil_,
        address dao,
        uint16[] memory cumulativeScheduleInBPS_,
        uint256 timePeriodInDays
    ) ERC20("vNil", "VNIL") {
        _setupRole(MINTER_ROLE, dao);
        _setupRole(ADMIN_ROLE, dao);
        _setupRole(MINTER_ROLE, msg.sender); // This will be surrendered after deployment
        _setupRole(ADMIN_ROLE, msg.sender); // This will be surrendered after deployment
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        nil = nil_;
        startTime = block.timestamp;
        cumulativeScheduleInBPS = cumulativeScheduleInBPS_;
        timePeriodInSeconds = timePeriodInDays * 1 days;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "VestedNil:MINT_DENIED");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "VestedNil:ACCESS_DENIED");
        _;
    }

    function multiMint(address[] calldata accounts, uint256[] calldata initialAmounts) external override onlyMinter {
        for (uint256 i = 0; i < accounts.length; i++) {
            mint(accounts[i], initialAmounts[i]);
        }
    }

    function mint(address account, uint256 initialAmount) public override onlyMinter {
        require(totalSupply() + nil.totalSupply() + initialAmount <= nil.MAX_SUPPLY(), "VestedNil:SUPPLY_OVERFLOW");
        _mint(account, initialAmount);
    }

    function _claim(address account) private returns (uint128 claimable) {
        claimable = uint128(claimableOf(account));
        if (claimable > 0) {
            claimedByAccount[account] += claimable;
            _burn(account, claimable);
            emit Claim(account, claimable);
        }
    }

    function _vestingSnapshot(address account)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint128 claimed = claimedByAccount[account];
        uint256 balance = balanceOf(account);
        uint256 initialAllocation = balance + claimed;
        return (_totalVestedOf(initialAllocation, block.timestamp), claimed, balance);
    }

    function claim(address recipient) external override nonReentrant {
        uint256 claimable = _claim(recipient);
        require(claimable > 0, "VestedNil:NOTHING_VESTED");
        nil.mint(recipient, claimable);
    }

    function claimAndStake() external override nonReentrant {
        require(address(nilStaking) != address(0), "VestedNil:STAKING_DISABLED");
        uint256 claimable = _claim(msg.sender);
        require(claimable > 0, "VestedNil:NOTHING_VESTED");
        nilStaking.mintAndStake(msg.sender, claimable);
    }

    function _totalVestedOf(uint256 initialAllocation, uint256 currentTime) internal view returns (uint256 total) {
        if (currentTime <= startTime) {
            return 0;
        }
        uint16[] memory _cumulativeScheduleInBPS = cumulativeScheduleInBPS;
        uint256 elapsed = Math.min(currentTime - startTime, _cumulativeScheduleInBPS.length * timePeriodInSeconds);
        uint256 currentPeriod = elapsed / timePeriodInSeconds;
        uint256 elapsedInCurrentPeriod = elapsed % timePeriodInSeconds;
        uint256 cumulativeMultiplierPast = 0;

        if (currentPeriod > 0) {
            cumulativeMultiplierPast = _cumulativeScheduleInBPS[currentPeriod - 1];
            total = (initialAllocation * cumulativeMultiplierPast) / 10000;
        }

        if (elapsedInCurrentPeriod > 0) {
            /**
                currentPeriod can never go out of bounds because after the last period elapsedInCurrentPeriod will always be 0
                so we will not enter this block
             */
            uint256 currentMultiplier = _cumulativeScheduleInBPS[currentPeriod] - cumulativeMultiplierPast;
            uint256 periodAllocation = (initialAllocation * currentMultiplier) / 10000;
            total += (periodAllocation * elapsedInCurrentPeriod) / timePeriodInSeconds;
        }
    }

    function vestedOf(address account) external view override returns (uint256) {
        (uint256 vested, , ) = _vestingSnapshot(account);
        return vested;
    }

    function claimableOf(address account) public view override returns (uint256) {
        (uint256 vested, uint256 claimed, uint256 balance) = _vestingSnapshot(account);
        return Math.min(vested - claimed, balance);
    }

    function setNilStaking(INilStaking nilStaking_) external onlyAdmin {
        nilStaking = nilStaking_;
    }

    function addMinter(address minter) external onlyAdmin {
        grantRole(MINTER_ROLE, minter);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        //Allow only mint and burn
        require(from == address(0) || to == address(0), "VestedNil:TRANSFER_DENIED");
    }
}