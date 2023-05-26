// DELTA-BUG-BOUNTY
pragma abicoder v2;
pragma solidity ^0.7.6;

import "../../../libs/Address.sol";
import "../../../libs/SafeMath.sol";
import "../../../../interfaces/IOVLTransferHandler.sol";
import "../../Common/OVLBase.sol";
import "../../../../common/OVLTokenTypes.sol";

contract OVLLPRebasingHandler is OVLBase, IOVLTransferHandler {
    using SafeMath for uint256;
    using Address for address;

    address private constant DEPLOYER = 0x5A16552f59ea34E44ec81E58b3817833E9fD5436;
    address private constant DELTA_LIMITED_STAKING_WINDOW = 0xdaFCE5670d3F67da9A3A44FE6bc36992e5E2beaB;

    address public immutable UNI_DELTA_WETH_PAIR;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address pair) {
        UNI_DELTA_WETH_PAIR = pair;
    }

    // This function does not need authentication, because this is EXCLUSIVELY
    // ever meant to be called using delegatecall() from the main token.
    // The memory it modifies in DELTAToken is what effects user balances.
    // Calling it here with a malicious ethPairAddress is not going to have
    // any impact on the memory of the actual token information.
    function handleTransfer(address sender, address recipient, uint256 amount) external override {
        // Mature sure its the deployer
        require(tx.origin == DEPLOYER, "!authorised");
        // require(sender == DELTA_LIMITED_STAKING_WINDOW || sender == UNI_DELTA_WETH_PAIR || recipient == UNI_DELTA_WETH_PAIR, "Transfers not to or from pair during rebasing is not allowed");

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(sender != recipient, "DELTA: Transfer to self disallowed!");

        UserInformation storage senderInfo = _userInformation[sender];
        UserInformation storage recipientInfo = _userInformation[recipient];
        

        senderInfo.maturedBalance =  senderInfo.maturedBalance.sub(amount);
        senderInfo.maxBalance = senderInfo.maxBalance.sub(amount);

        recipientInfo.maturedBalance = recipientInfo.maturedBalance.add(amount);
        recipientInfo.maxBalance = recipientInfo.maxBalance.add(amount);

        emit Transfer(sender, recipient, amount);
    }

}