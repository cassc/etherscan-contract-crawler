// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuarded.sol";

abstract contract Upgradeable is ReentrancyGuarded {
    address public trustedForwarder;
    address public recipient;
    address public signatureUtils;

    address public feeUtils;
    address public offerHandler;
    address public boxUtils;
    mapping(bytes => bool) public openedBoxSignatures;

    mapping(address => bool) adminList;
    mapping(address => bool) public acceptedTokens;
    mapping(uint256 => uint256) public soldQuantity;
    mapping(bytes => bool) invalidSaleOrder;
    mapping(bytes => bool) invalidOffers;
    mapping(bytes => bool) acceptedOffers;
    mapping(bytes => uint256) public soldQuantityBySaleOrder;

    mapping(address => uint256) public nonces;
    mapping(address => uint256) public tokensFee;
    address public metaHandler;

    mapping(bytes => mapping(address => uint256)) public claimedAmountPerUser;
    mapping(bytes32 => mapping(address => uint256)) _nonces;
    mapping(bytes => bool) public invalidAirdropEvent;
    address public airdropHandler;
    mapping(bytes => mapping(uint256 => uint256)) public claimedAmountPerNFT;
    address offerHandlerNativeAddress;
    address public buyHandler;
    address sellHandlerAddress;
    address erc721SellHandlerAddress;
    address public featureHandler;
    address public sellHandler;
    address erc721SellHandlerNativeAddress;

    mapping(string => mapping(string => bool)) storeFeatures;
    mapping(string => mapping(address => uint256)) royaltyFeeAmount;
    address public cancelHandler;
    mapping(string => mapping(address => uint256)) featurePrice;
    mapping(string => mapping(string => mapping(address => uint256))) featureStakedAmount;
    mapping(address => bool) signers;

    mapping(address => mapping(uint8 => bool)) subAdminList;

    function _delegatecall(address _impl) internal {
        require(_impl != address(0), "Impl address is 0");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                _impl,
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
        }
    }
}