// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IWrappedERC1155.sol";

/// @title A custom ERC1155 contract used in the bridge
contract WrappedERC1155 is IWrappedERC1155, ERC1155URIStorage, Initializable {

    address internal _bridge;
    string internal _tokenUri;  
    
    /// @dev Checks if the caller is the bridge contract
    modifier onlyBridge {
        require(msg.sender == _bridge, "Token: caller is not a bridge!");
        _;
    }

    /// @dev Creates an "empty" template token that will be cloned in the future
    constructor() ERC1155("") {}

    /// @dev Upgrades an "empty" template. Initializes internal variables. 
    /// @param bridge_ The address of the bridge of the tokens 
    function initialize(
        string memory tokensUri_,
        address bridge_
    ) external initializer {
        require(bytes(tokensUri_).length > 0, "ERC1155: initial token URI can not be empty!");
        require(bridge_ != address(0), "ERC1155: initial bridge address can not be a zero address!");
        _bridge = bridge_;
        _tokenUri = tokensUri_;
    }

    /// @notice Returns the URI of tokens
    /// @return The URI of tokens
    function tokensUri() external view returns(string memory) {
        return _tokenUri;
    }

    /// @notice Creates amount tokens of specific type and assigns them to the user
    /// @param to The receiver of tokens
    /// @param id The ID of the token type
    /// @param amount The amount of tokens to be minted
    function mint(address to, uint256 id, uint256 amount) 
        external 
        onlyBridge 
    {
        _mint(to, id, amount, "");
        emit Mint(to, id, amount);
    }

    /// @notice Creates a batch (batches) of tokens of specific type (types) and assigns them to the user
    /// @param to The receiver of tokens
    /// @param ids The array of token types IDs
    /// @param amounts The array of amount of tokens of each token type
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) 
        external 
        onlyBridge
    {
        _mintBatch(to, ids, amounts, "");
        emit MintBatch(to, ids, amounts);
    }

    /// @notice Destroys tokens of specific token type
    /// @param from The account holding tokens to be burnt
    /// @param id The token type ID
    /// @param amount The amount of tokens to be burnt
    function burn(address from, uint256 id, uint256 amount) 
        external 
        onlyBridge   
    {
        _burn(from, id, amount);
        emit Burn(from, id, amount);
    }
    
    /// @notice Destroys a batch (batches) of tokens of specific type (types)
    /// @param from The account holding tokens to be burnt
    /// @param ids The array of token type IDs
    /// @param amounts The array of amounts of tokens to be burnt
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) 
        external 
        onlyBridge        
    {
        _burnBatch(from, ids, amounts);
        emit BurnBatch(from, ids, amounts);
    }

    /// @notice Returns the address of the bridge contract
    /// @return The address of the bridge contract
    function bridge() external view returns(address) {
        return _bridge;
    }
}