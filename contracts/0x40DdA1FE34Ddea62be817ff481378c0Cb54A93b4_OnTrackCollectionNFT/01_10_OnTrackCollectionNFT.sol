// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721a/contracts/ERC721A.sol";

contract OnTrackCollectionNFT is ERC721A, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    State public state;
    string public tokenUriBase;

    enum State {
        Open,
        Closed
    }

    constructor() ERC721A("On Track Collection", "ONTRACK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        state = State.Closed;
    }

    /* @dev: Sets Claim to Open
     */
    function setOpen() external onlyOwner {
        state = State.Open;
    }

    /* @dev: Sets Claim to Closed
     */
    function setClosed() external onlyOwner {
        state = State.Closed;
    }

    /* @dev: Returns the URL of token's metadata
     * @param: tokenId Index of token
     * @returns: A string of tokenURI + tokenId
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return string(abi.encodePacked(tokenUriBase, _toString(tokenId)));
    }

    /* @dev: Set the base URL of the metadata
     * @param: _tokenUriBase Base URL of the metadata as a string
     */
    function setTokenURI(string memory _tokenUriBase) public onlyOwner {
        tokenUriBase = _tokenUriBase;
    }

    /* @dev: mint
     * @param: walletAddress Address to transfer minted token
     * @param: quantity Number of tokens to mint
     */
    function mint(address walletAddress, uint256 quantity)
        external
        onlyRole(MINTER_ROLE)
    {
        require(state == State.Open, "Minting is paused");
        _safeMint(walletAddress, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}