pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Splitter is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(uint256 => address) public EOAs;
    mapping(uint256 => uint256) public splits;
    address public deployer;

    function splitEth() external payable {
        uint256 balance = msg.value;
        require(balance > 0, "No Eth");
        for (uint256 i = 0; i < 10; i++) {
             if(splits[i]>0){
                uint256 toTranfer = balance.mul(splits[i]).div(1000);
                payable(EOAs[i]).transfer(toTranfer);
                balance -= toTranfer;
             }
        }
        if(balance>0){
            payable(deployer).transfer(balance);
        }

    }

    function splitOther(address _tokenAddress) external  {
        uint256 balance = IERC20(_tokenAddress).balanceOf(msg.sender);
        require(balance > 0, "No balance");
        for (uint256 i = 0; i < 10; i++) {
            if(splits[i]>0){
                IERC20(_tokenAddress).safeTransferFrom(
                    msg.sender,
                    EOAs[i],
                    balance.mul(splits[i]).div(1000)
                );
            }
        }
        IERC20(_tokenAddress).safeTransferFrom(
            msg.sender,
            deployer,
            IERC20(_tokenAddress).balanceOf(msg.sender)
        );
    }

    function editSplits(address[] memory _addys, uint256[] memory _splits)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addys.length; i++) {
            EOAs[i] = _addys[i];
            splits[i] = _splits[i];
        }
    }

    function tester() external payable {
        require(msg.value>0);
    }

    function editDeployer(address _deployer) external onlyOwner {
        deployer = _deployer;
    }
}