pragma solidity ^0.8.6;

import "./utils/Ownable.sol";
import "./SNTO.sol";
import "./utils/IPancakeRouter01.sol";
import "./utils/IERC20.sol";
import "./utils/Governance.sol";
import "./Pool.sol";

contract DAPP is Governance, Context {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    receive() external payable {}

    mapping(address => address) public parents;
    mapping(address => address[]) private children;
    mapping(address => uint) public groupCount;

    address public router;
    address public usdt;
    address public snto;
    address public pool;
    address public pair;
    address public root;

    address private marketingAddress;

    uint256 superTradeLPRate;
    uint256 superTradeNodeRate;
    uint256 superRemoveRate;

    uint256 tradeLPRate;
    uint256 tradeNodeRate;
    uint256 removeRate;
    uint256[5] public rate;


    bool public enable;

    constructor(
        address _snto,
        address _pair,
        address _pool,
        address _router,
        address _usdt,
        address _marketingAddress
    ) {
        snto = _snto;
        pool = _pool;
        pair = _pair;
        router = _router;
        usdt = _usdt;
        marketingAddress = _marketingAddress;
        rate = [200, 25, 25, 25, 25];

        superTradeLPRate = 0;
        superTradeNodeRate = 100;
        superRemoveRate = 100;

        tradeLPRate = 200;
        tradeNodeRate = 100;
        removeRate = 600;

        enable = true;
    }

    function setRate(
        uint256 _superTradeLPRate,
        uint256 _superTradeNodeRate,
        uint256 _superRemoveRate,
        uint256 _tradeLPRate,
        uint256 _tradeNodeRate,
        uint256 _removeRate
    ) public onlyGovernance {
        superTradeLPRate = _superTradeLPRate;
        superTradeNodeRate = _superTradeNodeRate;
        superRemoveRate = _superRemoveRate;
        tradeLPRate = _tradeLPRate;
        tradeNodeRate = _tradeNodeRate;
        removeRate = _removeRate;
    }


    function setAddresses(
        address _marketingAddress,
        address _root,
        address _pool
    ) public onlyGovernance {
        marketingAddress = _marketingAddress;
        root = _root;
        pool = _pool;
    }

    function setRates(uint256[5] memory _rate) public onlyGovernance {
        rate = _rate;
    }

    function setEnable(bool _enable) public onlyGovernance {
        enable = _enable;
    }

    function removeLiquidity(uint256 _amount, address _parent) public {
        require(enable, "not enable");


        if (parents[_msgSender()] == address(0) && _parent != address(0)) {
            setParent(_parent);
        }

        IERC20(pair).transferFrom(_msgSender(), address(this), _amount);
        IERC20(pair).approve(router, _amount);
        IPancakeRouter01(router).removeLiquidity(
            usdt,
            address(snto),
            _amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 _removeRate;
        uint256[5] memory _inviteAmounts;
        uint256 _tradeLPRate;
        uint256 _tradeNodeRate;

        bool isNode = Pool(pool).isNode(_msgSender());
        if (isNode) {
            _tradeLPRate = superTradeLPRate;
            _tradeNodeRate = superTradeNodeRate;
            _removeRate = superRemoveRate;
        } else {
            _inviteAmounts = getAmounts(_amount);
            _tradeLPRate = tradeLPRate;
            _tradeNodeRate = tradeNodeRate;
            _removeRate = removeRate;
        }

        uint256 usdtAmount = IERC20(usdt).balanceOf(address(this));
        uint256 sntoAmount = IERC20(snto).balanceOf(address(this));

        address[] memory sellSNTOPath = new address[](2);
        sellSNTOPath[0] = address(snto);
        sellSNTOPath[1] = usdt;

        if (_removeRate > 0) {
            uint256 removeSNTOAmount = sntoAmount.mul(_removeRate).div(10000);
            uint256 removeFeeAmount = usdtAmount.mul(_removeRate).div(10000);
            IERC20(snto).approve(router, removeSNTOAmount);
            IPancakeRouter01(router).swapExactTokensForTokens(
                removeSNTOAmount,
                0,
                sellSNTOPath,
                address(this),
                block.timestamp
            );
            uint256 removeFeeUSDT = IERC20(usdt).balanceOf(address(this)).sub(
                usdtAmount
            );
            uint256 fee = removeFeeAmount.add(removeFeeUSDT);
            IERC20(usdt).transfer(marketingAddress, fee);
        }

        uint256 SNTOBalance = IERC20(snto).balanceOf(address(this));

        uint256 tradeInviteAmount;
        uint256 tradeLpAmount;
        uint256 tradeNodeAmount;

        for (uint256 i = 0; i < _inviteAmounts.length; i++) {
            tradeInviteAmount = tradeInviteAmount.add(_inviteAmounts[i]);
        }

        tradeLpAmount = SNTOBalance.mul(_tradeLPRate).div(10000);
        tradeNodeAmount = SNTOBalance.mul(_tradeNodeRate).div(10000);

        if (tradeInviteAmount > 0) {
            IERC20(snto).transfer(address(pool), tradeInviteAmount);
            address[] memory invites = getParentsByLevel(_msgSender(), 5);
            for (uint256 i = 0; i < invites.length; i++) {
                if (invites[i] != address(0)) {
                    Pool(pool).InviteAddAmount(invites[i], _inviteAmounts[i]);
                } else {
                    Pool(pool).InviteAddAmount(root, _inviteAmounts[i]);
                }
            }
        }

        IERC20(snto).approve(router, IERC20(snto).balanceOf(address(this)));
        IPancakeRouter01(router).swapExactTokensForTokens(
            IERC20(snto).balanceOf(address(this)),
            0,
            sellSNTOPath,
            address(this),
            block.timestamp
        );

        IERC20(usdt).transfer(
            _msgSender(),
            IERC20(usdt).balanceOf(address(this))
        );
    }

    function addLiquidity(uint256 _amount, address _parent) external {
        require(enable, "not enable");

        if (parents[_msgSender()] == address(0) && _parent != address(0)) {
           setParent(_parent);
        }

        IERC20(usdt).transferFrom(_msgSender(), address(this), _amount);
        uint256 buyAmount = _amount.div(2);
        uint256 liquidityAmount = _amount.sub(buyAmount);

        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(snto);

        IERC20(usdt).approve(router, buyAmount);
        IPancakeRouter01(router).swapExactTokensForTokens(
            buyAmount,
            0,
            path,
            address(this),
            block.timestamp
        );


        bool isNode = Pool(pool).isNode(_msgSender());

        uint256[5] memory _inviteAmounts;
        uint256 _tradeLPRate;
        uint256 _tradeNodeRate;

        if (isNode) {
            _tradeLPRate = superTradeLPRate;
            _tradeNodeRate = superTradeNodeRate;
        } else {
            _inviteAmounts = getAmounts(_amount);
            _tradeLPRate = tradeLPRate;
            _tradeNodeRate = tradeNodeRate;
        }

        uint256 tradeInviteAmount;
        uint256 tradeLpAmount;
        uint256 tradeNodeAmount;

        for (uint256 i = 0; i < _inviteAmounts.length; i++) {
            tradeInviteAmount = tradeInviteAmount.add(_inviteAmounts[i]);
        }

        tradeLpAmount = _amount.mul(_tradeLPRate).div(10000);
        tradeNodeAmount = _amount.mul(_tradeNodeRate).div(10000);
        if (tradeInviteAmount > 0) {
            IERC20(snto).transfer(address(pool), tradeInviteAmount);
            address[] memory invites = getParentsByLevel(_msgSender(), 5);
            for (uint256 i = 0; i < invites.length; i++) {
                if (invites[i] != address(0)) {
                    Pool(pool).InviteAddAmount(invites[i], _inviteAmounts[i]);
                } else {
                    Pool(pool).InviteAddAmount(root, _inviteAmounts[i]);
                }
            }
        }

        if (tradeLpAmount > 0) {
            IERC20(snto).transfer(address(pool), tradeLpAmount);
            Pool(pool).addPoolReward(tradeLpAmount);
        }

        if (tradeNodeAmount > 0) {
            IERC20(snto).transfer(address(pool), tradeNodeAmount);
            Pool(pool).addNodeReward(tradeNodeAmount);
        }

        IERC20(usdt).approve(router, liquidityAmount);
        IERC20(snto).approve(router, IERC20(snto).balanceOf(address(this)));
        IPancakeRouter01(router).addLiquidity(
            usdt,
            address(snto),
            liquidityAmount,
            IERC20(snto).balanceOf(address(this)),
            0,
            0,
            _msgSender(),
            block.timestamp
        );

        if (IERC20(usdt).balanceOf(address(this)) > 0) {
            IERC20(usdt).transfer(
                _msgSender(),
                IERC20(usdt).balanceOf(address(this))
            );
        }

        if (IERC20(snto).balanceOf(address(this)) > 0) {
            IERC20(snto).transfer(
                _msgSender(),
                IERC20(snto).balanceOf(address(this))
            );
        }
    }

    function setParent(address parent) public {
        require(parents[_msgSender()] == address(0), "parent exist");
        require(parent != _msgSender(), "parent can not be self");
        parents[_msgSender()] = parent;
        children[parent].push(_msgSender());
        setGroupCount(_msgSender());
    }

    function setParentByGovernance(address _address, address parent) public onlyGovernance {
        require(parents[_address] == address(0), "parent exist");
        require(parent != _address, "parent can not be self");
        parents[_address] = parent;
        children[parent].push(_address);
        setGroupCount(_address);
    }


    function getParentsByLevel(address _address, uint256 level)
    public
    view
    returns (address[] memory)
    {
        address[] memory p = new address[](level);
        address parent = parents[_address];
        for (uint256 i = 0; i < level; i++) {
            p[i] = parent;
            parent = parents[parent];
        }
        return p;
    }

    function getChildrenLength(address _address) public view returns (uint256) {
        return children[_address].length;
    }

    function getChildren(address _address)
    public
    view
    returns (address[] memory)
    {
        return children[_address];
    }

    function getAmounts(uint256 _amount)
    public
    view
    returns (uint256[5] memory)
    {
        uint256[5] memory amounts;
        for (uint256 i = 0; i < 5; i++) {
            amounts[i] = _amount.mul(rate[i]).div(10000);
        }
        return amounts;
    }

    function setGroupCount(address _address) private {
        address parent = parents[_address];
        for (uint256 i = 0; i < 5; i++) {
            if (parent == address(0)) {
                break;
            }
            groupCount[parent]++;
            parent = parents[parent];
        }
    }

    function rescueToken(address tokenAddress, uint256 tokens)
    public
    onlyGovernance
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function rescueBNB(address payable _recipient) public onlyGovernance {
        _recipient.transfer(address(this).balance);
    }
}