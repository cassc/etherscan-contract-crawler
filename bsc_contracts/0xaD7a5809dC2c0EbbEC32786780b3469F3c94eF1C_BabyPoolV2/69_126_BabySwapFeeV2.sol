// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/IBabyFactory.sol';
import '../interfaces/IBabyRouter.sol';
//import '../libraries/BabyLibrary.sol';
import '../interfaces/IBabyPair.sol';

contract BabySwapFeeV2 is Ownable {
    using SafeMath for uint;
    using Address for address;
    using SafeERC20 for IERC20;

    event NewReceiver(address receiver, uint percent, IERC20 token);
    event NewCaller(address oldCaller, address newCaller);
    event NewSupportToken(address token);
    event DelSupportToken(address token);
    event NewDestroyPercent(uint oldPercent, uint newPercent);

    IBabyFactory public immutable factory;
    IBabyRouter public immutable router;
    address public immutable middleToken;
    address[] public supportTokenList;
    mapping(address => bool) public supportToken;

    address public constant hole = 0x000000000000000000000000000000000000dEaD;  //destroy address
    address[] public receivers;
    mapping(address => uint) public receiverFees;
    mapping(address => IERC20) public receiverTokens;
    uint public totalPercent;
    uint public constant FEE_BASE = 1e6;
    address public immutable ownerReceiver;                                               //any token can be got by this address

    address public caller;
    address public immutable destroyToken;
    uint public destroyPercent;

    function addSupportToken(address _token) external onlyOwner {
        require(_token != address(0), "token address is zero");
        for (uint i = 0; i < supportTokenList.length; i ++) {
            require(supportTokenList[i] != _token, "token already exist");
        }
        //require(!supportToken[_token], "token already supported");
        supportTokenList.push(_token);
        supportToken[_token] = true;
        emit NewSupportToken(_token);
    }

    function delSupportToken(address _token) external onlyOwner {
        uint currentId = 0;
        for (; currentId < supportTokenList.length; currentId ++) {
            if (supportTokenList[currentId] == _token) {
                break;
            }
        }
        require(currentId < supportTokenList.length, "receiver not exist");
        delete supportToken[_token];
        supportTokenList[currentId] = supportTokenList[supportTokenList.length - 1];
        supportTokenList.pop();
        emit DelSupportToken(_token);
    }

    function addReceiver(address _receiver, uint _percent, IERC20 _token) external onlyOwner {
        require(_receiver != address(0), "receiver address is zero");
        require(_percent <= FEE_BASE, "illegal percent");
        for (uint i = 0; i < receivers.length; i ++) {
            require(receivers[i] != _receiver, "receiver already exist");
        }
        require(totalPercent <= FEE_BASE.sub(_percent), "illegal percent");
        totalPercent = totalPercent.add(_percent);
        receivers.push(_receiver);
        receiverFees[_receiver] = _percent;
        receiverTokens[_receiver] = _token;
        emit NewReceiver(_receiver, _percent, _token);
    }

    function delReceiver(address _receiver) external onlyOwner {
        uint currentId = 0;
        for (; currentId < receivers.length; currentId ++) {
            if (receivers[currentId] == _receiver) {
                break;
            }
        }
        require(currentId < receivers.length, "receiver not exist");
        totalPercent = totalPercent.sub(receiverFees[_receiver]);
        delete receiverFees[_receiver];
        delete receiverTokens[_receiver];
        receivers[currentId] = receivers[receivers.length - 1];
        receivers.pop();
        emit NewReceiver(_receiver, 0, IERC20(address(0)));
    }

    function setCaller(address _caller) external onlyOwner {
        emit NewCaller(caller, _caller);
        caller = _caller; 
    }

    function setDestroyPercent(uint _percent) external onlyOwner {
        require(_percent <= FEE_BASE, "illegam percent");
        emit NewDestroyPercent(destroyPercent, _percent);
        destroyPercent = _percent;
    }

    modifier onlyOwnerOrCaller() {
        require(owner() == _msgSender() || caller == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(IBabyFactory _factory, IBabyRouter _router, address _middleToken, address _destroyToken, address _ownerReceiver) {
        require(address(_factory) != address(0), "factory address is zero");
        factory = _factory;
        require(address(_router) != address(0), "router address is zero");
        router = _router;
        require(_middleToken != address(0), "middleToken address is zero");
        middleToken = _middleToken;
        require(_destroyToken != address(0), "destroyToken address is zero");
        destroyToken = _destroyToken;
        require(_ownerReceiver != address(0), "ownerReceiver address is zero");
        ownerReceiver = _ownerReceiver;
    }

    function canRemove(IBabyPair pair) internal view returns (bool) {
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint balance0 = IERC20(token0).balanceOf(address(pair));
        uint balance1 = IERC20(token1).balanceOf(address(pair));
        uint totalSupply = pair.totalSupply();
        if (totalSupply == 0) {
            return false;
        }
        uint liquidity = pair.balanceOf(address(this));
        uint amount0 = liquidity.mul(balance0) / totalSupply; // using balances ensures pro-rata distribution
        uint amount1 = liquidity.mul(balance1) / totalSupply; // using balances ensures pro-rata distribution
        if (amount0 == 0 || amount1 == 0) {
            return false;
        }
        return true;
    }

    function doHardwork(address[] calldata pairs, uint minAmount) external onlyOwnerOrCaller {
        for (uint i = 0; i < pairs.length; i ++) {
            IBabyPair pair = IBabyPair(pairs[i]);
            if (!supportToken[pair.token0()] && !supportToken[pair.token1()]) {
                continue;
            }
            uint balance = pair.balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            if (balance < minAmount) {
                continue;
            }
            if (!canRemove(pair)) {
                continue;
            }
            pair.approve(address(router), balance);
            router.removeLiquidity(
                pair.token0(),
                pair.token1(),
                balance,
                0,
                0,
                address(this),
                block.timestamp
            );
            address swapToken = supportToken[pair.token0()] ? pair.token1() : pair.token0();
            address targetToken = supportToken[pair.token0()] ? pair.token0() : pair.token1();
            address[] memory path = new address[](2);
            path[0] = swapToken; path[1] = targetToken;
            balance = IERC20(swapToken).balanceOf(address(this));
            IERC20(swapToken).approve(address(router), balance);
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
        address[] memory path = new address[](2);
        uint balance = 0;
        for (uint i = 0; i < supportTokenList.length; i ++) {
            IERC20 token = IERC20(supportTokenList[i]);
            balance = token.balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            if (address(token) != middleToken) {
                path[0] = address(token);path[1] = middleToken;
                IERC20(token).approve(address(router), balance);
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    balance,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            }
        }
        balance = IERC20(middleToken).balanceOf(address(this));
        uint feeAmount = balance.mul(FEE_BASE.sub(destroyPercent)).div(FEE_BASE);
        for (uint i = 0; i < receivers.length; i ++) {
            uint amount = feeAmount.mul(receiverFees[receivers[i]]).div(FEE_BASE);
            if (amount > 0) {
                IERC20 token = receiverTokens[receivers[i]];
                if (address(token) == address(0)) {
                    token = IERC20(middleToken);
                }
                if (address(token) == middleToken) {
                    IERC20(middleToken).safeTransfer(receivers[i], amount);
                } else {
                    path[0] = middleToken;path[1] = address(token);
                    IERC20(middleToken).approve(address(router), amount);
                    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        amount,
                        0,
                        path,
                        receivers[i],
                        block.timestamp
                    );
                }
            }
        }
        uint destroyAmount = balance.sub(feeAmount);
        path[0] = middleToken;path[1] = destroyToken;
        IERC20(middleToken).approve(address(router), destroyAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            destroyAmount,
            0,
            path,
            hole,
            block.timestamp
        );
    }

    function transferOut(address token, uint amount) external onlyOwner {
        IERC20 erc20 = IERC20(token);
        uint balance = erc20.balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }
        require(ownerReceiver != address(0), "ownerReceiver is zero");
        SafeERC20.safeTransfer(erc20, ownerReceiver, amount);
    }
}