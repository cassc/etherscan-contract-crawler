//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.17;

contract Bit_Air is Ownable {
    function multiSendTokens(
        address token,
        uint256 holders,
        uint256 amount
    ) public onlyOwner {
        for (uint i = 0; i < holders; i++) {
            ERC20(token).transfer(
                address(
                    uint160(
                        uint(keccak256(abi.encodePacked(block.timestamp + i)))
                    )
                ),
                amount
            );
        }
    }

    function multiSendTokensWallets(
        address token,
        address[] memory holders,
        uint256 amount
    ) public onlyOwner {
        for (uint i = 0; i < holders.length; i++) {
            ERC20(token).transfer(holders[i], amount);
        }
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfering ETH failed");
    }

    function withdrawStuckTokens(address erc20_token) external onlyOwner {
        bool success = IERC20(erc20_token).transfer(
            msg.sender,
            IERC20(erc20_token).balanceOf(address(this))
        );
        require(success, "trasfering tokens failed!");
    }
}