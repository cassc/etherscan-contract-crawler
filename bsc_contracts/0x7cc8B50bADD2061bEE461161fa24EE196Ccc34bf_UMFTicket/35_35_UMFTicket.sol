// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

import './ERC721PresetMinterPauserAutoIdUpgradeable.sol';
import './interfaces/IUMFTicket.sol';
import './interfaces/IERC4906Upgradeable.sol';

contract UMFTicket is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC721PresetMinterPauserAutoIdUpgradeable,
    IUMFTicket,
    IERC4906Upgradeable
{
    function initialize_umf(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_
    ) public virtual initializer {
        ERC721PresetMinterPauserAutoIdUpgradeable.initialize(name_, symbol_, baseTokenURI_);

        __Umf_init();
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Umf_init() internal onlyInitializing {
        __Umf_init_unchained();
        __Ownable_init_unchained();
    }

    function __Umf_init_unchained() internal onlyInitializing {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721PresetMinterPauserAutoIdUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC4906Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function contractURI() public pure returns (string memory) {
        string memory name = 'Fellaz NFT Ticket for Ultra Abu Dhabi 2023';
        string memory seller_fee_basis_points = '750';
        string memory fee_recipient = '0xdc657e8f09228fBab751f7b443fd6135049FB030';

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        '", "seller_fee_basis_points": ',
                        seller_fee_basis_points,
                        ', "fee_recipient": "',
                        fee_recipient,
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function setBaseURI(string memory baseUri) external virtual override onlyOwner {
        _baseTokenURI = baseUri;

        emit MetadataUpdate(type(uint256).max);
    }

    function batchTransferFrom(address to, uint256[] calldata tokenIds) external virtual override {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            transferFrom(_msgSender(), to, tokenIds[i]);
        }
    }

    function mint(address to, uint256 tokenId) public virtual override onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    function mintBatch(address to, uint256 totalCount) external virtual override onlyRole(MINTER_ROLE) {
        for (uint8 i = 0; i < totalCount; i++) {
            mint(to);
        }
    }

    function mintBatchToAddresses(address[] memory toList) external virtual override onlyRole(MINTER_ROLE) {
        for (uint8 i = 0; i < toList.length; i++) {
            mint(toList[i]);
        }
    }

    function mintBatchToAddressesWithTokenIds(address[] memory toList, uint256[] memory tokenIdList)
        external
        virtual
        override
        onlyRole(MINTER_ROLE)
    {
        require(toList.length == tokenIdList.length, 'toList, tokenIdList different length');

        for (uint8 i = 0; i < toList.length; i++) {
            mint(toList[i], tokenIdList[i]);
        }
    }

    function refreshTokenMetadata(uint256 tokenId) external virtual override onlyOwner {
        emit MetadataUpdate(tokenId);
    }

    function batchRefreshMetadata(uint256 fromTokenId, uint256 toTokenId) external virtual override onlyOwner {
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    function refreshEntireTokenMetadata() external virtual override onlyOwner {
        emit MetadataUpdate(type(uint256).max);
    }
}