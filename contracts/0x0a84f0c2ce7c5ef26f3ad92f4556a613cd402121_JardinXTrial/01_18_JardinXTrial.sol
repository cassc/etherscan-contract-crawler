// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./AdministrationV1.sol";

contract JardinXTrial is
    Initializable,
    AdministrationV1,
    ERC1155Upgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    uint24 private _cid;
    uint256 private _txFee;

    struct Collections {
        uint24 cid;
        string currencyName;
        uint256 totalStaked;
    }
    struct Stake {
        uint48 timestamp;
        address owner;
    }
    mapping(ERC721Upgradeable => Collections) private collections;
    mapping(ERC721Upgradeable => mapping(uint256 => Stake)) private vault;

    function initialize() public initializer {
        __ERC1155_init("https://jardinx.platform/api/v1/collection/{id}.json");
        __Pausable_init();
        __Ownable_init();
        __ERC1155Burnable_init();
        _txFee = 10**13;
    }

    function setURI(string memory newuri) public onlySuperAdmin {
        _setURI(newuri);
    }

    function pause() public onlySuperAdmin {
        _pause();
    }

    function unpause() public onlySuperAdmin {
        _unpause();
    }

    function stake(ERC721Upgradeable nft, uint256[] calldata tokenIds)
        external
    {
        _stake(nft, tokenIds);
    }

    function unstake(ERC721Upgradeable nft, uint256[] calldata tokenIds)
        external
    {
        _unstake(nft, tokenIds);
    }

    function addCollection(ERC721Upgradeable nft, string memory currencyName)
        public
        onlySAnA
    {
        collections[nft] = Collections({
            cid: _cid,
            currencyName: currencyName,
            totalStaked: 0
        });
        _cid += 1;
    }

    function deleteCollection(ERC721Upgradeable nft) public onlySAnA {
        require(collections[nft].totalStaked == 0, "coll still have NFT");
        delete collections[nft];
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        _mint(account, id, amount, data);
    }

    function mintSuperAdmin(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlySuperAdmin {
        _mint(account, id, amount, data);
    }

    function transfer(
        address to,
        uint256 id,
        uint256 amount
    ) public payable {
        uint256 sentWei = msg.value;
        require(sentWei >= _txFee, "amount is to small");
        safeTransferFrom(msg.sender, to, id, amount, "0x");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // view functions
    function showCollection(ERC721Upgradeable nft)
        public
        view
        onlySAnA
        returns (Collections memory)
    {
        return collections[nft];
    }

    function showVault(ERC721Upgradeable nft, uint256 tokenId)
        public
        view
        onlySAnA
        returns (Stake memory)
    {
        return vault[nft][tokenId];
    }

    // internal function
    function _stake(ERC721Upgradeable nft, uint256[] calldata tokenIds)
        internal
        virtual
    {
        Collections memory collection;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(nft.ownerOf(tokenIds[i]) == msg.sender, "not your token");
            require(
                vault[nft][tokenIds[i]].owner == address(0),
                "already staked"
            );
            require(
                keccak256(abi.encodePacked(collections[nft].currencyName)) !=
                    keccak256(abi.encodePacked("")),
                "NFT not in collection"
            );
            if (i > 0) {
                require(
                    keccak256(
                        abi.encodePacked(collections[nft].currencyName)
                    ) == keccak256(abi.encodePacked(collection.currencyName)),
                    "there are multiple NFT"
                );
            }
            collection = collections[nft];
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            nft.transferFrom(msg.sender, address(this), tokenIds[i]);
            vault[nft][tokenIds[i]] = Stake({
                owner: msg.sender,
                timestamp: uint48(block.timestamp)
            });
        }
        mint(msg.sender, collection.cid, 10**18 * tokenIds.length, "0x");
        collections[nft].totalStaked += uint256(tokenIds.length);
    }

    function _unstake(ERC721Upgradeable nft, uint256[] calldata tokenIds)
        internal
        virtual
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Stake memory staked = vault[nft][tokenIds[i]];
            require(staked.owner == msg.sender, "not an owner");

            delete vault[nft][tokenIds[i]];
            nft.transferFrom(address(this), msg.sender, tokenIds[i]);
        }
        burn(msg.sender, collections[nft].cid, 10**18 * tokenIds.length);
        collections[nft].totalStaked -= uint256(tokenIds.length);
    }

    uint256[50] __gap;
}