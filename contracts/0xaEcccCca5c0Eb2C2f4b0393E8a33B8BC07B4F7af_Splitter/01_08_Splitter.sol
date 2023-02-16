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

    function splitEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        for (uint256 i = 0; i < 10; i++) {
             if(splits[i]>0){
                _widthdraw(EOAs[i], balance.mul(splits[i]).div(1000));
             }
        }
        _widthdraw(deployer, address(this).balance);
    }

    function splitOther(address _tokenAddress) external onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(balance > 0);
        for (uint256 i = 0; i < 10; i++) {
            if(splits[i]>0){
                IERC20(_tokenAddress).safeTransfer(
                    EOAs[i],
                    balance.mul(splits[i]).div(1000)
                );
            }
        }
        IERC20(_tokenAddress).safeTransfer(
            deployer,
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

     function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
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

    function editDeployer(address _deployer) external onlyOwner {
        deployer = _deployer;
    }
}