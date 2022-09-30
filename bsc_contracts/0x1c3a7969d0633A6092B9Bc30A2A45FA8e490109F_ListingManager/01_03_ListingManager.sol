//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Ownable.sol";
import "./IERC20.sol";

contract ListingManager is Ownable {

    /**
        Royalty Database
     */
    address public immutable feeDatabase;

    /**
        Constants
     */
    uint256 public constant FEE_DENOMINATOR = 10**5;

    /**
        OTC Platform
     */
    address public OTC;

    /**
        Token Structure
     */
    struct TokenInfo {
        bool isBlacklisted;
        bool isAvailableToTrade;
        uint256 transactionFee;
        address transactionFeeRecipient;
        uint256 valuePutTowardListing;
        uint256 amountTransacted;
        uint256[] allOrders;
        uint256 indexInAllTokenArray;
        uint256 indexInPartiallyListedTokenArray;
    }
    
    /**
        Mapping From Tokens => TokenInfo
     */
    mapping ( address => TokenInfo ) public tokenInfo;

    /**
        List Of All Available Tokens
     */
    address[] public allAvailableTokens;

    /**
        List Of All Available Tokens
     */
    address[] public allPartiallyListedTokens;

    /**
        Fee For Token To Get Listed
     */
    uint256 public listingFee;


    constructor(
        address OTC_, 
        uint256 listingFee_,
        address[] memory initialTokensToListWithoutFees,
        address feeDatabase_
    ) {

        OTC = OTC_;
        listingFee = listingFee_;
        feeDatabase = feeDatabase_;

        uint len = initialTokensToListWithoutFees.length;
        for (uint i = 0; i < len;) {
            _listToken(initialTokensToListWithoutFees[i]);
            unchecked{ ++i; }
        }
    }


    function ownerRegisterToken(address token, uint256 transactionFee, address feeRecipient) external onlyOwner {
        require(
            tokenInfo[token].isAvailableToTrade == false,
            'Token Already Listed'
        );
        require(
            transactionFee <= FEE_DENOMINATOR / 3,
            'Transaction Fee Too High'
        );
        
        _listToken(token);
        tokenInfo[token].transactionFee = transactionFee;
        tokenInfo[token].transactionFeeRecipient = feeRecipient;
    }


    function ownerRemoveToken(address token) external onlyOwner {
        require(
            tokenInfo[token].isAvailableToTrade,
            'Token Not Listed'
        );

        // save state to make it easier
        address lastListing = allAvailableTokens[allAvailableTokens.length - 1];
        uint256 rmIndex = tokenInfo[token].indexInAllTokenArray;

        // disable ability to trade
        delete tokenInfo[token].valuePutTowardListing;
        delete tokenInfo[token].indexInAllTokenArray;
        delete tokenInfo[token].isAvailableToTrade;

        // move element in token array
        allAvailableTokens[rmIndex] = lastListing;
        tokenInfo[lastListing].indexInAllTokenArray = rmIndex;
        allAvailableTokens.pop();
    }

    function setListingFee(uint256 newListingFee) external onlyOwner {
        listingFee = newListingFee;
    }

    function blackListToken(address token) external onlyOwner {
        tokenInfo[token].isBlacklisted = true;
    }

    function unBlackListToken(address token) external onlyOwner {
        tokenInfo[token].isBlacklisted = false;
    }

    function setTokenTransactionFee(address token, uint256 newFee, address feeRecipient) external onlyOwner {
        require(
            newFee <= FEE_DENOMINATOR / 3,
            'Transaction Fee Too High'
        );
        tokenInfo[token].transactionFee = newFee;
        tokenInfo[token].transactionFeeRecipient = feeRecipient;
    }

    function setOTC(address OTC_) external onlyOwner {
        OTC = OTC_;
    }

    function addOrder(uint256 orderID, address token) external {
        require(
            msg.sender == OTC,
            'Only OTC'
        );
        
        // push to all order list
        tokenInfo[token].allOrders.push(orderID);
    }

    function fulfilledOrder(address token, uint256 amount) external {
        require(
            msg.sender == OTC,
            'Only OTC'
        );

        tokenInfo[token].amountTransacted += amount;
    }

    function listToken(address token) external payable {
        require(
            msg.value > 0,
            'Zero Value'
        );
        require(
            tokenInfo[token].isAvailableToTrade == false,
            'Token Already Listed'
        );
        require(
            tokenInfo[token].isBlacklisted == false,
            'Token Is Blacklisted'
        );

        tokenInfo[token].valuePutTowardListing += msg.value;

        if (tokenInfo[token].valuePutTowardListing >= listingFee) {
            _listToken(token);
        } else {
            if (!isPartiallyListed(token)) {
                tokenInfo[token].indexInPartiallyListedTokenArray = allPartiallyListedTokens.length;
                allPartiallyListedTokens.push(token);
            }
        }

        _send(feeDatabase, address(this).balance);
    }


    function getFeeAndRecipient(address token) external view returns (uint256, address) {
        return (tokenInfo[token].transactionFee, tokenInfo[token].transactionFeeRecipient);
    }

    function valueLeftToGetListed(address token) external view returns (uint256) {
        if (tokenInfo[token].isAvailableToTrade || tokenInfo[token].isBlacklisted) {
            return 0;
        }
        return tokenInfo[token].valuePutTowardListing >= listingFee ? 0 : listingFee - tokenInfo[token].valuePutTowardListing;
    }

    function canTrade(address token) external view returns (bool) {
        return tokenInfo[token].isAvailableToTrade;
    }

    function fetchAllAvailableTokens() external view returns (address[] memory) {
        return allAvailableTokens;
    }
    function fetchAllPartiallyListedTokens() external view returns (address[] memory) {
        return allPartiallyListedTokens;
    }

    function numberOfListedTokens() external view returns (uint256) {
        return allAvailableTokens.length;
    }

    function numberOfPartiallyListedTokens() external view returns (uint256) {
        return allPartiallyListedTokens.length;
    }

    function fetchAllOrdersForToken(address token) external view returns (uint256[] memory) {
        return tokenInfo[token].allOrders;
    }

    function batchFetchAllOrdersForToken(address token, uint start, uint end) external view returns (uint256[] memory) {

        uint256[] memory orders = new uint256[](end - start);
        uint count = 0;
        for (uint i = start; i < end;) {
            orders[count] = tokenInfo[token].allOrders[i];
            unchecked { ++i; ++count; }
        }
        
        return orders;
    }

    function fetchTokenDetails(address token) public view returns (string memory symbol, uint8 decimals) {
        symbol = IERC20(token).symbol();
        decimals = IERC20(token).decimals();
    }

    function numOrdersForToken(address token) external view returns (uint256) {
        return tokenInfo[token].allOrders.length;
    }

    function isPartiallyListed(address token) public view returns (bool) {
        if (allPartiallyListedTokens.length <= tokenInfo[token].indexInPartiallyListedTokenArray) {
            return false;
        }
        return allPartiallyListedTokens[
            tokenInfo[token].indexInPartiallyListedTokenArray
        ] == token;
    }

    function batchFetchTokenDetails(address[] calldata tokens) public view returns (string[] memory, uint8[] memory) {

        uint len = tokens.length;
        string[] memory symbols = new string[](len);
        uint8[] memory decimals = new uint8[](len);

        for (uint i = 0; i < len;) {
            ( symbols[i], decimals[i] ) = fetchTokenDetails(tokens[i]);
            unchecked { ++i; }
        }
        return (symbols, decimals);
    }

    function fetchAvailableTokenDetails() external view returns (address[] memory, string[] memory, uint8[] memory) {

        uint len = allAvailableTokens.length;
        string[] memory symbols = new string[](len);
        uint8[] memory decimals = new uint8[](len);

        for (uint i = 0; i < len;) {
            ( symbols[i], decimals[i] ) = fetchTokenDetails(allAvailableTokens[i]);
            unchecked { ++i; }
        }

        return ( allAvailableTokens, symbols, decimals );
    }

    function fetchPartiallyListedTokenDetails() external view returns (address[] memory, string[] memory, uint8[] memory) {

        uint len = allPartiallyListedTokens.length;
        string[] memory symbols = new string[](len);
        uint8[] memory decimals = new uint8[](len);

        for (uint i = 0; i < len;) {
            ( symbols[i], decimals[i] ) = fetchTokenDetails(allPartiallyListedTokens[i]);
            unchecked { ++i; }
        }

        return ( allPartiallyListedTokens, symbols, decimals );
    }

    function iterativelyFetchAvailableTokenDetails(uint startIndex, uint endIndex) external view returns (address[] memory, string[] memory, uint8[] memory) {

        uint len = endIndex - startIndex;
        uint count = 0;
        address[] memory tokens = new address[](len);
        string[] memory symbols = new string[](len);
        uint8[] memory decimals = new uint8[](len);

        for (uint i = startIndex; i < endIndex;) {
            tokens[count] = allAvailableTokens[i];
            ( symbols[count], decimals[count] ) = fetchTokenDetails(allAvailableTokens[i]);
            unchecked { ++i; }
        }

        return ( tokens, symbols, decimals );
    }

    function iterativelyFetchPartiallyListedTokenDetails(uint startIndex, uint endIndex) external view returns (address[] memory, string[] memory, uint8[] memory) {

        uint len = endIndex - startIndex;
        uint count = 0;
        address[] memory tokens = new address[](len);
        string[] memory symbols = new string[](len);
        uint8[] memory decimals = new uint8[](len);

        for (uint i = startIndex; i < endIndex;) {
            tokens[count] = allPartiallyListedTokens[i];
            ( symbols[count], decimals[count] ) = fetchTokenDetails(allPartiallyListedTokens[i]);
            unchecked { ++i; }
        }

        return ( tokens, symbols, decimals );
    }

    function _listToken(address token) internal {
        tokenInfo[token].isAvailableToTrade = true;
        tokenInfo[token].indexInAllTokenArray = allAvailableTokens.length;
        allAvailableTokens.push(token);

        if (allPartiallyListedTokens.length > 0) {
            if (isPartiallyListed(token)) {

                // save state to make it easier
                address lastListing = allPartiallyListedTokens[allAvailableTokens.length - 1];
                uint256 rmIndex = tokenInfo[token].indexInPartiallyListedTokenArray;

                // delete index
                delete tokenInfo[token].indexInPartiallyListedTokenArray;

                // move element in token array
                allPartiallyListedTokens[rmIndex] = lastListing;
                tokenInfo[lastListing].indexInPartiallyListedTokenArray = rmIndex;
                allPartiallyListedTokens.pop();

            }
        }
    }

    function _send(address to, uint256 amount) internal {
        if (to == address(this) || to == address(0)) {
            return;
        }
        (bool s,) = payable(to).call{value: amount}("");
        require(s, 'ETH Transfer Failure');
    }

    
}