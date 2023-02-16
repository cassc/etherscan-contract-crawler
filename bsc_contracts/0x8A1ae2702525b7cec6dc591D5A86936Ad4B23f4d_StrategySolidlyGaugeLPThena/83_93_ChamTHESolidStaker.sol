// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ChamTHESolidManager.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVeToken.sol";
import "../interfaces/IVeDist.sol";
import "../interfaces/IMinter.sol";

contract ChamTHESolidStaker is ERC20, ChamTHESolidManager, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Addresses used
    IVoter public solidVoter;
    IVeToken public ve;
    IVeDist public veDist;

    // Want token and our NFT Token ID
    IERC20 public want;
    uint256 public tokenId;

    // Max Lock time, Max variable used for reserve split and the reserve rate.
    uint16 public constant MAX = 10000;
    uint256 public constant MAX_RATE = 1e18;
    // Vote weight decays linearly over time. Lock time cannot be more than `MAX_LOCK` (2 years).
    uint256 public constant MAX_LOCK = 365 days * 2;
    uint256 public reserveRate;
    bool public isAutoIncreaseLock = true;

    bool public enabledPenaltyFee = false;
    uint256 public penaltyRate = 0.5e18; // 0.5
    uint256 public maxBurnRate = 50; // 0.5%
    uint256 public maxPegReserve = 0.8e18;

    // Our on chain events.
    event CreateLock(
        address indexed user,
        uint256 veTokenId,
        uint256 amount,
        uint256 unlockTime
    );
    event Release(address indexed user, uint256 veTokenId, uint256 amount);
    event AutoIncreaseLock(bool _enabled);
    event EnabledPenaltyFee(bool _enabled);
    event IncreaseTime(
        address indexed user,
        uint256 veTokenId,
        uint256 unlockTime
    );
    event DepositWant(uint256 amount);
    event Withdraw(uint256 amount);
    event ClaimVeEmissions(
        address indexed user,
        uint256 veTokenId,
        uint256 amount
    );
    event UpdatedReserveRate(uint256 newRate);
    event SetMaxBurnRate(uint256 oldRate, uint256 newRate);
    event SetMaxPegReserve(uint256 oldValue, uint256 newValue);
    event SetPenaltyRate(uint256 oldValue, uint256 newValue);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _reserveRate,
        address _solidVoter,
        address _keeper,
        address _voter,
        address _taxWallet
    ) ERC20(_name, _symbol) ChamTHESolidManager(_keeper, _voter, _taxWallet) {
        reserveRate = _reserveRate;
        solidVoter = IVoter(_solidVoter);
        ve = IVeToken(solidVoter._ve());
        want = IERC20(ve.token());
        IMinter _minter = IMinter(solidVoter.minter());
        veDist = IVeDist(_minter._rewards_distributor());
        want.safeApprove(address(ve), type(uint256).max);
    }

    // Deposit all want for a user.
    function depositAll() external {
        _deposit(want.balanceOf(msg.sender));
    }

    // Deposit an amount of want.
    function deposit(uint256 _amount) external {
        _deposit(_amount);
    }

    // Internal: Deposits Want and mint CeWant, checks for ve increase opportunities first.
    function _deposit(uint256 _amount) internal nonReentrant whenNotPaused {
        lock();
        uint256 _balanceBefore = balanceOfWant();
        want.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = balanceOfWant() - _balanceBefore; // Additional check for deflationary tokens.

        if (_amount > 0) {
            _mint(msg.sender, _amount);
            emit DepositWant(totalWant());
        }
    }

    // Deposit more in ve and up lock_time.
    function lock() public {
        if (totalWant() > 0) {
            (, , bool shouldIncreaseLock) = lockInfo();
            if (balanceOfWant() > requiredReserve()) {
                uint256 availableBalance = balanceOfWant() - requiredReserve();
                ve.increase_amount(tokenId, availableBalance);
            }
            // Extend max lock
            if (shouldIncreaseLock) ve.increase_unlock_time(tokenId, MAX_LOCK);
        }
    }

    // Withdraw capable if we have enough Want in the contract.
    function withdraw(uint256 _amount) external {
        require(
            _amount <= withdrawableBalance(),
            "ChamTHEStaker: INSUFFICIENCY_AMOUNT_OUT"
        );

        _burn(msg.sender, _amount);
        if (enabledPenaltyFee) {
            uint256 maxAmountBurning = ((totalSupply() + _amount) *
                maxBurnRate) / MAX;
            require(
                _amount <= maxAmountBurning,
                "ChamTHEStaker: Over max burning amount"
            );

            uint256 penaltyAmount = calculatePenaltyFee(_amount);
            if (penaltyAmount > 0) {
                _amount = _amount - penaltyAmount;

                // tax
                uint256 taxAmount = penaltyAmount / 2;
                if (taxAmount > 0) _mint(taxWallet, taxAmount);

                // transfer into a dead address
                uint256 burnAmount = penaltyAmount - taxAmount;
                if (burnAmount > 0) _mint(0x000000000000000000000000000000000000dEaD, burnAmount);
            }
        }

        want.safeTransfer(msg.sender, _amount);
        emit Withdraw(totalWant());
    }

    // Total Want in ve contract and CeVe contract.
    function totalWant() public view returns (uint256) {
        return balanceOfWant() + balanceOfWantInVe();
    }

    // Our required Want held in the contract to enable withdraw capabilities.
    function requiredReserve() public view returns (uint256 reqReserve) {
        // We calculate allocation for reserve of the total staked in Ve.
        reqReserve = (balanceOfWantInVe() * reserveRate) / MAX;
    }

    // Calculate how much 'want' is held by this contract
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    // What is our end lock and seconds remaining in lock?
    function lockInfo()
        public
        view
        returns (
            uint256 endTime,
            uint256 secondsRemaining,
            bool shouldIncreaseLock
        )
    {
        (, endTime) = ve.locked(tokenId);
        uint256 unlockTime = ((block.timestamp + MAX_LOCK) / 1 weeks) * 1 weeks;
        secondsRemaining = endTime > block.timestamp
            ? endTime - block.timestamp
            : 0;
        shouldIncreaseLock = isAutoIncreaseLock && unlockTime > endTime;
    }

    // Withdrawable Balance for users
    function withdrawableBalance() public view returns (uint256) {
        return balanceOfWant();
    }

    // How many want we got earning?
    function balanceOfWantInVe() public view returns (uint256 wants) {
        (wants, ) = ve.locked(tokenId);
    }

    // Claim veToken emissions and increases locked amount in veToken
    function claimVeEmissions() public virtual {
        uint256 _amount = veDist.claim(tokenId);
        emit ClaimVeEmissions(msg.sender, tokenId, _amount);
    }

    // Reset current votes
    function resetVote() external onlyVoter {
        solidVoter.reset(tokenId);
    }

    // Create a new veToken if none is assigned to this address
    function createLock(
        uint256 _amount,
        uint256 _lock_duration
    ) external onlyManager {
        require(tokenId == 0, "ChamTHEStaker: ASSIGNED");
        require(_amount > 0, "ChamTHEStaker: ZERO_AMOUNT");

        want.safeTransferFrom(address(msg.sender), address(this), _amount);
        tokenId = ve.create_lock(_amount, _lock_duration);
        _mint(msg.sender, _amount);

        emit CreateLock(msg.sender, tokenId, _amount, _lock_duration);
    }

    // Release expired lock of a veToken owned by this address
    function release() external onlyOwner {
        (uint endTime, , ) = lockInfo();
        require(endTime <= block.timestamp, "ChamTHEStaker: LOCKED");
        ve.withdraw(tokenId);

        emit Release(msg.sender, tokenId, balanceOfWant());
    }

    // Whitelist new token
    function whitelist(address _token) external onlyManager {
        solidVoter.whitelist(_token, tokenId);
    }

    // Adjust reserve rate
    function adjustReserve(uint256 _rate) external onlyOwner {
        // validation from 15-50%
        require(
            _rate >= 1500 && _rate <= 5000,
            "ChamTHEStaker: RATE_OUT_OF_RANGE"
        );
        reserveRate = _rate;
        emit UpdatedReserveRate(_rate);
    }

    // Enable/Disable Penalty Fee
    function setEnabledPenaltyFee(bool _enabled) external onlyOwner {
        enabledPenaltyFee = _enabled;
        emit EnabledPenaltyFee(_enabled);
    }

    function setPenaltyRate(uint256 _rate) external onlyOwner {
        // validation from 0-0.5
        require(_rate <= MAX_RATE / 2, "ChamTHEStaker: RATE_OUT_OF_RANGE");
        emit SetPenaltyRate(penaltyRate, _rate);
        penaltyRate = _rate;
    }

    // Enable/Disable auto increase lock
    function setAutoIncreaseLock(bool _enabled) external onlyOwner {
        isAutoIncreaseLock = _enabled;
        emit AutoIncreaseLock(_enabled);
    }

    function setMaxBurnRate(uint256 _rate) external onlyOwner {
        // validation from 0.5-100%
        require(
            _rate >= 50 && _rate <= MAX,
            "ChamTHEStaker: RATE_OUT_OF_RANGE"
        );
        emit SetMaxBurnRate(maxBurnRate, _rate);
        maxBurnRate = _rate;
    }

    function setMaxPegReserve(uint256 _value) external onlyOwner {
        // validation from 0.6-1
        require(
            _value >= 0.6e18 && _value <= 1e18,
            "ChamTHEStaker: VALUE_OUT_OF_RANGE"
        );
        emit SetMaxPegReserve(maxPegReserve, _value);
        maxPegReserve = _value;
    }

    // Pause deposits
    function pause() public onlyManager {
        _pause();
        want.safeApprove(address(ve), 0);
    }

    // Unpause deposits
    function unpause() external onlyManager {
        _unpause();
        want.safeApprove(address(ve), type(uint256).max);
    }

    // Confirmation required for receiving veToken to smart contract
    function onERC721Received(
        address operator,
        address from,
        uint _tokenId,
        bytes calldata data
    ) external view returns (bytes4) {
        operator;
        from;
        _tokenId;
        data;
        require(msg.sender == address(ve), "ChamTHEStaker: VE_ONLY");
        return
            bytes4(keccak256("onERC721Received(address,address,uint,bytes)"));
    }

    function calculatePenaltyFee(
        uint256 _amount
    ) public view returns (uint256) {
        uint256 pegReserve = (balanceOfWant() * MAX_RATE) / requiredReserve();
        uint256 penaltyAmount = 0;
        if (pegReserve < maxPegReserve) {
            // penaltyPercent = 0.5 x (1 - pegReserve) * 100%
            penaltyAmount = (_amount * penaltyRate * (MAX_RATE - pegReserve)) / (MAX_RATE * MAX_RATE);
        }
        return penaltyAmount;
    }
}