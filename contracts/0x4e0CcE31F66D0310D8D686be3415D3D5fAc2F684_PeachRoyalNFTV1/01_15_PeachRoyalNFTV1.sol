// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

/**
 *
 * @title Peach Farmer Royal NFTs Contract
 * @notice This contract is used for the Royal NFTs of Peach Farmer. Learn more on https://www.peachfarmer.com/.
 */
contract PeachRoyalNFTV1 is
    ERC721A,
    Ownable,
    AccessControlEnumerable,
    ERC2981
{

    //Total Max supply. Will not be totally minted during the first season. Reserve for later giveaways.
    uint256 public constant MAX_SUPPLY = 100;

    //General admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    //Minter role, only allowed to mint
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    //Base URI of NFTs
    string public baseURI;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE); //Admin role manages Minter role
        _grantRole(ADMIN_ROLE, msg.sender); //msg.sender is granted Admin role. Role might be passed off to a more secure address.
        _safeMint(msg.sender, 1); //Needed to configure OpenSea. Will be sent to user that won a Royal NFT
        _setDefaultRoyalty(msg.sender, 750); //Default royalty
    }

    //Restrict function to admin role
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You must be an Admin to perform this action"
        );
        _;
    }

    //Restrict function to minter role
    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "You must be a Minter to perform this action"
        );
        _;
    }

    /**
     * @dev Overrides the default _baseURI function to use this contract's baseURI string.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Allows to change the baseURI. Used in case of an artwork update.
     * @param _newBaseURI The new base URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyAdmin {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Mints to the `to` address `amount` NFTs. May be used either manually for airdropping or by another contract.
     * @param to the address that the tokens will be minted to
     * @param amount Quantity to mint
     */
    function mintTo(address to, uint256 amount) public onlyMinter {
        require(totalSupply() + amount <= MAX_SUPPLY, "Mint too large");

        _safeMint(to, amount);
    }

     /**
     * @dev Mints multiple NFTs at the same time. Similar to mintTo but batched version.
     * @param addresses Array of recipients
     * @param amounts Quantity to mint for each recipient
     */
    function airdrop(address[] calldata addresses, uint256[] calldata amounts) public onlyMinter {

        require(addresses.length == amounts.length, "Length mismatch");

        uint256 totalAmount = 0;

        for(uint256 i = 0; i < amounts.length; i++){
            totalAmount += amounts[i];
        }

        require(totalSupply() + totalAmount <= MAX_SUPPLY, "Mint too large");

         for(uint256 i = 0; i < amounts.length; i++){
            _safeMint(addresses[i], amounts[i]);
        }

    }

     /**
     * @dev Change the default royalties for the collection.
     * @param _receiver Address that will receive the royalties
     * @param _feeBasisPoint Points of royalties
     */
    function setRoyalties(address _receiver, uint96 _feeBasisPoint)
        public
        onlyOwner
    {
        require(_feeBasisPoint > 0, "Royalties can't be set to 0%");
        require(_feeBasisPoint < 10000, "Royalties can't be set to 0%");
        require(_receiver != address(0), "Royalties can't go to zero address");

        _setDefaultRoyalty(_receiver, _feeBasisPoint);
    }

    /**
     * @dev Transfer Admin role. We don't allow the use of the zero address to avoid input errors.
     * @param _to the address that will be the new Admin
     */
    function transferAdmin(address _to) external onlyAdmin {
        require(_to != address(0), "Can't transfer to 0 address");

        _revokeRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, _to);
    }

    /**
     * @dev Indicates that this contract supports both ERC721Metadata, and ERC2981 interfaces
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}