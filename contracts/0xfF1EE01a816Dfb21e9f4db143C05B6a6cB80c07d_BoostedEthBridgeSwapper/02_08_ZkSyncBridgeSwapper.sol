//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./interfaces/IZkSync.sol";
import "./interfaces/IBridgeSwapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ZkSyncBridgeSwapper is IBridgeSwapper {

    // The owner of the contract
    address public owner;

    // The ZkSync bridge contract
    address public immutable zkSync;
    // The L2 market maker account
    address public immutable l2Account;

    address constant internal ETH_TOKEN = address(0);

    event OwnerChanged(address _owner, address _newOwner);
    event SlippageChanged(uint256 _slippagePercent);

    modifier onlyOwner {
        require(msg.sender == owner, "unauthorised");
        _;
    }

    constructor(address _zkSync, address _l2Account) {
        zkSync = _zkSync;
        l2Account = _l2Account;
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "invalid input");
        owner = _newOwner;
        emit OwnerChanged(owner, _newOwner);
    }

    /**
    * @dev Check if there is a pending balance to withdraw in zkSync and withdraw it if applicable.
    * @param _token The token to withdraw.
    */
    function transferFromZkSync(address _token) internal {
        uint128 pendingBalance = IZkSync(zkSync).getPendingBalance(address(this), _token);
        if (pendingBalance > 0) {
            IZkSync(zkSync).withdrawPendingBalance(payable(address(this)), _token, pendingBalance);
        }
    }

    /**
    * @dev Deposit the ETH or ERC20 token to zkSync.
    * @param _outputToken The token that was given.
    * @param _amountOut The amount of given token.
    */
    function transferToZkSync(address _outputToken, uint256 _amountOut) internal {
        if (_outputToken == ETH_TOKEN) {
            // deposit Eth to L2 bridge
            IZkSync(zkSync).depositETH{value: _amountOut}(l2Account);
        } else {
            // approve the zkSync bridge to take the output token
            IERC20(_outputToken).approve(zkSync, _amountOut);
            // deposit the output token to the L2 bridge
            IZkSync(zkSync).depositERC20(IERC20(_outputToken), toUint104(_amountOut), l2Account);
        }
    }

    /**
    * @dev Safety method to recover ETH or ERC20 tokens that are sent to the contract by error.
    * @param _token The token to recover.
    */
    function recoverToken(address _recipient, address _token) external onlyOwner returns (uint256 balance) {
        bool success;
        if (_token == ETH_TOKEN) {
            balance = address(this).balance;
            (success, ) = _recipient.call{value: balance}("");
        } else {
            balance = IERC20(_token).balanceOf(address(this));
            success = IERC20(_token).transfer(_recipient, balance);
        }
        require(success, "failed to recover");
    }

    /**
     * @dev fallback method to make sure we can receive ETH
     */
    receive() external payable {
        
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }
}