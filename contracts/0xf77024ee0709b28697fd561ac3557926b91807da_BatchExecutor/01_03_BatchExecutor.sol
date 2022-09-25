// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./utils/GPv2Order.sol"; 


interface IGnosisSettlement{
    function setPreSignature(
        bytes calldata orderUid, 
        bool signed) external;
    function domainSeparator() external view returns (bytes32);
}

contract BatchExecutor {

    address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    constructor(){}

    /// @dev Validates pending transaction in the CoWSwap pool.
    /// @param orderUid The unique identifier of the order to pre-sign.
    /// @param signed Pass true to validate order.
    function sendSetSignatureTx(
        bytes calldata orderUid, 
        bool signed) 
        external
    {
        // GPv2Settlement
        address _gnosisSettlement = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
        IGnosisSettlement(_gnosisSettlement).setPreSignature(orderUid,signed);
    }   

    /// @dev Validates a batch of pending transactions in the CoWSwap pool.
    /// @param orderUids The list of the unique identifiers of the order to pre-sign.
    /// @param signed Pass true to validate orders.
    function sendSetSignatureTxBatch(
        bytes[] calldata orderUids, 
        bool signed) 
        external
    {
        // GPv2Settlement
        address _gnosisSettlement = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
        uint len = orderUids.length;
        for (uint i = 0; i < len; i++){
            IGnosisSettlement(_gnosisSettlement).setPreSignature(orderUids[i],signed);
        }
    }   
    
    /// @dev Validates a batch of pending transactions in the CoWSwap pool.
    /// @param orderUids The list of the unique identifiers of the order to pre-sign.
    /// @param orderData The list of orders encoded data.
    /// @param signed Pass true to validate orders.
    function sendSetSignatureTxBatch(
        bytes[] calldata orderUids, 
        bytes[] calldata orderData, 
        bool signed) 
        external
    {
        isValid(orderUids,orderData);
        (address[] memory tokens, uint[] memory amounts) = evalApproval(orderData);
        approveSwaps(tokens,amounts);
        // GPv2Settlement
        address _gnosisSettlement = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
        uint len = orderUids.length;
        for (uint i = 0; i < len; i++){
            // sign order
            IGnosisSettlement(_gnosisSettlement).setPreSignature(orderUids[i],signed);
        }
    }   

    /// @dev Approves the Gnosis relayer, the contract which moves funds to fill orders.
    /// @param token The address of the token to sell.
    /// @param amount The amount to approve.
    function approveRelayer(
        address token,
        uint256 amount
    ) public {
        address gnosisVaultRelayer = 0xC92E8bdf79f0507f65a392b0ab4667716BFE0110;
        IERC20(token).approve(gnosisVaultRelayer,amount);
    }


    /// @dev Approves the Gnosis relayer, the contract which moves funds to fill orders.
    /// Multiple sell orders for the same token will get aggregated into one approve tx.
    /// @param orderData The list of orders encoded data.
    function evalApproval(
        bytes[] calldata orderData
    ) 
        internal 
        pure 
        returns(
            address[] memory tokens, uint[] memory amounts)
    {
        uint len = orderData.length;
        tokens = new address[](len);
        amounts = new uint[](len);
        for (uint i = 0; i < len; i++){
            (address sellToken,
            address buyToken,
            ,
            uint256 sellAmount,
            uint256 buyAmount,
            , , 
            uint256 feeAmount,
            , , ,
            ) = abi.decode(orderData[i], 
                    (address,address,address,uint256,uint256,uint32,bytes32,uint256,bytes32,bool,bytes32,bytes32));
            tokens[i] = sellToken; // duplicates will have amount equals 0 and get filtered out
            uint idx = indexOf(tokens,sellToken);
            amounts[idx] += (sellAmount+feeAmount);
        }
    }

    /// @dev Approves the Gnosis relayer, the contract which moves funds to fill orders.
    /// @param tokens The address list of the token to sell.
    /// @param amounts The amounts to approve.
    function approveSwaps(
        address[] memory tokens,
        uint[] memory amounts
    ) 
        internal 
    {
        address gnosisVaultRelayer = 0xC92E8bdf79f0507f65a392b0ab4667716BFE0110;
        uint len = amounts.length;
        for (uint i = 0; i < len; i++){
            if (amounts[i] > 0 && tokens[i] != native){
                IERC20(tokens[i]).approve(gnosisVaultRelayer,amounts[i]);
            }
        }
    } 


    function indexOf(address[] memory arr, address searchFor ) internal pure returns (uint) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor || arr[i] == address(0)) {
                return i;
            } 
        }
    }

    /// @dev Check authenticity of order submitted by interface.
    /// @param orderUids The list of the orders unique identifier.
    /// @param orderData The list of orders encoded data.
    function isValid(
        bytes[] calldata orderUids,
        bytes[] calldata orderData) 
        internal 
    {
        for (uint i = 0; i < orderData.length; i++){
            GPv2Order.Data memory orderDataDerived;
            {
                (address sellToken,
                address buyToken,
                address receiver,
                uint256 sellAmount,
                uint256 buyAmount,
                uint32 validTo,
                bytes32 appData,
                uint256 feeAmount,
                bytes32 kind,
                bool partiallyFillable,
                bytes32 sellTokenBalance,
                bytes32 buyTokenBalance
                ) = abi.decode(orderData[i], 
                (address,address,address,uint256,uint256,uint32,bytes32,uint256,bytes32,bool,bytes32,bytes32));
                
                orderDataDerived.sellToken = IERC20(sellToken);
                orderDataDerived.buyToken = IERC20(buyToken);
                orderDataDerived.receiver = receiver;
                orderDataDerived.sellAmount = sellAmount;
                orderDataDerived.buyAmount = buyAmount;
                orderDataDerived.validTo = validTo;
                orderDataDerived.appData = appData;
                orderDataDerived.feeAmount = feeAmount;
                orderDataDerived.kind = kind;
                orderDataDerived.partiallyFillable = partiallyFillable;
                orderDataDerived.sellTokenBalance = sellTokenBalance;
                orderDataDerived.buyTokenBalance = buyTokenBalance;
            }
            // GPv2Settlement
            address _gnosisSettlement = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
            bytes32 hashDerived = GPv2Order.hash(orderDataDerived, IGnosisSettlement(_gnosisSettlement).domainSeparator());
            orderDataDerived.receiver = address(this);
            require(GPv2Order.hash(orderDataDerived,IGnosisSettlement(_gnosisSettlement).domainSeparator()) == hashDerived,"HDIFF");
            (bytes32 orderDigest, , ) = GPv2Order.extractOrderUidParams(orderUids[i]);
            require(orderDigest == hashDerived,"ODIFF");
        }
    }

}