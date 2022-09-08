pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract PaymentArbiter is AccessControl {
    bytes32 public constant ADMIN = keccak256('ADMIN');
    mapping(uint8 => PaymentToken) public acceptedTokens;
    mapping(address => bool) public addedToken;

    uint8 public epoch;
    event PaymentTokenAdded(uint8 index, address tokenAddress, uint8 decimals, string symbol);

    struct PaymentToken {
        address tokenAddress;
        uint8 decimals;
    }

    modifier isAdmin() {
        require(hasRole(ADMIN, _msgSender()), 'sender must have the ADMIN role');
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN, _msgSender());

        _setRoleAdmin(DEFAULT_ADMIN_ROLE, ADMIN);
    }

    // epoch starts a 1 so acceptedTokens[0] will always equal address(0) which will represent ETH
    function addToken(address tokenContract) public isAdmin {
        require(addedToken[tokenContract] == false, 'token has already been added');

        uint8 decimals = IERC20Metadata(tokenContract).decimals();
        require(decimals > 0, 'invalid erc20');
        acceptedTokens[epoch] = PaymentToken(tokenContract, decimals);
        addedToken[tokenContract] = true;
        require(epoch < 255, 'maximum tokens added');
        epoch += 1;
        string memory symbol = IERC20Metadata(tokenContract).symbol();

        emit PaymentTokenAdded(epoch, tokenContract, decimals, symbol);
    }

    function getToken(uint8 id) public view returns (address, uint8) {
        PaymentToken memory token = acceptedTokens[id];

        require(token.tokenAddress != address(0), 'token does not exist');
        return (token.tokenAddress, token.decimals);
    }

    function getTokenAddress(uint8 id) public view returns (address) {
        PaymentToken memory token = acceptedTokens[id];
        if (token.tokenAddress == address(0)) revert();

        return token.tokenAddress;
    }
}