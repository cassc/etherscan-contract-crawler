// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "solmate/tokens/ERC721.sol";

import "./IDoubleDropNFT.sol";

contract DoubleDropNFT is IDoubleDropNFT, ERC721, ERC2981, Ownable {
    using Strings for uint256;

    address public redeemer;
    bool public metadataFrozen;

    string public baseURI;
    uint256 public totalSupply;

    event RedeemerSet(address indexed previousRedeemer, address indexed newRedeemer);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable() {}

    /**
     * @notice Redeems HashmasksDerivatives NFTs
     * Caller must be redeemer contract (DoubleDrop)
     */
    /// @param tokenIds The Hashmasks used to redeem these Derivatives.
    /// @param to The wallet to mint the NFTs to.
    function redeem(uint256[] calldata tokenIds, address to) public onlyRedeemer {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(to, tokenIds[i]);
        }
        totalSupply = totalSupply + tokenIds.length;
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        if (metadataFrozen) revert MetadataFrozen();

        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    /**
     * @notice Freezes metadata. Owners can no longer call setBaseURI.
     * Caller must be contract owner.
     */
    function freezeMetadata() public onlyOwner {
        metadataFrozen = true;
    }

    /**
     * @notice Set the DoubleDrop contract address
     * Caller must be contract owner.
     */
    /// @param redeemer_ The address of the DoubleDrop contract.
    function setRedeemer(address redeemer_) public onlyOwner {
        if (redeemer != address(0)) revert RedeemerAlreadySet();
        emit RedeemerSet(redeemer, redeemer_);
        redeemer = redeemer_;
    }

    /**
     * @notice Sets contract royalty information as specified by ERC2981
     * Caller must be contract owner.
     */
    /// @param receiver The royalties payout wallet address
    /// @param basisPoints The royalties percentage expressed as basis points. 100bps = 1%
    function setRoyalties(address receiver, uint96 basisPoints) public onlyOwner {
        _setDefaultRoyalty(receiver, basisPoints);
    }

    /**
     * @notice Removes royalty info from the contract as specified by ERC2981
     * Caller must be contract owner.
     * Useful for setting 0% royalties.
     */
    function deleteRoyaltyInfo() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC2981, ERC721) returns (bool) {
        return interfaceId == type(IDoubleDropNFT).interfaceId || super.supportsInterface(interfaceId);
    }

    modifier onlyRedeemer() {
        if (redeemer == address(0)) revert RedeemerNotSet();
        if (msg.sender != redeemer) revert OnlyRedeemerCanMint();
        _;
    }

}