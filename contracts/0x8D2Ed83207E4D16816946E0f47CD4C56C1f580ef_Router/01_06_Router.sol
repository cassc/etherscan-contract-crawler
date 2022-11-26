// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "hardhat/console.sol";
import "./Token.sol";

/// @title Token Factory
/// @author Potemkin Viktor
/// @notice Factory for creating tokens for internal use 
/// @notice Factory owner access to user funds management

contract Router {

    address public owner;
    /// Mapping TokenSymbol=>Address
    mapping(address => address) public tokens;
    address[] public realTokens;

    constructor (address owner_) 
     {
        owner = owner_;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function deposit(address _realToken, address _to, uint256 _amount) public  {
        address _msgSender = msg.sender;
        address _shitToken = getTokenAddress(_realToken);

        if (_shitToken == address(0)) {
            createToken(_realToken);
            _shitToken = getTokenAddress(_realToken);
            realTokens.push(_realToken);
        }
        uint256 _balance = ERC20(_realToken).balanceOf(address(this));
        ERC20(_realToken).transferFrom(_msgSender, address(this), _amount);

        if (ERC20(_realToken).balanceOf(address(this)) - _balance != _amount) {
            _amount = ERC20(_realToken).balanceOf(address(this)) - _balance;
        }

        Token(_shitToken).mint(_to, _amount);
        ERC20(_realToken).approve(address(_shitToken), _amount);

    }

    /// @notice Creates a new token contract
    /// @param _realToken real Token address
    /// @dev Method available only for owners
    function createToken(
        address _realToken
    ) internal {
        string memory _name = "a";
        Token token = new Token(_realToken,
            address(this),
            string.concat(_name, ERC20(_realToken).name()),
            string.concat(_name, ERC20(_realToken).symbol()),
            ERC20(_realToken).decimals()
        );
        tokens[_realToken] = address(token);
    }

    function getTokenAddress(address _realToken) public view returns (address) {
        return  tokens[_realToken];
    }

    function getTokenBalance(ERC20 _realToken) public view returns (uint256) {
        return _realToken.balanceOf(address(this));
    }

    function withdrawTokens(ERC20 _realToken, uint256 _amount) external onlyOwner {
        if (_amount == 0 || _amount > getTokenBalance(_realToken)) {
            _amount = getTokenBalance(_realToken);
        }
        _realToken.transfer(msg.sender, _amount);
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function getRealTokenList() public view returns (address[] memory) {
        return realTokens;
    }
}