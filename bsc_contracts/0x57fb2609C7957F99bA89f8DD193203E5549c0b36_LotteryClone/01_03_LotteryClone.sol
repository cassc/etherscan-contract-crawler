//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Cloneable.sol";
import "./IERC20.sol";

contract LotteryData {

    address public LotteryManager;
    address public winner;

    modifier onlyWinner() {
        require(
            msg.sender == winner && winner != address(0),
            'Only Winner'
        );
        _;
    }

}

contract LotteryClone is LotteryData, Cloneable {

    function __init__() external {
        require(
            LotteryManager == address(0),
            'Already Initialized'
        );
        LotteryManager = msg.sender;
    }

    function setWinner(address winner_) external {
        require(
            msg.sender == LotteryManager, 
            'Only Lotto Manager'
        );
        require(
            winner == address(0),
            'Winner Already Set'
        );
        winner = winner_;
    }

    function withdrawETH() external onlyWinner {
        (bool s,) = payable(winner).call{value: address(this).balance}("");
        require(s);
    }

    function withdraw(address[] calldata tokens) external onlyWinner {
        require(
            msg.sender == winner,
            'Only Winner Can Withdraw'
        );
        uint len = tokens.length;
        for (uint i = 0; i < len;) {
            _withdrawToken(tokens[i]);
            unchecked { ++i; }
        }
    }

    function withdrawToken(address token) public onlyWinner {
        _withdrawToken(token);
    }

    function _withdrawToken(address token) internal {
        IERC20(token).transfer(winner, IERC20(token).balanceOf(address(this)));
    }

    receive() external payable{}
}