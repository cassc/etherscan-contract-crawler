// SPDX-License-Identifier: Apache-2.0

/// @title Proof Of Innovation
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import "ERC721.sol";
import "EIP2981AllToken.sol";
import "Ownable.sol";
import "BlockList.sol";
import "ReentrancyGuard.sol";

contract ProofOfInnovation is ERC721, EIP2981AllToken, Ownable, BlockList, ReentrancyGuard {

    //================= State Variables =================//
    bool public claimOpen;
    uint256 private _counter;
    string private _baseTokenUri;
    mapping(bytes32 => bool) private _secrets;

    //================= Constructor ==================//
    constructor(
        address royaltyRecip,
        uint256 royaltyPerc,
        string memory initTokenUri
    )
    ERC721("Proof of Innovation", "POI")
    EIP2981AllToken(royaltyRecip, royaltyPerc)
    Ownable()
    ReentrancyGuard()
    {
        _baseTokenUri = initTokenUri;
    }

    //================= General Functions ==================//
    /// @notice sets the base URI
    /// @dev requires owner
    function setBaseURI(string memory newUri) external onlyOwner {
        _baseTokenUri = newUri;
    }

    /// @notice function to get total supply
    function totalSupply() external view returns(uint256) {
        return _counter;
    }

    //================= Secret Functions ==================//
    /// @notice function to set secret status
    /// @dev requires owner
    function setSecretStatus(bytes32[] calldata secrets, bool status) external onlyOwner {
        for (uint256 i = 0; i < secrets.length; i++) {
            _secrets[secrets[i]] = status;
        }
    }

    /// @notice function to check if secret is a secret
    function checkSecret(string calldata secret) external view returns(bool) {
        bytes32 hashedSecret = keccak256(bytes(secret));
        return _secrets[hashedSecret];
    }

    //================= Claim Functions ==================//
    /// @notice function to set claim status
    /// @dev requires owner
    function setClaimStatus(bool status) external onlyOwner {
        claimOpen = status;
    }

    /// @notice claim function
    function claim(string calldata secret) external nonReentrant {
        require(claimOpen, "Claim not open");
        bytes32 hashedSecret = keccak256(bytes(secret));
        require(_secrets[hashedSecret], "Secret not a secret");

        _secrets[hashedSecret] = false;
        _counter++;
        _safeMint(msg.sender, _counter);
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
    /// @dev see {ERC721.approve}
    function approve(address to, uint256 tokenId) public virtual override(ERC721) notBlocked(to) {
        ERC721.approve(to, tokenId);
    }

    /// @dev see {ERC721.setApprovalForAll}
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721) notBlocked(operator) {
        ERC721.setApprovalForAll(operator, approved);
    }

    /// @dev see {ERC165.supportsInterface}
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, EIP2981AllToken) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || EIP2981AllToken.supportsInterface(interfaceId);
    }

    /// @dev see {ERC721._baseURI}
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }
}