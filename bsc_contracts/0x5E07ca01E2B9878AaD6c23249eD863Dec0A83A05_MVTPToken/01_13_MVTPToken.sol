// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IPancakeswapV2Router02.sol";
import "./interfaces/IPancakeswapV2Factory.sol";

contract MVTPToken is ERC20, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE"); //set fun
    bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE"); //合约交互
    uint256 public constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    address public _uniswapV2Pair;
    address public _usdt;
    address public _router;

    address private _marketingWallet;
    address private _lpPool;

    IPancakeswapV2Router02 private _uniswapV2Router;

    mapping(address => address) public recommendation;

    event Recommend(address indexed referer, address indexed referee);
    event TransMvtp(address indexed from, address indexed to, uint256 amount);
    event LiquidityFee(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    constructor(
        address manager,
        address router,
        address usdt,
        address marketingWallet,
        address lpPool
    ) ERC20("MVTP", "MVTP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, manager);

        _router = router;
        _marketingWallet = marketingWallet;
        _lpPool = lpPool;
        _usdt = usdt;

        IPancakeswapV2Router02 uniswapV2Router = IPancakeswapV2Router02(router);
        _uniswapV2Pair = IPancakeswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), usdt);
        _uniswapV2Router = uniswapV2Router;

        approve(address(_uniswapV2Router), MAX_INT);
        IERC20(_usdt).approve(address(_uniswapV2Router), MAX_INT);

        _mint(
            address(0x01442669cd75ED7Ec40EE21beF70782E7a185cDE),
            96_0000_000000000000000000
        );
        _mint(
            address(0x6DeFdCb24F25cDC160b44E3051399Ada3Bbe96AE),
            96_0000_000000000000000000
        );
        _mint(
            address(0xa1251EFC32afd815F0628bCfad387604a5556337),
            96_0000_000000000000000000
        );
        _mint(
            address(0x9746A5384cA9993E70a81CaFE510CaeBc7220E52),
            96_0000_000000000000000000
        );
        _mint(
            address(0x765BEB87BE3771F89FB833DBcb7C2c761C17a690),
            96_0000_000000000000000000
        );
        _mint(
            address(0x70bD22E35Ab3FD54053A97aa205223C7A8B2F298),
            960_0000_000000000000000000
        );
        _mint(
            address(0x0AeB938DF3Dc7938902Cf15F8ecA57aa6D2590D2),
            8160_0000_000000000000000000
        );
    }

    function mint(address to, uint256 amount) public onlyRole(MANAGER_ROLE) {
        super._mint(to, amount);
    }

    function recommend(address referer) public {
        require(recommendation[msg.sender] == address(0), "double refer");
        recommendation[msg.sender] = referer;
        emit Recommend(referer, msg.sender);
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        if (_isBuyOrSellViaUniswap(owner, to)) {
            _transferFromUniswap(owner, to, amount);
            return true;
        } else {
            super._transfer(owner, to, amount);
            emit TransMvtp(owner, to, amount);
            return true;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        if (_isBuyOrSellViaUniswap(from, to)) {
            _transferFromUniswap(from, to, amount);
            return true;
        } else {
            super._transfer(from, to, amount);
            emit TransMvtp(from, to, amount);
            return true;
        }
    }

    function _transferFromUniswap(
        address from,
        address to,
        uint256 tAmount
    ) private {
        address user;
        if (from == _uniswapV2Pair) {
            user = to;
        } else {
            user = from;
        }

        uint256 marketFee = (tAmount * 20) / 1000;
        address referer1 = recommendation[user];
        address referer2 = recommendation[referer1];
        if (referer1 == address(0)) {
            referer1 = _marketingWallet;
        }
        if (referer2 == address(0)) {
            referer2 = _marketingWallet;
        }
        uint256 referer1Fee = (tAmount * 15) / 1000;
        uint256 referer2Fee = (tAmount * 5) / 1000;
        uint256 lpFee = (tAmount * 40) / 1000;

        tAmount = tAmount - (marketFee + referer1Fee + referer2Fee + lpFee);

        super._transfer(from, to, tAmount);
        super._transfer(from, _marketingWallet, marketFee);
        super._transfer(from, referer1, referer1Fee);
        super._transfer(from, referer2, referer2Fee);
        super._transfer(from, _lpPool, lpFee);
        emit LiquidityFee(from, _lpPool, lpFee);
    }

    function _getTransType(address _sender, address _recipient)
        private
        view
        returns (uint256)
    {
        if (!(_sender == _uniswapV2Pair) && !(_recipient == _uniswapV2Pair)) {
            return 1;
        } else if (
            (_sender == _uniswapV2Pair) && !(_recipient == _uniswapV2Pair)
        ) {
            return 2;
        } else if (
            !(_sender == _uniswapV2Pair) && (_recipient == _uniswapV2Pair)
        ) {
            return 3;
        } else {
            return 4;
        }
    }

    function _isBuyOrSellViaUniswap(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        uint256 transType = _getTransType(_sender, _recipient);
        return transType == 2 || transType == 3;
    }
}