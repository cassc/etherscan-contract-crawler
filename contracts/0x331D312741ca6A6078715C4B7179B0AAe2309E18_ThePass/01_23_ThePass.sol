// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: THE---PASS
/// @author: niftykit.com

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IThePass.sol";
import "./BaseCollection.sol";
import {MultiSaleStorage} from "./MultiSaleStorage.sol";
import {AppStorage} from "./AppStorage.sol";

contract ThePass is
    IThePass,
    BaseCollection,
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981
{
    using MultiSaleStorage for MultiSaleStorage.Layout;
    using AppStorage for AppStorage.Layout;
    using MerkleProof for bytes32[];
    using Strings for uint256;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    modifier onlyPublic(uint256 passSaleId) {
        require(
            MultiSaleStorage.layout().saleActive[passSaleId],
            "Sale not active"
        );
        require(
            !MultiSaleStorage.layout().presaleActive[passSaleId],
            "Presale active"
        );
        _;
    }

    modifier onlyPresale(
        uint256 passSaleId,
        uint256 allowed,
        bytes32[] calldata proof
    ) {
        require(
            MultiSaleStorage.layout().saleActive[passSaleId],
            "Sale not active"
        );
        require(
            MultiSaleStorage.layout().presaleActive[passSaleId],
            "Presale not active"
        );
        bytes32 merkleRoot = AppStorage.layout().merkleRoot;
        require(merkleRoot != "", "Presale not set");
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(_msgSender(), allowed))
            ),
            "Presale invalid"
        );
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address royalty_,
        uint96 royaltyFee_,
        string memory uri_,
        address niftyKit_
    ) ERC1155(uri_) BaseCollection(_msgSender(), niftyKit_) {
        AppStorage.layout().name = name_;
        AppStorage.layout().symbol = symbol_;
        AppStorage.layout().baseURI = uri_;
        _setDefaultRoyalty(royalty_, royaltyFee_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function purchasePass(
        uint256 passSaleId,
        uint256[] calldata passTypeIds,
        uint256[] calldata quantities
    ) external payable onlyPublic(passSaleId) {
        _batchPurchasePasses(
            passSaleId,
            passTypeIds,
            quantities,
            MultiSaleStorage.layout().maxPerMint[passSaleId]
        );
    }

    function presalePurchasePass(
        uint256 passSaleId,
        uint256[] calldata passTypeIds,
        uint256[] calldata quantities,
        bytes32[] calldata proof,
        uint256 allowed
    ) external payable onlyPresale(passSaleId, allowed, proof) {
        uint256 mintAllowed = MultiSaleStorage.layout().maxPerMint[passSaleId];
        _batchPurchasePasses(
            passSaleId,
            passTypeIds,
            quantities,
            mintAllowed <= 0 ? allowed : mintAllowed
        );
    }

    function batchAirdrop(
        uint256 passSaleId,
        uint256[] calldata passTypeIds,
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            recipients.length == passTypeIds.length,
            "Invalid number of recipients"
        );
        require(
            recipients.length == quantities.length,
            "Invalid number of quantities"
        );

        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; ) {
            uint256 passTypeId = passTypeIds[i];
            require(
                AppStorage
                .layout()
                .passesForSaleById[passSaleId][passTypeId].isValue,
                "Pass doesn't exist"
            );
            _mintPass(passSaleId, passTypeId, recipients[i], quantities[i]);
            unchecked {
                i++;
            }
        }
    }

    function startSale(
        uint256 passSaleId,
        uint256[] calldata passTypeIds,
        uint256[] calldata prices,
        uint256[] calldata maxSupplies,
        uint256 newMaxPerMint,
        bool maxPerWallet,
        bool presale
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            !MultiSaleStorage.layout().saleActive[passSaleId],
            "Sale already active"
        );
        require(
            passTypeIds.length == prices.length,
            "Invalid number of prices"
        );
        require(
            prices.length == maxSupplies.length,
            "Invalid number of supplies"
        );

        MultiSaleStorage.layout().saleActive[passSaleId] = true;
        MultiSaleStorage.layout().maxPerMint[passSaleId] = newMaxPerMint;
        MultiSaleStorage.layout().presaleActive[passSaleId] = presale;
        MultiSaleStorage.layout().maxPerWallet[passSaleId] = maxPerWallet;

        uint256 length = passTypeIds.length;
        for (uint256 i = 0; i < length; ) {
            uint256 passTypeId = passTypeIds[i];
            if (
                !AppStorage
                .layout()
                .passesForSaleById[passSaleId][passTypeId].isValue
            ) {
                _createPassOption(
                    passSaleId,
                    passTypeId,
                    prices[i],
                    maxSupplies[i]
                );
            } else {
                _updatePassOption(
                    passSaleId,
                    passTypeId,
                    prices[i],
                    maxSupplies[i]
                );
            }
            unchecked {
                i++;
            }
        }

        emit SaleStarted(passSaleId, newMaxPerMint, presale);
    }

    function stopSale(uint256 passSaleId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            MultiSaleStorage.layout().saleActive[passSaleId],
            "Sale not active"
        );

        MultiSaleStorage.layout().saleActive[passSaleId] = false;
        MultiSaleStorage.layout().presaleActive[passSaleId] = false;

        emit SaleStopped(passSaleId);
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function burn(
        uint256 passTypeId,
        address account,
        uint256 amount
    ) external onlyRole(BURNER_ROLE) {
        _burn(account, passTypeId, amount);
    }

    function setMerkleRoot(bytes32 newRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        AppStorage.layout().merkleRoot = newRoot;
    }

    function updateBaseUri(string memory newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        AppStorage.layout().baseURI = newBaseURI;
    }

    function getPrice(uint256 passSaleId, uint256 passTypeId)
        public
        view
        returns (uint256)
    {
        AppStorage.PassEntry memory pass = AppStorage
            .layout()
            .passesForSaleById[passSaleId][passTypeId];
        require(pass.isValue, "Pass doesn't exist");
        return pass.price;
    }

    function name() public view returns (string memory) {
        return AppStorage.layout().name;
    }

    function symbol() public view returns (string memory) {
        return AppStorage.layout().symbol;
    }

    function maxPerMint(uint256 passSaleId) external view returns (uint256) {
        return MultiSaleStorage.layout().maxPerMint[passSaleId];
    }

    function presaleActive(uint256 passSaleId) external view returns (bool) {
        return MultiSaleStorage.layout().presaleActive[passSaleId];
    }

    function mintCount(uint256 passSaleId, address account)
        external
        view
        returns (uint256)
    {
        return MultiSaleStorage.layout().mintCount[passSaleId][account];
    }

    function saleActive(uint256 passSaleId) external view returns (bool) {
        return MultiSaleStorage.layout().saleActive[passSaleId];
    }

    function saleSupply(uint256 passSaleId) external view returns (uint256) {
        return MultiSaleStorage.layout().saleSupply[passSaleId];
    }

    function _createPassOption(
        uint256 passSaleId,
        uint256 passTypeId,
        uint256 price,
        uint256 maxSupply
    ) internal {
        AppStorage.layout().passesForSaleById[passSaleId][
            passTypeId
        ] = AppStorage.PassEntry({
            price: price,
            maxSupply: maxSupply,
            isValue: true
        });

        emit PassOptionCreated(passSaleId, passTypeId, price);
    }

    function _updatePassOption(
        uint256 passSaleId,
        uint256 passTypeId,
        uint256 newPrice,
        uint256 newMaxSupply
    ) internal {
        AppStorage
        .layout()
        .passesForSaleById[passSaleId][passTypeId].price = newPrice;
        AppStorage
        .layout()
        .passesForSaleById[passSaleId][passTypeId].maxSupply = newMaxSupply;

        emit PassOptionUpdated(passSaleId, passTypeId, newPrice);
    }

    function _batchPurchasePasses(
        uint256 passSaleId,
        uint256[] calldata passTypeIds,
        uint256[] calldata quantities,
        uint256 allowed
    ) internal {
        require(quantities.length == passTypeIds.length, "Invalid quantities");

        uint256 length = quantities.length;
        uint256 totalMinted = 0;
        for (uint256 i = 0; i < length; ) {
            uint256 quantity = quantities[i];
            uint256 passTypeId = passTypeIds[i];
            unchecked {
                i++;
                totalMinted += quantity;
            }
            require(totalMinted <= allowed, "Exceeded max per mint");
            require(
                MultiSaleStorage.layout().maxPerWallet[passSaleId]
                    ? MultiSaleStorage.layout().mintCount[passSaleId][
                        _msgSender()
                    ] +
                        quantity <=
                        allowed
                    : true,
                "Exceeded max per wallet"
            );
            _purchasePass(passSaleId, passTypeId, quantity);
        }
    }

    function _purchasePass(
        uint256 passSaleId,
        uint256 passTypeId,
        uint256 quantity
    ) internal {
        AppStorage.PassEntry memory pass = AppStorage
            .layout()
            .passesForSaleById[passSaleId][passTypeId];
        require(pass.isValue, "Pass doesn't exist");
        require(
            AppStorage.layout().supplyById[passSaleId][passTypeId] + quantity <=
                pass.maxSupply,
            "Max supply reached"
        );
        require(pass.price * quantity <= msg.value, "Value incorrect");

        unchecked {
            MultiSaleStorage.layout().mintCount[passSaleId][
                _msgSender()
            ] += quantity;
        }

        _niftyKit.addFees(msg.value);
        _mintPass(passSaleId, passTypeId, _msgSender(), quantity);
    }

    function _mintPass(
        uint256 passSaleId,
        uint256 passTypeId,
        address to,
        uint256 quantity
    ) internal {
        require(quantity > 0, "Quantity is 0");
        unchecked {
            MultiSaleStorage.layout().saleSupply[passSaleId] += quantity;
            AppStorage.layout().supplyById[passSaleId][passTypeId] += quantity;
        }
        _mint(to, passTypeId, quantity, "");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            bytes(AppStorage.layout().baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        AppStorage.layout().baseURI,
                        tokenId.toString()
                    )
                )
                : AppStorage.layout().baseURI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory passTypeIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(
            operator,
            from,
            to,
            passTypeIds,
            amounts,
            data
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IBaseCollection).interfaceId ||
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }
}