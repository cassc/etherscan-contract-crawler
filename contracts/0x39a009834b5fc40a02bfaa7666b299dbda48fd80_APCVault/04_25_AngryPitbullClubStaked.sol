//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract AngryPitbullClubStaked is ERC721, Ownable {
    error NotAuthorized();

    /**
     * @notice The base URI for token metadata, set to an IPFS hash by default.
     */
    string private _baseTokenURI =
        "https://arweave.net/7ZBDeE4uR_LqEhQ5HDhPPlFj-Fb1IOq8Qd2Dk0LkPtA/";

    /**
     * @notice A mapping to store authorized controllers for minting and burning tokens.
     * The key is the controller's address and the value is a boolean indicating whether they are authorized or not.
     */
    mapping(address => bool) controllers;

    /**
     * @dev Constructor that sets the initial name and symbol for the token.
     */
    constructor() ERC721("Staked Angry Pitbull Club", "Staked APC") {}

    /**
     * @dev Mints a new token with the specified tokenId to the specified address.
     * @param to The address to mint the token to.
     * @param tokenId The unique tokenId of the new token.
     */
    function mint(address to, uint256 tokenId) public callerIsController {
        _safeMint(to, tokenId);
    }

    /**
     * @dev Modifier to check if the caller is authorized to mint or burn tokens.
     */
    modifier callerIsController() {
        if (!controllers[msg.sender]) revert NotAuthorized();
        _;
    }

    /**
     * @dev Adds a new controller that can mint and burn tokens.
     * @param controller The address of the new controller.
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * @dev Removes a controller, revoking their ability to mint and burn tokens.
     * @param controller The address of the controller to remove.
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    /**
     * @dev Mints a batch of tokens to the specified address.
     * @param to The address to mint the tokens to.
     * @param tokenIds An array of unique tokenIds for the new tokens.
     */
    function batchMint(
        address to,
        uint256[] memory tokenIds
    ) external callerIsController {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mint(to, tokenIds[i]);
        }
    }

    /**
     * @dev Burns a token with the specified tokenId.
     * @param tokenId The unique tokenId of the token to burn.
     */
    function burn(uint256 tokenId) public callerIsController {
        _burn(tokenId);
    }

    /**
     * @dev Burns a batch of tokens.
     * @param tokenIds An array of unique tokenIds for the tokens to burn.
     */
    function batchBurn(uint256[] memory tokenIds) external callerIsController {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }

    // VIEW FUNCTIONS
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // ADMIN FUNCTIONS
    /**
     * @dev Sets the base URI for token metadata.
     * @param baseURI The new base URI to use for token metadata.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Checks if the contract supports the specified interface.
     * @param interfaceId The identifier of the interface to check for support.
     * @return A boolean indicating whether the contract supports the given interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer, including minting and burning.
     * @param from The address the token is being transferred from.
     * @param to The address the token is being transferred to.
     * @param tokenId The unique tokenId of the token being transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override{
        require(
            controllers[msg.sender],
            "Staked APC can not be transferred!"
        );
    }
}