// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "../money/Found.sol";
import "./ArtData.sol";
import "./DailyMint.sol";
import "./FoundNote.sol";
import "./FoundGovt.sol";
import "./ArtToken.sol";

 /*$$$$$$$ /$$$$$$  /$$   /$$ /$$   /$$ /$$$$$$$        /$$$$$$$   /$$$$$$  /$$   /$$ /$$   /$$
| $$_____//$$__  $$| $$  | $$| $$$ | $$| $$__  $$      | $$__  $$ /$$__  $$| $$$ | $$| $$  /$$/
| $$     | $$  \ $$| $$  | $$| $$$$| $$| $$  \ $$      | $$  \ $$| $$  \ $$| $$$$| $$| $$ /$$/
| $$$$$  | $$  | $$| $$  | $$| $$ $$ $$| $$  | $$      | $$$$$$$ | $$$$$$$$| $$ $$ $$| $$$$$/
| $$__/  | $$  | $$| $$  | $$| $$  $$$$| $$  | $$      | $$__  $$| $$__  $$| $$  $$$$| $$  $$
| $$     | $$  | $$| $$  | $$| $$\  $$$| $$  | $$      | $$  \ $$| $$  | $$| $$\  $$$| $$\  $$
| $$     |  $$$$$$/|  $$$$$$/| $$ \  $$| $$$$$$$/      | $$$$$$$/| $$  | $$| $$ \  $$| $$ \  $$
|__/      \______/  \______/ |__/  \__/|_______/       |_______/ |__/  |__/|__/  \__/|__/  \_*/

