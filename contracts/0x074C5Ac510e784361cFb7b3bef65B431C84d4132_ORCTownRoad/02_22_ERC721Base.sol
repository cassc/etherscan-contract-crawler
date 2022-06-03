// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IBaseERC721Interface} from "./IBaseERC721Interface.sol";

struct ConfigSettings {
    uint16 royaltyBps;
    string uriBase;
    string uriExtension;
    bool hasTransferHook;
}

/**
    This smart contract adds features and allows for a ownership only by another smart contract as fallback behavior
    while also implementing all normal ERC721 functions as expected
*/
contract ERC721Base is
    ERC721Upgradeable,
    IBaseERC721Interface,
    IERC2981Upgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    // Minted counter for totalSupply()
    CountersUpgradeable.Counter private mintedCounter;

    modifier onlyInternal() {
        require(msg.sender == address(this), "Only internal");
        _;
    }

    /// on-chain record of when this contract was deployed
    uint256 public immutable deployedBlock;

    ConfigSettings public advancedConfig;

    /// Constructor called once when the base contract is deployed
    constructor() {
        // Can be used to verify contract implementation is correct at address
        deployedBlock = block.number;
    }

    /// Initializer that's called when a new child nft is setup
    /// @param newOwner Owner for the new derived nft
    /// @param _name name of NFT contract
    /// @param _symbol symbol of NFT contract
    /// @param settings configuration settings for uri, royalty, and hooks features
    function initialize(
        address newOwner,
        string memory _name,
        string memory _symbol,
        ConfigSettings memory settings
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();

        advancedConfig = settings;

        transferOwnership(newOwner);
    }

    /// Getter to expose appoval status to root contract
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            ERC721Upgradeable.isApprovedForAll(_owner, operator) ||
            operator == address(this);
    }

    /// internal getter for approval by all
    /// When isApprovedForAll is overridden, this can be used to call original impl
    function __isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return isApprovedForAll(_owner, operator);
    }

    /// Hook that when enabled manually calls _beforeTokenTransfer on
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (advancedConfig.hasTransferHook) {
            (bool success, ) = address(this).delegatecall(
                abi.encodeWithSignature(
                    "_beforeTokenTransfer(address,address,uint256)",
                    from,
                    to,
                    tokenId
                )
            );
            // Raise error again from result if error exists
            assembly {
                switch success
                // delegatecall returns 0 on error.
                case 0 {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    /// Internal-only function to update the base uri
    function __setBaseURI(string memory uriBase, string memory uriExtension)
        public
        override
        onlyInternal
    {
        advancedConfig.uriBase = uriBase;
        advancedConfig.uriExtension = uriExtension;
    }

    /// @dev returns the number of minted tokens
    /// uses some extra gas but makes etherscan and users happy so :shrug:
    /// partial erc721enumerable implemntation
    function totalSupply() public view returns (uint256) {
        return mintedCounter.current();
    }

    /**
      Internal-only
      @param to address to send the newly minted NFT to
      @dev This mints one edition to the given address by an allowed minter on the edition instance.
     */
    function __mint(address to, uint256 tokenId)
        external
        override
        onlyInternal
    {
        _mint(to, tokenId);
        mintedCounter.increment();
    }

    /**
        @param tokenId Token ID to burn
        User burn function for token id 
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not allowed");
        _burn(tokenId);
        mintedCounter.decrement();
    }

    /// Internal only
    function __burn(uint256 tokenId) public onlyInternal {
        _burn(tokenId);
        mintedCounter.decrement();
    }

    /**
        Simple override for owner interface.
     */
    function owner()
        public
        view
        override(OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    /// internal alias for overrides
    function __owner()
        public
        view
        override(IBaseERC721Interface)
        returns (address)
    {
        return owner();
    }

    /// Get royalty information for token
    /// ignored token id to get royalty info. able to override and set per-token royalties
    /// @param _salePrice sales price for token to determine royalty split
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // If ownership is revoked, don't set royalties.
        if (owner() == address(0x0)) {
            return (owner(), 0);
        }
        return (owner(), (_salePrice * advancedConfig.royaltyBps) / 10_000);
    }

    /// Default simple token-uri implementation. works for ipfs folders too
    /// @param tokenId token id ot get uri for
    /// @return default uri getter functionality
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "No token");

        return
            string(
                abi.encodePacked(
                    advancedConfig.uriBase,
                    StringsUpgradeable.toString(tokenId),
                    advancedConfig.uriExtension
                )
            );
    }

    /// internal base override
    function __tokenURI(uint256 tokenId)
        public
        view
        onlyInternal
        returns (string memory)
    {
        return tokenURI(tokenId);
    }

    /// Exposing token exists check for base contract
    function __exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /// Getter for approved or owner
    function __isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        override
        onlyInternal
        returns (bool)
    {
        return _isApprovedOrOwner(spender, tokenId);
    }

    /// IERC165 getter
    /// @param interfaceId interfaceId bytes4 to check support for
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            type(IBaseERC721Interface).interfaceId == interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }
}