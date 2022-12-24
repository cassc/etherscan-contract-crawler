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

contract ShibaDogeArmyV1 is ERC1155SupplyUpgradeable, Ownable2StepUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    string public name;
    string public contractURI;

    address public signerAddress;
    address constant ALL_TRAITS_INVENTORY = address(0x69);

    mapping(uint256 => bool) public DogeParentUsed;
    mapping(uint256 => bool) public ShibaParentUsed;

    IERC721 public DogeArmy;
    IERC721 public ShibaArmy;

    uint256 public NFTSupply;
    uint256 constant public NFTMaxSupply = 10000;

    mapping(uint256 => uint24[15]) nftTraitsArray;

    mapping(uint256 => uint256) public NFTEquipmentLockTime;

    bool[15] slotCanBeEmpty;

    // This is for the EFT Slot function. We store all equipped EFTs as 24 byte IDs. The first 4 bytes determine which slot the EFT can be equipped in, so to get there we need to discard the last 20 bytes.
    uint8 constant ID_SHIFT_MODIFIER = 20;

    // The largest uint24 value, if we mint an EFT larger than this it will interfere with the slot identifier
    uint256 constant MAX_EFT_VALUE  = 16777215;

    bool public traits_initialized;

    uint256 public freeMintMaxAmount;
    uint256 public freeMintID;
    bool public freeMintEnabled;

    mapping(uint256 => mapping(address => bool)) public freeMintClaimed;


    error NFTCannotBeEquippedAsEFT(uint256 id);

    error OverSupply(uint256 numToMint, uint256 NFTSupply);
    error SignatureExpired(uint256 validUntil, uint256 currentTimestamp);

    error DogeParentAlreadyUsed(uint256 id);
    error ShibaParentAlreadyUsed(uint256 id);

    event EFT_Equipped(address nftOwner, uint256 nftID, uint256 eftID);
    event EFT_Unequipped(address nftOwner, uint256 nftID, uint256 eftID);

    event ShibaDogeArmyMinted(uint256 ShibaDogeArmyID, uint256 DogeArmyParentID, uint256 ShibaArmyParentID, uint24[15] traits);
    event EFTMinted(address minter, uint256 id);

    event NFTEquipmentLocked(uint256 nftID, uint256 lockTime);

    event BaseURIUpdated(string _newBaseURI);

    function initialize(string memory _name, 
        string memory _uri, 
        string memory _contractUri, 
        IERC721 _DogeArmy, 
        IERC721 _ShibaArmy)
        public initializer {

            name      = _name;
            DogeArmy  = _DogeArmy;
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
    function freeMint(uint256 validUntil, bytes calldata data) external whenNotPaused {
        require(freeMintEnabled);
        require(totalSupply(freeMintID) < freeMintMaxAmount);
        require(!freeMintClaimed[freeMintID][msg.sender]);
        require(_validateMintSignature(data, msg.sender, freeMintID, validUntil));
        freeMintClaimed[freeMintID][msg.sender] = true;
        _mintEFT(msg.sender, freeMintID, 1, data);
    }

    // Determines the trait slot of any given EFT by bitshifting away the last 20 bytes. Slot 0 can't be used, as that's where NFTs will live. We then subtract 1 so that traits can be stored at index 0 in an array.
    // This requires all IDs to fit within a uint24 data structure.
    function determineTraitSlot(uint256 id) public pure returns (uint256) {
        uint256 slot = (id >> ID_SHIFT_MODIFIER);
        // eft can't be another nft;
        if(slot == 0){
            revert NFTCannotBeEquippedAsEFT(id);
        }
        return slot - 1;
    }

    // INTERNAL FUNCTIONS

    // Internal function to mint EFTs. Blocks access to mint tokens under id 10000, as these will be reserved for NFTs.
    function _mintEFT(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        require(id > 10000);
        if(balanceOf(ALL_TRAITS_INVENTORY, id) == 0){
            _mint(ALL_TRAITS_INVENTORY, id, 1, data);
        }
        _mint(to, id, amount, data);
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

    function setContractURI(string calldata _newContractURI) external onlyOwner {
        contractURI = _newContractURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // For use by project owner to create new EFTs for sale on marketplaces
    function mintEFT(uint256 id, uint256 amount, bytes calldata data) external onlyOwner whenNotPaused {
        _mintEFT(msg.sender, id, amount, data);
    }

    // For use by project owner to send EFTs to users
    function reserveEFT(address recipient, uint256 id, uint256 amount, bytes calldata data) external onlyOwner whenNotPaused {
        _mintEFT(recipient, id, amount, data);
    }

    // IDS MUST ALL BE OVER 10000
    function _initializeTraitsInventory(uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external onlyOwner {
        require(!traits_initialized);
        traits_initialized = true;
        _mintBatch(ALL_TRAITS_INVENTORY, ids, amounts, data);
    }

}