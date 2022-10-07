// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/BankConfig.sol";
import "./interfaces/Goblin.sol";
import "./interfaces/ILazyGoblin.sol";
import "./weth/IWETH.sol";
import "./libraries/SafeToken.sol";

contract Bank is ERC20, ReentrancyGuard, Ownable {
    /// @notice Libraries
    using SafeToken for address;
    using SafeMath for uint256;

    /// @notice Events
    event AddDebt(uint256 indexed id, uint256 debtShare);
    event RemoveDebt(uint256 indexed id, uint256 debtShare);
    event Work(uint256 indexed id, uint256 loan);
    event Kill(uint256 indexed id, address indexed killer, uint256 prize, uint256 left);

    string public name = "Interest Bearing BNB";
    string public symbol = "ibBNB";
    uint8 public decimals = 18;

    bool public killBpsToTreasury;
    address public treasuryAddr;

    struct Position {
        address goblin;
        address owner;
        uint256 debtShare;
    }

    BankConfig public config;
    mapping (uint256 => Position) public positions;
    uint256 public nextPositionID = 1;

    mapping(address => mapping(address => uint256)) public goblinAndUserToID;

    uint256 public glbDebtShare;
    uint256 public glbDebtVal;
    uint256 public lastAccrueTime;
    uint256 public reservePool;

    ILazyGoblin public lazyGoblin;
    IWETH public WETH;

    /// @dev Require that the caller must be an EOA account to avoid flash loans.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    /// @dev Add more debt to the global debt pool.
    modifier accrue(uint256 msgValue) {
        if (now > lastAccrueTime) {
            uint256 interest = pendingInterest(msgValue);
            uint256 toReserve = interest.mul(config.getReservePoolBps()).div(10000);
            reservePool = reservePool.add(toReserve);
            glbDebtVal = glbDebtVal.add(interest);
            lastAccrueTime = now;
        }
        _;
    }

    /// @dev Withdraw all ether from lazy goblin and deposit again
    modifier workLazyGoblin() {
        if (address(lazyGoblin) != address(0)) {
            lazyGoblin.withdraw();
            WETH.withdraw(WETH.balanceOf(address(this)));
        }
        _;
        if (address(lazyGoblin) != address(0) && address(this).balance > 0) {
            WETH.deposit.value(address(this).balance)();
            lazyGoblin.deposit();
        }
    }

    constructor(BankConfig _config, bool _killBpsToTreasury, address _treasuryAddr, IWETH _WETH) public {
        config = _config;
        killBpsToTreasury = _killBpsToTreasury;
        treasuryAddr = _treasuryAddr;
        lastAccrueTime = now;
        WETH = _WETH;
    }

    /// @dev Return the pending interest that will be accrued in the next call.
    /// @param msgValue Balance value to subtract off address(this).balance when called from payable functions.
    function pendingInterest(uint256 msgValue) public view returns (uint256) {
        if (now > lastAccrueTime) {
            uint256 timePast = now.sub(lastAccrueTime);
            uint256 balance = address(this).balance.sub(msgValue);
            uint256 ratePerSec = config.getInterestRate(glbDebtVal, balance);
            return ratePerSec.mul(glbDebtVal).mul(timePast).div(1e18);
        } else {
            return 0;
        }
    }

    /// @dev Return the ETH debt value given the debt share. Be careful of unaccrued interests.
    /// @param debtShare The debt share to be converted.
    function debtShareToVal(uint256 debtShare) public view returns (uint256) {
        if (glbDebtShare == 0) return debtShare; // When there's no share, 1 share = 1 val.
        return debtShare.mul(glbDebtVal).div(glbDebtShare);
    }

    /// @dev Return the debt share for the given debt value. Be careful of unaccrued interests.
    /// @param debtVal The debt value to be converted.
    function debtValToShare(uint256 debtVal) public view returns (uint256) {
        if (glbDebtShare == 0) return debtVal; // When there's no share, 1 share = 1 val.
        return debtVal.mul(glbDebtShare).div(glbDebtVal);
    }

    /// @dev Return ETH value and debt of the given position. Be careful of unaccrued interests.
    /// @param id The position ID to query.
    function positionInfo(uint256 id) public view returns (uint256, uint256) {
        Position storage pos = positions[id];
        return (Goblin(pos.goblin).health(id), debtShareToVal(pos.debtShare));
    }

    /// @dev Return the total ETH entitled to the token holders. Be careful of unaccrued interests.
    function totalETH() public view returns (uint256) {
        if (address(lazyGoblin) != address(0)) {
            return address(this).balance.add(glbDebtVal).add(lazyGoblin.balance()).sub(reservePool);
        }
        return address(this).balance.add(glbDebtVal).sub(reservePool);
    }

    /// @dev Add more ETH to the bank. Hope to get some good returns.
    function deposit() external payable workLazyGoblin accrue(msg.value) nonReentrant {
        uint256 total = totalETH().sub(msg.value);
        uint256 share = total == 0 ? msg.value : msg.value.mul(totalSupply()).div(total);
        _mint(msg.sender, share);
        require(totalSupply() > config.minDebtSize(), "no tiny shares");
    }

    /// @dev Withdraw ETH from the bank by burning the share tokens.
    function withdraw(uint256 share) external workLazyGoblin accrue(0) nonReentrant {
        uint256 amount = share.mul(totalETH()).div(totalSupply());
        _burn(msg.sender, share);
        SafeToken.safeTransferETH(msg.sender, amount);
        require(totalSupply() > config.minDebtSize(), "no tiny shares");
    }

    /// @dev Create a new farming position to unlock your yield farming potential.
    /// @param goblin The address of the authorized goblin to work for this position.
    /// @param loan The amount of ETH to borrow from the pool.
    /// @param maxReturn The max amount of ETH to return to the pool.
    /// @param data The calldata to pass along to the goblin for more working context.
    function work(address goblin, uint256 loan, uint256 maxReturn, bytes calldata data)
        external payable
        onlyEOA workLazyGoblin accrue(msg.value) nonReentrant
    {
        uint256 id = goblinAndUserToID[goblin][msg.sender];
        // 1. Sanity check the input position, or add a new position of ID is 0.
        if (id == 0) {
            id = nextPositionID++;
            positions[id].goblin = goblin;
            positions[id].owner = msg.sender;
            goblinAndUserToID[goblin][msg.sender] = id;
        } else {
            require(id < nextPositionID, "bad position id");
            require(positions[id].goblin == goblin, "bad position goblin");
            require(positions[id].owner == msg.sender, "not position owner");
        }
        emit Work(id, loan);
        // 2. Make sure the goblin can accept more debt and remove the existing debt.
        require(config.isGoblin(goblin), "not a goblin");
        require(loan == 0 || config.acceptDebt(goblin), "goblin not accept more debt");
        uint256 debt = _removeDebt(id).add(loan);
        // 3. Perform the actual work, using a new scope to avoid stack-too-deep errors.
        uint256 back;
        {
            uint256 sendETH = msg.value.add(loan);
            require(sendETH <= address(this).balance, "insufficient ETH in the bank");
            uint256 beforeETH = address(this).balance.sub(sendETH);
            Goblin(goblin).work.value(sendETH)(id, msg.sender, debt, data);
            back = address(this).balance.sub(beforeETH);
        }
        // 4. Check and update position debt.
        uint256 lessDebt = Math.min(debt, Math.min(back, maxReturn));
        debt = debt.sub(lessDebt);
        if (debt > 0) {
            require(debt >= config.minDebtSize(), "too small debt size");
            uint256 health = Goblin(goblin).health(id);
            uint256 workFactor = config.workFactor(goblin, debt);
            require(health.mul(workFactor) >= debt.mul(10000), "bad work factor");
            _addDebt(id, debt);
        }
        // 5. Return excess ETH back.
        if (back > lessDebt) SafeToken.safeTransferETH(msg.sender, back - lessDebt);
        // 6. Delete position if no shares
        if (Goblin(goblin).shares(id) == 0) {
            goblinAndUserToID[goblin][msg.sender] = 0;
        }
    }

    /// @dev Kill the given to the position. Liquidate it immediately if killFactor condition is met.
    /// @param id The position ID to be killed.
    function kill(uint256 id) external onlyEOA workLazyGoblin accrue(0) nonReentrant {
        // 1. Verify that the position is eligible for liquidation.
        Position storage pos = positions[id];
        require(pos.debtShare > 0, "no debt");
        uint256 debt = _removeDebt(id);
        uint256 health = Goblin(pos.goblin).health(id);
        uint256 killFactor = config.killFactor(pos.goblin, debt);
        require(health.mul(killFactor) < debt.mul(10000), "can't liquidate");
        // 2. Perform liquidation and compute the amount of ETH received.
        uint256 beforeETH = address(this).balance;
        Goblin(pos.goblin).liquidate(id);
        uint256 back = address(this).balance.sub(beforeETH);
        uint256 prize = back.mul(config.getKillBps()).div(10000);
        uint256 rest = back.sub(prize);
        // 3. Clear position debt and return funds to liquidator and position owner.
        if (prize > 0) {
            address rewardTo = killBpsToTreasury == true ? treasuryAddr : msg.sender;
            SafeToken.safeTransferETH(rewardTo, prize);
        }
        uint256 left = rest > debt ? rest - debt : 0;
        if (left > 0) SafeToken.safeTransferETH(pos.owner, left);
        goblinAndUserToID[pos.goblin][pos.owner] = 0;
        emit Kill(id, msg.sender, prize, left);
    }

    /// @dev Internal function to add the given debt value to the given position.
    function _addDebt(uint256 id, uint256 debtVal) internal {
        Position storage pos = positions[id];
        uint256 debtShare = debtValToShare(debtVal);
        pos.debtShare = pos.debtShare.add(debtShare);
        glbDebtShare = glbDebtShare.add(debtShare);
        glbDebtVal = glbDebtVal.add(debtVal);
        emit AddDebt(id, debtShare);
    }

    /// @dev Internal function to clear the debt of the given position. Return the debt value.
    function _removeDebt(uint256 id) internal returns (uint256) {
        Position storage pos = positions[id];
        uint256 debtShare = pos.debtShare;
        if (debtShare > 0) {
            uint256 debtVal = debtShareToVal(debtShare);
            pos.debtShare = 0;
            glbDebtShare = glbDebtShare.sub(debtShare);
            glbDebtVal = glbDebtVal.sub(debtVal);
            emit RemoveDebt(id, debtShare);
            return debtVal;
        } else {
            return 0;
        }
    }

    /// @dev Update bank configuration to a new address. Must only be called by owner.
    /// @param _config The new configurator address.
    function updateConfig(BankConfig _config) external onlyOwner {
        config = _config;
    }

    /// @dev Withdraw ETH reserve for underwater positions to the given address.
    /// @param to The address to transfer ETH to.
    /// @param value The number of ETH tokens to withdraw. Must not exceed `reservePool`.
    function withdrawReserve(address to, uint256 value) external onlyOwner nonReentrant {
        reservePool = reservePool.sub(value);
        SafeToken.safeTransferETH(to, value);
    }

    /// @dev Reduce ETH reserve, effectively giving them to the depositors.
    /// @param value The number of ETH reserve to reduce.
    function reduceReserve(uint256 value) external onlyOwner {
        reservePool = reservePool.sub(value);
    }

    /// @dev Set Reward Kill Bps to owner or msg,sender
    /// @param toTreasury bool set to owner or not
    function setKillBpsToTreasury (bool toTreasury) external onlyOwner {
        killBpsToTreasury = toTreasury;
    }

    /// @dev Set Treasury Address
    /// @param _treasuryAddr treasury address 
    function setTreasuryAddress (address _treasuryAddr) external onlyOwner {
        treasuryAddr = _treasuryAddr;
    }

    /// @dev Set Lazy Goblin. Withdraw from actual lazy goblin and deposit in new lazy goblin (if different from 0 address)
    /// @param _lazyGoblin Lazy Goblin address
    function setLazyGoblin(ILazyGoblin _lazyGoblin) external onlyOwner workLazyGoblin {
        lazyGoblin = _lazyGoblin;
        if (address(lazyGoblin) != address(0)) {
            WETH.approve(address(lazyGoblin), uint256(-1));
        }
    }

    /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
    /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
    /// @param to The address to send the tokens to.
    /// @param value The number of tokens to transfer to `to`.
    function recover(address token, address to, uint256 value) external onlyOwner nonReentrant {
        token.safeTransfer(to, value);
    }

    /// @dev Fallback function to accept ETH. Goblins will send ETH back the pool.
    function() external payable {}
}