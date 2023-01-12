// Live deployment v3

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract tokenDistributor is Ownable {
    using SafeMath for uint256;

    address public dropshare;

    uint256 private arrayLimit = 200;

    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data);

    event Multisended(uint256 total, address tokenAddress);

    receive() external payable {}


    function getArrayLimit() public view returns(uint256) {
        return arrayLimit;
    }

    function setArrayLimit(uint256 _newLimit) public onlyOwner {
        require(_newLimit != 0);
        arrayLimit = _newLimit;
    }

    function batchSendToken(address token, address[] memory _contributors, uint256[] memory _balances) external onlyOwner {
        uint256 total = 0;
        require(_contributors.length <= getArrayLimit(),"Array length exceeds limit");
        require(_contributors.length == _balances.length,"Array length mismatch");
        IERC20 erc20token = IERC20(token);

        for (uint8 i = 0; i < _contributors.length; i++) {
            erc20token.transfer( _contributors[i], _balances[i]);
            total += _balances[i];
        }

        emit Multisended(total, token);
    }


	function singleSendTokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(to, amount);
	}

    // to interact with other contracts
    function sendCustomTransaction(address target, uint value, string memory signature, bytes memory data) public payable onlyOwner returns (bytes memory)  {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data));
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data);

        return returnData;
    }

}