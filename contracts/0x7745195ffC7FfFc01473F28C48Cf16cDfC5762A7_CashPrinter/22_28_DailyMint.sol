// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "../art/ArtData.sol";
import "../money/Bank.sol";
import "../money/Coin.sol";

 /*$$$$$$$ /$$$$$$ /$$      /$$ /$$$$$$$$
|__  $$__/|_  $$_/| $$$    /$$$| $$_____/
   | $$     | $$  | $$$$  /$$$$| $$
   | $$     | $$  | $$ $$/$$ $$| $$$$$
   | $$     | $$  | $$  $$$| $$| $$__/
   | $$     | $$  | $$\  $ | $$| $$
   | $$    /$$$$$$| $$ \/  | $$| $$$$$$$$
   |__/   |______/|__/     |__/|_______*/

interface FoundBase {
    function currentDay() external view returns (uint coin);
    function dayLength()  external view returns (uint coin);
    function weekLength()  external view returns (uint coin);
    function coinToArt(uint coin) external view returns (uint art);
}

contract DailyMint is CoinBank {
    using Strings for uint;

    ArtData private _data;
    FoundBase private _base;
    address private _admin;

    uint public constant AMPLITUDE = 10;

    mapping(uint => Coin) private _coins;

    event MintCoin(
        address to,
        uint coinId,
        uint amount,
        uint timestamp
    );

    event DeployCoin(
        uint indexed coinId,
        Coin to,
        uint timestamp
    );

    function data() external view returns (ArtData) {
        return _data;
    }

    function base() external view returns (FoundBase) {
        return _base;
    }

    function admin() external view returns (address) {
        return _admin;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == address(_admin),
            "Caller is not based"
        );
        _;
    }

      /*$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$$ /$$$$$$$$  /$$$$$$
     /$$__  $$| $$__  $$| $$_____/ /$$__  $$|__  $$__/| $$_____/ /$$__  $$
    | $$  \__/| $$  \ $$| $$      | $$  \ $$   | $$   | $$      | $$  \__/
    | $$      | $$$$$$$/| $$$$$   | $$$$$$$$   | $$   | $$$$$   |  $$$$$$
    | $$      | $$__  $$| $$__/   | $$__  $$   | $$   | $$__/    \____  $$
    | $$    $$| $$  \ $$| $$      | $$  | $$   | $$   | $$       /$$  \ $$
    |  $$$$$$/| $$  | $$| $$$$$$$$| $$  | $$   | $$   | $$$$$$$$|  $$$$$$/
     \______/ |__/  |__/|________/|__/  |__/   |__/   |________/ \_____*/

    function artOf(uint coinId) external view returns (Art memory) {
        uint artId = _base.coinToArt(coinId);
        return _data.getArt(artId);
    }

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

    function tokenURI(uint coinId) external view returns (string memory) {
        uint artId = _base.coinToArt(coinId);
        return _data.tokenURI(artId);
    }

    function decimals() override public pure returns (uint8) {
        return 18;
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

        emit MintCoin(
            to,
            coinId,
            amount,
            block.timestamp
        );
    }

    function deployCoin(uint coinId) external returns (Coin) {
        require(
            coinId > 0 && coinId <= _base.currentDay(),
            "Coin is not yet deployable"
        );

        require(
            address(_coins[coinId]) == address(0),
            "Coin has already been deployed"
        );

        Coin coin = new Coin(
            CoinBank(this),
            coinId
        );

        _coins[coinId] = coin;

        emit DeployCoin(
            coinId,
            coin,
            block.timestamp
        );

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
            "Caller is not the coin contract"
        );
    }

    constructor(
        address admin_,
        ArtData data_,
        FoundBase base_
    ) Bank() {
        _admin = admin_;
        _data = data_;
        _base = base_;
    }
}