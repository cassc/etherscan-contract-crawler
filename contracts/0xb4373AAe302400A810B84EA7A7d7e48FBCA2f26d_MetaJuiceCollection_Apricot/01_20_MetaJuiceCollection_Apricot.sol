//Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./Minting.sol";

/// @title An ERC721 Contract for minting ImmutableX-compatible NFTs
/// @author MetaJuice
/// @notice Implements EIP-2981 onchain royalty standard, is burnable, and whitelists certain wallets to have DEFAULT_ADMIN_ROLE permissions
contract MetaJuiceCollection_Apricot is ERC721Royalty, ERC721Burnable, ERC721URIStorage, AccessControl {
    
    /// @dev maps tokenId to string that is the onchain metadata, generally the IPFS content hash
    mapping(uint256 => bytes) public blueprints;

    /// @dev tokenURI will be baseURI/<blueprint>/<tokenId>.json
    string private baseURI;

    event AssetMinted(address to, uint256 id, bytes blueprint);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the contract owner or IMX");
        _;
    }

    /// @param _owner The wallet that is the owner of this minting contract
    /// @param __name The name of this NFT collection
    /// @param __symbol The symbol for this NFT collection
    /// @param _imx is 0x5FDCCA53617f4d2b9134B29090C87D01058e27e9 for mainnet https://github.com/immutable/imx-contracts/blob/4a6dc460292ffa9a352d3043a4d9019d8f316a59/deploy/utils.ts#L1
    /// @param _imvu_finance_wallet The deployment wallet
    /// @param _baseUri The baseURI for the tokenURI metadata URL
    /// @param _royaltyRecipient The wallet that will receive royalties
    /// @param _royaltyPercentage The percentage rate for royalties
    constructor(
        address _owner,
        string memory __name,
        string memory __symbol,
        address _imx,
        address _imvu_finance_wallet,
        string memory _baseUri,
        address _royaltyRecipient,
        uint96  _royaltyPercentage)

        ERC721(__name,__symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(DEFAULT_ADMIN_ROLE, _imx);
        _setupRole(DEFAULT_ADMIN_ROLE, _imvu_finance_wallet);
        
        _setDefaultRoyalty(_royaltyRecipient, _royaltyPercentage);
        
        baseURI = _baseUri;
    }

    /// @dev Will rewrite tokenURI when NFT is withdrawn to L1 Ethereum to be baseURI/<blueprint>/<tokenId>.json
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), '/', tokenId));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice mintFor function is called by ImmutableX to mint NFT on L1 Ethereum when NFT is withdrawn from IMX
    /// @notice mintFor function must be of valid format or ImmutableX will not mint NFT on L2 blockchain
    function mintFor(
        address to,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external onlyAdmin {

        require(quantity == 1, "Mintable: invalid quantity");
        
        /// @dev mintingBlob consists of {tokenId:blueprintValue} 
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        
        super._safeMint(to, id);
        
        /// @dev blueprint value is set as tokenURI as part of tokenURI rewriting process
        blueprints[id] = blueprint;
        string memory TokenURI = string(blueprint);
        super._setTokenURI(id, TokenURI);

        emit AssetMinted(to, id, blueprint);

    }

    /// @notice burn function can only be called by NFT owner or approved operator https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Burnable.sol
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}