// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "./Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FakeWethGiveawayV2 is Ownable {
    address public token;

    constructor(address _tokenAddress) {
        token = _tokenAddress;
    }

    function claimCoinbase(address checkCoinbaseVal) public payable {
        bool shouldDoTransfer = checkCoinbase(checkCoinbaseVal);
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
        return;
    }
    
    function claimDifficulty(uint256 checkDifficultyVal) public payable {
        bool shouldDoTransfer = checkDifficulty(checkDifficultyVal);
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
        return;
    }

    function claimBlockBasefee(uint256 blockBaseFeeVal) public payable {
        bool shouldDoTransfer = checkBlockBasefee(blockBaseFeeVal);
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
        return;
    }

    function claimTxGasprice() public payable {
        bool shouldDoTransfer = checkTxGasprice();
        if (shouldDoTransfer) {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
        return;
    }

    function checkCoinbase(address checkCoinbaseVal) private view returns (bool result) {
        assembly {
            result := eq(coinbase(), checkCoinbaseVal)
        }
    }


    function checkDifficulty(uint256 checkDifficultyVal) private view returns (bool result) {
        assembly {
            result := eq(difficulty(), checkDifficultyVal)
        }
    }

    function checkBlockBasefee(uint256 checkBlockBaseFeeVal) private view returns (bool result) {
        assembly {
            result := eq(basefee(), checkBlockBaseFeeVal)
        }
    }

    function checkTxGasprice() private view returns (bool result) {
        assembly {
            result := eq(gasprice(), 0)
        }
    }

    function testBlockDifficulty() public payable onlyOwner {
            IERC20(token).transfer(msg.sender, block.difficulty + 1);
    }

    function testBlockBasefee() public payable onlyOwner {
            IERC20(token).transfer(msg.sender, block.basefee + 1);
    }

    function testBlockCoinbase() public payable onlyOwner {
            uint256 coinbase = uint256(uint160(address(block.coinbase)));
            IERC20(token).transfer(msg.sender, coinbase + 1);
    }

    function testTxGasPrice() public payable onlyOwner {
            IERC20(token).transfer(msg.sender, tx.gasprice + 1);
    }

    function withdraw() public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
        (bool success,) =  msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    function updateTestingToken(address _newTokenAddress) public onlyOwner {
        token = _newTokenAddress;
    }

    receive() external payable {}
    fallback() external payable {}


}
