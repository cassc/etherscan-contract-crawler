// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IContractURI.sol";
import "./IProxyRegistry.sol";
import "./IZerionDNA.sol";

contract ZerionDNA is Ownable, Pausable, ERC721, IContractURI, IZerionDNA {
    /// @inheritdoc IContractURI
    string public override contractURI;

    /// @inheritdoc IZerionDNA
    uint256 public override totalSupply;

    // OpenSea Proxy Registry address
    address internal constant OPENSEA_PROXY_REGISTRY = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    // Prefix of each tokenURI
    string internal baseURI;

    /// @notice Creates Zerion DNA 1.0
    constructor() ERC721("Zerion DNA 1.0", "DNA") {
        _pause();
    }

    /// @inheritdoc IZerionDNA
    function setBaseURI(string memory newBaseURI) external override onlyOwner {
        baseURI = newBaseURI;
    }

    /// @inheritdoc IZerionDNA
    function setContractURI(string memory newContractURI) external override onlyOwner {
        contractURI = newContractURI;
    }

    /// @inheritdoc IZerionDNA
    function mint() external override whenNotPaused {
        _safeMint(_msgSender(), totalSupply++);
    }

    /// @inheritdoc IZerionDNA
    function pause() external override onlyOwner {
        _pause();
    }

    /// @inheritdoc IZerionDNA
    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IContractURI).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool)
    {
        return
            operator == IProxyRegistry(OPENSEA_PROXY_REGISTRY).proxies(owner) ||
            super.isApprovedForAll(owner, operator);
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}