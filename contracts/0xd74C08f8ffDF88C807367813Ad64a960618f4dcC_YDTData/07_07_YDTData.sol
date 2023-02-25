// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract YDTData is AccessControl {

    //Accepted tokens
    struct Token {
        string symbol;
        uint128 decimals;
        address tokenAddress;
        bool accepted;
        bool isChainLinkFeed;
        address priceFeedAddress;
        uint128 priceFeedPrecision;
    }
    //mapping of accpeted tokens
    mapping(address => Token) public acceptedTokens;
    mapping(address => bool) public isAcceptedToken;
    // list of accepted tokens
    address[] public tokens;

    event TokenAdded(
        address indexed tokenAddress,
        uint128 indexed decimals,
        address indexed priceFeedAddress,
        string symbol,
        bool isChainLinkFeed,
        uint128 priceFeedPrecision
    );

    event TokenRemoved(address indexed tokenAddress);
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice add new token for payments
     * @param _symbol token symbols
     * @param _token token address
     * @param _decimal token decimals
     * @param isChainLinkFeed_ if price feed chain link feed
     * @param priceFeedAddress_ address of price feed
     * @param priceFeedPrecision_ precision of price feed

     */
    function addNewToken(
        string memory _symbol,
        address _token,
        uint128 _decimal,
        bool isChainLinkFeed_,
        address priceFeedAddress_,
        uint128 priceFeedPrecision_
    ) external onlyRole(DEFAULT_ADMIN_ROLE)
     {
        require(!acceptedTokens[_token].accepted, "token already added");
        require(_token != address(0), "invalid token");
        require(_decimal > 0, "invalid decimals");
        bytes memory tempEmptyStringTest = bytes(_symbol);
        require(tempEmptyStringTest.length != 0, "invalid symbol");
        Token memory token = Token(
            _symbol,
            _decimal,
            _token,
            true,
            isChainLinkFeed_,
            priceFeedAddress_,
            priceFeedPrecision_
        );
        acceptedTokens[_token] = token;
        tokens.push(_token);
        isAcceptedToken[_token] = true;
        emit TokenAdded(
            _token,
            _decimal,
            priceFeedAddress_,
            _symbol,
            isChainLinkFeed_,
            priceFeedPrecision_
        );
    }
    /**
     * @notice remove tokens for payment
     * @param t token address
     */
    function removeTokens(address t) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(t != address(0), "invalid token");
        if (acceptedTokens[t].accepted) {
            require(tokens.length > 1, "Cannot remove all tokens");
            for (uint256 j = 0; j < tokens.length; j = unsafeInc(j)) {
                if (tokens[j] == t) {
                    tokens[j] = tokens[tokens.length - 1];
                    tokens.pop();
                    acceptedTokens[t].accepted = false;
                    emit TokenRemoved(t);
                }
            }
            isAcceptedToken[t] = false;
        }
    }

    // unchecked iterator increment for gas optimization
    function unsafeInc(uint x) private pure returns (uint) {
        unchecked { return x + 1;}
    }
}