// SPDX-License-Identifier: UNLICENSED

/// @title THREETHREETHREE
/// @author M1LL1P3D3
/// @notice MAKE THE MAGIC YOU WANT TO SEE IN THE WORLD! ✦✦✦
/// @dev This contract is constructed for use with the FIRSTTHREAD receipt contract.

pragma solidity ^0.8.17;

import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/ReentrancyGuard.sol";

contract THREETHREETHREE is ERC1155, Owned, ReentrancyGuard {

    string public name = "THREETHREETHREE";
    string public symbol = "333";
    string private _uri;
    /// @dev Global per token supply cap, dualy a mint cap as once the supply decreases more tokens can't be minted.
    uint public constant MAX_SUPPLY_PER_TOKEN = 111;
    /// @dev The address of the receipt contract which may call burn functions in order to issue receipts.
    address public receiptContract;

    /// @dev Struct to hold the definition of a token.
    struct Token {
        /// @dev Name of token consumed by receipt contract for onchain receipt generation.
        string name;
        /// @dev The current supply of the token, initialized to 0 and incremented by mint functions.
        uint currentSupply;
        /// @dev The price of a single token represented in wei.
        uint etherPrice;
        /// @dev Whether the token is active or not, initialized to false and set to true by an admin function.
        bool mintActive;
    }

    /// @dev Mapping of uint token IDs to token definitions.
    mapping(uint => Token) public tokens;

    /// @dev Initializes token definitions with names, and ether prices.
    constructor() Owned(msg.sender) {       
        tokens[0].name = "FRANKINCENSE";
        tokens[1].name = "MYRRH";
        tokens[2].name = "GOLD";
        tokens[0].etherPrice = 0.777 ether;
        tokens[1].etherPrice = 0.888 ether;
        tokens[2].etherPrice = 1.111 ether;
    }

    /// @notice Modifier restricting burn function access to the receipt contract.
    /// @dev Checks that the address calling the burn function is a contract and not a user wallet by comparing the msg.sender to the tx.origin.
    modifier onlyReceiptContract() {
        require(msg.sender == receiptContract, "THREETHREETHREE: Only receipt contract can call this function");
        _;
    }

    /// @notice Mint an amount of up to the remaing supply of a single token.
    /// @param id The ID of the token to mint.
    /// @param amount The amount of tokens to mint.
    function mintSingle(
        uint id,
        uint amount
    ) public payable nonReentrant {
        require(tokens[id].mintActive, "THREETHREETHREE: Minting is not active");
        require(msg.value == amount * tokens[id].etherPrice, "THREETHREETHREE: msg.value is incorrect for the tokens being minted");
        require(tokens[id].currentSupply + amount <= MAX_SUPPLY_PER_TOKEN, "THREETHREETHREE: Max supply reached of the token being minted");
        _mint(msg.sender, id, amount, "");
        tokens[id].currentSupply += amount;
    }

    /// @notice Mint an amount of up to the remaining supply of multiple tokens.
    /// @param ids The IDs of the tokens to mint.
    /// @param amounts The amounts of tokens to mint.
    function mintBatch(
        uint[] memory ids,
        uint[] memory amounts
    ) external payable nonReentrant {
        require(ids.length == amounts.length, "THREETHREETHREE: IDs and amounts arrays must be the same length");
        uint totalEtherPrice;
        for (uint i = 0; i < ids.length; i++) {
            require(tokens[ids[i]].mintActive, "THREETHREETHREE: Minting is not active");
            require(tokens[ids[i]].currentSupply + amounts[i] <= MAX_SUPPLY_PER_TOKEN, "THREETHREETHREE: Max supply reached of the token being minted");
            totalEtherPrice += amounts[i] * tokens[ids[i]].etherPrice;
        }
        require(msg.value == totalEtherPrice, "THREETHREETHREE: msg.value is incorrect for the tokens being minted");
        _batchMint(msg.sender, ids, amounts, "");
        for (uint i = 0; i < ids.length; i++) {
            tokens[ids[i]].currentSupply += amounts[i];
        }
    }

    /// @notice Burn an amount of a single token as receipt contract.
    /// @param from The address to burn tokens from.
    /// @param id The ID of the token to burn.
    /// @param amount The amount of tokens to burn.
    function burnSingle(
        address from,
        uint id,
        uint amount
    ) external onlyReceiptContract {
        require(balanceOf[from][id] >= amount, "THREETHREETHREE: The owner of the tokens being burned does not have the amount of tokens being burned");
        _burn(from, id, amount);
    }

    /// @notice Burn multiple amounts of multiple tokens as receipt contract.
    /// @param from The address to burn tokens from.
    /// @param ids The IDs of the tokens to burn.
    /// @param amounts The amounts of tokens to burn.
    function burnBatch(
        address from,
        uint[] memory ids,
        uint[] memory amounts
    ) external onlyReceiptContract {
        require(ids.length == amounts.length, "THREETHREETHREE: IDs and amounts arrays must be the same length");
        for (uint i = 0; i < ids.length; i++) {
            require(balanceOf[from][ids[i]] >= amounts[i], "THREETHREETHREE: The owner of the tokens being burned does not have the amount of tokens being burned");
        }
        _batchBurn(from, ids, amounts);
    }

    /// @notice Get the URI of a token.
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /// @notice Owner can flip the minting status of a token.
    /// @param id The ID of the token to flip the minting status of.
    function flipTokenMintActive(
        uint id
    ) external onlyOwner {
        require(id < 3, "THREETHREETHREE: NONEXISTENT_TOKEN");
        tokens[id].mintActive = !tokens[id].mintActive;
    }

    /// @notice Owner can set the name of a token.
    /// @param id The ID of the token to set the name of.
    /// @param _name The name to set the token to.
    function setTokenName(
        uint id,
        string calldata _name
    ) external onlyOwner {
        require(id < 3, "THREETHREETHREE: NONEXISTENT_TOKEN");
        tokens[id].name = _name;
    }
    
    
    /// @notice Owner can set the URI of a token.
    /// @param newuri The URI to set for the contract.
    function setURI(
        string memory newuri
    ) external onlyOwner {
        _uri = newuri;
    }
    
    /// @notice Owner can set the receipt contract address.
    /// @param _receiptContract The address of the receipt contract.
    function setReceiptContract(
        address _receiptContract
    ) external onlyOwner {
        receiptContract = _receiptContract;
    }

    /// @notice Owner can withdraw all ether from contract
    function withdrawEther() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

}