// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract TokenBalanceStorage {

    uint256 public blockNumber;
    uint256 public lastTransactionNAV;
    address private owner;
    mapping(address=>uint256) tokenBalance;

    constructor(){
        // blockNumber = block.number;
        owner = msg.sender;
    }

    /// @dev Function to set the balance of a token.
    /// @param _tokenAddress Address of the token.
    /// @param _balance Balance of the token.
    function setTokenBalance(address _tokenAddress, uint256 _balance) public {
        require(msg.sender == owner, "only Owner");
        tokenBalance[_tokenAddress] = _balance;
    }
    
    /// @dev Function to get the balance of a token.
    /// @param _token Address of the token.
   function getTokenBalance(address _token) public view returns (uint256) {
        return tokenBalance[_token];
    }

    /// @dev Function to set the block Number of the current transaction.
    function setLastTransactionBlockNumber() public{
        require(msg.sender==owner,"not authorized");
        blockNumber = block.number;
    }

    /// @dev Function to set the NAV of the vault in last transaction.
    /// @param _nav Nav of the vault.
    function setLastTransactionNAV(uint256 _nav) public{
        require(msg.sender==owner,"not authorized");
        lastTransactionNAV = _nav;
    }
    
    /// @dev Function to get the block Number of the last transaction.
    function getLastTransactionBlockNumber() public view returns (uint256) {
        return blockNumber;
    }

    /// @dev Function to get the NAV of the last transaction.
    function getLastTransactionNav() public view returns (uint256) {
        return lastTransactionNAV;
    }


}