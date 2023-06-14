//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol';
import './IERC721Creator.sol';

contract FirstDibsToken is
    ERC721,
    Ownable,
    AccessControl,
    ERC721Burnable,
    ERC721Pausable,
    IERC721Creator
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    /**
     * @dev If greater than 0, then totalSupply will never exceed MAX_SUPPLY
     *      A value of 0 means there is no limit to the supply.
     */
    uint256 public MAX_SUPPLY = 0;

    /**
     * @dev token ID mapping to payable creator address
     */
    mapping(uint256 => address payable) private tokenCreators;

    /**
     * @dev Map token URI to a token ID
     */
    mapping(string => uint256) private tokenUris;

    /**
     * @dev Auto-incrementing counter for token IDs
     */
    Counters.Counter private tokenIds;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract. Also sets `MAX_SUPPLY`.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) public ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        // MAX_SUPPLY may only be set once
        MAX_SUPPLY = _maxSupply;
    }

    /**
     * @dev Internal function for setting the token's creator.
     * @param _creator address of the creator of the token.
     * @param _tokenId uint256 id of the token.
     */
    function _setTokenCreator(address payable _creator, uint256 _tokenId) private {
        tokenCreators[_tokenId] = _creator;
    }

    /**
     * @dev Internal function for saving token URIs
     * @param _tokenUri token URI string
     * @param _tokenId uint256 id of the token.
     */
    function _saveUniqueTokenURI(string memory _tokenUri, uint256 _tokenId) private {
        require(tokenUris[_tokenUri] == 0, 'Duplicate token URIs not allowed');
        tokenUris[_tokenUri] = _tokenId;
    }

    /**
     * @dev External function to get the token's creator
     * @param _tokenId uint256 id of the token.
     */
    function tokenCreator(uint256 _tokenId) external view override returns (address payable) {
        return tokenCreators[_tokenId];
    }

    /**
     * @dev internal function that mints a token. Sets _creator to creator and owner.
     *      Checks MAX_SUPPLY against totalSupply and will not mint if totalSupply would exceed MAX_SUPPLY.
     * @param _tokenURI uint256 metadata URI of the token.
     * @param _creator address of the creator of the token.
     */
    function _mint(string memory _tokenURI, address payable _creator) internal returns (uint256) {
        require(MAX_SUPPLY == 0 || totalSupply() < MAX_SUPPLY, 'minted too many tokens');
        tokenIds.increment();
        uint256 newTokenId = tokenIds.current();

        _saveUniqueTokenURI(_tokenURI, newTokenId);
        _safeMint(_creator, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        _setTokenCreator(_creator, newTokenId);
        return newTokenId;
    }

    /**
     * @dev Public function that mints a token. Sets msg.sender to creator and owner and requires MINTER_ROLE
     * @param _tokenURI uint256 metadata URI of the token.
     */
    function mint(string memory _tokenURI) public returns (uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), 'mint: must have MINTER_ROLE');
        return _mint(_tokenURI, _msgSender());
    }

    /**
     * @dev Public function that allows admin to mint a token setting _creator to creator and owner
     * @param _tokenURI uint256 metadata URI of the token.
     * @param _creator address of the creator of the token.
     */
    function mintWithCreator(string memory _tokenURI, address payable _creator)
        public
        returns (uint256)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'mintWithCreator: must have DEFAULT_ADMIN_ROLE'
        );
        return _mint(_tokenURI, _creator);
    }

    /**
     * @dev Pauses all token transfers.
     * See {ERC721Pausable} and {Pausable-_pause}.
     * Requirements: the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), 'pause: must have PAUSER_ROLE');
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     * See {ERC721Pausable} and {Pausable-_unpause}.
     * Requirements: the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), 'unpause: must have PAUSER_ROLE');
        _unpause();
    }

    /**
     * @dev Must override this function since both ERC721, ERC721Pausable define it
     * Checks that the contract isn't paused before doing a transfer
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Pausable) {
        ERC721Pausable._beforeTokenTransfer(_from, _to, _tokenId);
    }
}