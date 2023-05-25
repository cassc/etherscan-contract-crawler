// SPDX-License-Identifier: MIT

/**
 *
 *  █████╗ ██╗     ███████╗ █████╗ ██████╗  █████╗  ██████╗
 * ██╔══██╗██║     ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗
 * ███████║██║     █████╗  ███████║██║  ██║███████║██║   ██║
 * ██╔══██║██║     ██╔══╝  ██╔══██║██║  ██║██╔══██║██║   ██║
 * ██║  ██║███████╗██║     ██║  ██║██████╔╝██║  ██║╚██████╔╝
 * ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝
 *
 * https://alfadao.org
 * https://twitter.com/AlfaDAO_
 * https://discord.gg/alfadao
 *
 */

pragma solidity 0.8.13;

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to
 * approve contract use for users.
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract AlfaDAO is
    ERC721,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    ContextMixin,
    NativeMetaTransaction
{
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    bool public saleActive = false;
    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    uint256 public mintFee;
    string public baseURI;
    bytes32 public merkleRoot;

    constructor(
        uint256 _mintFee,
        string memory _base,
        bytes32 _merkleRoot
    ) ERC721("AlfaDAO", "ALFA") {
        mintFee = _mintFee;
        baseURI = _base;
        merkleRoot = _merkleRoot;
        _initializeEIP712("AlfaDAO");
    }

    function whitelistMint(address _account, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        bytes32 node = keccak256(abi.encodePacked(_account));

        require(msg.value == mintFee, "Wrong payment");
        require(balanceOf(msg.sender) == 0, "Already minted");
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "Invalid Merkle proof."
        );

        uint256 mintIndex = totalSupply();

        if (totalSupply() < MAX_SUPPLY) {
            _safeMint(msg.sender, mintIndex);
        }
    }

    function activeMint(uint256 _mintCount) external payable nonReentrant {
        require(msg.value == mintFee.mul(_mintCount), "Wrong payment");
        require(saleActive, "Sale inactive");
        require(totalSupply().add(_mintCount) <= MAX_SUPPLY, "Exceeds supply");

        for (uint256 i = 0; i < _mintCount; i++) {
            uint256 mintIndex = totalSupply();

            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _base) external onlyOwner {
        baseURI = _base;
    }

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function toggleActiveSales() external onlyOwner {
        saleActive = !saleActive;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract.json"));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original
     * token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}