// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../art/ArtToken.sol";
import "./FoundNote.sol";
import "./FoundGovt.sol";

  /*$$$$$   /$$$$$$  /$$      /$$ /$$      /$$ /$$   /$$ /$$   /$$ /$$$$$$ /$$$$$$$$ /$$$$$$ /$$$$$$$$  /$$$$$$
 /$$__  $$ /$$__  $$| $$$    /$$$| $$$    /$$$| $$  | $$| $$$ | $$|_  $$_/|__  $$__/|_  $$_/| $$_____/ /$$__  $$
| $$  \__/| $$  \ $$| $$$$  /$$$$| $$$$  /$$$$| $$  | $$| $$$$| $$  | $$     | $$     | $$  | $$      | $$  \__/
| $$      | $$  | $$| $$ $$/$$ $$| $$ $$/$$ $$| $$  | $$| $$ $$ $$  | $$     | $$     | $$  | $$$$$   |  $$$$$$
| $$      | $$  | $$| $$  $$$| $$| $$  $$$| $$| $$  | $$| $$  $$$$  | $$     | $$     | $$  | $$__/    \____  $$
| $$    $$| $$  | $$| $$\  $ | $$| $$\  $ | $$| $$  | $$| $$\  $$$  | $$     | $$     | $$  | $$       /$$  \ $$
|  $$$$$$/|  $$$$$$/| $$ \/  | $$| $$ \/  | $$|  $$$$$$/| $$ \  $$ /$$$$$$   | $$    /$$$$$$| $$$$$$$$|  $$$$$$/
 \______/  \______/ |__/     |__/|__/     |__/ \______/ |__/  \__/|______/   |__/   |______/|________/ \_____*/

