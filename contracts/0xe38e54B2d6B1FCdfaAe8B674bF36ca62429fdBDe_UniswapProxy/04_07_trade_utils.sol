pragma solidity >=0.6.12 <=0.8.9;

import './IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TradeUtils {
	IERC20 constant public ETH_CONTRACT_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);

	function balanceOf(IERC20 token) internal view returns (uint256) {
		if (token == ETH_CONTRACT_ADDRESS) {
			return address(this).balance;
		}
        return token.balanceOf(address(this));
    }

	function transfer(IERC20 token, uint amount) internal {
		if (token == ETH_CONTRACT_ADDRESS) {
			require(address(this).balance >= amount);
			(bool success, ) = msg.sender.call{value: amount}("");
          	require(success);
		} else {
			token.transfer(msg.sender, amount);
			require(checkSuccess());
		}
	}

	function approve(IERC20 token, address proxy, uint amount) internal {
		if (token != ETH_CONTRACT_ADDRESS) {
			token.approve(proxy, 0);
			require(checkSuccess());
			token.approve(proxy, amount);
			require(checkSuccess());
		}
	}

	/**
     * @dev Check if transfer() and transferFrom() of ERC20 succeeded or not
     * This check is needed to fix https://github.com/ethereum/solidity/issues/4116
     * This function is copied from https://github.com/AdExNetwork/adex-protocol-eth/blob/master/contracts/libs/SafeERC20.sol
     */
    function checkSuccess() internal pure returns (bool) {
		uint256 returnValue = 0;

		assembly {
			// check number of bytes returned from last function call
			switch returndatasize()

			// no bytes returned: assume success
			case 0x0 {
				returnValue := 1
			}

			// 32 bytes returned: check if non-zero
			case 0x20 {
				// copy 32 bytes into scratch space
				returndatacopy(0x0, 0x0, 0x20)

				// load those bytes into returnValue
				returnValue := mload(0x0)
			}

			// not sure what was returned: don't mark as success
			default { }
		}
		return returnValue != 0;
	}
}

abstract contract Executor is Ownable {
	mapping (address => bool) public dappAddresses;

	constructor() internal {
		dappAddresses[address(this)] = true;
	}

	function addDappAddress(address addr) external onlyOwner {
		require(addr != address(0x0), "Executor:A0"); // address is zero
		dappAddresses[addr] = true;
	}

	function removeDappAddress(address addr) external onlyOwner {
		require(addr != address(0x0), "Executor:A0"); // address is zero
		dappAddresses[addr] = false;
	}

	function dappExists(address addr) public view returns (bool) {
		return dappAddresses[addr];
	}

    function execute(address fns, bytes calldata data) external payable returns (bytes memory) {
    	require(dappExists(fns), "Executor:DNE"); // dapp does not exist
        (bool success, bytes memory result) = fns.delegatecall(data);
        if (!success) {
        	// Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
        return result;
    }
}