contract FoundBank is Governed, ArtToken {

    Found private _cash;
    FoundNote private _note;
    DailyMint private _bank;

    uint public constant BONUS = 1000;

    event Claim(
        address sender,
        address indexed minter,
        uint indexed coinId,
        uint indexed artId,
        uint amount,
        uint timestamp
    );

    event Mint(
        address payer,
        address indexed minter,
        uint indexed coinId,
        uint indexed artId,
        uint found,
        uint amount,
        uint timestamp
    );

    event Vote(
        address payer,
        address indexed minter,
        uint indexed coinId,
        uint indexed artId,
        uint found,
        uint amount,
        uint timestamp
    );

    event Deposit(
        address indexed payer,
        address indexed minter,
        uint id,
        uint tax,
        uint govt,
        uint artId,
        uint coinId,
        uint principal,
        uint shares,
        uint duration,
        uint createdAt,
        uint timestamp
    );

    event Withdraw(
        uint indexed id,
        address indexed to,
        uint artId,
        uint shares,
        uint principal,
        uint penalty,
        uint income,
        uint taxes,
        bool toEther,
        uint collectedAt,
        uint timestamp
    );

    event Close(
        uint indexed id,
        uint artId,
        uint principal,
        uint collectedAt,
        uint timestamp
    );

    event Lock(
        address owner,
        uint indexed artId,
        uint timestamp
    );

    event Delegate(
        uint indexed depositId,
        address owner,
        address to,
        string memo,
        uint timestamp
    );

    function cash() external view returns (Found) {
        return _cash;
    }

    function note() external view returns (FoundNote) {
        return _note;
    }

    function bank() external view returns (DailyMint) {
        return _bank;
    }

    function tokenCount() external view returns (uint) {
        return _note.tokenCount();
    }

      /*$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$$ /$$$$$$$$  /$$$$$$
     /$$__  $$| $$__  $$| $$_____/ /$$__  $$|__  $$__/| $$_____/ /$$__  $$
    | $$  \__/| $$  \ $$| $$      | $$  \ $$   | $$   | $$      | $$  \__/
    | $$      | $$$$$$$/| $$$$$   | $$$$$$$$   | $$   | $$$$$   |  $$$$$$
    | $$      | $$__  $$| $$__/   | $$__  $$   | $$   | $$__/    \____  $$
    | $$    $$| $$  \ $$| $$      | $$  | $$   | $$   | $$       /$$  \ $$
    |  $$$$$$/| $$  | $$| $$$$$$$$| $$  | $$   | $$   | $$$$$$$$|  $$$$$$/
     \______/ |__/  |__/|________/|__/  |__/   |__/   |________/ \_____*/

    function claim(ClaimParams calldata params) external {
        uint supply = _bank.totalSupplyOf(params.coinId);

        uint artId = _note.collectClaim(
            msg.sender,
            supply,
            params
        );

        _bank.mintCoin(
            params.minter,
            params.coinId,
            params.amount
        );

        emit Claim(
            msg.sender,
            params.minter,
            params.coinId,
            artId,
            params.amount,
            block.timestamp
        );
    }

    function lock(uint coinId, uint amount) external {
        uint supply = _bank.totalSupplyOf(coinId);
        require(
            amount >= supply, 
            "Amount must be greater than or equal to the total supply"
        );

        _note.collectLock(msg.sender, coinId, amount);
        emit Lock(msg.sender, coinId, block.timestamp);
    }

    function mint(MintParams calldata params) external {
        uint minted = _bank.convertCoin(params.coinId, params.amount);
        uint supply = _bank.totalSupplyOf(params.coinId);
        uint artId = _note.collectMint(supply, params);

        _cash.transferFrom(
            params.payer,
            address(this),
            params.amount
        );

        _bank.mintCoin(
            params.minter,
            params.coinId,
            minted
        );

        emit Mint(
            params.payer,
            params.minter,
            params.coinId,
            artId,
            params.amount,
            minted,
            block.timestamp
        );
    }

     /*$      /$$  /$$$$$$  /$$    /$$ /$$$$$$$$  /$$$$$$
    | $$  /$ | $$ /$$__  $$| $$   | $$| $$_____/ /$$__  $$
    | $$ /$$$| $$| $$  \ $$| $$   | $$| $$      | $$  \__/
    | $$/$$ $$ $$| $$$$$$$$|  $$ / $$/| $$$$$   |  $$$$$$
    | $$$$_  $$$$| $$__  $$ \  $$ $$/ | $$__/    \____  $$
    | $$$/ \  $$$| $$  | $$  \  $$$/  | $$       /$$  \ $$
    | $$/   \  $$| $$  | $$   \  $/   | $$$$$$$$|  $$$$$$/
    |__/     \__/|__/  |__/    \_/    |________/ \_____*/

    function vote(VoteParams calldata params) external whenNotPaused {
        uint coinId = _note.collectVote(params);
        uint amount = BONUS * params.amount;

        _cash.transferFrom(
            params.payer,
            address(this),
            params.amount
        );

        _bank.mintCoin(
            params.minter,
            coinId,
            amount
        );

        emit Vote(
            params.payer,
            params.minter,
            coinId,
            params.artId,
            params.amount,
            amount,
            block.timestamp
        );
    }

    function deposit(DepositParams calldata params) external whenNotPaused returns (uint) {
        uint count = governmentCount();
        require(
            params.govt > 0 || count == 0,
            "Must select a government"
        );

        uint tax = governmentTax(params.govt);
        Note memory token = _note.collectDeposit(params, tax);

        _cash.transferFrom(
            params.payer,
            address(this),
            params.amount
        );

        _safeMint(params.minter, token.id, new bytes(0));

        emit Deposit(
            params.payer,
            params.minter,
            token.id,
            token.tax,
            token.govt,
            token.artId,
            token.coinId,
            token.principal,
            token.shares,
            token.duration,
            token.createdAt,
            block.timestamp
        );

        return token.id;
    }

    function withdraw(WithdrawParams calldata params) external {
        Note memory token = _note.collectNote(
            params.depositId,
            msg.sender,
            ownerOf(params.depositId)
        );

        _payOut(token, params.payee, params.toEther);

        emit Withdraw(
            token.id,
            params.payee,
            token.artId,
            token.shares,
            token.principal,
            token.penalty,
            token.income,
            token.taxes,
            params.toEther,
            token.collectedAt,
            block.timestamp
        );
    }

    function close(uint depositId) external {
        Note memory token = _note.collectNote(
            depositId,
            msg.sender,
            ownerOf(depositId)
        );

        emit Close(
            token.id,
            token.artId,
            token.principal,
            token.collectedAt,
            block.timestamp
        );
    }

    function delegate(
        uint depositId, 
        address to, 
        string memory memo
    ) external {
        _note.delegateNote(
            depositId, 
            msg.sender,
            ownerOf(depositId),
            to, 
            memo
        );

        emit Delegate(
            depositId,
            msg.sender,
            to,
            memo,
            block.timestamp
        );
    }

    function _tokenToArt(uint tokenId) override internal view returns (uint) {
        return _note.getNote(tokenId).artId;
    }

    function _payOut(Note memory token, address to, bool toEther) internal {
        uint earned = token.principal + token.income - token.penalty;

        if (earned > 0) {
            if (toEther) {
                _cash.swap(address(this), to, earned);
            } else {
                _cash.transfer(to, earned);
            }
        }

        if (token.taxes > 0) {
            address payee = governmentPayee(token.govt);

            if (address(payee) != address(0)) {
                _cash.transfer(payee, token.taxes);
            }
        }
    }

    constructor(ArtData data_, Found cash_)
    ArtToken("Namespace Treasury Note", "TREASURY NOTE", data_) {
        _cash = cash_;
        _note = new FoundNote(address(this), data_, _cash);
        _bank = new DailyMint(address(this), data_, FoundBase(_note));
    }
}