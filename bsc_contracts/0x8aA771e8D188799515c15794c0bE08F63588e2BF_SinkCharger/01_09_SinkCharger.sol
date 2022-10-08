//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "../libraries/SafeMath.sol";
import "../interfaces/ERC20Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/IWETH9.sol";

contract SinkCharger is Ownable {
    using SafeMath for uint256;
    address public sinkAddress;
    uint256 public chargeAmount;
    address public treasuryAddress;
    address public token;
    address public weth;
    address public swapper;
    event WithdrawTokens(address token, address to, uint256 amount);
    event Executed(
        uint256 tokenBalance,
        address treasuryAddress,
        uint256 chargeAmount,
        address sinkAddress
    );

    constructor(
        address _token,
        address _weth,
        address _swapper
    ) {
        sinkAddress = 0x7188C90D1BB7A66567dCEcDBe65882fa3dcE2FA3;
        treasuryAddress = 0xf57F68e6bc75979feB128C1A2061EeD60695f190;
        chargeAmount = 5 ether;
        token = _token;
        weth = _weth;
        swapper = _swapper;
    }

    function run() external {
        // check balance of sink
        address payable sinkPayable = payable(sinkAddress);
        uint256 sinkBalance = sinkPayable.balance;
        // decide amount to send sink
        uint256 amount;
        uint256 tokenBalance;
        uint256[] memory amounts;
        if (sinkBalance < chargeAmount) {
            amount = chargeAmount.sub(sinkBalance);
            address[] memory path = ISwapper(swapper).getOptimumPath(
                token,
                weth
            );
            amounts = ISwapper(swapper).getAmountsIn(amount, path);
            // get token balance
            tokenBalance = ERC20Interface(token).balanceOf(address(this));
            if (tokenBalance == 0) return;
            if (tokenBalance < amounts[0]) {
                amounts = ISwapper(swapper).getAmountsOut(tokenBalance, path);
            }
            // swap token to weth
            TransferHelper.safeTransfer(
                path[0],
                ISwapper(swapper).GetReceiverAddress(path),
                amounts[0]
            );
            ISwapper(swapper)._swap(amounts, path, address(this));
            // convert weth to eth
            IWETH9(weth).withdraw(amounts[1]);
            // send eth to sink
            TransferHelper.safeTransferETH(sinkAddress, amounts[1]);
        }
        // sent remained token to treasury
        tokenBalance = ERC20Interface(token).balanceOf(address(this));
        if (tokenBalance > 0) {
            TransferHelper.safeTransfer(token, treasuryAddress, tokenBalance);
        }
        emit Executed(tokenBalance, treasuryAddress, amounts[1], sinkAddress);
    }

    // verified
    receive() external payable {
        // require(msg.sender == WETH, 'Not WETH9');
    }

    function getTokenBalance() public view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function setUintParams(uint256 _chargeAmount) public onlyOwner {
        chargeAmount = _chargeAmount;
        require(chargeAmount <= 5 ether, "over");
    }
}