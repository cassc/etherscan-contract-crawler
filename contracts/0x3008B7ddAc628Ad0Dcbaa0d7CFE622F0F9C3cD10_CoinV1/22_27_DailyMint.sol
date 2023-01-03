// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "../money/Bank.sol";
import "../money/Coin.sol";
import "./ArtData.sol";

 /*$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$  /$$       /$$$$$$$$
| $$__  $$| $$_____/ /$$__  $$| $$__  $$| $$      | $$_____/
| $$  \ $$| $$      | $$  \ $$| $$  \ $$| $$      | $$
| $$$$$$$/| $$$$$   | $$  | $$| $$$$$$$/| $$      | $$$$$
| $$____/ | $$__/   | $$  | $$| $$____/ | $$      | $$__/
| $$      | $$      | $$  | $$| $$      | $$      | $$
| $$      | $$$$$$$$|  $$$$$$/| $$      | $$$$$$$$| $$$$$$$$
|__/      |________/ \______/ |__/      |________/|_______*/

interface FoundBase {
    function currentDay() external view returns (uint coin);
    function dayDuration()  external view returns (uint coin);
    function weekDuration()  external view returns (uint coin);
    function coinToArt(uint coinId) external view returns (uint artId);
}

contract DailyMint is Purse {
    using Strings for uint;

    address private _admin;
    ArtData private _data;
    FoundBase private _base;

    uint public constant AMPLITUDE = 100;

    mapping(uint => Coin) private _coins;

    event DeployCoin(uint indexed coinId);

    function data() external view returns (ArtData) {
        return _data;
    }

    function base() external view returns (FoundBase) {
        return _base;
    }

    function admin() external view returns (address) {
        return _admin;
    }

      /*$$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$$ /$$$$$$$$
     /$$__  $$| $$__  $$| $$_____/ /$$__  $$|__  $$__/| $$_____/
    | $$  \__/| $$  \ $$| $$      | $$  \ $$   | $$   | $$
    | $$      | $$$$$$$/| $$$$$   | $$$$$$$$   | $$   | $$$$$
    | $$      | $$__  $$| $$__/   | $$__  $$   | $$   | $$__/
    | $$    $$| $$  \ $$| $$      | $$  | $$   | $$   | $$
    |  $$$$$$/| $$  | $$| $$$$$$$$| $$  | $$   | $$   | $$$$$$$$
     \______/ |__/  |__/|________/|__/  |__/   |__/   |_______*/

    function addressOf(uint coinId) external view returns (Coin) {
        return _coins[coinId];
    }

    function nameOf(uint coinId) override public view returns (string memory) {
        uint artId = _base.coinToArt(coinId);
        return _data.getArt(artId).name;
    }

    function symbolOf(uint coinId) override public view returns (string memory) {
        uint artId = _base.coinToArt(coinId);
        return _data.getArt(artId).symbol;
    }

    function decimals() override virtual public pure returns (uint8) {
        return 18;
    }

    function uri(uint coinId) override virtual public view returns (string memory) {
        uint artId = _base.coinToArt(coinId);
        return _data.tokenURI(artId);
    }

    function convertCoin(uint coinId, uint amount) public view returns (uint) {
        uint total = totalSupply();
        if (total == 0) return amount;

        uint current = _base.currentDay();
        if (current == 1) return amount;

        uint reserve = total - totalSupplyOf(current);
        uint average = reserve / (current - 1);
        uint supply = totalSupplyOf(coinId);

        if (supply > average * AMPLITUDE) {
            return amount / AMPLITUDE;
        }

        if (average > supply * AMPLITUDE) {
            return amount * AMPLITUDE;
        }

        return amount * average / supply;
    }

     /*$      /$$  /$$$$$$  /$$   /$$ /$$$$$$$$ /$$     /$$
    | $$$    /$$$ /$$__  $$| $$$ | $$| $$_____/|  $$   /$$/
    | $$$$  /$$$$| $$  \ $$| $$$$| $$| $$       \  $$ /$$/
    | $$ $$/$$ $$| $$  | $$| $$ $$ $$| $$$$$     \  $$$$/
    | $$  $$$| $$| $$  | $$| $$  $$$$| $$__/      \  $$/
    | $$\  $ | $$| $$  | $$| $$\  $$$| $$          | $$
    | $$ \/  | $$|  $$$$$$/| $$ \  $$| $$$$$$$$    | $$
    |__/     |__/ \______/ |__/  \__/|________/    |_*/

    modifier onlyAdmin() {
        require(
            msg.sender == address(_admin),
            "Caller is not based"
        );
        _;
    }

    function mintCoin(
        address to,
        uint coinId,
        uint amount
    ) external onlyAdmin {
        _mint(
            to, 
            coinId, 
            amount, 
            new bytes(0)
        );
    }

    function deployCoin(uint coinId) external returns (Coin) {
        require(
            coinId <= _base.currentDay(),
            "Coin has not been minted"
        );

        require(
            address(_coins[coinId]) == address(0),
            "Coin has already been deployed"
        );

        _coins[coinId] = new Coin(Purse(this), coinId);

        emit DeployCoin(coinId);

        return _coins[coinId];
    }

    function transferFromDeployed(
        address operator,
        address from,
        address to,
        uint coinId,
        uint amount
    ) external override {
        _requireCoinCaller(coinId);
        _transferFrom(
            operator,
            from,
            to,
            coinId,
            amount,
            new bytes(0)
        );
    }

    function approveDeployed(
        address operator,
        address spender,
        uint coinId,
        uint amount
    ) external override {
        _requireCoinCaller(coinId);
        _approve(
            operator,
            spender,
            coinId,
            amount
        );
    }

    function _requireCoinCaller(uint coinId) internal view {
        address coin = address(_coins[coinId]);
        require(
            coin == msg.sender && coin != address(0),
            "Caller is not a coin"
        );
    }

    constructor(
        address admin_,
        ArtData data_,
        FoundBase base_
    ) Bank("") {
        _admin = admin_;
        _data = data_;
        _base = base_;
    }
}