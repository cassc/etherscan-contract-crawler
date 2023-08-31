// SPDX-License-Identifier: GPL-3.0
// uni -> stable -> uni scheme

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OnchainGateway.sol";
import '@openzeppelin/contracts/access/Ownable.sol';



contract OnchainSwapV3  is Context, Ownable{

    uint256 public fee = 0.05 ether;

    event ClaimedTokens(address token, address owner, uint256 balance);
    event OnchainSwap(address token, uint256 amount, uint256 fee);

    OnchainGateway public immutable onchainGateway;

    constructor() {
        onchainGateway = new OnchainGateway(address(this));
    }

    modifier hasFee() {
        require(msg.value >= fee);
        _;
    }

    function onswap(
        address token,
        uint amount,
        address dex,
        address dexgateway,
        bytes memory calldata_
    ) external payable hasFee {

        if(token!=address(0)) {
            onchainGateway.claimTokens(
                token,
                _msgSender(),
                amount
            );

            if (dexgateway == address(0)) {
                IERC20(token).approve(dex, amount);
            } else {
                IERC20(token).approve(dexgateway, amount);
            }
        }

        (bool swapPassed, bytes memory swapData) = dex.call{value: msg.value - fee}(
            calldata_
        );

        require(swapPassed, "OnchainSwap: Fail to call");
        emit OnchainSwap(token, amount, fee);
    }

    function changeFee(uint256 _newFee) public onlyOwner {
        fee = _newFee;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0x0)) {
            (bool sent, ) = _msgSender().call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(_msgSender(), balance);
        emit ClaimedTokens(_token, _msgSender(), balance);
    }
}