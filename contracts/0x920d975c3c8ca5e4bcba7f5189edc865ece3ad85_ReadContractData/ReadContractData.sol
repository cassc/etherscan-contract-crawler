/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

// SPDX-License-Identifier: SimPL-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function checkIsContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(checkIsContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(checkIsContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(checkIsContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract ReadContractData {
    using Address for address;

    function isContract(address[] memory addr) public view returns (bool[] memory checkContract) {
        uint len = addr.length;

        checkContract = new bool[](len);
        for (uint i = 0; i < len; i++) {
            bool check = addr[i].checkIsContract();
            checkContract[i] = check;
        }
    }

    function getBalance(address[] memory addr, address tokenAddr) public view returns (uint[] memory balanceList, uint8 decimals) {
        uint len = addr.length;

        IERC20 erc = IERC20(tokenAddr);
        decimals = tokenAddr == address(0) ? uint8(18) : erc.decimals();

        balanceList = new uint[](len);
        for (uint i = 0; i < len; i++) {
            if (tokenAddr == address(0)) {
                balanceList[i] = addr[i].balance;
            } else {
                uint balance = erc.balanceOf(addr[i]);
                balanceList[i] = balance;
            }
        }
    }

    function getIsContractAndBalance(
        address[] memory addr, 
        address tokenAddr
    ) 
    public view returns (
        bool[] memory checkContract, 
        uint[] memory balanceList, 
        uint8 decimals
    ) {
        (balanceList, decimals) = getBalance(addr, tokenAddr);
        checkContract = isContract(addr);
    }

    function getTokenData(address[] memory tokenAddr) public view returns (
        string[] memory tokenName, 
        string[] memory tokenSymbol, 
        uint8[] memory decimals
    ) {
        uint len = tokenAddr.length;

        tokenName = new string[](len);
        tokenSymbol = new string[](len);
        decimals = new uint8[](len);

        for (uint i = 0; i < len; i++) {
            IERC20 erc = IERC20(tokenAddr[i]);
            tokenName[i] = erc.name();
            tokenSymbol[i] = erc.symbol();
            decimals[i] = erc.decimals();
        }
    }
}