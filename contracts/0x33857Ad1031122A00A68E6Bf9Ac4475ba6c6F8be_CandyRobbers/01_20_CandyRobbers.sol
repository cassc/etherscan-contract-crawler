//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./ICandyRobbers.sol";

contract CandyRobbers is ERC721A, Ownable, AccessControlEnumerable, Pausable, ICandyRobbers {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 5000;

    //Genral admin role, grants minter role to sale contract.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    //Minter role, allowed to perform mints on this contract.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    //Base uri for metadatas, used only after reveal
    string public baseURI;

    //uri for metadatas pre-reveal
    string public notRevealedUri;

    //Indicates if NFTs have been revealed
    bool public revealed = false;

    constructor() ERC721A("CandyRobbers", "CANDY") {
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE); //Admin role manages minter role

        _grantRole(ADMIN_ROLE, msg.sender); //Initial admin is deployer

        _safeMint(msg.sender, 1); // To configure OpenSea
    }

    //Restrict function access to admin only
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You are not allowed to perform this action."
        );
        _;
    }

    //Restrict function access to minter only
    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "You are not allowed to perform this action."
        );
        _;
    }

    //Allows ADMIN_ROLE to be transfered
    function transferAdmin(address _to) external onlyAdmin {
        require(_to != address(0), "Can't put 0 address");

        _revokeRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, _to);
    }

    /**
     * @dev Use this function with an address that has been granted the minter role to mint tokens
     * @param _to the address that the tokens will be minted to
     * @param _quantity Quantity to mint
     */
    function mintTo(address _to, uint256 _quantity) external onlyMinter {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max Supply Reached");

        _safeMint(_to, _quantity);
    }

    //Reveal the NFTs. Calling the function multiple time does not affect the metadatas
    function reveal() public onlyAdmin {
        revealed = true;
    }

    //Change the uri for pre-reveal
    function setNotRevealedURI(string memory _notRevealedURI) public onlyAdmin {
        notRevealedUri = _notRevealedURI;
    }

    //Change the uri post reveal. Will be used when robbers go on robberies
    function setBaseURI(string memory _newBaseURI) public onlyAdmin {
        baseURI = _newBaseURI;
    }

    /**
     * @dev This function override the base tokenURI function to manage the revealed state.
     * @dev When the NFTs are not revealed they all have the same URI. When they are revealed the URI is formed as : `baseURI/tokenId`
     *
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Indicates that this contract supports both ERC721Metadata and AccessControlEnumerable interfaces
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721A)
        returns (bool)
    {
        if (interfaceId == type(IAccessControlEnumerable).interfaceId) {
            return true;
        }
        if (interfaceId == type(IERC721Metadata).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}