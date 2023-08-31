// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ILmeow.sol";
import "./Ownable.sol";



contract Vault is Ownable {
    IUniswapV2Router02 public immutable router;

    constructor(IUniswapV2Router02 _router) {
        router = _router;
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint ethValue
    )
        external
        onlyOwner
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        )
    {



        (amountToken, amountETH, liquidity) = router.addLiquidityETH{value: ethValue}(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            to,
            block.timestamp
        );

    }

    function recover(uint256 amount) external onlyOwner {
        msg.sender.call{value: amount}(new bytes(0));
    }

    fallback() external payable onlyOwner {



        (bool success, ) = address(router).call{value: msg.value}(msg.data);
        require(success, "forward router faild");


    }

    receive() external payable {}
}

contract Lmeow is ILmeow, Ownable {
    string public constant override name = "Lmeow Token";
    string public constant override symbol = "lmeow";
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;

    uint256 public constant initialSupply = 420690000000000 ether;
    uint256 public constant initialLPSupply = (initialSupply * 75) / 100; // 75%
    uint256 public constant marketingSupply = (initialSupply * 10) / 100; // 10%
    uint256 public constant teamSupply = (initialSupply * 10) / 100; // 10%
    uint256 public constant devSupply = initialSupply - initialLPSupply - marketingSupply - teamSupply; // 5%

    address public constant marketingAddr = 0x5D98206E4a3E3b87E6d899A47f33DEB579105b96;
    address public constant teamAddr = 0x50E943A5e3c4078211a7e0226fc1e0f648B867af;
    address public constant devAddr = 0xbA6489eFB076194EB5551a0799d70648E0149952;

    uint256 public constant ticketPrice = 3000000000000 ether;
    uint256 public constant WIN_COUNT = 3;
    uint256 public constant CYCLE_DURATION = 1 weeks;
    // limit 100 = 1%, 1=0.01% ,10=0.1% , 1000=10%, 10000=100%
    uint256 public limitFractional = 100;
    uint256 public buyTaxFractional = 1000;
    uint256 public sellTaxFractional = 1000;
    uint256 public autoLpFractional = 7500;
    uint256 public constant TEN_THOUSAND = 10000;
    address public pair;
    IUniswapV2Router02 public router;
    Vault public vault;
    Vault public lpVault;
    address public weth;
    address public recoverAddress;

    uint256 public immutable deployTime;
    uint256 public lastAddLiquidityTime;
    uint256 private _seed = 2023;
    bool _inSwap;
    bool public autoAddLiquidity = true;
    bool public autoSwapBack = true;
    bool public initialLPSupplyAdded;
    mapping(address => bool) public lockedMap;
    mapping(address => uint256) public override balanceOf;
    mapping(address => bool) public withoutLimitMap;
    mapping(address => mapping(address => uint256)) public override allowance; // allowance[owner][spender]

    mapping(uint256 => mapping(uint256 => Ticket)) public ticketMap;
    mapping(uint256 => uint256) public ticketCountMap;
    mapping(uint256 => RewardCycle) public rewardCycleMap;
    mapping(uint256 => mapping(address => uint256[])) public ticketUserMap;
    mapping(uint256 => uint256) public cycleRewardAmountMap;

    event Lock(address user, uint256 timestamp);
    event OpenCycle(address user, uint256 cycleId);
    event Stake(uint256 indexed cycleId, address indexed user, uint256 count);
    event UnStake(uint256 indexed cycleId, address indexed user, uint256 count);
    event Reward(uint256 indexed cycleId, address indexed user, uint256 amount);

    error MaxHolderLimitExceeded(address user);
    error LengthMismatch();
    error AlreadySetUp();
    error AccountLocked(address user);
    error InsufficientAllowance(address owner, address spender, uint256 amount);
    error ExceedsBalance(address owner);
    error InvalidAddress(address addr);
    error InvalidTime();
    error IllegalOperation();
    error InvalidArgs();
    error OnlyHumanCall();
    error ZeroBalance();
    error TransferETHFailed(address user, uint256 amount);

    struct Ticket {
        address user;
        bool redeemed;
    }

    struct TicketDetail {
        uint256 ticketCycleId;
        uint256 ticketId;
        address user;
        bool redeemed;
    }

    struct TicketWinner {
        uint256 ticketId;
        uint256 amount;
        bool claimed;
    }

    struct RewardCycle {
        TicketWinner[] winner;
        uint256 totalRewardEth;
        bool opened;
    }

    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier validRecipient(address to) {
        if (to == address(0)) revert ZeroAddress();
        _;
    }

    modifier onlyEmergency() {
        if (msg.sender != recoverAddress) revert InvalidAddress(msg.sender);
        if (block.timestamp < (deployTime + 300 days)) revert IllegalOperation();
        _;
    }

    modifier holdThreshold(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (!withoutLimitMap[recipient]) {
            if (balanceOf[recipient] + amount > (initialSupply / TEN_THOUSAND) * limitFractional) {
                revert MaxHolderLimitExceeded(recipient);
            }
        }
        _;
    }

    modifier onlyHuman() {
        if (tx.origin != msg.sender) revert OnlyHumanCall();
        _;
    }

    modifier previousCycle(uint256 cycleId) {
        if (cycleId >= currentCycleId()) revert InvalidTime();
        _;
    }

    constructor(IUniswapV2Router02 router_) {
        deployTime = block.timestamp;
        router = router_;
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        address weth_ = router.WETH();
        weth = weth_;
        pair = factory.createPair(weth_, address(this));
        vault = new Vault(router);
        lpVault = new Vault(router);
        address sender = msg.sender;
        recoverAddress = sender;
        withoutLimitMap[pair] = true;
        withoutLimitMap[address(this)] = true;
        withoutLimitMap[address(vault)] = true;
        withoutLimitMap[address(lpVault)] = true;
        totalSupply = initialSupply;

        allowance[address(this)][address(router_)] = type(uint256).max;
        allowance[address(vault)][address(router_)] = type(uint256).max;
        allowance[address(lpVault)][address(router_)] = type(uint256).max;
        allowance[sender][address(router_)] = type(uint256).max;

        balanceOf[address(this)] = initialLPSupply;
        balanceOf[marketingAddr] = marketingSupply;
        balanceOf[teamAddr] = teamSupply;
        balanceOf[devAddr] = devSupply;

        emit Transfer(address(0), marketingAddr, marketingSupply);
        emit Transfer(address(0), teamAddr, teamSupply);
        emit Transfer(address(0), devAddr, devSupply);
        emit Transfer(address(0), address(this), initialLPSupply);
    }

    function addInitialLP() external payable onlyOwner swapping {


        if (initialLPSupplyAdded) revert IllegalOperation();
        if (msg.value != 1 ether) revert IllegalOperation();
        router.addLiquidityETH{value: 1 ether}(address(this), initialLPSupply, 0, 0, msg.sender, block.timestamp);
        initialLPSupplyAdded = true;

    }

    function setWithoutLimit(address user) external onlyOwner {
        withoutLimitMap[user] = true;
    }

    function setWithLimit(address user) external onlyOwner {
        withoutLimitMap[user] = false;
    }

    function setPair(address pair_) external onlyOwner {
        pair = pair_;
    }

    function setTaxBuyAndSellFractional(uint256 buy, uint256 sell) external onlyOwner {
        if (buy > TEN_THOUSAND / 10) revert InvalidArgs();
        if (sell > TEN_THOUSAND / 10) revert InvalidArgs();
        buyTaxFractional = buy;
        sellTaxFractional = sell;
    }

    function setAutoLpFractional(uint256 autoLpFractional_) external onlyOwner {
        if (autoLpFractional_ > TEN_THOUSAND) revert InvalidArgs();
        autoLpFractional = autoLpFractional_;
    }

    function setautoAddLiquidity(bool isAuto) external onlyOwner {
        autoAddLiquidity = isAuto;
    }

    function setAutoSwapBack(bool isAuto) external onlyOwner {
        autoSwapBack = isAuto;
    }

    /**
     * holder limit
     * @param limit 100 = 1%, 1=0.01%
     */
    function setLimitFractional(uint256 limit) external onlyOwner {
        if (limit > TEN_THOUSAND) revert InvalidArgs();
        limitFractional = limit;
    }

    function lockAccount(address[] memory users, bool locked) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            lockedMap[users[i]] = locked;
        }
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {

        uint256 bl = balanceOf[from];


        if (bl < amount) revert ExceedsBalance(from);
        unchecked {
            balanceOf[from] = bl - amount;
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal validRecipient(recipient) holdThreshold(sender, recipient, amount) returns (bool) {



        if (lockedMap[sender]) revert AccountLocked(sender);
        if (lockedMap[recipient]) revert AccountLocked(recipient);
        if (_inSwap) {

            return _basicTransfer(sender, recipient, amount);
        } else {
            if (shouldAddLiquidity()) {

                addLiquidity();

            }
            if (shouldSwapBack()) {

                swapBack();

            }

            uint256 taxAmount;
            if (sender == pair) {
                // buy
                if (buyTaxFractional > 0) {
                    // take buy tax
                    taxAmount = (amount / TEN_THOUSAND) * buyTaxFractional;
                }
            } else if (recipient == pair) {
                // sell
                if (sellTaxFractional > 0) {
                    // take sell tax
                    taxAmount = (amount / TEN_THOUSAND) * sellTaxFractional;
                }
            }

            if (taxAmount > 0) {
                balanceOf[sender] -= taxAmount;
                uint256 autoLpAmount = (taxAmount / TEN_THOUSAND) * autoLpFractional;
                uint256 rewardAmount = taxAmount - autoLpAmount;
                if (autoLpAmount > 0) {
                    balanceOf[address(lpVault)] += autoLpAmount;
                    emit Transfer(sender, address(lpVault), autoLpAmount);
                }
                if (rewardAmount > 0) {
                    balanceOf[address(vault)] += rewardAmount;
                    emit Transfer(sender, address(vault), rewardAmount);
                }
            }
            return _basicTransfer(sender, recipient, amount - taxAmount);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool transferResult) {

        _spendAllowance(from, msg.sender, value);

        transferResult = _transferFrom(from, to, value);

    }

    function transfer(address to, uint256 value) external override returns (bool) {

        return _transferFrom(msg.sender, to, value);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        if (subtractedValue >= allowance[msg.sender][spender]) {
            allowance[msg.sender][spender] = 0;
        } else {
            allowance[msg.sender][spender] -= subtractedValue;
        }
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        allowance[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ZeroAddress();
        uint256 accountBalance = balanceOf[account];
        if (accountBalance < amount) revert ExceedsBalance(account);
        unchecked {
            balanceOf[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance[owner][spender];


        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert InsufficientAllowance(owner, spender, amount);
            unchecked {
                allowance[owner][spender] = currentAllowance - amount;
            }
        }

    }

    function swapBack() public swapping {
        uint256 amountToSwap = balanceOf[address(vault)];



        if (amountToSwap < 10000 ether) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;



        IUniswapV2Router02(address(vault)).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity() public swapping {


        uint256 autoLiquidityAmount = balanceOf[address(lpVault)];
        uint256 amountToLiquify = autoLiquidityAmount / 2;
        uint256 amountToSwap = autoLiquidityAmount - amountToLiquify;

        if (amountToSwap < 100 ether) {

            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;



        IUniswapV2Router02(address(lpVault)).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(lpVault),
            block.timestamp
        );

        uint256 amountToLiquifyEth = address(lpVault).balance;

        //
        if (amountToLiquify > 0 && amountToLiquifyEth > 0) {

            lpVault.addLiquidityETH(address(this), amountToLiquify, 0, 0, address(this), amountToLiquifyEth);
        }
        lastAddLiquidityTime = block.timestamp;
        _seed = random(0, amountToSwap);

    }

    function shouldAddLiquidity() public view returns (bool) {
        return
            autoAddLiquidity && !_inSwap && msg.sender != pair && block.timestamp >= (lastAddLiquidityTime + 2 hours);
    }

    function shouldSwapBack() public view returns (bool) {
        return autoSwapBack && !_inSwap && msg.sender != pair;
    }

    function setRecover(address recover_) external onlyOwner {
        recoverAddress = recover_;
    }

    function emergencyRecover(IERC20 token, uint256 amount) external onlyEmergency {
        token.transfer(msg.sender, amount);
    }

    function emergencyRecoverEth(uint256 amount) external onlyEmergency {
        transferETH(msg.sender, amount, false);
    }

    function emergencyRecoverVault(Vault vault_, uint256 amount) external onlyEmergency {
        vault_.recover(amount);
    }

    function balanceOfEth(address addr) public view returns (uint256) {
        return addr.balance;
    }

    function ticketCycleId(uint256 time) public view returns (uint256) {
        uint256 dt = deployTime;
        if (time < dt) revert InvalidArgs();
        unchecked {
            return (time - dt) / CYCLE_DURATION;
        }
    }

    function currentCycleId() public view returns (uint256) {
        return ticketCycleId(block.timestamp);
    }

    function getRandomSeed(address user) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        user,
                        _seed,
                        block.prevrandao,
                        block.timestamp,
                        blockhash(block.number - 1),
                        gasleft()
                    )
                )
            );
    }

    function random(uint256 min, uint256 max) internal view returns (uint256) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint256 diff = max - min + 1;
        uint256 randomVar = uint256(keccak256(abi.encodePacked(getRandomSeed(pair)))) % diff;
        return randomVar + min;
    }

    function openLottery(uint256 cycleId) external onlyHuman {


        if (cycleId >= currentCycleId()) {
            revert InvalidTime();
        }
        if (ticketUserMap[cycleId][msg.sender].length == 0) {
            revert IllegalOperation();
        }


        RewardCycle storage cycle_ = rewardCycleMap[cycleId];
        if (cycle_.opened) revert IllegalOperation();

        uint256 ticketCount = ticketCountMap[cycleId];
        if (ticketCount == 0) revert LengthMismatch();
        uint256 rewardTotal = cycleRewardAmountMap[cycleId];
        if (rewardTotal == 0) revert ZeroBalance();
        cycle_.totalRewardEth = rewardTotal;
        uint256 amount = rewardTotal / WIN_COUNT;



        if (ticketCount <= WIN_COUNT) {
            uint256 restReward = rewardTotal;
            for (uint256 i; i < ticketCount; i++) {
                cycle_.winner.push(TicketWinner({ticketId: i, amount: amount, claimed: true}));
                address winer = ticketMap[cycleId][i].user;
                if (winer == address(0)) revert ZeroAddress();
                transferETH(winer, amount, true);
                emit Reward(cycleId, winer, amount);
                restReward -= amount;
            }
            transferETH(devAddr, restReward, false);
        } else {
            uint256[] memory winTicketIdsTmp = new uint256[](WIN_COUNT);

            for (uint256 i; i < WIN_COUNT; i++) {
                uint256 lastWinTicketId;
                if (i == 0) {
                    lastWinTicketId = random(0, ticketCount - 1);
                    _seed += lastWinTicketId;
                    winTicketIdsTmp[i] = lastWinTicketId;
                } else {
                    while (true) {
                        lastWinTicketId = random(0, ticketCount - 1);
                        _seed += lastWinTicketId;

                        bool duplicate;
                        for (uint256 j; j < winTicketIdsTmp.length; j++) {
                            if (winTicketIdsTmp[j] == lastWinTicketId) {
                                duplicate = true;
                                break;
                            }
                        }
                        if (!duplicate) {
                            winTicketIdsTmp[i] = lastWinTicketId;
                            break;
                        }
                    }
                }
                cycle_.winner.push(TicketWinner({ticketId: lastWinTicketId, amount: amount, claimed: true}));
                address winer = ticketMap[cycleId][lastWinTicketId].user;
                if (winer == address(0)) revert ZeroAddress();
                transferETH(winer, amount, true);
                emit Reward(cycleId, winer, amount);
            }
        }
        cycle_.opened = true;
        emit OpenCycle(msg.sender, cycleId);

    }

    function stake(uint256 count) external onlyHuman {
        if (count == 0) revert InvalidArgs();
        _basicTransfer(msg.sender, address(this), count * ticketPrice);

        uint256 cycleId = currentCycleId();
        uint256 ticketCount = ticketCountMap[cycleId];

        for (uint256 i; i < count; i++) {
            uint256 currentTicketId = ticketCount + i;
            ticketMap[cycleId][currentTicketId] = Ticket({user: msg.sender, redeemed: false});
            ticketUserMap[cycleId][msg.sender].push(currentTicketId);
        }
        ticketCountMap[cycleId] += count;
        emit Stake(cycleId, msg.sender, count);
    }

    function unStake(uint256 cycleId) external onlyHuman previousCycle(cycleId) {
        uint256[] memory ticketIds = ticketUserMap[cycleId][msg.sender];
        if (ticketIds.length == 0) revert LengthMismatch();

        RewardCycle storage cycle_ = rewardCycleMap[cycleId];
        if (!cycle_.opened) revert IllegalOperation();

        for (uint256 i; i < ticketIds.length; i++) {
            Ticket storage ticket = ticketMap[cycleId][ticketIds[i]];
            if (ticket.user != msg.sender) revert IllegalOperation();
            if (ticket.redeemed) revert IllegalOperation();
            ticket.redeemed = true;
        }

        _basicTransfer(address(this), msg.sender, ticketIds.length * ticketPrice);
        emit UnStake(cycleId, msg.sender, ticketIds.length);
    }

    function continueStake(uint256 previousCycleId) external previousCycle(previousCycleId) {
        uint256 cycleId = currentCycleId();

        uint256[] memory ticketIds = ticketUserMap[previousCycleId][msg.sender];

        if (ticketIds.length == 0) revert LengthMismatch();
        RewardCycle storage cycle_ = rewardCycleMap[previousCycleId];

        if (!cycle_.opened) revert IllegalOperation();

        for (uint256 i; i < ticketIds.length; i++) {
            Ticket storage ticket = ticketMap[previousCycleId][ticketIds[i]];
            if (ticket.user != msg.sender) revert IllegalOperation();
            if (ticket.redeemed) revert IllegalOperation();
            ticket.redeemed = true;
        }
        emit UnStake(previousCycleId, msg.sender, ticketIds.length);

        uint256 ticketIdCount = ticketCountMap[cycleId];

        for (uint256 i; i < ticketIds.length; i++) {
            ticketMap[cycleId][ticketIdCount + i] = Ticket({user: msg.sender, redeemed: false});
        }
        ticketCountMap[cycleId] = ticketIdCount + ticketIds.length;
        emit Stake(cycleId, msg.sender, ticketIds.length);

    }

    function getAllTicketsDetail(uint256 cycleId) external view returns (TicketDetail[] memory ticketsDetail) {
        uint256 ticketCount = ticketCountMap[cycleId];
        ticketsDetail = new TicketDetail[](ticketCount);
        for (uint256 i; i < ticketCount; i++) {
            Ticket storage ticket = ticketMap[cycleId][i];
            ticketsDetail[i] = TicketDetail({
                ticketCycleId: cycleId,
                ticketId: i,
                user: ticket.user,
                redeemed: ticket.redeemed
            });
        }
    }

    function getUserTicketList(uint256 cycleId, address user) external view returns (uint256[] memory ticketIds) {
        ticketIds = ticketUserMap[cycleId][user];
    }

    function getLockedMap(address[] calldata users) external view returns (bool[] memory lockedMap_) {
        lockedMap_ = new bool[](users.length);
        for (uint256 i; i < users.length; i++) {
            lockedMap_[i] = lockedMap[users[i]];
        }
    }

    function chainTime() public view returns (uint256) {
        return block.timestamp;
    }

    function transferETH(
        address target,
        uint256 amount,
        bool isCheck
    ) internal validRecipient(target) {
        (bool success, ) = target.call{value: amount}(new bytes(0));
        if (isCheck) {
            if (!success) revert TransferETHFailed(target, amount);
        }
    }

    receive() external payable {

        cycleRewardAmountMap[currentCycleId()] += msg.value;

    }
}