//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Loyal3Tokens is ERC1155, Ownable {
    using Address for address;
    using Strings for string;

    struct Token {
        uint128 maxSupply;
        uint128 supply;
        bytes32 name;
    }

    string baseURI;
    uint256 public tokenCount;

    mapping(uint256 => Token) public tokens;
    mapping(address => mapping(uint256 => uint8)) public whitelist;

    event TokenMinted(address indexed _to, uint256 _tokenId);
    event TokenBurned(address indexed _from, uint256 _tokenId);
    event AddressAddedToWhitelist(uint256 _tokenId, address _address);

    error NullAddress();
    error AddressNotWhitelisted(address);
    error NullAmount();
    error MaxSupplyReached();
    error TokenNotExists(uint256);

    modifier onlyWhitelisted(uint256 _tokenId) {
        if (whitelist[msg.sender][_tokenId] == 0)
            revert AddressNotWhitelisted(msg.sender);
        _;
    }

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
    }

    /*//////////////////////////////////////////////////////////////
                              TOKEN LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates a new token with the given max supply and name.
     * @param _maxSupply The maximum supply for the new token.
     * @param _name The name for the new token.
     */
    function createToken(uint128 _maxSupply, bytes32 _name) public onlyOwner {
        uint256 tokenId = tokenCount + 1;
        tokens[tokenId] = Token({
            maxSupply: _maxSupply,
            supply: 0,
            name: _name
        });
        tokenCount = tokenId;
    }

    /**
     * @dev Sets the maximum supply for a given token.
     * @param _tokenId The ID of the token to set the maximum supply for.
     * @param _maxSupply The new maximum supply for the token.
     */
    function setTokenMaxSupply(uint256 _tokenId, uint128 _maxSupply)
        external
        onlyOwner
    {
        if (!isExist(_tokenId)) {
            revert TokenNotExists(_tokenId);
        }
        // Set the new maximum supply for the token
        tokens[_tokenId].maxSupply = _maxSupply;
    }

    /**
     * @dev Sets the name for a given token.
     * @param _tokenId The ID of the token to set the name for.
     * @param _name The new name for the token.
     */
    function setTokenName(uint256 _tokenId, bytes32 _name) external onlyOwner {
        if (!isExist(_tokenId)) {
            revert TokenNotExists(_tokenId);
        }
        // Set the new name for the token
        tokens[_tokenId].name = _name;
    }

    /**
     * @dev Retrieves the name, maximum supply, and current supply of a given token.
     * @param _tokenId The ID of the token to retrieve information for.
     * @return The name, maximum supply, and current supply of the token.
     */
    function getTokenInfo(uint256 _tokenId)
        external
        view
        returns (
            bytes32,
            uint128,
            uint128
        )
    {
        if (!isExist(_tokenId)) {
            revert TokenNotExists(_tokenId);
        }
        // Retrieve the token information and return it
        Token storage token = tokens[_tokenId];
        return (token.name, token.maxSupply, token.supply);
    }

    /*//////////////////////////////////////////////////////////////
                            WHITELIST LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Adds addresses to the whitelist for a given token.
     * @param _tokenId The ID of the token to add addresses to the whitelist for.
     * @param _addressesToAdd An array of addresses to add to the whitelist.
     */
    function addAddressesToWhitelist(
        uint256 _tokenId,
        address[] memory _addressesToAdd
    ) external onlyOwner {
        if (!isExist(_tokenId)) {
            revert TokenNotExists(_tokenId);
        }

        // Add each address to the whitelist
        for (uint256 i = 0; i < _addressesToAdd.length; i++) {
            // Check that the address is not null
            if (_addressesToAdd[i] == address(0)) {
                revert NullAddress();
            }
            // Add the address to the whitelist for this token
            whitelist[_addressesToAdd[i]][_tokenId]++;
            // Emit an event to signal the address has been added to the whitelist
            emit AddressAddedToWhitelist(_tokenId, _addressesToAdd[i]);
        }
    }

    /**
     * @dev Checks if an address is whitelisted for a given token.
     * @param _tokenId The ID of the token to check the whitelist for.
     * @param _address The address to check the whitelist for.
     * @return The number of tokens whitelisted for the address and token.
     */
    function isWhitelisted(uint256 _tokenId, address _address)
        public
        view
        onlyOwner
        returns (uint8)
    {
        if (!isExist(_tokenId)) {
            revert TokenNotExists(_tokenId);
        }
        // Return the number of tokens whitelisted for the address and token
        return whitelist[_address][_tokenId];
    }

    /**
     * @dev Removes addresses from the whitelist for a given token.
     * @param _tokenId The ID of the token to remove addresses from the whitelist for.
     * @param _addressesToRemove An array of addresses to remove from the whitelist.
     */
    function removeAddressFromWhitelist(
        uint256 _tokenId,
        address[] memory _addressesToRemove
    ) external onlyOwner {
        if (!isExist(_tokenId)) {
            revert TokenNotExists(_tokenId);
        }

        // Remove each address from the whitelist
        for (uint256 i = 0; i < _addressesToRemove.length; i++) {
            // Check that the address is not null
            if (_addressesToRemove[i] == address(0)) {
                revert NullAddress();
            }
            // Remove the address from the whitelist for this token
            whitelist[_addressesToRemove[i]][_tokenId]--;
        }
    }

    /*//////////////////////////////////////////////////////////////
                               MINT LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Mints a new token with the given ID to the caller's address, if the caller is whitelisted for the token.
     * @param _tokenId The ID of the token to mint.
     */
    function mint(uint256 _tokenId) external onlyWhitelisted(_tokenId) {
        if (!isExist(_tokenId)) {
            revert TokenNotExists(_tokenId);
        }
        // Retrieve the token information
        Token storage token = tokens[_tokenId];
        // Check if the maximum supply for the token has been reached
        if (token.supply == token.maxSupply) {
            revert MaxSupplyReached();
        }
        // Increase the supply of the token by 1
        ++tokens[_tokenId].supply;
        // Decrement the caller's whitelisted balance for the token by 1
        whitelist[msg.sender][_tokenId]--;
        // Mint the token to the caller's address with a quantity of 1
        _mint(msg.sender, _tokenId, 1, "");
        // Emit a Mint event to notify listeners
        emit TokenMinted(msg.sender, _tokenId);
    }

    /**
     * @dev Destroys the given amount of tokens of a given ID from the caller's address.
     * @param id The ID of the token to burn.
     * @param amount The amount of the token to burn.
     */
    function burn(uint256 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
        emit TokenBurned(msg.sender, id);
    }

    /**
     * @dev Checks if a token with the given ID exists.
     * @param _tokenId The ID of the token to check.
     * @return True if a token with the given ID exists, false otherwise.
     */
    function isExist(uint256 _tokenId) public view returns (bool) {
        return (tokens[_tokenId].name != "");
    }

    /**
     * @dev Sets the base URL for the token URIs.
     * @param _baseUrl The new base URL for the token URIs.
     */
    function setBaseUrl(string memory _baseUrl) public onlyOwner {
        baseURI = _baseUrl;
    }

    /**
     * @dev Returns the URI for a given token ID.
     * @param _tokenId The ID of the token to retrieve the URI for.
     * @return A string representing the URI for the given token ID.
     */
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }
}