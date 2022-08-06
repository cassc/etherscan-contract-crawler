//SPDX-License-Identifier: Copyright 2022 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ClipperCommonExchange.sol";

contract LPTransfer {
    address payable public immutable OLD_EXCHANGE;
    address payable public immutable NEW_EXCHANGE;

    uint256 constant ONE_IN_TEN_DECIMALS = 1e10;

    using SafeERC20 for IERC20;

    event LPTransferred(
        address indexed depositor,
        uint256 oldPoolTokens,
        uint256 newPoolTokens
    );

    constructor(address _oldExchange, address _newExchange) {
        OLD_EXCHANGE = payable(_oldExchange);
        NEW_EXCHANGE = payable(_newExchange);
    }

    function verifyBalanceFromBurn(address theAsset, uint256 allegedDeposit, uint256 poolTokensToBurn) internal view {
        // check that fraction of poolTokens aligns with holdings of allegedDeposit
        uint256 myFraction = (poolTokensToBurn*ONE_IN_TEN_DECIMALS)/IERC20(OLD_EXCHANGE).totalSupply();
        uint256 correspondingTokens = (myFraction*IERC20(theAsset).balanceOf(OLD_EXCHANGE))/ONE_IN_TEN_DECIMALS;
        require(allegedDeposit <= correspondingTokens, "Deposit unsupported by old pool assets");
    }

    // Transfers LP from old to new pool contracts.
    // This contract should be whitelisted for zero-day deposits with reasonable limit
    // No sender -> must be this contract
    // No nDays -> must be 0
    function transferLP(uint256[] calldata depositAmounts, uint256 poolTokens, uint256 goodUntil, ClipperCommonExchange.Signature calldata theSignature) external {
        uint256 oldLPBalance = IERC20(OLD_EXCHANGE).balanceOf(msg.sender);

        // Make sure we'll get enough tokens from burning this LP's pool tokens to make the deposit
        uint256 i;
        uint256 newNTokens = ClipperCommonExchange(NEW_EXCHANGE).nTokens();
        for(i=0; i < newNTokens; i++){
            address _theToken = ClipperCommonExchange(NEW_EXCHANGE).tokenAt(i);
            if(ClipperCommonExchange(OLD_EXCHANGE).isToken(_theToken)){
                verifyBalanceFromBurn(_theToken, depositAmounts[i], oldLPBalance);
            } else {
                require(depositAmounts[i]==0, "Invalid deposit");
            }
        }

        IERC20(OLD_EXCHANGE).safeTransferFrom(msg.sender, address(this), oldLPBalance);
        ClipperCommonExchange(OLD_EXCHANGE).burnToWithdraw(oldLPBalance);
        
        // Go through all the tokens of the old pool and transfer to the new exchange if they're supported there
        // If not, just send them back to the depositor
        uint256 oldNTokens = ClipperCommonExchange(OLD_EXCHANGE).nTokens();
        for(i=0; i < oldNTokens; i++){
            address _theToken = ClipperCommonExchange(OLD_EXCHANGE).tokenAt(i);
            uint256 _theBalance = IERC20(_theToken).balanceOf(address(this));
            address _destination;
            if(ClipperCommonExchange(NEW_EXCHANGE).isToken(_theToken)){
                _destination = NEW_EXCHANGE;
            } else {
                _destination = msg.sender;
            }
            IERC20(_theToken).safeTransfer(_destination, _theBalance);
        }
        ClipperCommonExchange(NEW_EXCHANGE).deposit(address(this), depositAmounts, 0, poolTokens, goodUntil, theSignature);
        IERC20(NEW_EXCHANGE).safeTransfer(msg.sender, poolTokens);

        emit LPTransferred(msg.sender, oldLPBalance, poolTokens);
    }
}