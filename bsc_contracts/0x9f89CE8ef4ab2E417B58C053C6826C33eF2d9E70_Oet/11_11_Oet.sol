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

contract Oet is IERC20, IERC20Metadata, Ownable {
    using Address for address;
    using BitMaps for BitMaps.BitMap;

    /// @dev 绑定上下级关系
    /// @param user 用户地址
    /// @param parent 上级地址
    event Bind(address indexed user, address indexed parent);

    event addFeeWl(address indexed adr);

    event removeFeeWl(address indexed adr);

    event addBotWl(address indexed adr);

    event removeBotWl(address indexed adr);

    /// @dev 可分配lpFee
    /// @param eco 生态地址
    /// @param rate 生态地址比例
    /// @param amount 本次分配数量
    /// @param restAmount 剩余数量
    event distributeLpFee(
        address eco,
        uint256 rate,
        uint256 amount,
        uint256 restAmount
    );

    //testnet 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    //mainnet 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address private constant ROUTER_ADDRESS =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    //testnet 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684
    //mainnet 0x55d398326f99059fF775485246999027B3197955
    address private constant USDT_ADDRESS =
        0x55d398326f99059fF775485246999027B3197955;

    uint256 public constant DIS_AMOUNT = 50000*1e18;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /// @dev 用户地址=>上级地址
    mapping(address => address) public parents;

    /// @dev keccak256(用户地址+下级级别)=>地址列表
    mapping(bytes32 => address[]) public children;

    address public buyCommunityAddress;

    address public techAddress;

    address public sellCommunityAddress;

    address public ecoAddress;

    /// @dev pancake pair地址
    address public pair;

    /// @dev 用户地址=>购买数量
    mapping(address => uint256) public buyPerAccount;

    /// @dev 用户地址=>收到手续费数量
    mapping(address => uint256) public feePerAccount;

    /// @dev 买卖币免手续费白单
    BitMaps.BitMap private feeWhitelist;

    /// @dev 分红机器人白单
    BitMaps.BitMap private botWhitelist;

    /// @dev 当前可分配的lpFee数量
    uint256 public lpFeeDisAmount;

    constructor(
        uint256 initAmount,
        address _receiver,
        address genesis,
        address _techAddress,
        address _sellCommunityAddress,
        address _buyCommunityAddress,
        address _ecoAddress,
        address bot
    ) {
        _name = "optimum earn  track";
        _symbol = "OET";
        techAddress = _techAddress;
        sellCommunityAddress = _sellCommunityAddress;
        buyCommunityAddress = _buyCommunityAddress;
        ecoAddress = _ecoAddress;
        pair = IPancakeFactory(IPancakeRouter(ROUTER_ADDRESS).factory())
            .createPair(address(this), USDT_ADDRESS);
        uint256 amount = initAmount * 10**decimals();
        parents[genesis] = address(1);
        emit Bind(genesis, address(1));
        parents[_receiver] = genesis;
        addChild(_receiver, genesis);
        emit Bind(_receiver, genesis);
        _mint(_receiver, amount);
        addFeeWhitelist(_receiver);
        addFeeWhitelist(genesis);
        addFeeWhitelist(_ecoAddress);
        addBotWhitelist(bot);
    }

    function addFeeWhitelist(address adr) public onlyOwner {
        feeWhitelist.set(uint256(uint160(adr)));
        emit addFeeWl(adr);
    }

    function removeTransferWhitelist(address adr) public onlyOwner {
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

        uint256 tranType = 0; //转帐类型 0转帐 1卖币 2加池 3买币 4移池
        if (to == pair) {
            //转币到pair地址时
            (uint112 r0, uint112 r1, ) = IPancakePair(pair).getReserves(); //此代币地址要比usdt的地址大
            uint256 amountA;
            if (r0 > 0 && r1 > 0) {
                amountA = IPancakeRouter(ROUTER_ADDRESS).quote(amount, r1, r0);
            }
            uint256 balanceA = IERC20(USDT_ADDRESS).balanceOf(pair);
            if (balanceA < r0 + amountA) {
                //pair的usdt余额<此数，则判定行为是卖币
                tranType = 1;
            } else {
                tranType = 2;
            }
        }
        if (from == pair) {
            //从pair转出币
            (uint112 r0, uint112 r1, ) = IPancakePair(pair).getReserves(); //此代币地址要比usdt的地址大
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
                //pair的usdt余额>=此数，则判定行为是买币
                tranType = 3;
            } else {
                tranType = 4;
            }
        }

        uint256 oldBalance = balanceOf(from); //from当前余额
        require(oldBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = oldBalance - amount;
        }

        uint256 subAmount;
        if (tranType == 1) {
            //地址没在卖币白单里
            if (!feeWhitelist.get(uint256(uint160(from)))) {
                subAmount += shareFee(
                    from,
                    sellCommunityAddress,
                    (amount * 30) / 1000
                );
                subAmount += shareFee(
                    from,
                    address(this),
                    (amount * 20) / 1000
                );
                subAmount += shareFee(
                    from,
                    address(0),
                    (amount * 10) / 1000
                );
                subAmount += shareFee(
                    from,
                    techAddress,
                    (amount * 20) / 1000
                );
            }
        } else if (tranType == 3) {
            //地址没在买币白单里
            if (!feeWhitelist.get(uint256(uint160(to)))) {
                subAmount += shareFee(
                    to,
                    address(this),
                    (amount * 20) / 1000
                );
                subAmount += shareFee(
                    to,
                    techAddress,
                    (amount * 10) / 1000
                );
                subAmount += shareFee(
                    from,
                    buyCommunityAddress,
                    (amount * 20) / 1000
                );
                subAmount += shareFee(
                    to,
                    address(0),
                    (amount * 10) / 1000
                );
                uint256 marketAmount = (amount * 20) / 1000;
                marketReward(to, amount, marketAmount);
                subAmount += marketAmount;
            }
            buyPerAccount[to] += amount - subAmount; //累积地址购买数量
        }

        uint256 toAmount = amount - subAmount;
        _balances[to] += toAmount;
        emit Transfer(from, to, toAmount);

        if (balanceOf(address(this)) >= lpFeeDisAmount) {
            uint256 lpFeeRest = balanceOf(address(this)) - lpFeeDisAmount;
            if (lpFeeRest >= DIS_AMOUNT) {
                lpFeeDisAmount += DIS_AMOUNT;
                emit distributeLpFee(
                    ecoAddress,
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
        address p = parents[to];
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
            p = parents[p];
        }
        if (restAmount > 0) {
            //剩余给生态建设地址
            _balances[ecoAddress] += restAmount;
            feePerAccount[ecoAddress] += restAmount;
            emit Transfer(to, ecoAddress, restAmount);
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

    function bind(address parent) external {
        require(parents[msg.sender] == address(0), "already bind");
        require(parents[parent] != address(0), "parent invalid");
        parents[msg.sender] = parent;
        addChild(msg.sender, parent);
        emit Bind(msg.sender, parent);
    }

    function addChild(address user, address p) private {
        for (uint256 i = 1; i <= 2 && p != address(0) && p != address(1); ++i) {
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
        for (uint256 i = 1; i <= 2; ++i) {
            len += children[keccak256(abi.encode(user, i))].length;
        }
        return len;
    }

    /// @dev 分页获取下级地址
    /// @param user 用户地址
    /// @param level 下级级别 [1,2]
    /// @param 第几页，从1开始
    /// @param 每页几条
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