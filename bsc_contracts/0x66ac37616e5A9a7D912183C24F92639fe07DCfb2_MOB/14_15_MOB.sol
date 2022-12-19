// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./library/Math.sol";
import "./library/SafeMath.sol";
import "./library/PancakeLibrary.sol";
import "./interface/IPancakeRouter01.sol";
import "./interface/IPancakePair.sol";
import "./interface/IPancakeFactory.sol";
import "./interface/IMOBLock.sol";
import "./Rel.sol";

contract MOB is IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using BitMaps for BitMaps.BitMap;

    struct BuyOrder {
        uint256 timestamp;
        uint256 price;
        uint256 amount;
        uint256 claimed;
    }

    event addFeeWl(address indexed adr);

    event removeFeeWl(address indexed adr);

    event addBotWl(address indexed adr);

    event removeBotWl(address indexed adr);

    event addBL(address indexed adr);

    event removeBL(address indexed adr);

    event distributeLpFee(uint256 amount);

    event distributeNftFee(uint256 amount);

    address private constant ROUTER_ADDRESS =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private constant USDT_ADDRESS =
        0x55d398326f99059fF775485246999027B3197955;

    uint256 public constant LP_DIS_AMOUNT = 3000 * 1e18;

    uint256 public constant NFT_DIS_AMOUNT = 6000 * 1e18;

    uint256 public constant initPrice = 1e16;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address public communityAddress;

    address public techAddress;

    address public netAddress;

    address public relAddress;

    address public lockAddress;

    address public comTreasury;

    address public techTreasury;

    uint256 public startTradeTime = 2**200;

    mapping(address => BuyOrder[]) public buyOrderPerAccount;

    address public pair;

    mapping(address => uint256) public buyPerAccount;

    mapping(address => uint256) public sellPerAccount;

    mapping(address => uint256) public feePerAccount;

    BitMaps.BitMap private feeWhitelist;

    BitMaps.BitMap private botWhitelist;

    BitMaps.BitMap private bList;

    uint256 public lpFeeDisAmount;

    uint256 public lpFee;

    uint256 public nftFeeDisAmount;

    uint256 public nftFee;

    constructor(
        address _receiver,
        address _genesis,
        address _techAddress,
        address _communityAddress,
        address _netAddress,
        address _comTreasury,
        address _techTreasury,
        address _relAddress
    ) {
        _name = "MobileCoin";
        _symbol = "MOB";
        techAddress = _techAddress;
        communityAddress = _communityAddress;
        relAddress = _relAddress;
        comTreasury = _comTreasury;
        techTreasury = _techTreasury;
        netAddress = _netAddress;
        pair = IPancakeFactory(IPancakeRouter01(ROUTER_ADDRESS).factory())
            .createPair(address(this), USDT_ADDRESS);
        _mint(_receiver, 1000000 * 10**decimals());
        addFeeWhitelist(_genesis);
        addFeeWhitelist(_receiver);
        addFeeWhitelist(techAddress);
        addFeeWhitelist(communityAddress);
    }

    function setLockAdress(address adr) external onlyOwner {
        lockAddress = adr;
    }

    function setStartTradeTime(uint256 startTime) external onlyOwner {
        startTradeTime = startTime;
    }

    function airdropTreasury() external onlyOwner {
        IMOBLock lock = IMOBLock(lockAddress);
        uint256 amount = 1000000 * 10**decimals();
        _mint(lockAddress, amount);
        lock.lockTreasury(comTreasury, amount);
        amount = 1000000 * 10**decimals();
        _mint(lockAddress, amount);
        lock.lockTreasury(techTreasury, amount);
    }

    function price() public view returns (uint256) {
        (uint256 r0, uint256 r1, ) = IPancakePair(pair).getReserves();
        if (r0 > 0 && r1 > 0) {
            return (r0 * 1e18) / r1;
        }
        return 0;
    }

    function treasuryClaim() external {
        require(
            msg.sender == comTreasury || msg.sender == techTreasury,
            "not allowed call"
        );
        uint256 k = (price() * 10) / initPrice;
        require(k >= 15, "nothing claim");
        uint256 percent = ((k - 10) / 5) * 2;
        if (percent > 100) {
            percent = 100;
        }
        uint256 amount = IMOBLock(lockAddress).releaseTreasury(
            msg.sender,
            percent
        );
        _balances[lockAddress] -= amount;
        _balances[msg.sender] += amount;
        emit Transfer(lockAddress, msg.sender, amount);
    }

    function airdropNFT(address[] calldata adr, uint256[] calldata amount)
        external
        onlyOwner
    {
        require(adr.length == amount.length, "length error");
        require(adr.length <= 1100, "length max 1100");
        IMOBLock lock = IMOBLock(lockAddress);
        for (uint256 i = 0; i < adr.length; ++i) {
            uint256 init = amount[i] / 2;
            uint256 rest = amount[i] - init;
            _mint(adr[i], init);
            _mint(lockAddress, rest);
            lock.lockNFT(adr[i], init, rest);
            addBlist(adr[i]);
        }
    }

    function nftClaim() external {
        uint256 begin = startTradeTime + 30 days * 3;
        require(block.timestamp > begin, "nothing claim");
        uint256 percent = ((block.timestamp - begin) / 30 days) * 3;
        if (percent > 100) {
            percent = 100;
        }
        (uint256 released, uint256 blackhole) = IMOBLock(lockAddress)
            .releaseNFT(msg.sender, percent);
        _balances[lockAddress] -= (released + blackhole);
        _balances[msg.sender] += released;
        emit Transfer(lockAddress, msg.sender, released);
        if (blackhole > 0) {
            _burn(lockAddress, blackhole);
        }
    }

    function availableClaim()
        public
        view
        returns (uint256 avl, uint256 claimed)
    {
        return availableClaim(msg.sender);
    }

    function availableClaim(address adr)
        public
        view
        returns (uint256 avl, uint256 claimed)
    {
        uint256 mp = price() * 100;
        for (uint256 i = 0; i < buyOrderPerAccount[adr].length; ++i) {
            BuyOrder memory bo = buyOrderPerAccount[adr][i];
            claimed += bo.claimed;
            uint256 k = mp / bo.price;
            if (k < 115) {
                continue;
            }
            uint256 percent = ((k - 100) / 15) * 2;
            if (percent > 100) {
                percent = 100;
            }
            uint256 release = (percent * bo.amount) / 100;
            if (release <= bo.claimed) {
                continue;
            }
            avl += (release - bo.claimed);
        }
    }

    function treasuryAvailableClaim()
        public
        view
        returns (uint256 avl, uint256 claimed)
    {
        return treasuryAvailableClaim(msg.sender);
    }

    function treasuryAvailableClaim(address adr)
        public
        view
        returns (uint256 avl, uint256 claimed)
    {
        require(adr == comTreasury || adr == techTreasury, "not allowed call");
        uint256 k = (price() * 10) / initPrice;
        if (k >= 15) {
            uint256 percent = ((k - 10) / 5) * 2;
            if (percent > 100) {
                percent = 100;
            }
            (avl, claimed) = IMOBLock(lockAddress).treasuryAvailableClaim(
                msg.sender,
                percent
            );
        } else {
            (avl, claimed) = IMOBLock(lockAddress).treasuryAvailableClaim(
                msg.sender,
                0
            );
        }
    }

    function nftAvailableClaim()
        public
        view
        returns (uint256 avl, uint256 claimed)
    {
        return nftAvailableClaim(msg.sender);
    }

    function nftAvailableClaim(address adr)
        public
        view
        returns (uint256 avl, uint256 claimed)
    {
        uint256 begin = startTradeTime + 30 days * 3;
        if (block.timestamp > begin) {
            uint256 percent = ((block.timestamp - begin) / 30 days) * 3;
            if (percent > 100) {
                percent = 100;
            }
            (avl, claimed) = IMOBLock(lockAddress).nftAvailableClaim(
                adr,
                percent
            );
        }
    }

    function buyOrderLength(address adr) public view returns (uint256) {
        return buyOrderPerAccount[adr].length;
    }

    function buyOrderList(
        address adr,
        uint256 pageIndex,
        uint256 pageSize
    ) public view returns (BuyOrder[] memory) {
        uint256 mp = price() * 100;
        uint256 len = buyOrderPerAccount[adr].length;
        if (len == 0) {
            return new BuyOrder[](0);
        }
        BuyOrder[] memory list = new BuyOrder[](
            pageIndex * pageSize <= len
                ? pageSize
                : len - (pageIndex - 1) * pageSize
        );
        uint256 start = len - 1 - (pageIndex - 1) * pageSize;
        uint256 end = start > list.length ? start - list.length + 1 : 0;
        for (uint256 i = start; i >= end; ) {
            BuyOrder memory bo = buyOrderPerAccount[adr][i];
            uint256 k = mp / bo.price;
            if (k < 115) {
                list[start - i] = BuyOrder(
                    bo.timestamp,
                    bo.price,
                    bo.amount,
                    bo.claimed
                );
            } else {
                uint256 percent = ((k - 100) / 15) * 2;
                if (percent > 100) {
                    percent = 100;
                }
                uint256 release = (percent * bo.amount) / 100;
                list[start - i] = BuyOrder(
                    bo.timestamp,
                    bo.price,
                    bo.amount,
                    release
                );
            }
            if (i > 0) {
                --i;
            } else {
                break;
            }
        }
        return list;
    }

    function claim() external {
        uint256 amount;
        uint256 mp = price() * 100;
        for (uint256 i = 0; i < buyOrderPerAccount[msg.sender].length; ++i) {
            BuyOrder memory bo = buyOrderPerAccount[msg.sender][i];
            uint256 k = mp / bo.price;
            if (k < 115) {
                continue;
            }
            uint256 percent = ((k - 100) / 15) * 2;
            if (percent > 100) {
                percent = 100;
            }
            uint256 release = (percent * bo.amount) / 100;
            if (release <= bo.claimed) {
                continue;
            }
            amount += (release - bo.claimed);
            buyOrderPerAccount[msg.sender][i].claimed = release;
        }
        if (amount > 0) {
            _balances[lockAddress] -= amount;
            _balances[msg.sender] += amount;
            emit Transfer(lockAddress, msg.sender, amount);
        }
    }

    function addFeeWhitelist(address adr) public onlyOwner {
        feeWhitelist.set(uint256(uint160(adr)));
        emit addFeeWl(adr);
    }

    function removeFeeWhitelist(address adr) public onlyOwner {
        feeWhitelist.unset(uint256(uint160(adr)));
        emit removeFeeWl(adr);
    }

    function getFeeWhitelist(address adr) public view returns (bool) {
        return feeWhitelist.get(uint256(uint160(adr)));
    }

    function addBotWhitelist(address adr) public onlyOwner {
        botWhitelist.set(uint256(uint160(adr)));
        emit addBotWl(adr);
    }

    function removeBotWhitelist(address adr) public onlyOwner {
        botWhitelist.unset(uint256(uint160(adr)));
        emit removeBotWl(adr);
    }

    function getBotWhitelist(address adr) public view returns (bool) {
        return botWhitelist.get(uint256(uint160(adr)));
    }

    function addBlist(address adr) public onlyOwner {
        bList.set(uint256(uint160(adr)));
        emit addBL(adr);
    }

    function removeBlist(address adr) public {
        require(
            msg.sender == owner() || msg.sender == lockAddress,
            "not allowed call"
        );
        bList.unset(uint256(uint160(adr)));
        emit removeBL(adr);
    }

    function getBlist(address adr) public view returns (bool) {
        return bList.get(uint256(uint160(adr)));
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (to.isContract() && to != pair && to != lockAddress) {
            revert("can't transfer to contract");
        }

        uint256 tranType = 0;
        uint112 r0;
        uint112 r1;
        uint256 balanceA;
        uint256 curPrice;
        if (to == pair) {
            (r0, r1, ) = IPancakePair(pair).getReserves();
            uint256 amountA;
            if (r0 > 0 && r1 > 0) {
                amountA = IPancakeRouter01(ROUTER_ADDRESS).quote(
                    amount,
                    r1,
                    r0
                );
            }
            balanceA = IERC20(USDT_ADDRESS).balanceOf(pair);
            if (balanceA < r0 + amountA) {
                tranType = 1;
            } else {
                tranType = 2;
            }
        }
        if (from == pair) {
            (r0, r1, ) = IPancakePair(pair).getReserves();
            uint256 amountA;
            if (r0 > 0 && r1 > 0) {
                amountA = IPancakeRouter01(ROUTER_ADDRESS).getAmountIn(
                    amount,
                    r0,
                    r1
                );
            }
            balanceA = IERC20(USDT_ADDRESS).balanceOf(pair);
            if (balanceA >= r0 + amountA) {
                require(to == lockAddress, "to must be lockAddress");
                tranType = 3;
                curPrice = ((balanceA - r0) * 1e18) / amount;
            } else {
                tranType = 4;
            }
        }

        if (block.timestamp >= startTradeTime) {
            if (bList.get(uint256(uint160(tx.origin)))) {
                revert("not allowed transfer");
            }
            if (tranType <= 2 && bList.get(uint256(uint160(from)))) {
                revert("not allowed transfer");
            }
            if (tranType == 3 && bList.get(uint256(uint160(tx.origin)))) {
                revert("not allowed transfer");
            }
            if (tranType == 4 && bList.get(uint256(uint160(to)))) {
                revert("not allowed transfer");
            }
        } else if (tranType != 2) {
            revert("not allowed now");
        }

        uint256 oldBalance = balanceOf(from);
        require(oldBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = oldBalance - amount;
        }

        uint256 subAmount;
        if (tranType == 1) {
            if (!feeWhitelist.get(uint256(uint160(from)))) {
                uint256 marketAmount = (amount * 20) / 1000;
                marketSellReward(from, amount, marketAmount);
                subAmount += marketAmount;
                subAmount += shareFee(
                    from,
                    address(this),
                    (amount * 20) / 1000,
                    1
                );
                subAmount += shareFee(
                    from,
                    address(this),
                    (amount * 15) / 1000,
                    2
                );
                subAmount += _burn(from, (amount * 10) / 1000);
                subAmount += shareFee(
                    from,
                    communityAddress,
                    (amount * 7) / 1000,
                    0
                );
                subAmount += shareFee(
                    from,
                    techAddress,
                    (amount * 8) / 1000,
                    0
                );
            }
            sellPerAccount[from] += amount;
        } else if (tranType == 2) {
            if (block.timestamp < startTradeTime) {
                (uint256 addedLp, ) = calLiquidity(balanceA, amount, r0, r1);
                _burn(from, _balances[from]);
                _balances[from] = 0;
                IMOBLock(lockAddress).addLiq(from, amount, addedLp);
            }
        } else if (tranType == 3) {
            if (!feeWhitelist.get(uint256(uint160(tx.origin)))) {
                uint256 marketAmount = (amount * 20) / 1000;
                marketBuyReward(tx.origin, amount, marketAmount);
                subAmount += marketAmount;
                subAmount += shareFee(
                    tx.origin,
                    address(this),
                    (amount * 20) / 1000,
                    1
                );
                subAmount += shareFee(
                    tx.origin,
                    address(this),
                    (amount * 15) / 1000,
                    2
                );
                subAmount += _burn(tx.origin, (amount * 10) / 1000);
                subAmount += shareFee(
                    tx.origin,
                    communityAddress,
                    (amount * 7) / 1000,
                    0
                );
                subAmount += shareFee(
                    tx.origin,
                    techAddress,
                    (amount * 8) / 1000,
                    0
                );
            }
            BuyOrder memory bo = BuyOrder(
                block.timestamp,
                curPrice,
                amount - subAmount,
                0
            );
            buyOrderPerAccount[tx.origin].push(bo);
            buyPerAccount[tx.origin] += (amount - subAmount);
        }

        uint256 toAmount = amount - subAmount;
        _balances[to] += toAmount;
        emit Transfer(from, to, toAmount);
    }

    function calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint112 r0,
        uint112 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = IPancakePair(pair).totalSupply();
        address feeTo = IPancakeFactory(
            IPancakeRouter01(ROUTER_ADDRESS).factory()
        ).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = IPancakePair(pair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(r0).mul(r1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = pairTotalSupply
                        .mul(rootK.sub(rootKLast))
                        .mul(8);
                    uint256 denominator = rootK.mul(17).add(rootKLast.mul(8));
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount) - 1000;
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }

    function shareFee(
        address from,
        address to,
        uint256 amount,
        uint256 t
    ) private returns (uint256) {
        _balances[to] += amount;
        feePerAccount[to] += amount;
        emit Transfer(from, to, amount);
        if (t == 1) {
            lpFee += amount;
            uint256 r = lpFee / LP_DIS_AMOUNT;
            if (r > 0) {
                lpFee = lpFee % LP_DIS_AMOUNT;
                lpFeeDisAmount += LP_DIS_AMOUNT * r;
                emit distributeLpFee(LP_DIS_AMOUNT * r);
            }
        } else if (t == 2) {
            nftFee += amount;
            uint256 r = nftFee / NFT_DIS_AMOUNT;
            if (r > 0) {
                nftFee = nftFee % NFT_DIS_AMOUNT;
                nftFeeDisAmount += NFT_DIS_AMOUNT * r;
                emit distributeNftFee(NFT_DIS_AMOUNT * r);
            }
        }
        return amount;
    }

    function marketBuyReward(
        address to,
        uint256 amount,
        uint256 restAmount
    ) private {
        Rel rel = Rel(relAddress);
        address p = rel.parents(to);
        for (uint256 i = 1; i <= 5 && p != address(0) && p != address(1); ++i) {
            uint256 pAmount;
            if (i == 1) {
                pAmount = (amount * 6) / 1000;
            } else if (i == 2) {
                pAmount = (amount * 5) / 1000;
            } else if (i == 3) {
                pAmount = (amount * 4) / 1000;
            } else if (i == 4) {
                pAmount = (amount * 3) / 1000;
            } else {
                pAmount = restAmount;
            }
            _balances[p] += pAmount;
            feePerAccount[p] += pAmount;
            emit Transfer(to, p, pAmount);
            restAmount -= pAmount;
            p = rel.parents(p);
        }
        if (restAmount > 0) {
            _balances[netAddress] += restAmount;
            feePerAccount[netAddress] += restAmount;
            emit Transfer(to, netAddress, restAmount);
        }
    }

    function marketSellReward(
        address to,
        uint256 amount,
        uint256 restAmount
    ) private {
        Rel rel = Rel(relAddress);
        address p = rel.parents(to);
        for (uint256 i = 1; i <= 3 && p != address(0) && p != address(1); ++i) {
            uint256 pAmount;
            if (i == 1) {
                pAmount = (amount * 8) / 1000;
            } else if (i == 2) {
                pAmount = (amount * 6) / 1000;
            } else {
                pAmount = restAmount;
            }
            _balances[p] += pAmount;
            feePerAccount[p] += pAmount;
            emit Transfer(to, p, pAmount);
            restAmount -= pAmount;
            p = rel.parents(p);
        }
        if (restAmount > 0) {
            _balances[netAddress] += restAmount;
            feePerAccount[netAddress] += restAmount;
            emit Transfer(to, netAddress, restAmount);
        }
    }

    function disLpFee(address[] calldata addr, uint256[] calldata amount)
        external
    {
        require(
            botWhitelist.get(uint256(uint160(msg.sender))),
            "not allowed call"
        );
        require(addr.length == amount.length, "addrLen!=amountLen");
        require(addr.length <= 500, "addrLen max 500");
        uint256 total;
        for (uint256 i = 0; i < addr.length; ++i) {
            address adr = addr[i];
            uint256 a = amount[i];
            _transfer(address(this), adr, a);
            total += a;
        }
        lpFeeDisAmount -= total;
    }

    function disNftFee(address[] calldata addr, uint256[] calldata amount)
        external
    {
        require(
            botWhitelist.get(uint256(uint160(msg.sender))),
            "not allowed call"
        );
        require(addr.length == amount.length, "addrLen!=amountLen");
        require(addr.length <= 500, "addrLen max 500");
        uint256 total;
        for (uint256 i = 0; i < addr.length; ++i) {
            address adr = addr[i];
            uint256 a = amount[i];
            _transfer(address(this), adr, a);
            total += a;
        }
        nftFeeDisAmount -= total;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        require(_totalSupply <= 25000000 * 10**decimals(), "max mint");
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private returns (uint256) {
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        return amount;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function getInfo(address[] calldata addr)
        external
        view
        returns (uint256[4][] memory r)
    {
        uint256 lp = IPancakePair(pair).totalSupply();
        uint256 tokenAmount = balanceOf(pair);
        r = new uint256[4][](addr.length);
        for (uint256 i = 0; i < addr.length; ++i) {
            uint256 lpBalance = IPancakePair(pair).balanceOf(addr[i]);
            r[i] = [
                lp > 0 ? (lpBalance * tokenAmount) / lp : 0,
                feePerAccount[addr[i]],
                buyPerAccount[addr[i]],
                sellPerAccount[addr[i]]
            ];
        }
    }
}