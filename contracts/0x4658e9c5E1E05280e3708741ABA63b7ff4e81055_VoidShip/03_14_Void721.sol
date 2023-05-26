// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IBeforeTransferHook} from "../interfaces/IBeforeTransferHook.sol";

error NotAnAdmin();
error ExceedsMaxSupply();
error CannotBurn();

// for OpenSea gasless listings
interface OpenSeaProxyRegistry {
    function proxies(address addr) external view returns (address);
}

/**
  @title Void721, a robust ERC721A-based NFT
  @notice Intended to be used in conjunction with DropShop721 as a minting frontend

  Featuring:

  - configurable baseURI
  - token IDs starting at 1 rather than 0
  - administrative mgmnt, for delegating mint permission() to DropShop71.
    also allows us keep owner keys in cold storage post-deploy
  - modular beforeTransferHook, allowing for upgradable transfer locking or other future tokenomic mechanics
  - EIP2981 on-chain royalty payment info
  - OpenSea gasless listings, which can be toggled on and off
  - exposes how long a given token has been owned, for use in insight/clockspeed-style calculations
  - burning available to token owner
*/
contract Void721 is ERC721AQueryable, Ownable {
    // maximum number of tokens that can be minted, set in constructor
    uint256 public immutable maxSupply;

    // timestamp when contract was deployed
    uint256 public immutable startTime;

    // metadata URI to which token IDs are appended for generating `tokenURI`
    // configurable with `setBaseURI`
    string public baseURI;

    // administrative callers set by the owner (e.g. so DropShop can call mint)
    // configurable with `setAdmin()`
    mapping(address => bool) private administrators;

    // our modular beforeTransferHook contract, defaulting off
    // for upgradable transfer-locking and other tokenomic mechanics
    // inspired by @frolic: https://twitter.com/frolic/status/1527698740336656389
    IBeforeTransferHook public beforeTransferHook;

    // ERC2981 royalty payments; configurable with `setRoyaltyInfo`
    address public royaltyRecipient;
    uint256 public royaltyAmount = 500; // 5% by default

    // OpenSea gasless listings
    // configurable with `setOpenSeaProxyActive` and `setOpenSeaProxyAddress`
    address public openSeaProxyRegistryAddress;
    bool public openSeaProxyActive = true;

    modifier onlyAdmin() {
        if (_msgSender() != owner() && !administrators[_msgSender()]) {
            revert NotAnAdmin();
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _argBaseURI,
        uint256 _cap,
        address _royaltyRecipient,
        address _openSeaProxyRegistryAddress
    ) ERC721A(_name, _symbol) {
        startTime = block.timestamp;
        baseURI = _argBaseURI;
        maxSupply = _cap;
        royaltyRecipient = _royaltyRecipient;
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    /// @dev overload ERC721A's start index so we begin at token 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev overload ERC721A to return our configurable metadata baseURI
    ///      note that we also have a configurable baseURI inside VoidShipData
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice change the base ERC721 token URI
    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    /// @notice non-owner administrative mgmnt, primarily for use by our DropShop
    function setAdmin(address _newAdmin, bool _isAdmin) external onlyOwner {
        administrators[_newAdmin] = _isAdmin;
    }

    /// @notice is a given address an administrator of this contract?
    function isAdmin(address addressToCheck) external view returns (bool) {
        return
            addressToCheck == owner() || administrators[addressToCheck] == true;
    }

    /// @notice our primary minting function, restricted to admins (e.g. our DropShop)
    /// @dev we are using _mint() rather than _safeMint(), which checks if recipient can accept an ERC721
    ///      don't mint if you can't receive an ERC-721!
    function mint(address _recipient, uint256 _amount) public onlyAdmin {
        if (_nextTokenId() + _amount > maxSupply) {
            revert ExceedsMaxSupply();
        }
        _mint(_recipient, _amount);
    }

    /// @notice called by ERC721A before any token transfer and delegated to
    ///         our configured beforeTransferHook. this could be used to add
    ///         (or remove) transfer-locking and other tokenomic mechanics
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (address(beforeTransferHook) != address(0)) {
            beforeTransferHook.beforeTokenTransfer(
                from,
                to,
                startTokenId,
                quantity
            );
        }
    }

    /// @notice let owner set an address for our (optional) IBeforeTransferHook contract
    function setBeforeTransferHook(IBeforeTransferHook _beforeTransferHook)
        external
        onlyOwner
    {
        beforeTransferHook = _beforeTransferHook;
    }

    /// @notice timestamp of when this token was last transferred
    ///         can be used for an insight/clockspeed-style rewards
    ///         shoutout Corruptions* and OKPC
    function getLastTransferTime(uint256 id) public view returns (uint64) {
        return _ownershipOf(id).startTimestamp;
    }

    /// @notice convenience function to calculate seconds since the last transfer
    function getSecondsSinceLastTransfer(uint256 id)
        public
        view
        returns (uint256)
    {
        return block.timestamp - getLastTransferTime(id);
    }

    /// @notice support for ERC-2981 NFT royalty standard
    ///         https://eips.ethereum.org/EIPS/eip-2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        return (royaltyRecipient, (salePrice * royaltyAmount) / 10000);
    }

    /// @notice allow owner (but not admins) to set the secondary-sale royalty amount
    function setRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyAmount)
        external
        onlyOwner
    {
        royaltyRecipient = _royaltyRecipient;
        royaltyAmount = _royaltyAmount;
    }

    /// @notice enable or disable OpenSea gasless listings
    ///         this is a separate boolean rather than address(0) so we can preserve
    ///         valid values for the proxy, but can still enable and disable
    function setOpenSeaProxyActive(bool _openSeaProxyActive)
        external
        onlyOwner
    {
        openSeaProxyActive = _openSeaProxyActive;
    }

    /// @notice allow owner (but not admins) to set the address of the OpenSea proxy registry
    function setOpenSeaProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        openSeaProxyRegistryAddress = _proxyRegistryAddress;
    }

    /// @notice overload the standard approval check to always allow the OpenSea proxy, if enabled
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            openSeaProxyActive &&
            address(openSeaProxyRegistryAddress) != address(0) &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /// @dev let everyone know that we support ERC2981 (royalty payments)
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return
            (_interfaceId == type(IERC2981).interfaceId) ||
            (super.supportsInterface(_interfaceId));
    }

    /// @notice allow token owner to burn their tokens
    function burn(uint256 id) external {
        if (_msgSender() != ownerOf(id)) {
            revert CannotBurn();
        }
        _burn(id);
    }

    /// @notice check if a given token exists, meaning it has been minted and has not been burned
    function exists(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    /// @notice how many tokens have been minted? use `totalSupply()` to get `totalMinted() - totalBurned()`
    /// @dev exposing some internal ERC721A methods, primarily for use by DropShop
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /// @notice how many tokens have been burned?
    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    /// @notice how many tokens have been minted by a given address?
    function numberMinted(address minter) external view returns (uint256) {
        return _numberMinted(minter);
    }

    /// @notice how many tokens have been burned by a given address?
    function numberBurned(address burner) external view returns (uint256) {
        return _numberBurned(burner);
    }

    /// @dev allow owners and admins (DropShop) to set the number of prerelease mints for given user
    /// @dev this utilizes ERC721A's spare bitmask space via getAux/setAux
    function setPrereleasePurchases(address buyer, uint64 amount)
        external
        onlyAdmin
    {
        _setAux(buyer, amount);
    }

    /// @notice how many tokens have been minted as part of our allowlist & friendlist phases?
    function prereleasePurchases(address buyer) external view returns (uint64) {
        return _getAux(buyer);
    }
}