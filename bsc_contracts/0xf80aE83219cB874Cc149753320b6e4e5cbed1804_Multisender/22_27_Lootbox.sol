// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/INftFactory.sol";
import "./interfaces/ILootbox.sol";

contract Lootbox is ILootbox, AccessControl {
    using SafeMath for uint256;

    INftFactory public factory;
    IUniswapV2Router02 public router;

    IERC20 public token0;
    IERC20 public token1;

    uint256 public price;

    uint256[] public chances;
    address[] public items;

    uint256 private randNonce = 1;
    uint256 public total;

    address public nftBankAdress;

    address public lotteryAdress;
    uint256 public lotteryRate = 1000; // 10%

    uint256 public limit = 1;
    uint256 public counter;

    modifier isActive {
        require(chances.length > 0 && chances.length == items.length, "chances_and_items_not_init");
        require(price > 0, "not active");
        _;
    }

    event NftMinted(address indexed _user, address indexed _nft);

    constructor(
        IERC20 _token0,
        IERC20 _token1,
        uint256 _price,
        INftFactory _factory,
        IUniswapV2Router02 _router,
        address _nftBankAdress,
        address _lotteryAdress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        setToken(_token0, _token1);
        setPrice(_price);

        setFactory(_factory);
        setRouter(_router);

        setNftBankAdress(_nftBankAdress);
        setLotteryAddress(_lotteryAdress);
    }

    function open(uint256 _quantity) override external isActive {
        require(_quantity > 0, "QUANTITY TOO LOW");

        uint256 amount = price.mul(_quantity);

        uint256 oldBalance = token0.balanceOf(address(this));
        token0.transferFrom(msg.sender, address(this), amount);
        uint256 balance = token0.balanceOf(address(this));

        require(balance.sub(oldBalance) == amount, "TRANSFER ERROR");

        counter = counter.add(1);

        for (uint256 i = 1; i <= _quantity; i++) {
            _open(msg.sender);
        }

        uint256 nftBankAmount = amount;

        if (lotteryRate > 0) {
            uint256 lotteryTotal = amount.mul(lotteryRate).div(10000);
            nftBankAmount = nftBankAmount.sub(lotteryTotal);
        }

        if (nftBankAmount > 0) {
            token0.transfer(nftBankAdress, nftBankAmount);
        }

        if (counter >= limit) {
            uint256 amountToSwap = token0.balanceOf(address(this));
            address[] memory path = new address[](2);
            path[0] = address(token0);
            path[1] = address(token1);

            token0.approve(address(router), amountToSwap);

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                lotteryAdress,
                block.timestamp
            );

            counter = 0;
        }
    }

    function recoverTokens(address _token, uint256 _amount) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function recoverTokensFor(address _token, address _to, uint256 _amount) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).transfer(_to, _amount);
    }

    function setLimit(uint256 _limit) override public onlyRole(DEFAULT_ADMIN_ROLE) {
        limit = _limit;
    }

    function resetCounter() override public onlyRole(DEFAULT_ADMIN_ROLE) {
        counter = 0;
    }

    function setToken(IERC20 _token0, IERC20 _token1) override public onlyRole(DEFAULT_ADMIN_ROLE) {
        token0 = _token0;
        token1 = _token1;
    }

    function setPrice(uint256 _price) override public onlyRole(DEFAULT_ADMIN_ROLE) {
        price = _price;
    }

    function setFactory(INftFactory _factory) override public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(_factory) != address(0), "zero _factory");
        factory = _factory;
    }

    function setRouter(IUniswapV2Router02 _router) override public onlyRole(DEFAULT_ADMIN_ROLE) {
        router = _router;
    }

    function setNftBankAdress(address _nftBankAdress) override public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_nftBankAdress != address(0), "zero _nftBankAdress");
        nftBankAdress = _nftBankAdress;
    }

    function setLotteryAddress(address _lotteryAdress) override public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_lotteryAdress != address(0), "zero _lotteryAdress");
        lotteryAdress = _lotteryAdress;
    }

    function updateLotteryRate(uint256 _lotteryRate) override public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_lotteryRate <= 10000);

        lotteryRate = _lotteryRate;
    }

    function setChances(uint256[] calldata _chances) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 itemLength = chances.length;
        for (uint i = 0; i < _chances.length; i++) {
            if (itemLength > 0 && itemLength - 1 >= i) {
                chances[i] = _chances[i];
            } else {
                chances.push(_chances[i]);
            }
        }

        if (itemLength > _chances.length) {
            uint256 diff = itemLength.sub(_chances.length);
            for (uint i = 0; i < diff; i++) {
                chances.pop();
            }
        }
    }

    function setItems(address[] calldata _items) override external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 itemLength = items.length;
        for (uint i = 0; i < _items.length; i++) {
            if (itemLength > 0 && itemLength - 1 >= i) {
                items[i] = _items[i];
            } else {
                items.push(_items[i]);
            }
        }

        if (itemLength > _items.length) {
            uint256 diff = itemLength.sub(_items.length);
            for (uint i = 0; i < diff; i++) {
                items.pop();
            }
        }
    }

    function _open(address _to) internal {
        address nft = _randomItem();

        factory.mintNft(nft, _to, 1);

        emit NftMinted(_to, nft);

        total = total.add(1);
    }

    function _randomItem() internal returns (address) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, 'nyt', ++randNonce))) % chances[chances.length - 1] + 1;

        address result;
        uint256 i = 0;

        while (i < chances.length && result == address(0)) {
            if (rand <= chances[i]) {
                result = items[i];
            }
            i++;
        }

        require(result != address(0), "ITEM NOT FOUND");

        return result;
    }

}