// SPDX-License-Identifier: MIT

/// @title Looking In by Snuffy
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import { ERC721A } from "ERC721A.sol";
import { Ownable } from "Ownable.sol";
import { EIP2981AllToken } from "EIP2981AllToken.sol";
import { BlockList } from "BlockList.sol";
import { ReentrancyGuard } from "ReentrancyGuard.sol";

contract LookingIn is ERC721A, EIP2981AllToken, BlockList, Ownable, ReentrancyGuard {

    //================= State Variables =================//
    // general details
    address public adminAddress;
    address payable public payoutAddress;

    // sale details
    bool public saleOpen;
    uint256 public mintPrice;

    // burn details
    bool public burnOpen;

    // token uri details
    string internal _baseTokenUri;

    //================= Modifiers =================//
    modifier adminOrOwner {
        require(msg.sender == adminAddress || msg.sender == owner(), "Address not admin or owner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == adminAddress, "Address not admin");
        _;
    }

    //================= Constructor =================//
    constructor(
        address admin,
        address payout,
        uint256 price,
        string memory initUri,
        address royaltyPayout,
        uint256 royaltyPerc,
        address[] memory blockedMarketplaces
    )
    ERC721A("Looking In", "LOOKIN")
    EIP2981AllToken(royaltyPayout, royaltyPerc)
    BlockList()
    Ownable()
    ReentrancyGuard()
    {   
        // state updates
        adminAddress = admin;
        payoutAddress = payable(payout);
        mintPrice = price;
        _baseTokenUri = initUri;

        // blocklist
        for (uint256 i = 0; i < blockedMarketplaces.length; i++) {
            _setBlockListStatus(blockedMarketplaces[i], true);
        }
    }

    //================= General Functions =================//
    /// @notice function to renounce admin rights
    /// @dev requires admin only
    function renounceAdmin() external onlyAdmin {
        adminAddress = address(0);
    }

    /// @notice function to set admin address
    /// @dev requires owner
    function setAdminAddress(address newAdmin) external onlyOwner {
        adminAddress = newAdmin;
    }

    /// @notice function to set payout address
    /// @dev requires owner
    function setPayoutAddress(address newPayout) external onlyOwner {
        payoutAddress = payable(newPayout);
    }

    /// @notice sets the base URI
    /// @dev requires admin or owner
    function setBaseURI(string memory newUri) external adminOrOwner {
        _baseTokenUri = newUri;
    }

    //================= Sale Functions =================//
    /// @notice funciton to set sale status
    /// @dev requires admin or owner
    function setSaleStatus(bool status) external adminOrOwner {
        saleOpen = status;
    }

    /// @notice function to set the mint price
    /// @dev requires admin or owner
    function setMintPrice(uint256 newPrice) external adminOrOwner {
        mintPrice = newPrice;
    }

    /// @notice airdrop function
    /// @dev requires admin or owner
    function airdrop(address[] calldata addresses) external nonReentrant adminOrOwner {
        require(addresses.length > 0, "Cannot mint zero tokens");

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    /// @notice mint function
    /// @dev nonreentrant and requires a sale to be open
    function mint(uint256 numToMint) external payable nonReentrant {
        require(saleOpen, "Sale not open");
        require(numToMint < 20, "Maximum batch size is 20");
        require(msg.value >= mintPrice * numToMint, "Not enough ether attached");

        (bool success, ) = payoutAddress.call{value: msg.value}("");
        require(success, "payment failed");

        _safeMint(msg.sender, numToMint);
    }

    //================= Burn Functions =================//
    /// @notice function to set burn status
    /// @dev requires admin or owner
    function setBurnStatus(bool status) external adminOrOwner {
        burnOpen = status;
    }

    /// @notice burn function
    /// @dev requires burn to be open
    function burn(uint256 tokenId) external {
        require(burnOpen, "Burn is not open");
        _burn(tokenId, true);
    }

    //================= Royalty Functions =================//
    /// @notice function to change the royalty info
    /// @dev requires owner
    /// @dev this is useful if the amount was set improperly at contract creation.
    function setRoyaltyInfo(address newAddr, uint256 newPerc) external onlyOwner {
        _setRoyaltyInfo(newAddr, newPerc);
    }

    //================= BlockList =================//
    function setBlockListStatus(address operator, bool status) external onlyOwner {
        _setBlockListStatus(operator, status);
    }

    //================= Overrides =================//
    /// @dev see {ERC721A.approve}
    function approve(address to, uint256 tokenId) public payable virtual override(ERC721A) notBlocked(to) {
        ERC721A.approve(to, tokenId);
    }

    /// @dev see {ERC721A.setApprovalForAll}
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A) notBlocked(operator) {
        ERC721A.setApprovalForAll(operator, approved);
    }

    /// @dev see {ERC165.supportsInterface}
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, EIP2981AllToken) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || EIP2981AllToken.supportsInterface(interfaceId);
    }

    /// @dev see {ERC721A._baseURI}
    function _baseURI() internal view override returns(string memory) {
        return _baseTokenUri;
    }

    // @dev see {ERC721A._startTokenId}
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}