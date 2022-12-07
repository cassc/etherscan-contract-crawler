// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ERC721BurnableUpgradeable.sol";

import "../users/AddressManagerNode.sol";

import "../interfaces/ITokenCreator.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IRoles.sol";

abstract contract ERC721Distinctive is
    Initializable,
    IOwnable,
    ERC721BurnableUpgradeable
{
    /**
     * @dev Information about collection
     */
    struct CollectionInfo {
        // The creator of collection
        address payable creator;
        // The licensor of collection
        address payable licensor;
        // The last Id that was mint
        // The 2**32 for an individual's collection is big enough
        uint32 lastTokenId;
        // The number of burned tokens
        // The 2**32 for an individual's collection is big enough
        uint32 burnCounter;
    }

    /**
     * @dev Stores a IPFSHash for each NFT.
     */
    mapping(uint256 => string) internal tokenIPFSHash;

    /// @dev Token policy matching tokenId
    mapping(uint256 => uint256) internal tokenPolicy;

    CollectionInfo internal collectionInfo;

    modifier onlyCreator() {
        require(
            msg.sender == collectionInfo.creator,
            "ERC721Distinctive: Caller is not creator"
        );
        _;
    }

    function _initializeERC721Distinctive(
        address payable _creator,
        string memory _name,
        string memory _symbol,
        address _core
    ) internal onlyInitializing {
        collectionInfo.creator = _creator;
        collectionInfo.licensor = _creator;
        __ERC721_init(_name, _symbol, _core);
    }

    /**
     * @notice The function to get the creator of a collection
     */
    function creator() public view returns (address _creator) {
        _creator = address(collectionInfo.creator);
    }

    /**
     * @notice The function to get the licensor of a collection
     */
    function owner() public view override returns (address _licensor) {
        _licensor = address(collectionInfo.licensor);
    }

    function _burn(uint256 tokenId) internal override {
        unchecked {
            // Number of burned tokens cannot exceed latestTokenId which is the same size.
            ++collectionInfo.burnCounter;
        }
        delete tokenIPFSHash[tokenId];
        super._burn(tokenId);
    }

    /**
     * @notice Internal function to set the colletion licensor
     */
    function setLicensor(address newOwner) public onlyCHIZUModule {
        collectionInfo.licensor = payable(newOwner);
    }

    /**
     * @notice Internal function to register token policy
     */
    function _setTokenPolicy(uint256 tokenId, uint256 policy) internal {
        tokenPolicy[tokenId] = policy;
    }

    /**
     * @dev The IPFS path should be the CID
     */
    function _setTokenIPFSHash(uint256 tokenId, string memory ipfsHash)
        internal
    {
        // 46 is the minimum length for an IPFS content hash, it may be longer if paths are used
        require(
            bytes(ipfsHash).length >= 46,
            "DistinctiveCollection: Invalid IPFS path"
        );

        tokenIPFSHash[tokenId] = ipfsHash;
    }

    /**
     * @notice Returns the total amount of tokens stored by the contract.
     * @dev From the ERC-721 enumerable standard.
     * @return supply The total number of NFTs tracked by this contract.
     */
    function totalSupply() public view returns (uint256 supply) {
        unchecked {
            // Number of tokens minted is always >= burned tokens.
            supply = collectionInfo.lastTokenId - collectionInfo.burnCounter;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (interfaceId == type(IOwnable).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    uint256[999] private __gap;
}