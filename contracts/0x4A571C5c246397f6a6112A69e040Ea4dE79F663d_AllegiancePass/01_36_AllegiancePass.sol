// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/utils/Base64Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./lib/FragmentERC721EnumerableUpgradeable.sol";
import "./lib/FragmentSignedRedeemerUpgradeable.sol";
import "./lib/IDelegationRegistry.sol";
import "./lib/IWarmWallet.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract AllegiancePass is FragmentERC721EnumerableUpgradeable, FragmentSignedRedeemerUpgradeable {
    using StringsUpgradeable for uint256;
    using Base64Upgradeable for string;

    uint256 public constant MAX_SUPPLY_PER_TYPE = 2500; 
    uint8 public constant LAB = 0;
    uint8 public constant PATH = 1;

    uint256 public publicMintPrice;
    uint256 public maxPublicSale;

    string public labImage;
    string public labAnimation;
    string public pathImage;
    string public pathAnimation;

    mapping(uint8 => uint256) public totalMinted;
    mapping(address => uint256) public publicMinted;
    mapping(address => bool) public allowlistMinted;
    mapping(uint256 => bool) private keycardMinted;

    mapping(uint256 => uint8) public passTypes;

    bool public isAllowlistActive;
    bool public isKeycardMintActive;
    bool public isPublicSaleActive;

    address public keycardsContractAddress;

    IDelegationRegistry public delegateCash;
    IWarmWallet public warmWallet;

    error AllowlistMinted();
    error KeycardMinted();
    error InvalidKeycardOwnership();
    error InvalidKeycard();
    error InvalidPassType();
    error InvalidPayment();
    error InvalidQuantity();
    error InvalidSignature();
    error MintInactive();
    error OnlyEOA();

    event AllowlistActive(bool indexed isAllowlistActive);
    event KeycardMintActive(bool indexed isKeycardMintActive);
    event PublicSaleActive(bool indexed isPublicSaleActive);
    event PassMinted(uint256 indexed tokenID, uint8 indexed typeId, address minter);

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        address signer_,
        address keycards_,
        address delegateCash_,
        address warmWallet_
    ) public initializer {
        __FragmentERC721_init(name_, symbol_, owner_);
        __FragmentSignedRedeemer_init(signer_);

        keycardsContractAddress = keycards_;
        delegateCash = IDelegationRegistry(delegateCash_);
        warmWallet = IWarmWallet(warmWallet_);

        publicMintPrice = 0.05 ether;
        maxPublicSale = 5;
    }

    function allowlistMint(uint8 typeId, bytes memory signature) public {
        if (!isAllowlistActive) revert MintInactive();

        if (allowlistMinted[msg.sender]) revert AllowlistMinted();
        if (!validateSignature(signature, msg.sender, "")) revert InvalidSignature();

        allowlistMinted[msg.sender] = true;

        _performMint(msg.sender, typeId, 1);
    }

    function partnerMint(uint8 typeId, bytes memory signature) public {
        if (!isKeycardMintActive) revert MintInactive(); // Partner mint happens during keycard phase

        // Partner mint uses the same data structures as allowlist 
        // to limit partner mints during allowlist phase
        if (allowlistMinted[msg.sender]) revert AllowlistMinted();
        if (!validateSignature(signature, msg.sender, "")) revert InvalidSignature();

        allowlistMinted[msg.sender] = true;

        _performMint(msg.sender, typeId, 1);
    }

    function publicMint(uint8 typeId, uint256 quantity) public payable {
        if (!isPublicSaleActive) revert MintInactive();

        if (msg.sender != tx.origin) revert OnlyEOA();
        if (msg.value != (publicMintPrice * quantity)) revert InvalidPayment();
        if ((publicMinted[msg.sender] + quantity) > maxPublicSale) revert InvalidQuantity();

        publicMinted[msg.sender] += quantity;

        _performMint(msg.sender, typeId, quantity);
    }

    function batchKeycardMint(uint16 labAmount, uint16 pathAmount, uint16[] memory keycardIds) public {
        if (!isKeycardMintActive) revert MintInactive();
        if (labAmount + pathAmount != keycardIds.length) revert InvalidQuantity();

        IERC721 keycardsContract = IERC721(keycardsContractAddress);
        uint256 length = keycardIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 keycardId = uint256(keycardIds[i]);
            if (keycardMinted[keycardId]) revert KeycardMinted();

            address keycardOwner = keycardsContract.ownerOf(keycardId);
            bool validOwnership = keycardOwner == msg.sender;

            // check delegate.cash at the wallet level
            if (!validOwnership) {
                validOwnership = delegateCash.checkDelegateForAll(msg.sender, keycardOwner);
            }

            // check warm xyz
            if (!validOwnership) {
                validOwnership = warmWallet.ownerOf(keycardsContractAddress, keycardId) == msg.sender;
            }

            // check delegate.cash contract level
            if (!validOwnership) {
                validOwnership = delegateCash.checkDelegateForContract(msg.sender, keycardOwner, keycardsContractAddress);
            }

            // check delegate.cash single token
            if (!validOwnership) {
                validOwnership =
                    delegateCash.checkDelegateForToken(msg.sender, keycardOwner, keycardsContractAddress, keycardId);
            }

            if (!validOwnership) revert InvalidKeycardOwnership();

            keycardMinted[keycardId] = true; // also avoids repeated IDs
        }

        _performMint(msg.sender, LAB, labAmount);
        _performMint(msg.sender, PATH, pathAmount);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        
        if (passTypes[tokenId] == LAB) return _metadata(labImage, labAnimation, "Lab", tokenId);
        else if (passTypes[tokenId] == PATH) return _metadata(pathImage, pathAnimation, "Path", tokenId);
        else return "";
    }

    function balanceOfLab(address owner) public view returns (uint256) {
        return balanceOf(owner, LAB);
    }

    function balanceOfPath(address owner) public view returns (uint256) {
        return balanceOf(owner, PATH);
    }

    function amountsMinted() public view returns (uint256, uint256) {
        return (totalMinted[LAB], totalMinted[PATH]);
    }

    function mintStatus() public view returns (bool, bool, bool) {
        return (isKeycardMintActive, isAllowlistActive, isPublicSaleActive);
    }

    function balanceOf(address owner, uint256 typeId) public view returns (uint256) {
        uint256 totalBalance = balanceOf(owner);
        uint256 counter = 0;
        for (uint256 tokenIndex = 0; tokenIndex < totalBalance; tokenIndex++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, tokenIndex);
            if (passTypes[tokenId] == typeId) counter++;
        }
        return counter;
    }

    function keycardsMinted(uint256[] calldata keycardIds) public view returns (bool[] memory) {
        uint256 length = keycardIds.length;
        bool[] memory statuses = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 keycardId = keycardIds[i];
            statuses[i] = keycardMinted[keycardId];
        }
        return statuses;
    }

    function checkKeycardMinted(uint256 keycardId) public view returns (bool) {
        if (keycardId < 1 || keycardId > 2222) revert InvalidKeycard();
        return keycardMinted[keycardId];
    }

    function operatorMint(address to, uint8 typeId, uint256 quantity) public onlyOperator {
        _performMint(to, typeId, quantity);
    }

    function setKeycardMintActive(bool isKeycardMintActive_) public onlyOperator {
        isKeycardMintActive = isKeycardMintActive_;
        emit KeycardMintActive(isKeycardMintActive_);
    }

    function setAllowlistActive(bool isAllowlistActive_) public onlyOperator {
        isAllowlistActive = isAllowlistActive_;
        emit AllowlistActive(isAllowlistActive_);
    }

    function setPublicSaleActive(bool isPublicSaleActive_) public onlyOperator {
        isPublicSaleActive = isPublicSaleActive_;
        emit PublicSaleActive(isPublicSaleActive_);
    }

    function setPublicMintPrice(uint256 publicMintPrice_) public onlyOperator {
        publicMintPrice = publicMintPrice_;
    }

    function setMaxPublicSale(uint256 maxPublicSale_) public onlyOperator {
        maxPublicSale = maxPublicSale_;
    }

    function setPathImage(string calldata pathImage_) public onlyOperator {
        pathImage = pathImage_;
    }

    function setPathAnimation(string calldata pathAnimation_) public onlyOperator {
        pathAnimation = pathAnimation_;
    }

    function setLabImage(string calldata labImage_) public onlyOperator {
        labImage = labImage_;
    }

    function setLabAnimation(string calldata labAnimation_) public onlyOperator {
        labAnimation = labAnimation_;
    }

    function _performMint(address to, uint8 typeId, uint256 quantity) internal {
        if (typeId != PATH && typeId != LAB) revert InvalidPassType();
        if ((totalMinted[typeId] + quantity) > MAX_SUPPLY_PER_TYPE) revert InvalidQuantity();

        totalMinted[typeId] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply();

            passTypes[tokenId] = typeId;
            _safeMint(to, tokenId);

            emit PassMinted(tokenId, typeId, msg.sender);
        }
    }

    function _metadata(string memory image, string memory animation, string memory factionTitle, uint256 tokenId) internal pure returns (string memory) {
        bytes memory json = abi.encodePacked("{");
        json = abi.encodePacked(json, _jsonify("name", abi.encodePacked("#", tokenId.toString())), ",");

        if (bytes(image).length > 0) json = abi.encodePacked(json, _jsonify("image", bytes(image)), ",");
        if (bytes(animation).length > 0) json = abi.encodePacked(json, _jsonify("animation_url", bytes(animation)), ",");

        json = abi.encodePacked(json, '"attributes":' "[");
        json = abi.encodePacked(json, _jsonifyAttribute("Faction", factionTitle));
        json = abi.encodePacked(json, "]");
        json = abi.encodePacked(json, "}");

        string memory uri = string(abi.encodePacked("data:application/json;base64,", Base64Upgradeable.encode(bytes(json))));
        return uri;
    }

    function _jsonifyAttribute(string memory traitType, string memory traitValue) private pure returns (bytes memory) {
        bytes memory value = abi.encodePacked('"value":"', traitValue, '"');
        bytes memory trait = abi.encodePacked('"trait_type":"', traitType, '"');
        return abi.encodePacked("{", trait, ",", value, "}");
    }

    function _jsonify(string memory key, bytes memory value) private pure returns (bytes memory) {
        return abi.encodePacked('"', key, '":"', value, '"');
    }
}