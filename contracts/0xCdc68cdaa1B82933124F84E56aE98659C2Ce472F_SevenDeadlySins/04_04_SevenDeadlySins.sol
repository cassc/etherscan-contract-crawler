// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

/// @title Seven Deadly Sins
/// @author @CM4YN3Z

import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/ReentrancyGuard.sol";

contract SevenDeadlySins is ERC1155, Owned {

    string public name;
    string public symbol;
    uint public receiveTokenId;

    struct Token {
        string uri;
        uint price;
        uint incrementor;
        bool mintActive;
    }
    
    mapping(uint => Token) public tokens;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner
    )Owned(_owner){
        name = _name;
        symbol = _symbol;
    }

    receive() external payable {
        mint(receiveTokenId);
    }

    /// @notice Mints a token and increases the token price by the value stored in the incrementor.
    /// @param tokenId uint ID of the token to be minted.
    function mint(uint tokenId) public payable {
        require(tokens[tokenId].mintActive, "SevenDeadlySins: Minting is not active");
        require(msg.value >= tokens[tokenId].price, "SevenDeadlySins: Incorrect payment amount");
        _mint(msg.sender, tokenId, 1, "");
        tokens[tokenId].price += tokens[tokenId].incrementor;
    }
    
    /// @notice Returns the URI for a given token ID.
    /// @param tokenId uint ID of the token to query
    /// @return URI of given token ID
    function uri(uint tokenId) public view override returns (string memory) {
        return tokens[tokenId].uri;
    }

    /// @notice Owner function to set the token URI for a given token ID.
    /// @param tokenId uint ID of the token to set the URI for.
    /// @param newURI string memory new URI value.
    function setTokenURI(uint tokenId, string memory newURI) external onlyOwner {
        tokens[tokenId].uri = newURI;
    }

    /// @notice Owner function to set the token price for a given token ID.
    /// @param tokenId uint ID of the token to set the price for.
    /// @param newTokenPrice uint new price value.
    function setTokenPrice(uint tokenId, uint newTokenPrice) external onlyOwner {
        tokens[tokenId].price = newTokenPrice;
    }

    /// @notice Owner function to set the incrementor that is added to the price after each mint.
    /// @param tokenId uint ID of the token to set the incrementor for.
    /// @param newTokenIncrementor uint new incrementor value in wei.
    /// @dev The value defaults to 0, so if no incrementor is set, the price of the token will be constant.
    function setTokenIncrementor(uint tokenId, uint newTokenIncrementor) external onlyOwner {
        tokens[tokenId].incrementor = newTokenIncrementor;
    }

    /// @notice Owner function to set the tokenID that is minted when ether is sent to the contract.
    /// @param tokenId uint ID of the token to set the receiveTokenId for.
    /// @dev This value defaults to 0, so if no receiveTokenId is set, the contract will always mint the token with ID 0.
    function setReceiveTokenId(uint tokenId) external onlyOwner {
        receiveTokenId = tokenId;
    }

    /// @notice Owner function to activate a token for minting.
    /// @param tokenId uint ID of the token to be activated.
    function flipMintActive(uint tokenId) external onlyOwner {
        tokens[tokenId].mintActive = !tokens[tokenId].mintActive;
    }

    /// @notice Owner function to withdraw ETH from the contract.
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}