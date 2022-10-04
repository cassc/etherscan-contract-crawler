// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract ShibaChess is Ownable, ERC20, Pausable { 

    ShibaChessGame public game;

    event SetGameContract(address indexed gameContract);
    event Send(address indexed sender, bytes transactions);
    event Received(address indexed sender, uint256 amount);

    constructor() ERC20("Shiba Chess Token", "SHESS") {
        uint256 totalSupply_ = 6e8 * 1e18;
        _mint(msg.sender, totalSupply_);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function suspend(bool flag) external onlyOwner {
        if (flag) {
            _pause();
        } else {
            _unpause();
        }
    }

    function assignToken(address erc20, address[] memory receivers, uint256 amount) external onlyOwner {
        require(IERC20(erc20).allowance(msg.sender, address(this)) >= amount * receivers.length, "ERC20: approved allowance insufficient");
        for (uint i = 0; i < receivers.length; i++) {
            require(IERC20(erc20).transferFrom(msg.sender, receivers[i], amount), "ERC20: transferFrom failure");
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function handle(bytes memory transactions) external payable onlyOwner {
        assembly {
            let length := mload(transactions)
            let i := 0x20
            for {} lt(i, length) {} {
                let operation := shr(0xf8, mload(add(transactions, i)))
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))
                let value := mload(add(transactions, add(i, 0x15)))
                let dataLength := mload(add(transactions, add(i, 0x35)))
                let data := add(transactions, add(i, 0x55))
                if eq(operation, 1) {
                    if eq(call(gas(), to, value, data, dataLength, 0, 0), 0) {
                        break
                    }
                }
                i := add(i, add(0x55, dataLength))
            }
        }
        emit Send(msg.sender, transactions);
    }

    function setGameContract(address game_) external onlyOwner {
        game = ShibaChessGame(game_);
        emit SetGameContract(game_);
    }

    function startGame() external {
        return game.startGame();
    }

    function movePiece(uint8 round, uint8 party, string memory piece, uint256 fromPieceIndex, uint256 toPieceIndex) external returns (bool) {
        return game.movePiece(round, party, piece, fromPieceIndex, toPieceIndex);
    }

    function endGame(uint8 round, uint8 party) external {
        game.endGame(round, party);
    }

    function getMyAwards(uint8 round) external view returns (uint256) {
        return game.getMyAwards(round);
    }

    function withdrawMyAwards(uint8 round) external {
        game.withdrawMyAwards(round);
    }
    
    function voteForNext(uint8 round) external {
        game.voteForNext(round);
    }

    function voteResult(uint8 round) external view returns(address[] memory) {
        return game.voteResult(round);
    }

    function getGameRound(uint8 round) external view returns(address[] memory winners, address[] memory losers, uint256 totalCapitals) {
        return game.getGameRound(round);
    }

    function setPaymentERC20(uint8 round, address erc20) external {
        return game.setPaymentERC20(round, erc20);
    }

    function betOnBlackParty(uint8 round, address erc20, uint256 amount) external {
        game.betOnBlackParty(round, erc20, amount);
    }

    function betOnWhiteParty(uint8 round, address erc20, uint256 amount) external {
        game.betOnWhiteParty(round, erc20, amount);
    }

    function getWinningPrice(uint8 round) external view returns (address, uint256) {
        return game.getWinningPrice(round);
    }

    function withdrawWinningPrice(uint8 round) external {
        game.withdrawWinningPrice(round);
    }

}


interface ShibaChessGame {

    function startGame() external;
    function movePiece(uint8 round, uint8 party, string memory piece, uint256 fromPieceIndex, uint256 toPieceIndex) external returns (bool);
    function endGame(uint8 round, uint8 party) external;

    function getMyAwards(uint8 round) external view returns (uint256);
    function withdrawMyAwards(uint8 round) external;

    function voteForNext(uint8 round) external;
    function voteResult(uint8 round) external view returns(address[] memory);

    function getGameRound(uint8 round) external view returns(address[] memory winners, address[] memory losers, uint256 totalCapitals);

    function setPaymentERC20(uint8 round, address erc20) external;
    function betOnBlackParty(uint8 round, address erc20, uint256 amount) external;
    function betOnWhiteParty(uint8 round, address erc20, uint256 amount) external;
    function getWinningPrice(uint8 round) external view returns (address, uint256);
    function withdrawWinningPrice(uint8 round) external;

}