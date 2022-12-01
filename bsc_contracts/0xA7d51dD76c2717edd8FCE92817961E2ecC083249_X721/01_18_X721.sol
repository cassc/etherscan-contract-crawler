// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract X721 is ERC721Enumerable, ERC721URIStorage, ERC721Burnable, AccessControl { 
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct Metadata2 {
        uint256 poolId;
        uint256 amount;
    }
    mapping(uint256 => Metadata2) tokensData; // id => data
    //uint256[] tokens;

    /* ========== EVENTS ========== */

    event Minted(address indexed user, uint256 indexed poolId, uint256 indexed amount, uint256 tokenId);

    /* ========== METHODS ========== */

    /**
     * @dev Initialises the contract
     */
    constructor() ERC721("xUSD", "xUSD") public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    // SHOULD NOT BE USED
    function safeMint(address to) internal {
    }

    // The following function is override required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following function is override required by Solidity.
   function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Mints a new token
     * @param _client The address of the token owner
     * @param _poolId The id of the pool
     * @param _amount The amount of the token
     */
    function mintNFT(address _client, uint256 _poolId, uint256 _amount) public returns (uint256) {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        
        if (_tokenIdCounter.current() == 0) {
            _tokenIdCounter.increment();
        }

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        tokensData[newItemId] = Metadata2(_poolId, _amount);
        //tokens.push(newItemId);

        _mint(_client, newItemId);

        emit Minted(_client, _poolId, _amount, newItemId);
        
        return newItemId;
    }

    /**
     * @dev Formats the token URI
     * @param _poolId The id of the pool
     * @param _tokenAmount The amount of the token
     */
    function formatTokenURI(uint256 _poolId, uint256 _tokenAmount) public pure returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "xUSD", "description": "A token representing the stake.", "attributes:" ["poolId":', Strings.toString(_poolId), '"tokenAmount":', Strings.toString(_tokenAmount),']}'
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns the token URI
     * @param _tokenId The id of the token
     */
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        uint256 poolId = tokensData[_tokenId].poolId;
        uint256 amount = tokensData[_tokenId].amount;
        return formatTokenURI(poolId, amount);
    }

    /**
     * @dev Returns the amount of investments for a given token 
     * @param _tokenId The id of the token
     */
    function peggedAmount(uint256 _tokenId) public view returns (uint256) {
        return tokensData[_tokenId].amount;
    }

    /**
     * @dev Returns the pool id for a given token 
     * @param _tokenId The id of the token
     */
    function getPoolId(uint256 _tokenId) public view returns (uint256) {
        return tokensData[_tokenId].poolId;
    }

    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(_tokenId);
        delete tokensData[_tokenId];
    }
}