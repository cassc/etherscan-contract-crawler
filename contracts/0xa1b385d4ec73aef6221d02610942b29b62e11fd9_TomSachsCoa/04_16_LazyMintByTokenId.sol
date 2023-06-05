// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*----------------------------------------------------------\
|                             _                 _           |
|        /\                  | |     /\        | |          |
|       /  \__   ____ _ _ __ | |_   /  \   _ __| |_ ___     |
|      / /\ \ \ / / _` | '_ \| __| / /\ \ | '__| __/ _ \    |
|     / ____ \ V / (_| | | | | |_ / ____ \| |  | ||  __/    |
|    /_/    \_\_/ \__,_|_| |_|\__/_/    \_\_|   \__\___|    |
|                                                           |
|    https://avantarte.com/careers                          |
|    https://avantarte.com/support/contact                  |
|                                                           |
\----------------------------------------------------------*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ISpecifiedMinter} from "./ISpecifiedMinter.sol";
import {SimpleRoyalties} from "../../libraries/SimpleRoyalties.sol";

/**
 * @title A Lazy minting contract that can mint arbitrary token ids
 * @author Liron Navon
 * @notice this contract specified an address "minter" which is the only address that can call "mint"
 * @dev This contract heavily relies on vouchers with valid signatures.
 */
contract LazyMintByTokenId is
    ERC721,
    SimpleRoyalties,
    Ownable,
    ISpecifiedMinter
{
    /// @dev the uri used for the tokens
    string public uri;
    /// @dev only the minter address can call "mint"
    address public minter;

    constructor(
        string memory _name,
        string memory _uri,
        string memory _symbol,
        address _minter,
        address royaltiesReciever,
        uint256 royaltiesFraction
    )
        ERC721(_name, _symbol)
        SimpleRoyalties(royaltiesReciever, royaltiesFraction)
    {
        uri = _uri;
        minter = _minter;
    }

    modifier onlyMinter() {
        require(minter == msg.sender, "Unauthorized minter");
        _;
    }

    /**
     * @dev Mints a token to a given user
     */
    function _mintToken(address to, uint256 tokenId) private returns (uint256) {
        _mint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Overrides the token URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return uri;
    }

    /**
     * @dev Calls mint, only for requests of the minter address
     */
    function mint(address to, uint256 tokenId)
        public
        onlyMinter
        returns (uint256)
    {
        return _mintToken(to, tokenId);
    }

    /**
     * @dev Calls mint, only for the contract owner
     */
    function ownerMint(address to, uint256 tokenId)
        public
        onlyOwner
        returns (uint256)
    {
        return _mintToken(to, tokenId);
    }

    /**
     * @dev Set a new uri
     */
    function setUri(string calldata _uri) public onlyOwner {
        uri = _uri;
    }

    /**
     * @dev Set a new minter
     */
    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    /**
     * @dev Set new royalties for the contract
     */
    function setRoyalties(address reciever, uint256 fraction) public onlyOwner {
        _setRoyalty(reciever, fraction);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, SimpleRoyalties)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            SimpleRoyalties.supportsInterface(interfaceId);
    }
}