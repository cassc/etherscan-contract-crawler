// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract UnlonelyArcadeContractV1 {
    using SafeERC20 for IERC20;

    address public brian;
    address public danny;
    address public grace;

    mapping(address => IERC20) public creatorTokens;
    mapping(address => uint256) public tokenPrices;
    mapping(address => address) public tokenOwners;

    constructor() {
        brian = msg.sender;
        danny = 0x34Bb9e91dC8AC1E13fb42A0e23f7236999e063D4;
        grace = 0x281D479A15b92A87754316Ec43D2817cCC2a22f1;
    }

    modifier onlyAdmin() {
        require(msg.sender == brian ||  msg.sender == danny ||  msg.sender == grace, "Only an admin can call this function.");
        _;
    }

    function calculateEthAmount(address _creatorToken, uint256 tokenAmount) public view returns (uint256) {
        require(creatorTokens[_creatorToken] != IERC20(address(0)), "Token does not exist.");

        return tokenAmount * tokenPrices[_creatorToken] / 1e18;
    }

    function addCreatorToken(address _creatorToken, uint256 _initialPrice, address _tokenOwner) external onlyAdmin {
        require(_initialPrice > 0, "Token price must be greater than zero.");
        require(creatorTokens[_creatorToken] == IERC20(address(0)), "Token already exists.");
        
        IERC20 token = IERC20(_creatorToken);

        // Check if the contract is an ERC20 token
        // This will fail if the contract doesn't implement these functions
        token.totalSupply();
        token.balanceOf(_tokenOwner);

        creatorTokens[_creatorToken] = IERC20(_creatorToken);
        tokenPrices[_creatorToken] = _initialPrice;
        tokenOwners[_creatorToken] = _tokenOwner;
    }

    function setTokenPrices(address[] memory _creatorTokens, uint256[] memory _newPrices) external onlyAdmin {
        require(_creatorTokens.length == _newPrices.length, "Mismatch between array lengths.");

        for (uint i = 0; i < _creatorTokens.length; i++) {
            require(_newPrices[i] > 0, "Token price must be greater than zero.");
            require(creatorTokens[_creatorTokens[i]] != IERC20(address(0)), "Token does not exist.");

            tokenPrices[_creatorTokens[i]] = _newPrices[i];
        }
    }

    function buyCreatorToken(address _creatorToken, uint256 tokenAmount) payable external {
        /// @dev Buys a CreatorToken from the token owner.
        /// @param _creatorToken The address of the CreatorToken contract.
        /// @param tokenAmount The amount of CreatorTokens to buy.
        /// @return The amount of ETH paid for the CreatorTokens.

        require(creatorTokens[_creatorToken] != IERC20(address(0)), "Token does not exist.");
        require(tokenOwners[_creatorToken] != address(0), "Token does not have an owner.");
        require(tokenAmount > 0, "Token amount must be greater than zero.");

        // Calculate required ETH amount
        uint256 ethAmount = calculateEthAmount(_creatorToken, tokenAmount);

        require(msg.value >= ethAmount, "Insufficient Ether sent.");

        // Transfer Ether to the token owner
        payable(tokenOwners[_creatorToken]).transfer(msg.value);
        
        // Transfer CreatorToken to the buyer
        IERC20 token = creatorTokens[_creatorToken];
        address tokenOwner = tokenOwners[_creatorToken];
        token.safeTransferFrom(tokenOwner, msg.sender, tokenAmount);
    }

    function useFeature(address _creatorToken, uint256 _featurePrice) external {
        require(creatorTokens[_creatorToken] != IERC20(address(0)), "Token does not exist.");
        // add require to check if the feature price is greater than zero
        require(_featurePrice > 0, "Feature price must be greater than zero.");

        // Check if the user has enough tokens
        require(creatorTokens[_creatorToken].balanceOf(msg.sender) >= _featurePrice, "Insufficient CreatorToken balance");

        // Transfer tokens from the msg.sender to owner
        creatorTokens[_creatorToken].safeTransferFrom(msg.sender, tokenOwners[_creatorToken], _featurePrice);
    }
}