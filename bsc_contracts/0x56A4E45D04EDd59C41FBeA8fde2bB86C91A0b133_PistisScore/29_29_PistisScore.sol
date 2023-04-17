// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../interfaces/IERC4906.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/// @custom:security-contact [email protected]
contract PistisScore is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IERC4906
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    string public contractURI;
    string private externalURL;
    string private tokenImageRenderURL;

    struct TokenData {
        bool exists;
        address[] addresses;
        uint256 globalRating;
        uint256 ratingUpdatedDate;
        string name;
        mapping(uint256 => ProviderData) providerData;
        uint256[] participatingProviders;
    }

    struct Provider {
        bool exists;
        uint256 providerType;
        address[] trustedAddresses;
    }

    struct ProviderData {
        bool exists;
        uint256 finalRating;
        uint256 loyaltyPoints;
        uint256[] ratings;
    }

    struct Wallet {
        bool exists;
        uint256 token;
    }

    struct Name {
        bool exists;
        uint256 token;
    }

    event TokenAddressAdded(
        uint256 indexed token,
        address indexed sender,
        address indexed newAddress
    );

    event TokenIdChanged(
        uint256 indexed oldTokenId,
        uint256 indexed newTokenId
    );

    mapping(uint256 => TokenData) public tokens;
    mapping(address => Wallet) public wallets;
    mapping(string => Name) public names;
    mapping(uint256 => Provider) public providers;

    /**
     * @dev Roles definitions
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _contractURI,
        string memory _externalURL,
        string memory _tokenImageRenderURL
    ) public initializer {
        __ERC721_init("Pistis Score", "PISTIS");
        __ERC721Enumerable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        contractURI = _contractURI;
        externalURL = _externalURL;
        tokenImageRenderURL = _tokenImageRenderURL;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function isLinkedWallet(address _wallet) public view returns (bool) {
        return wallets[_wallet].exists;
    }

    function safeMint() public {
        address sender = msg.sender;
        require(!isLinkedWallet(sender), "The address is already in use");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(sender, tokenId);

        tokens[tokenId].exists = true;
        tokens[tokenId].addresses = [sender];

        wallets[sender].exists = true;
        wallets[sender].token = tokenId;
    }

    function airdropMint(address _recipient) external onlyRole(OPERATOR_ROLE) {
        require(!isLinkedWallet(_recipient), "The address is already in use");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_recipient, tokenId);

        tokens[tokenId].exists = true;
        tokens[tokenId].addresses = [_recipient];

        wallets[_recipient].exists = true;
        wallets[_recipient].token = tokenId;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: The token doesn't exist");

        bytes memory data = abi.encodePacked(
            baseSection(_tokenId),
            attributesSection(_tokenId)
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(data)
                )
            );
    }

    function getTokenAddresses(
        uint256 _tokenId
    ) public view returns (address[] memory) {
        return tokens[_tokenId].addresses;
    }

    function getTokenByName(
        string memory _name
    ) public view returns (uint256 token) {
        require(names[_name].exists, "Name doesn't exist");

        return names[_name].token;
    }

    function addressInTokenExists(
        uint256 _tokenId,
        address _wallet
    ) public view returns (bool) {
        if (wallets[_wallet].exists && wallets[_wallet].token == _tokenId) {
            return true;
        }

        return false;
    }

    function addTokenAddress(
        uint256 _tokenId,
        address _newAddress,
        bytes memory _signature
    ) external {
        require(_exists(_tokenId), "ERC721Metadata: The token doesn't exist");
        require(
            addressInTokenExists(_tokenId, msg.sender),
            "You aren't the token owner"
        );
        require(
            !addressInTokenExists(_tokenId, _newAddress),
            "Address already exists"
        );

        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    _newAddress,
                    _tokenId,
                    "Please verify you intent to add address to Pistis token."
                )
            )
        );

        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                _newAddress,
                hash,
                _signature
            ),
            "Signature is not valid"
        );

        tokens[_tokenId].addresses.push(_newAddress);

        wallets[_newAddress].exists = true;
        wallets[_newAddress].token = _tokenId;

        emit TokenAddressAdded(_tokenId, msg.sender, _newAddress);
    }

    function checkTokenExists(uint256 _token) public view returns (bool) {
        return _exists(_token);
    }

    function checkNameExists(string memory _name) public view returns (bool) {
        return names[_name].exists;
    }

    function getTokenProviderLoyaltyPoints(
        uint256 _tokenId,
        uint256 _provider
    ) public view returns (uint256) {
        require(_exists(_tokenId), "ERC721Metadata: The token doesn't exist");
        require(providers[_provider].exists, "Provider doesn't exist");

        return tokens[_tokenId].providerData[_provider].loyaltyPoints;
    }

    function updateTokenLoyaltyPointsByProvider(
        uint256 _tokenId,
        uint256 _provider,
        uint256 _points
    ) external {
        require(_exists(_tokenId), "ERC721Metadata: The token doesn't exist");
        require(providers[_provider].exists, "Provider doesn't exist");

        require(
            checkProviderTrustedAddress(_provider, msg.sender) == true,
            "Sender not in trusted addresses"
        );

        tokens[_tokenId].providerData[_provider].exists = true;
        tokens[_tokenId].providerData[_provider].loyaltyPoints = _points;
    }

    function addNewTokenPointByProvider(
        uint256 _tokenId,
        uint256 _provider,
        uint256 _points
    ) external onlyRole(ORACLE_ROLE) {
        require(_exists(_tokenId), "ERC721Metadata: The token doesn't exist");
        require(providers[_provider].exists, "Provider doesn't exist");
        require(_points >= 1 && _points <= 5, "Incorrect points amount"); // add checking on integer

        require(
            checkProviderTrustedAddress(_provider, msg.sender) == true,
            "Sender not in trusted addresses"
        );

        tokens[_tokenId].providerData[_provider].exists = true;
        tokens[_tokenId].providerData[_provider].ratings.push(_points);

        if (checkProviderTrustedAddress(_provider, msg.sender) == false) {
            tokens[_tokenId].participatingProviders.push(_provider);
        }
    }

    function updateTokenRating(
        uint256 _token,
        uint256 _provider,
        uint256 _providerRating,
        uint256 _globalRating
    ) external onlyRole(ORACLE_ROLE) {
        require(
            checkTokenExists(_token),
            "ERC721Metadata: The token doesn't exist"
        );
        require(providers[_provider].exists, "Provider doesn't exist");

        tokens[_token].providerData[_provider].exists = true;
        tokens[_token].providerData[_provider].finalRating = _providerRating;
        tokens[_token].globalRating = _globalRating;
        tokens[_token].ratingUpdatedDate = block.timestamp;

        emit MetadataUpdate(_token);
    }

    function setPNSName(
        uint256 _token,
        string memory _name
    ) public onlyRole(ORACLE_ROLE) {
        if (bytes(tokens[_token].name).length != 0) {
            delete names[tokens[_token].name];
        }

        tokens[_token].name = _name;

        names[_name].exists = true;
        names[_name].token = _token;

        emit MetadataUpdate(_token);
    }

    function renouncePNSName(uint256 _tokenId) public {
        require(_exists(_tokenId), "ERC721Metadata: The token doesn't exist");
        require(
            addressInTokenExists(_tokenId, msg.sender),
            "You aren't the token owner"
        );

        string memory currentName = tokens[_tokenId].name;
        if (bytes(currentName).length != 0) {
            delete names[currentName];
            delete tokens[_tokenId].name;

            emit MetadataUpdate(_tokenId);
        }
    }

    function revokePNSName(uint256 _tokenId) public onlyRole(DAO_ROLE) {
        require(_exists(_tokenId), "ERC721Metadata: The token doesn't exist");

        string memory currentName = tokens[_tokenId].name;
        if (bytes(currentName).length != 0) {
            delete names[currentName];
            delete tokens[_tokenId].name;

            emit MetadataUpdate(_tokenId);
        }
    }

    function setPNSNameByDAO(
        uint256 _tokenId,
        string memory _name
    ) public onlyRole(DAO_ROLE) {
        require(_exists(_tokenId), "ERC721Metadata: The token doesn't exist");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(!checkNameExists(_name), "Name already exist");

        string memory currentName = tokens[_tokenId].name;
        if (bytes(currentName).length != 0) {
            delete names[currentName];
        }

        tokens[_tokenId].name = _name;

        names[_name].exists = true;
        names[_name].token = _tokenId;

        emit MetadataUpdate(_tokenId);
    }

    function updateExternalURL(
        string memory _newExternalURL
    ) external onlyRole(OPERATOR_ROLE) {
        externalURL = _newExternalURL;
    }

    function updateTokenImageRenderURL(
        string memory _newTokenImageRenderURL
    ) external onlyRole(OPERATOR_ROLE) {
        tokenImageRenderURL = _newTokenImageRenderURL;
    }

    function setContractURI(
        string memory _contractURI
    ) external onlyRole(OPERATOR_ROLE) {
        contractURI = _contractURI;
    }

    function addNewProvider(
        uint256 _provider,
        address[] memory _trustedAddresses
    ) external onlyRole(DAO_ROLE) {
        require(!providers[_provider].exists, "Provider already exist");

        providers[_provider].exists = true;
        providers[_provider].trustedAddresses = _trustedAddresses;
    }

    function addProviderTrustedAddress(
        uint256 _provider,
        address _trustedAddress
    ) external onlyRole(DAO_ROLE) {
        require(providers[_provider].exists, "Provider doesn't exist");

        providers[_provider].trustedAddresses.push(_trustedAddress);
    }

    function removeProviderTrustedAddress(
        uint256 _provider,
        address _trustedAddress
    ) external onlyRole(DAO_ROLE) {
        require(providers[_provider].exists, "Provider doesn't exist");

        uint256 trustedAddressesLength = providers[_provider]
            .trustedAddresses
            .length;

        for (uint256 i = 0; i < trustedAddressesLength; i++) {
            if (providers[_provider].trustedAddresses[i] == _trustedAddress) {
                if (i != trustedAddressesLength - 1) {
                    providers[_provider].trustedAddresses[i] = providers[
                        _provider
                    ].trustedAddresses[trustedAddressesLength - 1];
                }
                providers[_provider].trustedAddresses.pop();
                return;
            }
        }
    }

    function getProviderTrustedAddresses(
        uint256 _provider
    ) public view returns (address[] memory) {
        require(providers[_provider].exists, "Provider doesn't exist");

        return providers[_provider].trustedAddresses;
    }

    function checkProviderTrustedAddress(
        uint256 _provider,
        address _wallet
    ) public view returns (bool) {
        bool providerFlag = false;

        uint256 trustedAddressesLength = providers[_provider]
            .trustedAddresses
            .length;

        for (uint256 i = 0; i < trustedAddressesLength; i++) {
            if (providers[_provider].trustedAddresses[i] == _wallet) {
                providerFlag = true;
            }
        }

        return providerFlag;
    }

    function getTokenProviderData(
        uint256 _tokenId,
        uint256 _provider
    ) public view returns (ProviderData memory) {
        require(_exists(_tokenId), "ERC721Metadata: The token doesn't exist");
        require(providers[_provider].exists, "Provider doesn't exist");

        return tokens[_tokenId].providerData[_provider];
    }

    function baseSection(uint256 _tokenId) private view returns (bytes memory) {
        bytes memory name = bytes(tokens[_tokenId].name);
        string memory baseName = bytes(name).length != 0
            ? string(name)
            : string.concat("Pistis #", _tokenId.toString(), " token");
        string memory imageURI = string.concat(
            tokenImageRenderURL,
            _tokenId.toString()
        );

        return
            abi.encodePacked(
                "{",
                '"description": "Pistis Score token",',
                '"external_url": "',
                externalURL,
                _tokenId.toString(),
                '",',
                '"name": "',
                baseName,
                '.pistis",',
                '"image": "',
                imageURI,
                '",'
            );
    }

    function attributesSection(
        uint256 _tokenId
    ) private view returns (bytes memory) {
        return
            abi.encodePacked(
                '"attributes": [',
                '{ "trait_type": "Global rating", "value": ',
                tokens[_tokenId].globalRating.toString(),
                " },",
                '{ "display_type": "date", "trait_type": "Last updated date", "value": ',
                tokens[_tokenId].ratingUpdatedDate.toString(),
                " }",
                "] }"
            );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        require(
            from == address(0) || addressInTokenExists(tokenId, to),
            "This a SBT token. It can't be transferred outside."
        );
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }
}