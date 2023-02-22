// SPDX-License-Identifier: SPWPL

pragma solidity 0.8.15;
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract RevenueAggregatorV2 is ERC2771Recipient{
    /** @notice Emits when a withdrawal takes place
     * @param path The address of the revenue path
     * @param status Whether the withdrawal suceeded
     */
    event WithdrawStatus(address indexed path, bool indexed status, bytes result);
    error ZeroAddressProvided();

    constructor (address _forwarder){

        _setTrustedForwarder(_forwarder);
    }

    /** @notice Batch withdrawal request for tokens across revenue paths
     * @param paths List of revenue paths
     * @param targetWallet The wallet for which the withdrawal is being made
     */
    function withdrawPathToken(address[] calldata paths, address targetWallet, address tokenAddress) external {
        uint256 pathLength = paths.length;

        for (uint256 i; i < pathLength; ) {
            if(paths[i] == address(0)){
                revert ZeroAddressProvided();
            }
            (bool status, bytes memory result) = address(paths[i]).call(
                abi.encodeWithSignature("release(address,address)",tokenAddress,targetWallet)
            );
            
            emit WithdrawStatus(paths[i], status, result);
            unchecked{++i;}
        }
    }

        function distributePathToken(address[] calldata paths, address tokenAddress) external {
        uint256 pathLength = paths.length;

        for (uint256 i; i < pathLength; ) {

            (bool status, bytes memory result) = address(paths[i]).call(
                abi.encodeWithSignature("distributePendingTokens(address)",tokenAddress)
            );

            unchecked{++i;}
        }
    }

   
}