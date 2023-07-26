//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@imtbl/imx-contracts/contracts/IMintable.sol";
import "@imtbl/imx-contracts/contracts/utils/Minting.sol";


/**
@title Season 0 Access Pass
@author Marco Huberts
@dev Implementation of an Access Pass for Crystale using ERC721 on Immutable X. 
 */

contract AccessPass is ERC721, IMintable, AccessControl {

    string public uri;

    bool internal frozen = false;
    bool public allowListCompleted = false;

    address private _owner;
    address public imx;

    uint256 public constant MAX_SUPPLY = 1000;

    mapping(address => bool) public allowList;
    mapping(uint256 => bytes) public blueprints;

    event AssetMinted(address to, uint256 id, bytes blueprint);

    modifier onlyAdminOrIMX() {
        require(msg.sender == imx || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
        "Function can only be called by admin or IMX");
        _;
    }

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        address owner_,
        address _imx
    ) ERC721(_name, _symbol)
    {
        imx = _imx;
        uri = _uri;
        _owner = owner_;
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    /**
     * @dev adds members to the allow list mapping
     * @param members adds an array of addresses eligible for the mint
     */
    function addToAllowList(address[] memory members) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < members.length; i++) {
            allowList[members[i]] = true;
        }
    }

    /**
     * @dev ERC721 uses this function to determine the token URI.
     *      It returns our own set URI. 
     */
    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    /**
     * @notice Allows the admin to freeze the set URI function. 
     */
    function freeze() external onlyRole(DEFAULT_ADMIN_ROLE) {
        frozen = true;
    }

    /**
     * @notice Allows the admin to finalize the allowlisting. 
     */
    function completeAllowList() external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowListCompleted = true;
    }

    /**
     * @dev Returns the owner of the smart contract. 
     * @notice required by Immutable X.
     */
    function owner() external view returns(address) {
        return _owner;
    }

    /**
     * @notice Allows the admin to set the owner of the smart contract. 
     */
    function setOwner(address newOwner, address previousOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _owner = newOwner;
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, previousOwner);
    }

    /**
     * @notice the requirements to mint an asset from L2 to L1
     * @param user the user that minted on L2
     */
    function mintRequirements(address user) internal view {
        require(balanceOf(user) == 0, "You can mint only one Access Pass");
        if (!allowListCompleted) {
            require(allowList[user] == true, "You are not in the allow list");
        }
    }

    /**
     * @notice Mints one NFT. 
     */
    function _mintFor(address user, uint256 id, bytes memory) internal {
        _safeMint(user, id);
    }
    
    /**
     * @notice Mints an NFT if readyToMint is set to true.
     * @notice Can only be called by IMX or Admin when transferring assets from L2 to L1.
     * @param user the address of the user that has minted on Immutable X.
     * @param quantity of tokens minted. Should always be equal to 1.
     * @param mintingBlob data about the NFT.
     */
    function mintFor(
        address user, 
        uint256 quantity, 
        bytes calldata mintingBlob
    ) external override onlyAdminOrIMX {
        mintRequirements(user);
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        require(id <= MAX_SUPPLY, "Max supply reached");
        _mintFor(user, id, blueprint);
        blueprints[id] = blueprint;
        emit AssetMinted(user, id, blueprint);
    }

    /**
     * @dev Checks if token Id exists and returns the base URI as the image is the same for all token ids. 
     * @param tokenId the id of the token of interest.
     */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
    }

    /**
     * @notice Allows the admin to set the base URI of the stored NFT content.
     * @param baseURI the URI without a reference to a specific token ID.
     */
    function setURI(string memory baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!frozen);
        uri = baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

}