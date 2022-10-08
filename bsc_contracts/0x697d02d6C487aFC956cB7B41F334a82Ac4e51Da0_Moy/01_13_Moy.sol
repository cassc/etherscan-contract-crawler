// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./library/PancakeLibrary.sol";
import "./library/Math.sol";
import "./library/SafeMath.sol";
import "./interface/IPancakeRouter.sol";
import "./interface/IPancakePair.sol";
import "./interface/IPancakeFactory.sol";

contract Moy is IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using BitMaps for BitMaps.BitMap;

    event Bind(address user, address parent);

    event Fee(address indexed from, address indexed to, uint256 amount);

    address private constant ROUTER_ADDRESS =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private constant USDT_ADDRESS =
        0x55d398326f99059fF775485246999027B3197955;

    uint256 public constant PERIOD = 12 hours;

    uint256 public constant RATE1 = 10;
    uint256 public constant RATE2 = 11;
    uint256 public constant RATE3 = 12;
    uint256 public constant RATE4 = 14;
    uint256 public constant RATE5 = 17;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    mapping(address => address) public parents;

    mapping(address => bytes6) public accountToCode;

    mapping(bytes6 => address) public codeToAccount;

    mapping(bytes32 => address[]) public children;

    address public sellExiAddress = address(2);

    address public sellEaiAddress = address(3);

    address public sellTreaturyAddress = address(4);

    address public buyLeaderAddress = address(5);

    uint256 public initTimestamp;

    address public pair;

    mapping(uint24 => uint256) public lpPerEpoch;

    mapping(uint24 => uint256) public moyPerEpoch;

    mapping(address => uint256) public liquidityPerAccount;

    mapping(address => uint24) public lastEpochPerAccount;

    mapping(address => uint256) public buymoyPerAccount;

    mapping(address => uint256) public feePerAccount;

    address[] public lpAccounts;

    BitMaps.BitMap private hasLp;

    BitMaps.BitMap private sellWhitelist;

    BitMaps.BitMap private buyWhitelist;

    BitMaps.BitMap private transferWhitelist;

    constructor(address _receiver, address genesis) {
        _name = "moeny";
        _symbol = "MOY";
        initTimestamp = block.timestamp;
        pair = IPancakeFactory(IPancakeRouter(ROUTER_ADDRESS).factory())
            .createPair(address(this), USDT_ADDRESS);
        uint256 amount = 80259395 * 10**decimals();
        parents[genesis] = address(1);
        bytes6 code = generateCode(genesis);
        accountToCode[genesis] = code;
        codeToAccount[code] = genesis;
        emit Bind(genesis, address(1));
        parents[_receiver] = genesis;
        code = generateCode(_receiver);
        accountToCode[_receiver] = code;
        codeToAccount[code] = _receiver;
        addChild(_receiver, genesis);
        emit Bind(_receiver, genesis);
        _mint(_receiver, amount);
        addBuyWhitelist(_receiver);
        addSellWhitelist(_receiver);
        addTransferWhitelist(_receiver);
        addBuyWhitelist(genesis);
        addSellWhitelist(genesis);
        addTransferWhitelist(genesis);
    }

    function airdropNoParent(address[] calldata addr, uint256[] calldata amount)
        external
        onlyOwner
    {
        require(addr.length == amount.length, "addrLen!=amountLen");
        uint24 curPeriod = getCurrentEpoch();
        for (uint256 i = 0; i < addr.length; ++i) {
            address adr = addr[i];
            uint256 a = amount[i];
            require(adr != address(0), "ERC20: mint to the zero address");
            _totalSupply += a;
            uint256 curB = balanceOf(adr);
            updateAccount(
                curPeriod,
                lastEpochPerAccount[adr],
                adr,
                curB - _balances[adr]
            );
            _balances[adr] = curB + a;
            emit Transfer(address(0), adr, a);
        }
    }

    function addTransferWhitelist(address adr) public onlyOwner {
        transferWhitelist.set(uint256(uint160(adr)));
    }

    function removeTransferWhitelist(address adr) public onlyOwner {
        transferWhitelist.unset(uint256(uint160(adr)));
    }

    function getTransferWhitelist(address adr) public view returns (bool) {
        return transferWhitelist.get(uint256(uint160(adr)));
    }

    function addSellWhitelist(address adr) public onlyOwner {
        sellWhitelist.set(uint256(uint160(adr)));
    }

    function removeSellWhitelist(address adr) public onlyOwner {
        sellWhitelist.unset(uint256(uint160(adr)));
    }

    function getSellWhitelist(address adr) public view returns (bool) {
        return sellWhitelist.get(uint256(uint160(adr)));
    }

    function addBuyWhitelist(address adr) public onlyOwner {
        buyWhitelist.set(uint256(uint160(adr)));
    }

    function removeBuyWhitelist(address adr) public onlyOwner {
        buyWhitelist.unset(uint256(uint160(adr)));
    }

    function getBuyWhitelist(address adr) public view returns (bool) {
        return buyWhitelist.get(uint256(uint160(adr)));
    }

    function setSellExiAddress(address adr) external onlyOwner {
        sellExiAddress = adr;
        addBuyWhitelist(adr);
        addSellWhitelist(adr);
        addTransferWhitelist(adr);
    }

    function setSellEaiAddress(address adr) external onlyOwner {
        sellEaiAddress = adr;
        addBuyWhitelist(adr);
        addSellWhitelist(adr);
        addTransferWhitelist(adr);
    }

    function setSellTreaturyAddress(address adr) external onlyOwner {
        sellTreaturyAddress = adr;
        addBuyWhitelist(adr);
        addSellWhitelist(adr);
        addTransferWhitelist(adr);
    }

    function setbuyLeaderAddress(address adr) external onlyOwner {
        buyLeaderAddress = adr;
        addBuyWhitelist(adr);
        addSellWhitelist(adr);
        addTransferWhitelist(adr);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function totalSupply() public view virtual override returns (uint256) {
        uint256 total = _totalSupply;
        for (uint256 i = 0; i < lpAccounts.length; ++i) {
            address account = lpAccounts[i];
            total += calAccountInterest(account, _balances[account], 0);
        }
        return total;
    }

    function calc(uint256 amount) private pure returns (uint256) {
        uint256 rate;
        if (amount <= 1000 * 1e6) {
            rate = RATE1;
        } else if (amount <= 3000 * 1e6) {
            rate = RATE2;
        } else if (amount <= 10000 * 1e6) {
            rate = RATE3;
        } else if (amount <= 30000 * 1e6) {
            rate = RATE4;
        } else {
            rate = RATE5;
        }
        return (amount * rate) / 1000;
    }

    function getCurrentEpoch() public view returns (uint24) {
        return uint24((block.timestamp - initTimestamp) / PERIOD);
    }

    function canInterest(address adr) private view returns (bool) {
        if (adr.isContract() || adr == address(0)) {
            return false;
        }
        return true;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 balance = _balances[account];
        return balance + calAccountInterest(account, balance, 0);
    }

    function calAccountInterest(
        address account,
        uint256 balance,
        uint256 removedLp
    ) private view returns (uint256) {
        uint24 i = lastEpochPerAccount[account] + 1;
        uint256 curEpoch = getCurrentEpoch();
        if (!canInterest(account) || i > curEpoch) {
            return 0;
        }
        uint24 smallEpoch = i;
        if (lpPerEpoch[smallEpoch] == 0) {
            return 0;
        }
        uint256 lastEpochLp = lpPerEpoch[smallEpoch];
        uint256 lastEpochMoy = moyPerEpoch[smallEpoch];
        uint256 interest;
        uint256 liquidity = liquidityPerAccount[account];
        uint256 lpBalance = IPancakePair(pair).balanceOf(account) + removedLp;
        uint256 effectLp = Math.min(liquidity, lpBalance);
        uint256 moy;
        for (; i <= curEpoch; ++i) {
            uint256 iLp = lpPerEpoch[i];
            if (iLp == 0) {
                moy = (effectLp * lastEpochMoy) / lastEpochLp;
            } else {
                lastEpochMoy = moyPerEpoch[i];
                lastEpochLp = lpPerEpoch[i];
                moy = (effectLp * lastEpochMoy) / lastEpochLp;
            }
            if (balance > moy) {
                return 0;
            }
            interest += calc(moy);
            if (balance + interest > moy) {
                interest = moy - balance;
                break;
            }
        }
        return interest;
    }

    function balanceOf(address account, uint256 removedLiq)
        private
        view
        returns (uint256)
    {
        uint256 balance = _balances[account];
        return balance + calAccountInterest(account, balance, removedLiq);
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

    function updateAccount(
        uint24 currentEpoch,
        uint24 lastPeriod,
        address account,
        uint256 interest
    ) private {
        if (currentEpoch > lastPeriod) {
            lastEpochPerAccount[account] = currentEpoch;
            _totalSupply += interest;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 tranType = 0;
        uint256 changedLp;
        uint256 feeToLp;
        if (to == pair) {
            (uint112 r0, uint112 r1, ) = IPancakePair(pair).getReserves();
            uint256 amountA;
            if (r0 > 0 && r1 > 0) {
                amountA = IPancakeRouter(ROUTER_ADDRESS).quote(amount, r1, r0);
            }
            uint256 balanceA = IERC20(USDT_ADDRESS).balanceOf(pair);
            if (balanceA < r0 + amountA) {
                tranType = 1;
            } else {
                tranType = 2;
                (changedLp, feeToLp) = calLiquidity(balanceA, amount, r0, r1);
            }
        }
        if (from == pair) {
            (uint112 r0, uint112 r1, ) = IPancakePair(pair).getReserves();
            uint256 amountA;
            if (r0 > 0 && r1 > 0) {
                amountA = IPancakeRouter(ROUTER_ADDRESS).getAmountIn(
                    amount,
                    r0,
                    r1
                );
            }
            uint256 balanceA = IERC20(USDT_ADDRESS).balanceOf(pair);
            if (balanceA > r0 + amountA) {
                tranType = 3;
            } else {
                tranType = 4;
            }
        }

        uint24 currentEpoch = getCurrentEpoch();

        uint256 oldBalance = balanceOf(from);
        require(oldBalance >= amount, "ERC20: transfer amount exceeds balance");
        updateAccount(
            currentEpoch,
            lastEpochPerAccount[from],
            from,
            oldBalance - _balances[from]
        );
        unchecked {
            _balances[from] = oldBalance - amount;
        }

        uint256 subAmount;
        if (tranType == 0) {
            if (!transferWhitelist.get(uint256(uint160(from)))) {
                subAmount = (amount * 15) / 100;
                _balances[address(0)] += subAmount;
                emit Transfer(from, address(0), subAmount);
            }
        } else if (tranType == 1) {
            if (!sellWhitelist.get(uint256(uint160(from)))) {
                uint256 amount50 = (amount * 50) / 1000;
                uint256 curB = balanceOf(sellExiAddress);
                updateAccount(
                    currentEpoch,
                    lastEpochPerAccount[sellExiAddress],
                    sellExiAddress,
                    curB - _balances[sellExiAddress]
                );
                _balances[sellExiAddress] = curB + amount50;
                emit Fee(from, sellExiAddress, amount50);
                curB = balanceOf(sellEaiAddress);
                updateAccount(
                    currentEpoch,
                    lastEpochPerAccount[sellEaiAddress],
                    sellEaiAddress,
                    curB - _balances[sellEaiAddress]
                );
                _balances[sellEaiAddress] = curB + amount50;
                emit Fee(from, sellEaiAddress, amount50);
                uint256 amount25 = (amount * 25) / 1000;
                _balances[address(0)] += amount25;
                emit Fee(from, address(0), amount25);
                curB = balanceOf(sellTreaturyAddress);
                updateAccount(
                    currentEpoch,
                    lastEpochPerAccount[sellTreaturyAddress],
                    sellTreaturyAddress,
                    curB - _balances[sellTreaturyAddress]
                );
                _balances[sellTreaturyAddress] = curB + amount25;
                emit Fee(from, sellTreaturyAddress, amount25);
                subAmount = amount50 + amount50 + amount25 + amount25;
            }
        } else if (tranType == 2) {
            liquidityPerAccount[from] += changedLp;
            if (!hasLp.get(uint256(uint160(from)))) {
                lpAccounts.push(from);
                hasLp.set(uint256(uint160(from)));
            }
        } else if (tranType == 3) {
            if (!buyWhitelist.get(uint256(uint160(to)))) {
                uint256 amount50 = (amount * 50) / 1000;
                uint256 curB = balanceOf(buyLeaderAddress);
                updateAccount(
                    currentEpoch,
                    lastEpochPerAccount[buyLeaderAddress],
                    buyLeaderAddress,
                    curB - _balances[buyLeaderAddress]
                );
                _balances[buyLeaderAddress] = curB + amount50;
                emit Fee(from, buyLeaderAddress, amount50);
                marketReward(from, to, currentEpoch, amount, amount50);
                _balances[address(0)] += amount50;
                emit Fee(from, address(0), amount50);
                subAmount = amount50 + amount50 + amount50;
            }
            buymoyPerAccount[to] += amount - subAmount;
        } else if (tranType == 4) {
            changedLp =
                ((amount + 1) * IPancakePair(pair).totalSupply()) /
                (balanceOf(pair) - 1);
            uint256 currB = balanceOf(to, changedLp);
            updateAccount(
                currentEpoch,
                lastEpochPerAccount[to],
                to,
                currB - _balances[to]
            );
            _balances[to] = currB;
            liquidityPerAccount[to] -= changedLp;
        }

        uint256 toAmount = amount - subAmount;
        oldBalance = balanceOf(to);
        updateAccount(
            currentEpoch,
            lastEpochPerAccount[to],
            to,
            oldBalance - _balances[to]
        );
        _balances[to] = oldBalance + toAmount;

        uint256 lpTotal = IPancakePair(pair).totalSupply();
        if (tranType == 2) {
            if (lpTotal == 0) {
                lpPerEpoch[currentEpoch + 1] = lpTotal + changedLp + 1000;
            } else {
                lpPerEpoch[currentEpoch + 1] = lpTotal + changedLp + feeToLp;
            }
        } else {
            lpPerEpoch[currentEpoch + 1] = lpTotal;
        }
        moyPerEpoch[currentEpoch + 1] = balanceOf(pair);

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
            IPancakeRouter(ROUTER_ADDRESS).factory()
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

    function marketReward(
        address from,
        address to,
        uint24 currentEpoch,
        uint256 amount,
        uint256 restAmount
    ) private {
        address p = parents[to];
        for (
            uint256 i = 1;
            i <= 10 && p != address(0) && p != address(1);
            ++i
        ) {
            uint256 pAmount;
            if (i == 1) {
                pAmount = (amount * 9) / 1000;
            } else if (i == 2) {
                pAmount = (amount * 7) / 1000;
            } else if (i == 3) {
                pAmount = (amount * 5) / 1000;
            } else if (i == 4) {
                pAmount = (amount * 3) / 1000;
            } else if (i == 5) {
                pAmount = amount / 1000;
            } else if (i == 6) {
                pAmount = amount / 1000;
            } else if (i == 7) {
                pAmount = (amount * 3) / 1000;
            } else if (i == 8) {
                pAmount = (amount * 5) / 1000;
            } else if (i == 9) {
                pAmount = (amount * 7) / 1000;
            } else {
                pAmount = restAmount;
            }
            uint256 curB = balanceOf(p);
            updateAccount(
                currentEpoch,
                lastEpochPerAccount[p],
                p,
                curB - _balances[p]
            );
            _balances[p] = curB + pAmount;
            feePerAccount[p] += pAmount;
            emit Fee(from, p, pAmount);
            restAmount -= pAmount;
            p = parents[p];
        }
        if (restAmount > 0) {
            _balances[address(0)] += restAmount;
            emit Fee(from, address(0), restAmount);
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        uint256 curB = balanceOf(account);
        updateAccount(
            getCurrentEpoch(),
            lastEpochPerAccount[account],
            account,
            curB - _balances[account]
        );
        _balances[account] = curB + amount;

        emit Transfer(address(0), account, amount);
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

    function bind(bytes6 pCode) external {
        require(parents[msg.sender] == address(0), "already bind");
        address parent = codeToAccount[pCode];
        require(parents[parent] != address(0), "parent invalid");
        parents[msg.sender] = parent;
        addChild(msg.sender, parent);
        bytes6 code = generateCode(msg.sender);
        accountToCode[msg.sender] = code;
        codeToAccount[code] = msg.sender;
        emit Bind(msg.sender, parent);
    }

    function addChild(address user, address p) private {
        for (
            uint256 i = 1;
            i <= 10 && p != address(0) && p != address(1);
            ++i
        ) {
            children[keccak256(abi.encode(p, i))].push(user);
            p = parents[p];
        }
    }

    function getChildren(address user, uint256 level)
        external
        view
        returns (address[] memory)
    {
        return children[keccak256(abi.encode(user, level))];
    }

    function getChildrenLength(address user, uint256 level)
        external
        view
        returns (uint256)
    {
        return children[keccak256(abi.encode(user, level))].length;
    }

    function getChildrenLength(address user) external view returns (uint256) {
        uint256 len;
        for (uint256 i = 1; i <= 10; ++i) {
            len += children[keccak256(abi.encode(user, i))].length;
        }
        return len;
    }

    function getChildren(
        address user,
        uint256 level,
        uint256 pageIndex,
        uint256 pageSize
    ) external view returns (address[] memory) {
        bytes32 key = keccak256(abi.encode(user, level));
        uint256 len = children[key].length;
        address[] memory list = new address[](
            pageIndex * pageSize <= len
                ? pageSize
                : len - (pageIndex - 1) * pageSize
        );
        uint256 start = (pageIndex - 1) * pageSize;
        for (uint256 i = start; i < start + list.length; ++i) {
            list[i - start] = children[key][i];
        }
        return list;
    }

    function getMoyFee(address[] calldata addr)
        external
        view
        returns (uint256[3][] memory r)
    {
        uint256 lp = IPancakePair(pair).totalSupply();
        uint256 moy = balanceOf(pair);
        r = new uint256[3][](addr.length);
        for (uint256 i = 0; i < addr.length; ++i) {
            uint256 lpBalance = IPancakePair(pair).balanceOf(addr[i]);
            uint256 effectLp = Math.min(
                liquidityPerAccount[addr[i]],
                lpBalance
            );
            r[i] = [
                (effectLp * moy) / lp,
                feePerAccount[addr[i]],
                buymoyPerAccount[addr[i]]
            ];
        }
    }

    function generateCode(address adr) public view returns (bytes6) {
        for (uint8 i = 0; i < 256; ++i) {
            bytes6 c6 = bytes6(
                keccak256(abi.encodePacked(adr, i, block.number))
            );
            bytes memory c = new bytes(6);
            for (uint8 j = 0; j < 6; ++j) {
                uint8 t = uint8(c6[j]) % 36;
                c[j] = bytes1(t < 26 ? t + 65 : t + 22);
            }
            bytes6 rc = bytes6(c);
            if (codeToAccount[rc] == address(0)) {
                return rc;
            }
        }
        revert("generate code error");
    }
}