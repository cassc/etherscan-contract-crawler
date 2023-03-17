// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ShibaDogeArmy_V1_1 is
    ERC1155SupplyUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using AddressUpgradeable for address;

    string public name;
    string public contractURI;

    address public signerAddress;
    address constant ALL_TRAITS_INVENTORY = address(69);

    mapping(uint256 => bool) public DogeParentUsed;
    mapping(uint256 => bool) public ShibaParentUsed;

    IERC721 public DogeArmy;
    IERC721 public ShibaArmy;

    uint256 public NFTSupply;
    uint256 public constant NFTMaxSupply = 10000;

    mapping(uint256 => uint24[15]) nftTraitsArray;

    mapping(uint256 => uint256) public NFTEquipmentLockTime;

    bool[15] public slotCanBeEmpty;

    // This is for the EFT Slot function. We store all equipped EFTs as 24 byte IDs. The first 4 bytes determine which slot the EFT can be equipped in, so to get there we need to discard the last 20 bytes.
    uint8 constant ID_SHIFT_MODIFIER = 20;

    // The largest uint24 value, if we mint an EFT larger than this it will interfere with the slot identifier
    uint256 constant MAX_EFT_VALUE = 16777215;

    bool public traits_initialized; // vestigial, memory slot may be reused for something else later if needed

    uint256 public freeMintMaxAmount;
    uint256 public freeMintID;
    bool public freeMintEnabled;

    mapping(uint256 => mapping(address => bool)) public freeMintClaimed;

    error NFTCannotBeEquippedAsEFT(uint256 id);

    error OverSupply(uint256 numToMint, uint256 NFTSupply);
    error SignatureExpired(uint256 validUntil, uint256 currentTimestamp);

    error DogeParentAlreadyUsed(uint256 id);
    error ShibaParentAlreadyUsed(uint256 id);

    event EFT_Equipped(address indexed nftOwner, uint256 indexed nftID, uint256 indexed eftID);
    event EFT_Unequipped(address indexed nftOwner, uint256 indexed nftID, uint256 indexed eftID);

    event ShibaDogeArmyMinted(
        uint256 indexed ShibaDogeArmyID,
        uint256 indexed DogeArmyParentID,
        uint256 indexed ShibaArmyParentID,
        uint24[15] traits
    );
    event EFTMinted(address indexed minter, uint256 indexed id);

    event NFTEquipmentLocked(uint256 indexed nftID, uint256 indexed lockTime);

    event BaseURIUpdated(string _newBaseURI);

    function initialize(
        string memory _name,
        string memory _uri,
        string memory _contractUri,
        IERC721 _DogeArmy,
        IERC721 _ShibaArmy
    ) public initializer {
        name = _name;
        DogeArmy = _DogeArmy;
        ShibaArmy = _ShibaArmy;
        contractURI = _contractUri;

        NFTSupply = 0;

        // call parent initializers
        __ERC165_init();
        __ReentrancyGuard_init();
        __ERC1155_init(_uri);
        __ERC1155Supply_init();
        __Pausable_init();
        __Ownable2Step_init();

        // frontend signing address
        signerAddress = 0x5aBEF98fdD9a83B1c8C90224F86673959C19C701;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // Free mint system. This function is for the owner of the contract to launch a new Free Mint campaign. Only 1 campaign can be active at a time, and each address can only claim a token type 1 time.
    function launchFreeMint(uint256 maxAmount, uint256 id) external onlyOwner {
        require(!freeMintEnabled);
        freeMintMaxAmount = maxAmount + 1;
        freeMintID = id;
        freeMintEnabled = true;
    }

    // Function for owner to disable free mints.
    function disableFreeMint() external onlyOwner {
        freeMintEnabled = false;
    }

    // Free Mint function for users. validUntil is the expiry date for the signature, and data is the signature. Data is also used as the datablob for safeTransfer.
    function freeMint(
        uint256 validUntil,
        bytes calldata data
    ) external whenNotPaused {
        require(freeMintEnabled);
        require(totalSupply(freeMintID) < freeMintMaxAmount);
        require(!freeMintClaimed[freeMintID][msg.sender]);
        require(
            _validateMintSignature(data, msg.sender, freeMintID, validUntil)
        );
        freeMintClaimed[freeMintID][msg.sender] = true;
        _mintEFT(msg.sender, freeMintID, 1, data);
    }

    function mintNFT(
        bytes calldata signature,
        uint24[15] calldata traits,
        uint256 dogeParentID,
        uint256 shibaParentID,
        uint256 validUntil,
        bytes calldata data
    ) external whenNotPaused {
        // Don't mint over the maximum
        require(NFTSupply < NFTMaxSupply);

        // verify ownership of parents
        require(DogeArmy.ownerOf(dogeParentID) == msg.sender);
        require(ShibaArmy.ownerOf(shibaParentID) == msg.sender);

        // verify breeding status
        if (DogeParentUsed[dogeParentID]) {
            revert DogeParentAlreadyUsed(dogeParentID);
        }

        if (ShibaParentUsed[shibaParentID]) {
            revert ShibaParentAlreadyUsed(shibaParentID);
        }

        // set parents as used
        DogeParentUsed[dogeParentID] = true;
        ShibaParentUsed[shibaParentID] = true;

        // verify signature

        require(
            _validateSignature(
                signature,
                dogeParentID,
                shibaParentID,
                traits,
                validUntil
            ),
            "Invalid data provided"
        );

        NFTSupply += 1;

        _mint(msg.sender, NFTSupply, 1, data);

        applyMintedTraits(NFTSupply, traits);

        emit ShibaDogeArmyMinted(
            NFTSupply,
            dogeParentID,
            shibaParentID,
            traits
        );
    }

    function equipEFT(
        uint256 nftId,
        uint256 eftId,
        bytes calldata data
    ) public whenNotPaused {
        require(balanceOf(msg.sender, eftId) > 0);
        require(nftId <= 10000);
        require(NFTEquipmentLockTime[nftId] < block.timestamp);
        // make sure they have the EFT to equip
        require(eftId > 2 ** 20);

        // either they need to approve the contract, or we can overwrite the approval function to always allow the contract

        // burn or transfer EFT to contract, not sure which yet
        _burn(msg.sender, eftId, 1);

        // check what is equipped in slot
        uint24 currentlyEquipped;
        uint eftslot = determineTraitSlot(eftId);

        // if not an equippable, revert
        if (eftslot > 15) {
            revert NFTCannotBeEquippedAsEFT(eftId);
        }

        currentlyEquipped = nftTraitsArray[nftId][eftslot];

        // equip the new eft
        nftTraitsArray[nftId][eftslot] = uint24(eftId);

        // if there's nothing equipped, don't mint;
        if (currentlyEquipped != 0) {
            // mint or transfer the currently minted token
            _mintEFT(msg.sender, currentlyEquipped, 1, data);
        }

        emit EFT_Equipped(msg.sender, nftId, eftId);
    }

    function unequipEFT(
        uint256 nftId,
        uint256 eftId,
        bytes calldata data
    ) public whenNotPaused {
        require(balanceOf(msg.sender, nftId) > 0);
        require(nftId <= 10000);
        require(NFTEquipmentLockTime[nftId] < block.timestamp);

        // Check which slot the EFT goes in
        uint eftslot = determineTraitSlot(eftId);

        // if not an equippable, revert
        if (eftslot > 15) {
            revert NFTCannotBeEquippedAsEFT(eftId);
        }

        // Validate that the slot can be empty
        require(slotCanBeEmpty[eftslot]);

        // Validate that the eft is actually is equipped
        require(nftTraitsArray[nftId][eftslot] == eftId);

        // update token equipment
        nftTraitsArray[nftId][eftslot] = 0;

        // mint eft to msg.sender
        _mintEFT(msg.sender, eftId, 1, data);

        emit EFT_Unequipped(msg.sender, nftId, eftId);
    }

    function multiEquipEFT(
        uint256 nftId,
        uint256[] calldata eftIds,
        bytes calldata data
    ) public whenNotPaused {
        for (uint256 index = 0; index < eftIds.length; index++) {
            equipEFT(nftId, eftIds[index], data);
        }
    }

    function multiUnequipEFT(
        uint256 nftId,
        uint256[] calldata eftIds,
        bytes calldata data
    ) public whenNotPaused {
        for (uint256 index = 0; index < eftIds.length; index++) {
            unequipEFT(nftId, eftIds[index], data);
        }
    }

    function batchEquipmentChange(
        uint256 nftId,
        uint256[] calldata unequipIds,
        uint256[] calldata equipIds,
        bytes calldata data
    ) external whenNotPaused {
        multiUnequipEFT(nftId, unequipIds, data);
        multiEquipEFT(nftId, equipIds, data);

        emit URI(uri(nftId), nftId);
    }

    // to avoid frontrunning sales with an unequip call
    // should probably come up with some way to remove this lock after a sale. Maybe we edit the unlock block to a later block whenever the NFT is transferred?
    function lockNFTEquipmentForSale(
        uint256 tokenID,
        uint256 lockTime
    ) external whenNotPaused {
        require(tokenID <= 10000); // must be NFT and not EFT
        require(balanceOf(msg.sender, tokenID) > 0); // caller must own NFT
        require(lockTime > block.timestamp); // must be set for a later time than now
        require(lockTime > NFTEquipmentLockTime[tokenID]); // must be set for a later time than previously set
        NFTEquipmentLockTime[tokenID] = lockTime;

        emit NFTEquipmentLocked(tokenID, lockTime);
    }

    function viewNFTTraitsArray(
        uint256 id
    ) external view returns (uint24[15] memory) {
        require(id < NFTMaxSupply);
        return (nftTraitsArray[id]);
    }

    // The maximum id of an EFT. (4 bits for slot, 20bits for individual id). Used for detecting non-equippable tokens
    uint256 constant MAX_EFT_ID_VALUE = 2 ** 24;

    // Determines the trait slot of any given EFT by bitshifting away the last 20 bytes. Slot 0 can't be used, as that's where NFTs will live. We then subtract 1 so that traits can be stored at index 0 in an array.
    // This requires all IDs to fit within a uint24 data structure.
    function determineTraitSlot(uint256 id) public pure returns (uint256) {
        uint256 slot = (id >> ID_SHIFT_MODIFIER);

        // if an NFT (id <= 10000), return slot 16. Ensure that this is checked by the caller to the function to handle this
        if (slot == 0) {
            return 16;
            // revert NFTCannotBeEquippedAsEFT(id);
        }

        // check that this is not in the ID range used for non-equippable Fungible Tokens, returns slot 17 if so. Ensure that this is checked by the caller to the function to handle this
        if (id > MAX_EFT_ID_VALUE) {
            return 17;
        }

        return slot - 1;
    }

    // INTERNAL FUNCTIONS

    // not in v1
    function applyMintedTraits(
        uint256 tokenID,
        uint24[15] calldata traits
    ) internal {
        require(traits.length == 15);
        nftTraitsArray[tokenID] = traits;
    }

    // Internal function to mint EFTs. Blocks access to mint tokens under id 10000, as these will be reserved for NFTs.
    function _mintEFT(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        require(id > 10000);
        if (balanceOf(ALL_TRAITS_INVENTORY, id) == 0) {
            _mint(ALL_TRAITS_INVENTORY, id, 1, data);
        }
        _mint(to, id, amount, data);
    }

    // not in v1
    function _validateSignature(
        bytes calldata signature,
        uint256 dogeParentID,
        uint256 shibaParentID,
        uint24[15] calldata traits,
        uint256 validUntil
    ) internal view returns (bool) {
        if (block.timestamp > validUntil) {
            return false;
        }
        bytes32 dataHash = keccak256(
            abi.encodePacked(dogeParentID, shibaParentID, traits, validUntil)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) &&
            receivedAddress == signerAddress);
    }

    function _validateMintSignature(
        bytes calldata signature,
        address receiver,
        uint256 tokenID,
        uint256 validUntil
    ) internal view returns (bool) {
        if (block.timestamp > validUntil) {
            return false;
        }
        bytes32 dataHash = keccak256(
            abi.encodePacked(receiver, tokenID, validUntil)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) &&
            receivedAddress == signerAddress);
    }

    // OWNER FUNCTIONS

    function updateSignerAddress(address _signer) public onlyOwner {
        signerAddress = _signer;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _setURI(_newBaseURI);
        emit BaseURIUpdated(_newBaseURI);
    }

    function setContractURI(
        string calldata _newContractURI
    ) external onlyOwner {
        contractURI = _newContractURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // not in v1
    function modifySlotsCanBeEmpty(
        bool[15] calldata GobbledygoolBobbledyBools
    ) external onlyOwner {
        slotCanBeEmpty = GobbledygoolBobbledyBools;
    }

    // For use by project owner to create new EFTs for sale on marketplaces
    function mintEFT(
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyOwner whenNotPaused {
        _mintEFT(msg.sender, id, amount, data);
    }

    // For use by project owner to send EFTs to users
    function reserveEFT(
        address recipient,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyOwner whenNotPaused {
        _mintEFT(recipient, id, amount, data);
    }

    // IDS MUST ALL BE OVER 10000
    // THIS WILL SERIOUSLY BREAK IF NOT DONE CORRECTLY
    function _initializeTraitsInventory(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyOwner {
        _mintBatch(ALL_TRAITS_INVENTORY, ids, amounts, data);
    }

    function updateArmyAddresses(
        address doge,
        address shiba
    ) external onlyOwner {
        DogeArmy = IERC721(doge);
        ShibaArmy = IERC721(shiba);
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        // Unlock traits of NFTs 24 hours after being transferred
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] <= NFTMaxSupply) {
                if (NFTEquipmentLockTime[ids[i]] > block.timestamp) {
                    uint256 newLockTime = block.timestamp + 24 hours;
                    // unlock the NFT in 24 hours
                    NFTEquipmentLockTime[ids[i]] = newLockTime;
                    emit NFTEquipmentLocked(ids[i], newLockTime);
                }
            }
        }
    }
}