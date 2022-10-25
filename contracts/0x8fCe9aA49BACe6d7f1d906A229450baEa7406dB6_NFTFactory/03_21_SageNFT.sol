// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils/StringUtils.sol";
import "../../interfaces/ISageStorage.sol";

contract SageNFT is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721URIStorage,
    Ownable
{
    using Counters for Counters.Counter;
    ISageStorage immutable sageStorage;

    address public artist;
    uint256 private artistShare;

    string private contractMetadata;

    Counters.Counter public nextTokenId;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = keccak256("role.minter");
    bytes32 public constant BURNER_ROLE = keccak256("role.burner");

    uint256 private constant DEFAULT_ROYALTY_PERCENTAGE = 1200; // in basis points (100 = 1%)

    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a; // implements ERC-2981 interface

    constructor(
        string memory _name,
        string memory _symbol,
        address _sageStorage,
        address _artist,
        uint256 _artistShare
    ) ERC721(_name, _symbol) {
        sageStorage = ISageStorage(_sageStorage);
        artist = _artist;
        artistShare = _artistShare;
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        nextTokenId.increment();
    }

    /**
     * @dev Throws if not called by an admin account.
     */
    modifier onlyMultisig() {
        require(sageStorage.multisig() == msg.sender, "Admin calls only");
        _;
    }

    modifier onlyArtist() {
        require(msg.sender == artist, "Only artist calls");
        _;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadata;
    }

    function _incMint(address to, string calldata uri) internal {
        uint256 currentTokenId = nextTokenId.current();
        nextTokenId.increment();
        _safeMint(to, currentTokenId);
        _setTokenURI(currentTokenId, uri);
    }

    function artistMint(string calldata uri) public onlyArtist {
        _incMint(msg.sender, uri);
    }

    function safeMint(address to, string calldata uri) public {
        require(
            sageStorage.hasRole(MINTER_ROLE, msg.sender),
            "No minting rights"
        );
        _incMint(to, uri);
    }

    function setTokenURI(uint256 _tokenId, string calldata _uri)
        public
        onlyMultisig
    {
        _setTokenURI(_tokenId, _uri);
    }

    function setArtist(address _artist) public onlyMultisig {
        artist = _artist;
    }

    function setArtistShare(uint256 _artistShare) public onlyMultisig {
        artistShare = _artistShare;
    }

    function withdrawERC20(address erc20) public {
        IERC20 token = IERC20(erc20);
        uint256 balance = token.balanceOf(address(this));
        uint256 _artist = (balance * 8333) / 10000;
        token.transfer(artist, _artist);
        token.transfer(sageStorage.multisig(), balance - _artist);
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        uint256 _share = (balance * artistShare) / 10000;
        (bool sent, ) = artist.call{value: _share}("");
        if (!sent) {
            revert();
        }
        (sent, ) = sageStorage.multisig().call{value: balance - _share}("");
        if (!sent) {
            revert();
        }
    }

    receive() external payable {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function burnFromAuthorizedAddress(uint256 _id) public {
        require(
            sageStorage.hasRole(BURNER_ROLE, msg.sender),
            "No burning rights"
        );
        _burn(_id);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setContractMetadata(string calldata _contractMetadata) public {
        require(
            sageStorage.hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                (msg.sender == artist && bytes(contractMetadata).length == 0),
            "Only creator or admin calls"
        );
        contractMetadata = _contractMetadata;
    }

    /**
     * Override isApprovedForAll to whitelist SAGE's market
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        // Whitelist Sage's marketplace
        if (
            sageStorage.getAddress(
                keccak256(abi.encodePacked("address.marketplace"))
            ) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Calculates royalties based on a sale price provided following EIP-2981.
     * Solution is agnostic of the sale price unit and will answer using the same unit.
     * @return  address to receive royaltyAmount, amount to be paid as royalty.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        return (
            address(this),
            (salePrice * DEFAULT_ROYALTY_PERCENTAGE) / 10000
        );
    }
}