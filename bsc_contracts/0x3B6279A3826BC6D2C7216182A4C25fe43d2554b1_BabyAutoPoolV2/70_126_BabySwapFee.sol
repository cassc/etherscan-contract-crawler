// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import './BabyPair.sol';
import '../libraries/BabyLibrary.sol';
import '../interfaces/IBabyRouter.sol';
import '../interfaces/IBabyFactory.sol';
import '../interfaces/IBabyPair.sol';
import '../libraries/SafeMath.sol';
import '../token/SafeBEP20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../libraries/Address.sol';

contract BabySwapFee is Ownable {
    using SafeMath for uint;
    using Address for address;

    address public constant hole = 0x000000000000000000000000000000000000dEaD;
    address public bottle;
    address public vault;
    IBabyRouter public immutable router;
    IBabyFactory public immutable factory;
    address public immutable WBNB;
    address public immutable BABY;
    address public immutable USDT;
    address public receiver;
    address public caller;

    constructor(address bottle_, address vault_, IBabyRouter router_, IBabyFactory factory_, address WBNB_, address BABY_, address USDT_, address receiver_, address caller_) {
        bottle = bottle_; 
        vault = vault_;
        router = router_;
        factory = factory_;
        WBNB = WBNB_;
        BABY = BABY_;
        USDT = USDT_;
        receiver = receiver_;
        caller = caller_;
    }

    function setCaller(address newCaller_) external onlyOwner {
        require(newCaller_ != address(0), "caller is zero");
        caller = newCaller_;
    }

    function setVault(address newVault_) external onlyOwner {
        require(newVault_ != address(0), "vault is zero");
        vault = newVault_;
    }

    function setBottle(address newBottle_) external onlyOwner {
        require(newBottle_ != address(0), "vault is zero");
        bottle = newBottle_;
    }

    function setReceiver(address newReceiver_) external onlyOwner {
        require(newReceiver_ != address(0), "receiver is zero");
        receiver = newReceiver_;
    }

    function transferToVault(IBabyPair pair, uint balance) internal returns (uint balanceRemained) {
        uint balanceUsed = balance.div(3);
        balanceRemained = balance.sub(balanceUsed);
        SafeBEP20.safeTransfer(IBEP20(address(pair)), vault, balanceUsed);
    }

    function transferToBottle(address token, uint balance) internal returns (uint balanceRemained) {
        uint balanceUsed = balance.div(2);
        balanceRemained = balance.sub(balanceUsed);
        SafeBEP20.safeTransfer(IBEP20(token), bottle, balanceUsed);
    }

    function doHardwork(address[] calldata pairs, uint minAmount) external {
        require(msg.sender == caller, "illegal caller");
        for (uint i = 0; i < pairs.length; i ++) {
            IBabyPair pair = IBabyPair(pairs[i]);
            if (pair.token0() != USDT && pair.token1() != USDT) {
                continue;
            }
            uint balance = pair.balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            if (balance < minAmount) {
                continue;
            }
            balance = transferToVault(pair, balance);
            address token = pair.token0() != USDT ? pair.token0() : pair.token1();
            pair.approve(address(router), balance);
            router.removeLiquidity(
                token,
                USDT,
                balance,
                0,
                0,
                address(this),
                block.timestamp
            );
            address[] memory path = new address[](2);
            path[0] = token;path[1] = USDT;
            balance = IBEP20(token).balanceOf(address(this));
            IBEP20(token).approve(address(router), balance);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balance,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function destroyAll() external onlyOwner {
        uint balance = IBEP20(USDT).balanceOf(address(this));
        balance = transferToBottle(USDT, balance);
        address[] memory path = new address[](2);
        path[0] = USDT;path[1] = BABY;
        balance = IBEP20(USDT).balanceOf(address(this));
        IBEP20(USDT).approve(address(router), balance);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            balance,
            0,
            path,
            address(this),
            block.timestamp
        );
        balance = IBEP20(BABY).balanceOf(address(this));
        SafeBEP20.safeTransfer(IBEP20(BABY), hole, balance);
    }

    function transferOut(address token, uint amount) external {
        IBEP20 bep20 = IBEP20(token);
        uint balance = bep20.balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }
        SafeBEP20.safeTransfer(bep20, receiver, amount);
    }
}