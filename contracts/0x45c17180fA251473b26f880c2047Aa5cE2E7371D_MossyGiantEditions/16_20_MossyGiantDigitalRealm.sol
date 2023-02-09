// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MossyGiantEditions
 * MossyGiantEditions - an 1155 contract for  TheReeferRascals
 */
contract MossyGiantEditions is
    ERC1155Supply,
    ERC2981,
    DefaultOperatorFilterer,
    Ownable
{
    using Strings for string;
    string public name;
    string public symbol;

    string public baseURI =
        "https://mother-plant.s3.amazonaws.com/mossygianteditions/metadata/";

    IERC721A public motherplantNFT;

    // Item data
    struct itemData {
        uint256 maxSupply;
        bool claimIdActive;
        bool onlyWhitelist;
        bool burnable;
    }
    mapping(uint256 => itemData) public idStats;

    // Public claim reqs &  tracker
    mapping(uint256 => mapping(uint256 => bool)) public publicClaimedId;
    bool public publicClaimIsActive = false;

    // WL claim reqs & tracker
    mapping(uint256 => mapping(uint256 => bool)) public whitelistClaimedId;
    mapping(uint256 => bool) public isNightMotherPlant;
    bool public whitelistClaimIsActive = false;

    //Burning
    bool public burningIsActive = false;

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        address payable royaltiesReceiver,
        address motherplantAddress
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
        motherplantNFT = IERC721A(motherplantAddress);
        setRoyaltyInfo(royaltiesReceiver, 750);
    }

    function createItem(
        uint256 _id,
        uint256 _maxSupply,
        bool _claimIdActive,
        bool _onlyWhitelist,
        bool _burnable
    ) external onlyOwner {
        idStats[_id].maxSupply = _maxSupply;
        idStats[_id].claimIdActive = _claimIdActive;
        idStats[_id].onlyWhitelist = _onlyWhitelist;
        idStats[_id].burnable = _burnable;
    }

    function setNightMotherPlants(
        uint256 _id,
        bool _isNightMotherPlant
    ) external onlyOwner {
        isNightMotherPlant[_id] = _isNightMotherPlant;
    }

    function ownedMotherPlants(
        address _address
    ) public view returns (uint256[] memory _ids) {
        uint256 nftBalance = motherplantNFT.balanceOf(_address);
        uint256[] memory ownedIds = new uint256[](nftBalance);
        uint256 totalSupply = motherplantNFT.totalSupply();
        uint256 j = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (motherplantNFT.ownerOf(i) == _address) {
                ownedIds[j] = i;
                j++;
            }
        }
        return ownedIds;
    }

    function nightMotherPlantBalance(
        address _address
    ) public view returns (uint256 _nightMotherPlantBalance) {
        uint256[] memory _ownedMotherPlants = ownedMotherPlants(_address);
        uint256 balance = 0;
        for (uint256 i = 0; i < _ownedMotherPlants.length; i++) {
            if (isNightMotherPlant[_ownedMotherPlants[i]]) {
                balance += 1;
            }
        }
        return balance;
    }

    function ownedNightMotherPlants(
        address _address
    ) public view returns (uint256[] memory _ownedNight) {
        uint256[] memory _ownedMotherPlants = ownedMotherPlants(_address);
        uint256 _nightMotherPlantBalance = nightMotherPlantBalance(_address);
        uint256[] memory _ownedNightMotherPlants = new uint256[](
            _nightMotherPlantBalance
        );

        uint256 j = 0;
        for (uint256 i = 0; i < _ownedMotherPlants.length; i++) {
            if (isNightMotherPlant[_ownedMotherPlants[i]]) {
                _ownedNightMotherPlants[j] = _ownedMotherPlants[i];
                j++;
            }
        }
        return _ownedNightMotherPlants;
    }

    function whitelistClaimsAvailable(
        address _address,
        uint256 _id
    ) public view returns (uint256 _claimsAvailable) {
        uint256[] memory ownedIds = ownedNightMotherPlants(_address);
        uint256 mintsAvailable = 0;
        for (uint256 i = 0; i < ownedIds.length; i++) {
            if (!whitelistClaimedId[ownedIds[i]][_id]) {
                mintsAvailable += 1;
            }
        }
        return mintsAvailable;
    }

    function publicClaimsAvailable(
        address _address,
        uint256 _id
    ) public view returns (uint256 _claimsAvailable) {
        uint256[] memory ownedIds = ownedMotherPlants(_address);
        uint256 mintsAvailable = 0;
        for (uint256 i = 0; i < ownedIds.length; i++) {
            if (!publicClaimedId[ownedIds[i]][_id]) {
                mintsAvailable += 1;
            }
        }
        return mintsAvailable;
    }

    function publicClaim(uint256 _id, uint256 _quantity) external {
        require(publicClaimIsActive, "Claim is not active.");
        require(
            idStats[_id].claimIdActive,
            "Sale not available for this item now."
        );
        require(
            !idStats[_id].onlyWhitelist,
            "This item is only available for whitelisted users."
        );
        require(
            totalSupply(_id) + _quantity <= idStats[_id].maxSupply,
            "Minting limit reached."
        );
        uint256[] memory ownedIds = ownedMotherPlants(msg.sender);
        uint256 mintsAvailable = 0;
        for (uint256 i = 0; i < ownedIds.length; i++) {
            if (!publicClaimedId[ownedIds[i]][_id]) {
                mintsAvailable += 1;
            }
        }
        // uint256 mintsAvailable = claimsAvailable(msg.sender, _id);
        require(mintsAvailable > 0, "No more claims available.");
        require(
            _quantity <= mintsAvailable,
            "Quantity exceeded available mints."
        );
        uint256 limit = _quantity;
        for (uint256 i = 0; limit > 0; i++) {
            if (!publicClaimedId[ownedIds[i]][_id]) {
                publicClaimedId[ownedIds[i]][_id] = true;
                limit--;
            }
        }
        _mint(msg.sender, _id, _quantity, "");
    }

    function whitelistClaim(uint256 _id, uint256 _quantity) external {
        require(whitelistClaimIsActive, "Whitelist not active.");
        require(
            idStats[_id].onlyWhitelist,
            "This item is only available for whitelisted users."
        );
        require(
            idStats[_id].claimIdActive,
            "Sale not available for this item now."
        );
        require(
            totalSupply(_id) + _quantity <= idStats[_id].maxSupply,
            "Minting limit reached."
        );
        uint256[] memory ownedIds = ownedNightMotherPlants(msg.sender);
        uint256 mintsAvailable = 0;
        for (uint256 i = 0; i < ownedIds.length; i++) {
            if (!whitelistClaimedId[ownedIds[i]][_id]) {
                mintsAvailable += 1;
            }
        }
        // uint256 mintsAvailable = claimsAvailable(msg.sender, _id);
        require(mintsAvailable > 0, "No more claims available");
        require(
            _quantity <= mintsAvailable,
            "Quantity exceeded available mints"
        );
        uint256 limit = _quantity;
        for (uint256 i = 0; limit > 0; i++) {
            if (!whitelistClaimedId[ownedIds[i]][_id]) {
                whitelistClaimedId[ownedIds[i]][_id] = true;
                limit--;
            }
        }
        _mint(msg.sender, _id, _quantity, "");
    }

    function airdrop(
        address _address,
        uint256 _id,
        uint256 _quantity
    ) external onlyOwner {
        // Meant to be sent all at once to the holders for a public claim.
        uint256[] memory ownedIds = ownedMotherPlants(_address);
        uint256 mintsAvailable = 0;
        for (uint256 i = 0; i < ownedIds.length; i++) {
            if (!publicClaimedId[ownedIds[i]][_id]) {
                mintsAvailable += 1;
                publicClaimedId[ownedIds[i]][_id] = true;
            }
        }
        require(mintsAvailable > 0, "No more claims available");
        require(
            _quantity <= mintsAvailable,
            "Quantity exceeded available mints"
        );
        require(
            totalSupply(_id) + _quantity <= idStats[_id].maxSupply,
            "Minting limit reached."
        );
        _mint(_address, _id, _quantity, "");
    }

    function burn(uint256 id, uint256 amount) public {
        require(burningIsActive, "Burning not available");
        require(idStats[id].burnable, "Burning not allowed for this item");
        _burn(msg.sender, id, amount);
    }

    function setClaimIdActive(bool _idActive, uint256 _id) external onlyOwner {
        idStats[_id].claimIdActive = _idActive;
    }

    function setMaxSupply(uint256 _maxSupply, uint256 _id) external onlyOwner {
        idStats[_id].maxSupply = _maxSupply;
    }

    function setOnlyWhitelist(
        bool _onlyWhitelist,
        uint256 _id
    ) external onlyOwner {
        idStats[_id].onlyWhitelist = _onlyWhitelist;
    }

    function setBurnable(bool _burnable, uint256 _id) external onlyOwner {
        idStats[_id].burnable = _burnable;
    }

    function flipPublicClaimState() external onlyOwner {
        publicClaimIsActive = !publicClaimIsActive;
    }

    function flipWhitelistClaimState() external onlyOwner {
        whitelistClaimIsActive = !whitelistClaimIsActive;
    }

    function flipBurningState() external onlyOwner {
        burningIsActive = !burningIsActive;
    }

    function withdraw() external onlyOwner {
        (bool rr, ) = payable(0xad8076DcaC7d6FA6F392d24eE225f4d715FAa363).call{
            value: address(this).balance
        }("");
        require(rr, "Transfer failed");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "ERC1155: NONEXISTENT_TOKEN");
        return (
            string(abi.encodePacked(baseURI, Strings.toString(_id), ".json"))
        );
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // IERC2981
    function setRoyaltyInfo(
        address payable receiver,
        uint96 numerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }
}