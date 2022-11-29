// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./library/PancakeLibrary.sol";
import "./interface/IPancakeRouter.sol";
import "./interface/IPancakePair.sol";
import "./interface/IPancakeFactory.sol";
import "./Rel.sol";

contract Icc is IERC20, IERC20Metadata, Ownable {
    using Address for address;
    using BitMaps for BitMaps.BitMap;

    event addBotWl(address indexed adr);

    event removeBotWl(address indexed adr);

    event addBL(address indexed adr);

    event removeBL(address indexed adr);

    event addWL(address indexed adr);

    event removeWL(address indexed adr);

    event openSetted(bool f);

    event distributeLpFee(
        address eco,
        uint256 rate,
        uint256 amount,
        uint256 restAmount
    );

    address private constant ROUTER_ADDRESS =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private constant USDT_ADDRESS =
        0x55d398326f99059fF775485246999027B3197955;

    uint256 public constant DIS_AMOUNT = 30000 * 1e18;

    uint256 public constant INIT_AMOUNT = 50000000 * 1e18;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address public leaderAddress;

    address public marketAddress;

    address public techAddress;

    address public sellCommunityAddress;

    address public subComAddress;

    address public groupAddress;

    address public relAddress;

    address public pair;

    mapping(address => uint256) public buyPerAccount;

    mapping(address => uint256) public feePerAccount;

    BitMaps.BitMap private botWhitelist;

    BitMaps.BitMap private bList;

    BitMaps.BitMap private wList;

    bool public isOpen = false;

    uint256 public lpFeeDisAmount;

    constructor(
        address _receiver,
        address _leaderAddress,
        address _sellCommunityAddress,
        address _marketAddress,
        address _subComAddress,
        address _groupAddress,
        address _techAddress,
        address _relAddress,
        address bot
    ) {
        _name = "ideal cooperative community";
        _symbol = "ICC";
        leaderAddress = _leaderAddress;
        sellCommunityAddress = _sellCommunityAddress;
        marketAddress = _marketAddress;
        subComAddress = _subComAddress;
        groupAddress = _groupAddress;
        techAddress = _techAddress;
        relAddress = _relAddress;
        pair = IPancakeFactory(IPancakeRouter(ROUTER_ADDRESS).factory())
            .createPair(address(this), USDT_ADDRESS);
        _mint(_receiver, INIT_AMOUNT);
        addBotWhitelist(bot);
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

    function removeBlist(address adr) public onlyOwner {
        bList.unset(uint256(uint160(adr)));
        emit removeBL(adr);
    }

    function getBlist(address adr) public view returns (bool) {
        return bList.get(uint256(uint160(adr)));
    }

    function addWlist(address adr) public onlyOwner {
        wList.set(uint256(uint160(adr)));
        emit addWL(adr);
    }

    function removeWlist(address adr) public onlyOwner {
        wList.unset(uint256(uint160(adr)));
        emit removeWL(adr);
    }   

    function getWlist(address adr) public view returns (bool) {
        return wList.get(uint256(uint160(adr)));
    }

     function setOpen(bool f) public onlyOwner {
        isOpen = f;
        emit openSetted(f);
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

        uint256 tranType = 0;
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
            if (balanceA >= r0 + amountA) {
                tranType = 3;
            } else {
                tranType = 4;
            }
        }
        if(bList.get(uint256(uint160(tx.origin)))) {
            revert("not allowed transfer");
        }
        if (tranType <= 2 && bList.get(uint256(uint160(from)))) {
            revert("not allowed transfer");
        }
        if (tranType > 2 && bList.get(uint256(uint160(to)))) {
            revert("not allowed transfer");
        }

        uint256 oldBalance = balanceOf(from);
        require(oldBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = oldBalance - amount;
        }

        uint256 subAmount;
        if (tranType == 1) {
            if (!wList.get(uint256(uint160(from)))) {
                subAmount += shareFee(
                    from,
                    sellCommunityAddress,
                    (amount * 20) / 1000
                );
                subAmount += shareFee(
                    from,
                    marketAddress,
                    (amount * 20) / 1000
                );
                subAmount += shareFee(
                    from,
                    subComAddress,
                    (amount * 20) / 1000
                );
                subAmount += shareFee(
                    from,
                    address(this),
                    (amount * 20) / 1000
                );
                subAmount += shareFee(from, groupAddress, (amount * 20) / 1000);
                if (!isOpen) {
                    bList.set(uint256(uint160(from)));
                    emit addBL(from);
                    if (from != tx.origin && !wList.get(uint256(uint160(tx.origin)))) {
                        bList.set(uint256(uint160(tx.origin)));
                        emit addBL(tx.origin);
                    }
                }
            }
        } else if (tranType == 3) {
            if (!wList.get(uint256(uint160(to)))) {
                subAmount += shareFee(to, address(this), (amount * 20) / 1000);
                subAmount += shareFee(to, techAddress, (amount * 20) / 1000);
                subAmount += shareFee(to, leaderAddress, (amount * 30) / 1000);
                subAmount += shareFee(to, address(0), (amount * 10) / 1000);
                uint256 marketAmount = (amount * 20) / 1000;
                marketReward(to, amount, marketAmount);
                subAmount += marketAmount;
                if (!isOpen) {
                    bList.set(uint256(uint160(to)));
                    emit addBL(to);
                    if (to != tx.origin && !wList.get(uint256(uint160(tx.origin)))) {
                        bList.set(uint256(uint160(tx.origin)));
                        emit addBL(tx.origin);
                    }
                }
            }
            buyPerAccount[to] += amount - subAmount;
        }

        uint256 toAmount = amount - subAmount;
        _balances[to] += toAmount;
        emit Transfer(from, to, toAmount);

        if (balanceOf(address(this)) >= lpFeeDisAmount) {
            uint256 lpFeeRest = balanceOf(address(this)) - lpFeeDisAmount;
            if (lpFeeRest >= DIS_AMOUNT) {
                lpFeeDisAmount += DIS_AMOUNT;
                emit distributeLpFee(
                    address(0),
                    15,
                    DIS_AMOUNT,
                    lpFeeRest - DIS_AMOUNT
                );
            }
        }
    }

    function shareFee(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256) {
        _balances[to] += amount;
        feePerAccount[to] += amount;
        emit Transfer(from, to, amount);
        return amount;
    }

    function marketReward(
        address to,
        uint256 amount,
        uint256 restAmount
    ) private {
        Rel rel=Rel(relAddress);
        address p = rel.parents(to);
        for (uint256 i = 1; i <= 2 && p != address(0) && p != address(1); ++i) {
            uint256 pAmount;
            if (i == 1) {
                pAmount = (amount * 10) / 1000;
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
            _balances[address(0)] += restAmount;
            feePerAccount[address(0)] += restAmount;
            emit Transfer(to, address(0), restAmount);
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
        require(addr.length <= 300, "addrLen max 300");
        uint256 total;
        for (uint256 i = 0; i < addr.length; ++i) {
            address adr = addr[i];
            uint256 a = amount[i];
            _transfer(address(this), adr, a);
            total += a;
        }
        lpFeeDisAmount -= total;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

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

    function getInfo(address[] calldata addr)
        external
        view
        returns (uint256[3][] memory r)
    {
        uint256 lp = IPancakePair(pair).totalSupply();
        uint256 tokenAmount = balanceOf(pair);
        r = new uint256[3][](addr.length);
        for (uint256 i = 0; i < addr.length; ++i) {
            uint256 lpBalance = IPancakePair(pair).balanceOf(addr[i]);
            r[i] = [
                lp > 0 ? (lpBalance * tokenAmount) / lp : 0,
                feePerAccount[addr[i]],
                buyPerAccount[addr[i]]
            ];
        }
    }
}