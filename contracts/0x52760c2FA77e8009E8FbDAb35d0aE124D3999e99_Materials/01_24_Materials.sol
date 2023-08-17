// SPDX-License-Identifier: MIT
// @ Fair.xyz dev

pragma solidity 0.8.17;

import "PausableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "MerkleProofUpgradeable.sol";
import "ERC1155xyzUpgradeable.sol";
import "IMutantHounds.sol";
import "IMaterials.sol";

contract Materials is IMaterials, ERC1155xyzUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {

    mapping(uint256 => string) internal uriMapping;

    address constant houndsContractAddress = 0x354634c4621cDfb7a25E6486cCA1E019777D841B;

    uint256 internal materialsCycle;
    
    // Token name
    string public name;

    // Token symbol
    string public symbol;

    mapping(uint256 => SaleStage) public saleStages;

    constructor() {
        _disableInitializers();
    }

    /*///////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _isOperatorFilterAdmin(address operator) override internal view returns (bool) {
        if(!(owner() == operator)) revert NotOwner();
    }

    /*///////////////////////////////////////////////////////////////
                               PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initialise the contract
     */
    function initialize(
        address royaltyReceiver,
        uint96 royaltyPercentage,
        string memory name_,
        string memory symbol_,
        address DEFAULT_OPERATOR_FILTER_REGISTRY,
        address DEFAULT_OPERATOR_FILTER_SUBSCRIPTION
    ) public initializer {
        __ERC1155_init();
        __Pausable_init();
        __OperatorFilterer_init(
            DEFAULT_OPERATOR_FILTER_REGISTRY,
            DEFAULT_OPERATOR_FILTER_SUBSCRIPTION,
            true
        );
        __Ownable_init();
        _setDefaultRoyalty(royaltyReceiver, royaltyPercentage);
        name = name_;
        symbol = symbol_;
    }

     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155xyzUpgradeable, IMaterials) returns (bool) {
        return interfaceId == type(IERC1155Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                              EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IMaterials-burn2Redeem}.
     */
    function burn2Redeem(
        uint256[] memory tokenIds, 
        uint256 saleId, 
        bytes32[] calldata _merkleProof
    ) public override whenNotPaused {

        SaleStage memory stage = saleStages[saleId];

        if(stage.startTime == 0) revert InvalidStageTime();

        if (stage.merkleRoot != bytes32(0)) {
            if(!_verifyMerkleAddress(_merkleProof, stage.merkleRoot, msg.sender, saleId)) revert IncorrectProof();
        }

        if(stage.startTime >= block.timestamp) revert InvalidStageTime();

        uint256 length = tokenIds.length;
        if(length <= 0) revert NoTokenIdsSpecified();

        IMutantHounds(houndsContractAddress).materialsBurn(tokenIds, msg.sender);

        uint256 roundsClaimed = length / 4;
        uint256 roundsModulus = length % 4;

        uint256 materialsCycle_ = materialsCycle;
        uint256 i = materialsCycle_;

        if(roundsClaimed > 0) {
            do {
                _mint(msg.sender, i % 4 + 1, roundsClaimed, "");
                unchecked { ++i; }
            } while (i < materialsCycle_ + 4);
        }

        uint256 additionalRounds = i + roundsModulus;
        if(roundsModulus > 0) {
            do {
                _mint(msg.sender, i % 4 + 1, 1, "");
                unchecked { ++i; }
            } while (i < additionalRounds);
        }
        unchecked {
            materialsCycle = (materialsCycle_ + length) % 4;
        }
    }

    /**
     * @dev See {IMaterials-changeSecondaryRoyaltyReceiver}.
     */
    function changeSecondaryRoyaltyReceiver(
        address newSecondaryRoyaltyReceiver,
        uint96 newRoyaltyValue
    ) external override onlyOwner {
        _setDefaultRoyalty(newSecondaryRoyaltyReceiver, newRoyaltyValue);
        emit NewSecondaryRoyalties(newSecondaryRoyaltyReceiver, newRoyaltyValue);
    }

    /**
     * @dev See {IMaterials-pause}.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @dev See {IMaterials-setSaleStage}.
     */
    function setSaleStage(
        uint256 id, 
        SaleStage memory stage
    ) external override onlyOwner {
        saleStages[id] = stage;
    }

    /**
     * @dev See {IMaterials-setUri}.
     */
    function setUri(
        uint256 id, 
        string memory newURI
    ) external override onlyOwner {
        uriMapping[id] = newURI;
    }

    /**
     * @dev See {IMaterials-unpause}.
     */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev See {IMaterials-VIPAirdrop}.
     */
    function VIPAirdrop(
        address[] memory VIPs, 
        uint256 amount
    ) external override onlyOwner {
        uint256 length = VIPs.length;
        if(length <= 0) revert NoRecipients();
        uint256 i;
        do {
            _mint(VIPs[i], 5, amount, "");
            unchecked { ++i; }
        } while (i < length);
    }

    /**
     * @dev See {IMaterials-uri}.
     */
    function uri(uint256 id) external view override(IERC1155MetadataURIUpgradeable, IMaterials) returns(string memory) {
        return uriMapping[id];
    }

    /*///////////////////////////////////////////////////////////////
                               PRIVATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Verify merkle proof for address and the ID of the sale
     */
    function _verifyMerkleAddress(
        bytes32[] calldata merkleProof,
        bytes32 _merkleRoot,
        address minterAddress,
        uint256 saleId
    ) private pure returns (bool) {
        return MerkleProofUpgradeable.verify(
            merkleProof,
            _merkleRoot,
            keccak256(bytes.concat(keccak256(abi.encode(minterAddress, saleId))))
        );
    }

}