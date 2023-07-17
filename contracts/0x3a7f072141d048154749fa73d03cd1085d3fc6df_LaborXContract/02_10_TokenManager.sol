// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/Ownable.sol";

contract TokenManager is Ownable {
    event TokenAdded(address indexed _tokenAddress);
    event TokenRemoved(address indexed _tokenAddress);

    struct Token {
        address tokenAddress;
        string name;
        string symbol;
        uint256 decimals;
        address usdPriceContract;
        bool isStable;
    }

    address[] public tokenAddresses;
    mapping(address => Token) public tokens;

    function addToken(
        address _tokenAddress,
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        address _usdPriceContract,
        bool _isStable
    ) public onlyOwner {
        (bool found,) = indexOfToken(_tokenAddress);
        require(!found, 'Token already added');
        tokens[_tokenAddress] = Token(_tokenAddress, _name, _symbol, _decimals, _usdPriceContract, _isStable);
        tokenAddresses.push(_tokenAddress);
        emit TokenAdded(_tokenAddress);
    }

    function removeToken(
        address _tokenAddress
    ) public onlyOwner {
        (bool found, uint256 index) = indexOfToken(_tokenAddress);
        require(found, 'Erc20 token not found');
        if (tokenAddresses.length > 1) {
            tokenAddresses[index] = tokenAddresses[tokenAddresses.length - 1];
        }
        tokenAddresses.pop();
        delete tokens[_tokenAddress];
        emit TokenRemoved(_tokenAddress);
    }

    function indexOfToken(address _address) public view returns (bool found, uint256 index) {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == _address) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function getListTokenAddresses() public view returns (address[] memory)
    {
        return tokenAddresses;
    }

    function getLengthTokenAddresses() public view returns (uint256)
    {
        return tokenAddresses.length;
    }
}