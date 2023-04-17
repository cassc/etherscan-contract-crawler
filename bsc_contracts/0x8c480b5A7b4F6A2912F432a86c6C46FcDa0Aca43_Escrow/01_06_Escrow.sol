// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEscrow.sol";

contract Escrow is IEscrow, Ownable {
    address public controlContract;

    modifier onlyControlContract () {
        require(msg.sender == controlContract, 'You are not an Operator.');
        _;
    }

    constructor (address _owner) {
        controlContract = msg.sender;
        transferOwnership(_owner);
    }

    function emergencyWithdrawBNB (address _to) external virtual override onlyOwner {
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        if(!success){
            revert("Transfer Failed");
        }
    }

    function emergencyWithdrawToken (
        address _tokenAddress,
        address _to
    ) external virtual override onlyOwner {
        IERC20(_tokenAddress).transfer(_to, IERC20(_tokenAddress).balanceOf(address(this)));
    }

    function transferMultiTokensToWithPercentage (
        address[] memory _tokens,
        address _to,
        uint256 _percentage,
        uint256 _denominator
    ) external virtual override onlyControlContract {
        for(uint256 i = 0; i < _tokens.length; ++i){
            IERC20 token = IERC20(_tokens[i]);
            uint256 tokenBalance = token.balanceOf(address(this));
            if(tokenBalance > 0) {
                token.transfer(_to, tokenBalance * _percentage / _denominator);
            }
        }
    }

    function transferTokenTo (
        address _token,
        address _to,
        uint256 _quantity
    ) external virtual override onlyControlContract {
        IERC20(_token).transfer(_to, _quantity);
    }

    function setControlContract(address _controlContract) external onlyOwner {
        controlContract = _controlContract;
    }
}