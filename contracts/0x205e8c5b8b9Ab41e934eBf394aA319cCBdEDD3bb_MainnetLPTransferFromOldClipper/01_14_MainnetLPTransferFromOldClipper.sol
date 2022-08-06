//SPDX-License-Identifier: Copyright 2022 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ClipperCommonExchange.sol";
import "./interfaces/WrapperContractInterface.sol";

contract MainnetLPTransferFromOldClipper {
    address payable public immutable OLD_EXCHANGE_INTERFACE;
    address payable public immutable OLD_POOL;
    address payable public immutable NEW_EXCHANGE;
    address payable public immutable WRAPPER_CONTRACT;

    uint256 private constant ONE_IN_TEN_DECIMALS = 1e10;

    using SafeERC20 for IERC20;

    event LPTransferred(
        address indexed depositor,
        uint256 oldPoolTokens,
        uint256 newPoolTokens
    );

    constructor(address _oldExchangeInterface, address _oldPool, address payable _newExchange) {
        OLD_EXCHANGE_INTERFACE = payable(_oldExchangeInterface);
        OLD_POOL = payable(_oldPool);
        NEW_EXCHANGE = _newExchange;
        WRAPPER_CONTRACT = payable(ClipperCommonExchange(_newExchange).WRAPPER_CONTRACT());
    }

    // Allows the receipt of ETH directly from burn
    receive() external payable {
    }

    function safeEthSend(address recipient, uint256 howMuch) internal {
        (bool success, ) = payable(recipient).call{value: howMuch}("");
        require(success, "Call with value failed");
    }

    function verifyETHBalanceFromBurn(uint256 allegedDeposit, uint256 myFraction) internal view {
        // check that fraction of ETH balance aligns with allegedDeposit
        uint256 correspondingTokens = (myFraction*OLD_POOL.balance)/ONE_IN_TEN_DECIMALS;
        require(allegedDeposit <= correspondingTokens, "Deposit unsupported by old pool balance");
    }

    function verifyBalanceFromBurn(address theAsset, uint256 allegedDeposit, uint256 myFraction) internal view {
        // check that fraction of poolTokens aligns with token holdings
        uint256 correspondingTokens = (myFraction*IERC20(theAsset).balanceOf(OLD_POOL))/ONE_IN_TEN_DECIMALS;
        require(allegedDeposit <= correspondingTokens, "Deposit unsupported by old pool assets");

    }

    // Transfers LP from old to new pool contracts.
    // This contract should be whitelisted for zero-day deposits with reasonable limit
    // No sender -> must be this contract
    // No nDays -> must be 0
    function transferLP(uint256[] calldata depositAmounts, uint256 poolTokens, uint256 goodUntil, ClipperCommonExchange.Signature calldata theSignature) external {
        uint256 oldLPBalance = IERC20(OLD_POOL).balanceOf(msg.sender);

        // Make sure we'll get enough tokens from burning this LP's pool tokens to make the deposit
        uint256 i;
        uint256 newNTokens = ClipperCommonExchange(NEW_EXCHANGE).nTokens();
        uint256 myFraction = (oldLPBalance*ONE_IN_TEN_DECIMALS)/IERC20(OLD_POOL).totalSupply();
        
        for(i=0; i < newNTokens; i++){
            address _theToken = ClipperCommonExchange(NEW_EXCHANGE).tokenAt(i);
            if(ClipperCommonExchange(OLD_POOL).isToken(_theToken)){
                verifyBalanceFromBurn(_theToken, depositAmounts[i], myFraction);
            } else if(_theToken == WRAPPER_CONTRACT){
                verifyETHBalanceFromBurn(depositAmounts[i], myFraction);
            } else {
                require(depositAmounts[i]==0, "Invalid deposit");
            }
        }

        IERC20(OLD_POOL).safeTransferFrom(msg.sender, address(this), oldLPBalance);

        // Call signature here is exactly the same as WETH
        WrapperContractInterface(OLD_EXCHANGE_INTERFACE).withdraw(oldLPBalance);
        
        // Go through all the tokens of the old pool and transfer to the new exchange if they're supported there
        // If not, just send them back to the depositor
        uint256 oldNTokens = ClipperCommonExchange(OLD_POOL).nTokens();
        for(i=0; i < oldNTokens; i++){
            address _theToken = ClipperCommonExchange(OLD_POOL).tokenAt(i);
            uint256 _theBalance = IERC20(_theToken).balanceOf(address(this));
            address _destination;
            if(ClipperCommonExchange(NEW_EXCHANGE).isToken(_theToken)){
                _destination = NEW_EXCHANGE;
            } else {
                _destination = msg.sender;
            }
            IERC20(_theToken).safeTransfer(_destination, _theBalance);
        }

        // We got raw ETH back from the burn. Wrap and send that, too.
        uint256 _myEthBalance = address(this).balance;
        safeEthSend(WRAPPER_CONTRACT, _myEthBalance);
        IERC20(WRAPPER_CONTRACT).safeTransfer(NEW_EXCHANGE, _myEthBalance);

        // Make the deposit and send back the tokens to the user
        ClipperCommonExchange(NEW_EXCHANGE).deposit(address(this), depositAmounts, 0, poolTokens, goodUntil, theSignature);
        IERC20(NEW_EXCHANGE).safeTransfer(msg.sender, poolTokens);

        emit LPTransferred(msg.sender, oldLPBalance, poolTokens);
    }
}