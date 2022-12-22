// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./AllowlistMerkle.sol";
import "./Errors.sol";

contract RuffionReborn is ERC721, ERC721Enumerable, AllowlistMerkle, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for string;


    // ********** State Variables **********
    Counters.Counter private _tokenIdCounter;

    bool public saleIsActive = false;
    bool public allowlistIsActive = false;

    string private _baseURIextended;

    uint256 public constant MAX_PUBLIC_MINT_SUPPLY = 3000;
    uint256 public constant MAX_RESERVE_MINT_SUPPLY = 333;
    uint256 public constant MAX_MINTS_PER_ADDRESS = 3;

    uint256 public mintedPublicSupply;
    uint256 public mintedReserveSupply;

    uint256 public publicPrice = 0.015 ether;

    /// @dev Mapping of created pupper structs from token ID
    mapping(uint256 => Pupper) internal _puppers;

    /// @dev Mapping of pupper trait combinations to a boolean indicate whether the combinations exists
    mapping(uint256 => bool) internal _existMap;


    // ********** Modifiers **********
    modifier publicMintCompliance(uint256 _amount) {
        if ((mintedPublicSupply + _amount) > MAX_PUBLIC_MINT_SUPPLY) revert ExceededMaxPublicSupply();
        _;
    }

    modifier reserveMintCompliance(uint256 _amount) {
        if ((mintedReserveSupply + _amount) > MAX_RESERVE_MINT_SUPPLY) revert ExceededMaxReserveSupply();
        _;
    }


    // ********** Structs **********
    struct Pupper {
        uint256 traits;
    }

    struct PupperTraits {
        uint16 breed;
        uint16 hat;
        uint16 eye;
        uint16 collar;
        uint16 tail;
        uint16 socket;
        uint16 fur;
        uint16 color;
    }


    // ********** Constructor **********
    constructor(address _owner, bytes32 _allowlistMerkleRoot) ERC721("RuffionReborn", "RUFFION") AllowlistMerkle(_allowlistMerkleRoot) {
        transferOwnership(_owner);
    }


    // ********** External Functions **********
    function setBaseURI(string memory baseURI_)
        external
        onlyOwner()
    {
        _baseURIextended = baseURI_;
    }

    function setSaleActiveState(bool state)
        external
        onlyOwner
    {
        saleIsActive = state;
    }

    function setAllowlistActiveState(bool state)
        external
        onlyOwner
    {
        allowlistIsActive = state;
    }

    /**
     * @notice Retrieve a list of pupper traits for a token
     * @param tokenId ID of NFT
     * @dev Permissioning not added because it is only callable once.
     * @return _pupperTraits - indexed list of pupper traits
     */
    function getPupperTraits(uint256 tokenId)
        external
        view
        returns (PupperTraits memory _pupperTraits)
    {
        require(_exists(tokenId), "nonexistent token");
        Pupper memory pupper = _puppers[tokenId];
        _pupperTraits.breed = _unpackUint10(pupper.traits);
        _pupperTraits.hat = _unpackUint10(pupper.traits >> 10);
        _pupperTraits.eye = _unpackUint10(pupper.traits >> 20);
        _pupperTraits.collar = _unpackUint10(pupper.traits >> 30);
        _pupperTraits.tail = _unpackUint10(pupper.traits >> 40);
        _pupperTraits.socket = _unpackUint10(pupper.traits >> 50);
        _pupperTraits.fur = _unpackUint10(pupper.traits >> 60);
        _pupperTraits.color = _unpackUint10(pupper.traits >> 70);
    }

    /**
     * @notice Safely mints 3 NFTs in the public supply (from allowlist).
     * @param traits1 Indexed list of pupper 1 traits (breed, hat, eye, collar, tail, socket, fur, color)
     * @param traits2 Indexed list of pupper 2 traits (breed, hat, eye, collar, tail, socket, fur, color)
     * @param traits3 Indexed list of pupper 3 traits (breed, hat, eye, collar, tail, socket, fur, color)
     */
    function mintAllowlist(bytes32[] calldata _merkleProof, uint256[8] memory traits1, uint256[8] memory traits2, uint256[8] memory traits3)
        external
        payable
        publicMintCompliance(MAX_MINTS_PER_ADDRESS)
        onlyAllowlisted(_merkleProof)
        whenNotPaused
    {
        require(allowlistIsActive, "Allowlist is not active");
        uint256 totalPrice = publicPrice * MAX_MINTS_PER_ADDRESS;
        if (msg.value != totalPrice) revert IncorrectPrice();
        if (balanceOf(msg.sender) == MAX_MINTS_PER_ADDRESS) revert ExceededMaxMintsPerAddress();

        // Mint pupper 1
        _validateTraits(traits1);
        uint256 traitCombo1 = generateTraitCombo(traits1);
        _storeNewPupper(traitCombo1);

        // Mint pupper 2
        _validateTraits(traits2);
        uint256 traitCombo2 = generateTraitCombo(traits2);
        _storeNewPupper(traitCombo2);

        // Mint pupper 3
        _validateTraits(traits3);
        uint256 traitCombo3 = generateTraitCombo(traits3);
        _storeNewPupper(traitCombo3);

        mintedPublicSupply += MAX_MINTS_PER_ADDRESS;
    }

    /**
     * @notice Safely mints 3 NFTs in the public supply.
     * @param traits1 Indexed list of pupper 1 traits (breed, hat, eye, collar, tail, socket, fur, color)
     * @param traits2 Indexed list of pupper 2 traits (breed, hat, eye, collar, tail, socket, fur, color)
     * @param traits3 Indexed list of pupper 3 traits (breed, hat, eye, collar, tail, socket, fur, color)
     */
    function mintPublic(uint256[8] memory traits1, uint256[8] memory traits2, uint256[8] memory traits3)
        external
        payable
        publicMintCompliance(MAX_MINTS_PER_ADDRESS)
        whenNotPaused
    {
        require(saleIsActive, "Public sale is not active");
        uint256 totalPrice = publicPrice * MAX_MINTS_PER_ADDRESS;
        if (msg.value != totalPrice) revert IncorrectPrice();
        if (balanceOf(msg.sender) == MAX_MINTS_PER_ADDRESS) revert ExceededMaxMintsPerAddress();

        // Mint pupper 1
        _validateTraits(traits1);
        uint256 traitCombo1 = generateTraitCombo(traits1);
        _storeNewPupper(traitCombo1);

        // Mint pupper 2
        _validateTraits(traits2);
        uint256 traitCombo2 = generateTraitCombo(traits2);
        _storeNewPupper(traitCombo2);

        // Mint pupper 3
        _validateTraits(traits3);
        uint256 traitCombo3 = generateTraitCombo(traits3);
        _storeNewPupper(traitCombo3);

        mintedPublicSupply += MAX_MINTS_PER_ADDRESS;
    }

    /**
     * @notice Safely mints NFTs in the public supply (only owner).
     * @param batchSize Number of puppers to mint
     * @param traitCombos Array of trait combos
     * @dev Generation of trait combos performed off-chain. Trait validation still performed on-chain.
     */
    function mintPublicOwner(uint256 batchSize, uint256[] memory traitCombos)
        external
        payable
        publicMintCompliance(batchSize)
        onlyOwner
    {
        require(batchSize == traitCombos.length, "Batch size does not match the number of trait combos provided");
        require(saleIsActive, "Public sale is not active");
        uint256 totalPrice = publicPrice * batchSize;
        if (msg.value != totalPrice) revert IncorrectPrice();

        for (uint i=0; i<traitCombos.length; i++) {
            uint256 traitCombo = traitCombos[i];
            uint256[8] memory traits = [
                (uint256)(_unpackUint10(traitCombo)),
                (uint256)(_unpackUint10(traitCombo >> 10)),
                (uint256)(_unpackUint10(traitCombo >> 20)),
                (uint256)(_unpackUint10(traitCombo >> 30)),
                (uint256)(_unpackUint10(traitCombo >> 40)),
                (uint256)(_unpackUint10(traitCombo >> 50)),
                (uint256)(_unpackUint10(traitCombo >> 60)),
                (uint256)(_unpackUint10(traitCombo >> 70))
            ];
            _validateTraits(traits);
            _storeNewPupper(traitCombo);
        }
        mintedPublicSupply += batchSize;
    }

    /**
     * @notice Safely mints NFTs in the reserved supply (only owner).
     * @param batchSize Number of puppers to mint
     * @param traitCombos Array of trait combos
     * @dev Generation of trait combos performed off-chain. Trait validation still performed on-chain.
     */
    function mintReserved(uint256 batchSize, uint256[] memory traitCombos)
        external
        payable
        reserveMintCompliance(batchSize)
        onlyOwner
    {
        require(batchSize == traitCombos.length, "Batch size does not match the number of trait combos provided");

        for (uint i=0; i<traitCombos.length; i++) {
            uint256 traitCombo = traitCombos[i];
            uint256[8] memory traits = [
                (uint256)(_unpackUint10(traitCombo)),
                (uint256)(_unpackUint10(traitCombo >> 10)),
                (uint256)(_unpackUint10(traitCombo >> 20)),
                (uint256)(_unpackUint10(traitCombo >> 30)),
                (uint256)(_unpackUint10(traitCombo >> 40)),
                (uint256)(_unpackUint10(traitCombo >> 50)),
                (uint256)(_unpackUint10(traitCombo >> 60)),
                (uint256)(_unpackUint10(traitCombo >> 70))
            ];
            _validateTraits(traits);
            _storeNewPupper(traitCombo);
        }
        mintedReserveSupply += batchSize;
    }

    /// @notice Sets public price of NFTs.
    /// @dev Sets public price of NFTs.
    function setPublicPrice(uint256 _price)
        external
        onlyOwner
    {
        publicPrice = _price;
    }

    /**
     * @notice Withdraw ether from this contract (only owner may call)
     */
    function withdraw()
        external
        onlyOwner
    {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }


    // ********** Public Functions **********
    function pause()
        public
        onlyOwner
    {
        _pause();
    }

    function unpause()
        public
        onlyOwner
    {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Check whether trait combo is unique
     * @param traitCombo Generated trait combo packed into uint256
     * @return True if combo is unique and available
     */
    function isUnique(uint256 traitCombo)
        public
        view
        returns (bool)
    {
        return !_existMap[traitCombo];
    }

    /**
     * @notice Generates uint256 bitwise trait combo
     * @param _traits Indexed list of pupper traits (breed, hat, eye, collar, tail, socket, fur, color)
     * @dev Each trait is stored in 10 bits
     * @return Trait combo packed into uint256
     */
    function generateTraitCombo(uint256[8] memory _traits)
        public
        pure
        returns (uint256)
    {
        uint256 traits = _traits[0];
        traits |= _traits[1] << 10;
        traits |= _traits[2] << 20;
        traits |= _traits[3] << 30;
        traits |= _traits[4] << 40;
        traits |= _traits[5] << 50;
        traits |= _traits[6] << 60;
        traits |= _traits[7] << 70;
        return traits;
    }


    // ********** Internal Functions **********
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _baseURIextended;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Unpack trait id from trait list
     * @param traits Section within trait combo
     * @return Trait ID
     */
    function _unpackUint10(uint256 traits)
        internal
        pure
        returns (uint16)
    {
        return uint16(traits) & 0x03FF;
    }


    // ********** Private Functions **********
    function _validateTraits(uint256[8] memory traits)
        private
        pure
    {
        require(_isTraitInRange(traits[0], 1, 9), "Breed incorrect");
        require(_isTraitInRange(traits[1], 10, 42), "Hat incorrect");
        require(_isTraitInRange(traits[2], 43, 63), "Eye incorrect");
        require(_isTraitInRange(traits[3], 64, 71), "Collar incorrect");
        require(_isTraitInRange(traits[4], 72, 90), "Tail incorrect");
        require(_isTraitInRange(traits[5], 91, 105), "Socket incorrect");
        require(_isTraitInRange(traits[6], 106, 150), "Fur incorrect");
        require(_isTraitInRange(traits[7], 151, 170), "Color incorrect");
    }

    /**
     * @notice Mints NFT if unique
     * @param traitCombo Trait combo provided from generateTraitCombo
     */
    function _storeNewPupper(uint256 traitCombo)
        private
    {
        require(isUnique(traitCombo), "Trait combination already exists");
        _existMap[traitCombo] = true;
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        Pupper memory newPupper;
        newPupper.traits = traitCombo;
        _puppers[tokenId] = newPupper;
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Checks whether trait id is in range of lower/upper bounds
     * @param lower lower range-bound
     * @param upper upper range-bound
     * @return True if in range
     */
    function _isTraitInRange(uint256 trait, uint256 lower, uint256 upper)
        private
        pure
        returns (bool)
    {
        return (trait >= lower && trait <= upper);
    }
}