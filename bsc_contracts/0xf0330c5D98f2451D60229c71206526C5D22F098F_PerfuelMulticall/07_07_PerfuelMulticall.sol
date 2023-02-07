// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPerfuelPresale {
    function buyToken() external payable;
}

interface IPerfuelReferral {
    function buyToken() external payable returns (bool);
}

contract PerfuelMulticall is Ownable {
    using SafeERC20 for IERC20;
    IPerfuelPresale public perfuelPresale;
    IPerfuelReferral public perfuelReferral;

    address public perfuelAddress;

    uint256 public tokenPerEth = 200000;

    constructor(address _perfuelPresale,address _perfuelReferral,address _perfuelAddress) {
        perfuelPresale = IPerfuelPresale(_perfuelPresale);
        perfuelReferral = IPerfuelReferral(_perfuelReferral);
        perfuelAddress = _perfuelAddress;
    }

    function getPerfuelBalance() public view returns(uint256){
        return IERC20(perfuelAddress).balanceOf(perfuelAddress);
    }

    function buyTokenWithReferral(uint256 _referral) external payable{

        (bool success1, bytes memory returndata1) = address(perfuelPresale).call{value:msg.value}(abi.encodeWithSignature("buyToken()"));

        if (!success1) {
            if (returndata1.length == 0) revert();
            assembly {
                revert(add(32, returndata1), mload(returndata1))
            }
        }

        uint256 amount = (msg.value * tokenPerEth)/(1 ether);

        IERC20(perfuelAddress).safeTransfer(msg.sender,amount);  

        (bool success2,bytes memory returndata2) = address(perfuelReferral).call(abi.encodeWithSignature("buyToken(address,uint256,uint256)",msg.sender,msg.value,_referral));

        if (!success2) {
            if (returndata2.length == 0) revert();
            assembly {
                revert(add(32, returndata2), mload(returndata2))
            }
        }
    }
}