contract FoundBank is Governed, ArtToken {
    IFound private _money;
    DailyMint private _bank;
    FoundNote private _note;

    uint public constant BONUS = 100;

    event Vote(
        address payer,
        address indexed minter,
        uint indexed coinId,
        uint indexed artId,
        uint amount,
        uint minted,
        uint timestamp
    );

    event Mint(
        address payer,
        address indexed minter,
        uint indexed coinId,
        uint indexed artId,
        uint amount,
        uint minted,
        uint timestamp
    );

    event Claim(
        address from,
        address indexed minter,
        uint indexed coinId,
        uint indexed artId,
        uint amount,
        uint timestamp
    );

    event Lock(
        address indexed from,
        uint indexed coinId,
        uint amount,
        uint timestamp
    );

    event Deposit(
        address indexed to,
        address from,
        uint indexed id,
        uint artId,
        uint coinId,
        uint indexed fund,
        uint reward,
        uint shares,
        uint principal,
        uint duration,
        uint dailyBonus,
        address delegate,
        address payee,
        uint expiresAt,
        uint timestamp
    );

    event Withdraw(
        address indexed to,
        address from,
        uint indexed id,
        uint indexed fund,
        uint artId,
        uint coinId,
        uint shares,
        uint reward,
        uint principal,
        uint penalty,
        uint earnings,
        uint funding,
        uint dailyBonus,
        uint createdAt,
        uint timestamp
    );

    event Delegate(
        address from,
        address indexed owner,
        uint indexed id,
        address indexed delegate,
        address payee,
        string memo,
        uint timestamp
    );

    event Close(
        address indexed from,
        address indexed owner,
        uint indexed id,
        uint fund,
        uint artId,
        uint coinId,
        uint shares,
        uint principal,
        uint penalty,
        uint duration,
        uint dailyBonus,
        uint createdAt,
        uint timestamp
    );

    event Credit(
        address indexed account,
        uint indexed fund,
        uint indexed deposit,
        uint amount,
        uint timestamp
    );

    function money() external view returns (IFound) {
        return _money;
    }

    function bank() external view returns (DailyMint) {
        return _bank;
    }

    function note() external view returns (FoundNote) {
        return _note;
    }

    function tokenCount() external view returns (uint) {
        return _note.tokenCount();
    }

      /*$$$$$  /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$$ /$$$$$$$$
     /$$__  $$| $$__  $$| $$_____/ /$$__  $$|__  $$__/| $$_____/
    | $$  \__/| $$  \ $$| $$      | $$  \ $$   | $$   | $$
    | $$      | $$$$$$$/| $$$$$   | $$$$$$$$   | $$   | $$$$$
    | $$      | $$__  $$| $$__/   | $$__  $$   | $$   | $$__/
    | $$    $$| $$  \ $$| $$      | $$  | $$   | $$   | $$
    |  $$$$$$/| $$  | $$| $$$$$$$$| $$  | $$   | $$   | $$$$$$$$
     \______/ |__/  |__/|________/|__/  |__/   |__/   |_______*/

    function vote(CoinVote calldata params) external whenNotPaused {
        uint coinId = _note.collectVote(params);
        uint minted = BONUS * params.amount;

        _money.transferFrom(
            params.payer,
            address(this),
            params.amount
        );

        _bank.mintCoin(
            params.minter,
            coinId,
            minted
        );

        emit Vote(
            params.payer,
            params.minter,
            coinId,
            params.artId,
            params.amount,
            minted,
            block.timestamp
        );
    }

    function mint(MintCoin calldata params) external {
        uint minted = _bank.convertCoin(params.coinId, params.amount);
        uint supply = _bank.totalSupplyOf(params.coinId);
        uint artId = _note.collectMint(supply, params);

        _money.transferFrom(
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

    function claim(ClaimCoin calldata params) external {
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
            amount == 0 || amount >= supply,
            "Amount cannot be less than the total supply"
        );

        _note.collectLock(
            msg.sender,
            coinId,
            amount
        );

        emit Lock(
            msg.sender,
            coinId,
            amount,
            block.timestamp
        );
    }

      /*$$$$$  /$$$$$$$$  /$$$$$$  /$$   /$$ /$$$$$$$  /$$$$$$ /$$$$$$$$ /$$     /$$
     /$$__  $$| $$_____/ /$$__  $$| $$  | $$| $$__  $$|_  $$_/|__  $$__/|  $$   /$$/
    | $$  \__/| $$      | $$  \__/| $$  | $$| $$  \ $$  | $$     | $$    \  $$ /$$/
    |  $$$$$$ | $$$$$   | $$      | $$  | $$| $$$$$$$/  | $$     | $$     \  $$$$/
     \____  $$| $$__/   | $$      | $$  | $$| $$__  $$  | $$     | $$      \  $$/
     /$$  \ $$| $$      | $$    $$| $$  | $$| $$  \ $$  | $$     | $$       | $$
    |  $$$$$$/| $$$$$$$$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$   | $$       | $$
     \______/ |________/ \______/  \______/ |__/  |__/|______/   |__/       |_*/

    function deposit(CreateNote calldata params) external whenNotPaused returns (uint) {
        uint reward = rewardOf(params.fund);

        Note memory token = _note.collectDeposit(
            params,
            reward
        );

        _money.transferFrom(
            params.payer,
            address(this),
            params.amount
        );

        _safeMint(
            params.minter,
            token.id,
            new bytes(0)
        );

        emit Deposit(
            params.minter,
            params.payer,
            token.id,
            token.artId,
            token.coinId,
            token.fund,
            token.reward,
            token.shares,
            token.principal,
            token.duration,
            token.dailyBonus,
            token.delegate,
            token.payee,
            token.expiresAt,
            token.createdAt
        );

        return token.id;
    }

    function withdraw(WithdrawNote calldata params) external {
        address owner = ownerOf(params.noteId);

        Note memory token = _note.collectNote(
            msg.sender,
            owner,
            params.noteId,
            params.payee,
            params.target
        );

        _pay(token, params.payee);

        emit Withdraw(
            params.payee,
            msg.sender,
            token.id,
            token.fund,
            token.artId,
            token.coinId,
            token.shares,
            token.reward,
            token.principal,
            token.penalty,
            token.earnings,
            token.funding,
            token.dailyBonus,
            token.createdAt,
            block.timestamp
        );
    }

    function delegate(DelegateNote calldata params) external {
        address owner = ownerOf(params.noteId);

        Note memory token = _note.collectDelegate(
            msg.sender,
            owner,
            params
        );

        emit Delegate(
            msg.sender,
            owner,
            params.noteId,
            token.delegate,
            token.payee,
            token.memo,
            block.timestamp
        );
    }

    function close(uint noteId) external {
        address owner = ownerOf(noteId);

        Note memory token = _note.collectNote(
            msg.sender,
            owner,
            noteId,
            address(0),
            0
        );

        emit Close(
            msg.sender,
            owner,
            token.id,
            token.fund,
            token.artId,
            token.coinId,
            token.shares,
            token.principal,
            token.penalty,
            token.duration,
            token.dailyBonus,
            token.createdAt,
            block.timestamp
        );
    }

    constructor(ArtData data_, IFound money_)
    ArtToken("Treasury Note", "T NOTE", data_) {
        _money = money_;
        _note = new FoundNote(address(this), data_, _money);
        _bank = new DailyMint(address(this), data_, FoundBase(_note));
    }

    function _tokenToArt(uint tokenId) override internal view returns (uint) {
        return _note.getNote(tokenId).artId;
    }

    function _pay(Note memory token, address to) internal {
        uint out = token.principal + token.earnings - token.penalty;

        if (out == 0) return;
        _money.transfer(to, out);

        if (token.funding > 0) {
            _payFund(to, token);
        }
    }

    function _payFund(address to, Note memory token) internal {
        address payee = payeeOf(token.fund);
        if (address(payee) == address(0)) return;

        _money.transfer(
            payee,
            token.funding
        );

        _credit(
            to,
            token.fund,
            token.id,
            token.funding
        );

        emit Credit(
            to,
            token.fund,
            token.id,
            token.funding,
            block.timestamp
        );
    }

    function _afterTokenTransfer(
        address from, address, uint tokenId, uint
    ) internal virtual override {
        if (from != address(0)) {
            _note.afterTransfer(tokenId);
        }
    }
}