// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../opensea/ContextMixin.sol";
import "../opensea/NativeMetaTransaction.sol";

contract OpenSeaOwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OpenSeaOwnableDelegateProxy) public proxies;
}

contract TTTERC721BaseRoyalties is
    ContextMixin,
    ERC721Enumerable,
    Ownable,
    NativeMetaTransaction
{
    bool public isSealed;
    string public openseaContractUri;
    address public openseaProxyRegistryAddress;
    address payable public royaltyAddress;
    uint16 public royaltyBps;

    // https://docs.rarible.org/asset/royalties-schema#royalties-v1
    bytes4 private constant _INTERFACE_ID_RARIBLE_ROYALTIES = 0xb7799584;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory openSeaContractUri_,
        address openseaProxyRegistryAddress_,
        address payable royaltyAddress_,
        uint16 royaltyBps_
    ) ERC721(name_, symbol_) {
        openseaContractUri = openSeaContractUri_;
        openseaProxyRegistryAddress = openseaProxyRegistryAddress_;
        royaltyAddress = royaltyAddress_;
        royaltyBps = royaltyBps_;
    }

    //
    //
    // ERC165
    //
    //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_RARIBLE_ROYALTIES ||
            interfaceId == _INTERFACE_ID_ERC2981 ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }

    //
    //
    // SEAL CONTRACT
    //
    //
    modifier onlyUnsealed() {
        require(!isSealed, "tokens are sealed");
        _;
    }

    modifier onlySealed() {
        require(isSealed, "tokens are not sealed");
        _;
    }

    function sealTokens() public onlyOwner onlyUnsealed {
        isSealed = true;
    }

    //
    //
    // TOKEN MINT / BURN
    //
    //
    function mint(address to, uint256 tokenId)
        public
        virtual
        onlyOwner
        onlyUnsealed
    {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "TTTERC721Base: caller is neither owner nor approved"
        );
        _burn(tokenId);
    }

    //
    //
    // ROYALTIES
    //
    //
    function setRoyalties(
        address payable newRoyaltyAddress,
        uint16 newRoyaltyBps,
        string calldata newOpenseaContractUri
    ) public onlyOwner {
        require(
            royaltyBps == 0 || newRoyaltyBps <= royaltyBps,
            "TTTERC721Base: token royalties cannot be increased"
        );
        royaltyAddress = newRoyaltyAddress;
        royaltyBps = newRoyaltyBps;
        openseaContractUri = newOpenseaContractUri;
    }

    // rarible-royalties
    function getFeeRecipients(uint256)
        public
        view
        returns (address payable[] memory)
    {
        address payable[] memory result = new address payable[](1);
        result[0] = royaltyAddress;
        return result;
    }

    function getFeeBps(uint256) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](1);
        result[0] = royaltyBps;
        return result;
    }

    // mintable-royalties (and ERC2981 generally)
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyAddress, (_salePrice * royaltyBps) / 10000);
    }

    // opensea contract uri containing royalty info
    function contractURI() public view returns (string memory) {
        return openseaContractUri;
    }

    //
    //
    // OPENSEA PROXY
    //
    //
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (openseaProxyRegistryAddress != address(0)) {
            // Whitelist OpenSea proxy contract for easy trading.
            OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
                openseaProxyRegistryAddress
            );
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(owner, operator);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}