/*
    Copyright 2022 https://www.dzap.io
    SPDX-License-Identifier: MIT
*/
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./../interfaces/IDZapDiscountNft.sol";

import { NftData } from "./../common/Types.sol";

contract DZapDiscountNft is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, IDZapDiscountNft {
    string public contractUri;

    mapping(uint256 => NftData) public discountDetails;
    mapping(address => mapping(uint256 => uint256)) public minters;

    uint256 public nextId = 1;
    uint256 private constant _BPS_MULTIPLIER = 100;

    /* ========= CONSTRUCTOR ========= */

    constructor(string memory baseUri_, string memory contractUri_) ERC1155(baseUri_) {
        contractUri = contractUri_;
    }

    /* ========= VIEWS ========= */

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        return string(abi.encodePacked(uri(0), Strings.toString(tokenId_), ".json"));
    }

    /* ========= FUNCTIONS ========= */

    function setBaseURI(string memory newUri_) public onlyOwner {
        _setURI(newUri_);
    }

    function setContractURI(string memory newContractUri_) public onlyOwner {
        contractUri = newContractUri_;
    }

    function createNfts(NftData[] calldata nftData_) public onlyOwner {
        uint256 startingId = nextId;

        for (uint256 i; i < nftData_.length; ++i) {
            NftData memory data = nftData_[i];

            require(data.discountedFeeBps > 0 && data.discountedFeeBps <= 100 * _BPS_MULTIPLIER, "DZN002");
            require(data.expiry > block.timestamp, "DZN003");

            discountDetails[nextId++] = data;
        }

        emit Created(startingId, nftData_.length);
    }

    function createAndMint(
        NftData[] calldata nftData_,
        address[] calldata to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) public onlyOwner {
        createNfts(nftData_);

        for (uint256 i; i < to_.length; ++i) {
            uint256 id = ids_[i];
            _isValidNft(id);

            _mint(to_[i], id, amounts_[i], "0x");
        }

        emit Minted(to_, ids_, amounts_);
    }

    function approveMinter(
        address[] calldata minters_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) public onlyOwner {
        for (uint256 i; i < minters_.length; ++i) {
            _isValidNft(ids_[i]);

            minters[minters_[i]][ids_[i]] += amounts_[i];
        }

        emit MintersApproved(minters_, ids_, amounts_);
    }

    function revokeMinter(address[] calldata minters_, uint256[] calldata ids_) public onlyOwner {
        for (uint256 i; i < minters_.length; ++i) {
            _isValidNft(ids_[i]);

            minters[minters_[i]][ids_[i]] = 0;
        }

        emit MintersRevoked(minters_, ids_);
    }

    function mint(
        address[] calldata to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    ) public {
        for (uint256 i; i < to_.length; ++i) {
            uint256 id = ids_[i];
            _isValidNft(id);

            if (_msgSender() != owner()) {
                require(minters[_msgSender()][id] >= amounts_[i], "DZN001");
                minters[_msgSender()][id] -= amounts_[i];
            }

            _mint(to_[i], id, amounts_[i], "0x");
        }

        emit Minted(to_, ids_, amounts_);
    }

    function mintBatch(
        address to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        bytes calldata data_
    ) public onlyOwner {
        for (uint256 i; i < ids_.length; ++i) {
            _isValidNft(ids_[i]);
        }

        _mintBatch(to_, ids_, amounts_, data_);

        emit BatchMinted(to_, ids_, amounts_);
    }

    /* ========= INTERNAL/PRIVATE ========= */

    function _isValidNft(uint256 id_) private view {
        require(id_ != 0 && id_ < nextId, "DZN004");
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator_,
        address from,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator_, from, to_, ids_, amounts_, data_);
    }
}