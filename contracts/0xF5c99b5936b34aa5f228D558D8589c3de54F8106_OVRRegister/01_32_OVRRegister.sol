// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ERC721Full.sol";

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBaseRegistrar.sol";
import "./interfaces/IENSRegistry.sol";
import "./interfaces/IENSResolver.sol";
import "./interfaces/IResolver.sol";
import "./PriceCalculator.sol";

contract OVRRegister is ERC721Full, AccessControlUpgradeable, UUPSUpgradeable {
    using AddressUpgradeable for address;
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

    // The ENS registry
    IENSRegistry public registry;
    // The ENS base registrar
    IBaseRegistrar public base;

    IResolver public resolverSubnodes;

    // Token accepted
    IERC20 public acceptedToken;
    // Price in OVR
    uint256 public priceDef;
    uint256 public specialPrice;
    // Treasury
    address public treasury;
    // Empty hash
    bytes32 public emptyNamehash;
    // Top domain e.g: eth
    string public topdomain;
    // Domain e.g: ovr
    string public domain;
    // Top domain hash
    bytes32 public topdomainNameHash;
    // Domain hash
    bytes32 public domainNameHash;
    // Base URI
    string public baseURI;
    //content hash (ipfs Url)
    bytes public contentHash;

    // A map of subdomain hashes to its string for reverse lookup
    mapping(bytes32 => string) public subdomains;
    mapping(string => bool) public blacklistedSubdomains;

    /* ========== EVENTS ========== */
    // prettier-ignore
    event LandChanged(string indexed _subdomain, address indexed _owner, uint256 indexed _newLand, uint256 timestamp);

    // prettier-ignore
    event ContentHashRestored(string indexed _subdomain, address indexed _owner, bytes indexed _newContentHash, uint256 timestamp);

    // Emitted when a user reclaim a subdomain to the ENS Registry
    // prettier-ignore
    event Reclaimed(address indexed _caller, address indexed _owner, uint256 indexed _tokenId);

    // Emitted everytime a user transfers a token
    // prettier-ignore
    event ReclaimedAfterTransfer(address indexed _oldOwner, address indexed _owner, uint256 indexed _tokenId);

    // Emitted when the owner of the contract reclaim the domain to the ENS Registry
    event DomainReclaimed(uint256 indexed _tokenId);

    // Emitted when the domain was transferred
    // prettier-ignore
    event DomainTransferred(address indexed _newOwner, uint256 indexed _tokenId);

    // Emitted when the registry was updated
    // prettier-ignore
    event RegistryUpdated(IENSRegistry indexed _previousRegistry, IENSRegistry indexed _newRegistry);

    // Emitted when the base was updated
    // prettier-ignore
    event BaseUpdated( IBaseRegistrar indexed _previousBase, IBaseRegistrar indexed _newBase);

    // Emitted when base URI is was changed
    event BaseURI(string _oldBaseURI, string _newBaseURI);

    // Emit when the resolver is set to the owned domain
    // prettier-ignore
    event ResolverUpdated(address indexed _oldResolver, address indexed _newResolver);

    // Emit when a call is forwarred to the resolver
    // prettier-ignore
    event CallForwarwedToResolver( address indexed _resolver, bytes indexed _data, bytes indexed res);

    /* ========== MODIFIERS ========== */

    /**
     * @dev Validate a name
     * @notice that only a-z is allowed
     * @param _name - string for the name
     */
    function requireNameValid(string memory _name)
        internal
        pure
        returns (uint32 _length)
    {
        bytes memory tempName = bytes(_name);

        // prettier-ignore
        require(tempName.length >= 2 && tempName.length <= 20, "2-20 chars");
        for (uint256 i = 0; i < tempName.length; i++) {
            require(_isLetterOrNumber(tempName[i]), "Invalid char");
        }
        _length = uint32(tempName.length);
    }

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor of the contract
     * @param _registry - address of the ENS registry contract
     * @param _base - address of the ENS base registrar contract
     * @param _topdomain - top domain (e.g. "eth")
     * @param _domain - domain (e.g. "ovr")
     * @param _baseURI - base URI for token URIs
     */
    function initialize(
        IENSRegistry _registry,
        IBaseRegistrar _base,
        string memory _topdomain,
        string memory _domain,
        string memory _baseURI,
        address _treasury,
        IERC20 _token,
        uint256 _priceDef,
        uint256 _specialPrice,
        IResolver _resolver,
        bytes memory _contentHash
    ) public initializer {
        __init_721("OVR Subdomains", "OVRENS");
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // ENS registry
        updateRegistry(_registry);
        // ENS base registrar
        updateBase(_base);
        // Top domain string
        require(bytes(_topdomain).length > 0, "Top domain can not be empty");
        topdomain = _topdomain;
        // Domain string
        require(bytes(_domain).length > 0, "Domain can not be empty");
        domain = _domain;
        resolverSubnodes = _resolver;
        contentHash = _contentHash;
        emptyNamehash = 0x00;
        // Generate namehash for the top domain
        topdomainNameHash = keccak256(
            abi.encodePacked(
                emptyNamehash,
                keccak256(abi.encodePacked(topdomain))
            )
        );
        // Generate namehash for the domain
        domainNameHash = keccak256(
            abi.encodePacked(
                topdomainNameHash,
                keccak256(abi.encodePacked(domain))
            )
        );

        priceDef = _priceDef;
        specialPrice = _specialPrice;
        acceptedToken = _token;
        treasury = _treasury;

        // Set base URI
        updateBaseURI(_baseURI);
    }

    /* ========== FUNCTIONS ========== */

    function viewHash(string calldata _subdomain)
        public
        view
        returns (bytes32)
    {
        bytes32 subdomainLabelHash = keccak256(
            abi.encodePacked(_toLowerCase(_subdomain))
        );
        return keccak256(abi.encodePacked(domainNameHash, subdomainLabelHash));
    }

    /**
     * @dev Allows an admin to grant the admin role to a user
     * @param _admin - user's address to grant admin role
     */
    function addAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows an admin to revoke the admin role of a user
     * @param _admin - user's address to revoke admin role
     */
    function removeAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows an admin to change the price
     * @param _price - default price in wei
     * @param _specialPrice - expensive price in wei
     */
    function changePrice(uint256 _price, uint256 _specialPrice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        priceDef = _price;
        specialPrice = _specialPrice;
    }

    function addNamesToBlacklist(string[] memory _names)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint8 i = 0; i < _names.length; i++) {
            blacklistedSubdomains[_names[i]] = true;
        }
    }

    function removeNameFromBlacklist(string[] memory _names)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint8 i = 0; i < _names.length; i++) {
            blacklistedSubdomains[_names[i]] = false;
        }
    }

    /**
     * @dev Allows users to see current price for a domain in OVR
     */
    function price()
        public
        view
        returns (uint256 _priceDef, uint256 _specialPrice)
    {
        return (priceDef, specialPrice);
    }

    /**
     * @dev Allows to create a subdomain (e.g. "rome.ovr.eth"), set its resolver, owner and target address
     * @param _subdomain - subdomain  (e.g. "rome")
     * @param _beneficiary - address that will become owner of this new subdomain
     */
    function register(
        string calldata _subdomain,
        address _beneficiary,
        string memory _land
    ) external {
        require(!blacklistedSubdomains[_subdomain], "Invalid name");
        require(_beneficiary != address(0), "Invalid beneficiary");
        // Make sure this contract owns the domain
        _checkOwnerOfDomain();
        //requireNameValid(_subdomain)
        uint32 length = requireNameValid(_subdomain);
        // Create labelhash for the subdomain
        bytes32 subdomainLabelHash = keccak256(
            abi.encodePacked(_toLowerCase(_subdomain))
        );
        // Make sure it is free
        require(_available(subdomainLabelHash), "Already owned");
        //if domain has less than 5 characters, price is special, otherwise is default
        uint256 toPay = length < 5 ? specialPrice : priceDef;
        require(
            acceptedToken.transferFrom(_msgSender(), treasury, toPay),
            "Transfer failed"
        );
        // solium-disable-next-line security/no-block-members
        _register(_subdomain, subdomainLabelHash, _beneficiary, _land);
    }

    /**
     * @dev Re-claim the ownership of a subdomain (e.g. "rome").
     * @notice After a subdomain is transferred by this contract, the owner in the ENS registry contract
     * is still the old owner. Therefore, the owner should call `reclaim` to update the owner of the subdomain.
     * It is also useful to recreate the subdomains in case of an ENS migration.
     * @param _tokenId - erc721 token id which represents the node (subdomain).
     */
    function reclaim(uint256 _tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address owner = ownerOf(_tokenId);

        registry.setSubnodeOwner(
            domainNameHash,
            bytes32(_tokenId),
            ownerOf(_tokenId)
        );

        emit Reclaimed(_msgSender(), owner, _tokenId);
    }

    /**
     * @dev Re-claim the ownership of a subdomain (e.g. "rome").
     * @notice After a subdomain is transferred by this contract, the owner in the ENS registry contract
     * is still the old owner. Therefore, the owner should call `reclaim` to update the owner of the subdomain.
     * It is also useful to recreate the subdomains in case of an ENS migration.
     * @param _tokenId - erc721 token id which represents the node (subdomain).
     * @param _owner - new owner.
     */
    function reclaim(uint256 _tokenId, address _owner) public {
        // Check if the sender is authorized to manage the subdomain
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "Only an authorized account can change the subdomain settings"
        );

        registry.setSubnodeOwner(domainNameHash, bytes32(_tokenId), _owner);

        emit Reclaimed(_msgSender(), _owner, _tokenId);
    }

    /**
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safetransfer`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the contract address is always the message sender.
     * @notice Handle the receipt of an NFT. Used to re-claim ownership at the ENS registry contract
     * @param _tokenId The NFT identifier which is being transferred
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address, /* _operator */
        address, /* _from */
        uint256 _tokenId,
        bytes memory /* _data */
    ) public returns (bytes4) {
        require(
            _msgSender() == address(base),
            "Only base can send NFTs to this contract"
        );

        // Re-claim to update the owner at the ENS Registry
        base.reclaim(_tokenId, address(this));
        return ERC721_RECEIVED;
    }

    /**
     * @dev Check whether a name is available to be registered or not
     * @param _subdomain - name to check
     * @return whether the name is available or not
     */
    function available(string memory _subdomain) public view returns (bool) {
        // Create labelhash for the subdomain
        bytes32 subdomainLabelHash = keccak256(
            abi.encodePacked(_toLowerCase(_subdomain))
        );
        return _available(subdomainLabelHash);
    }

    /**
     * @dev Get the token id by its subdomain
     * @param _subdomain - string of the subdomain
     * @return token id mapped to the subdomain
     */
    function getTokenId(string memory _subdomain)
        public
        view
        returns (uint256)
    {
        string memory subdomain = _toLowerCase(_subdomain);
        bytes32 subdomainLabelHash = keccak256(abi.encodePacked(subdomain));
        uint256 tokenId = uint256(subdomainLabelHash);

        require(_exists(tokenId), "Not registered");

        return tokenId;
    }

    /**
     * @dev Get the owner of a subdomain
     * @param _subdomain - string of the subdomain
     * @return owner of the subdomain
     */
    function getOwnerOf(string memory _subdomain)
        public
        view
        returns (address)
    {
        return ownerOf(getTokenId(_subdomain));
    }

    /**
     * @dev Returns an URI for a given token ID.
     * @notice that throws if the token ID does not exist. May return an empty string.
     * Also, if baseURI is empty, an empty string will be returned.
     * @param _tokenId - uint256 ID of the token queried
     * @return token URI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (bytes(baseURI).length == 0) {
            return "";
        }

        require(_exists(_tokenId), "ERC721Metadata: nonexistent token");
        return
            string(
                abi.encodePacked(
                    baseURI,
                    _toLowerCase(subdomains[bytes32(_tokenId)])
                )
            );
    }

    /**
     * @dev Re-claim the ownership of the domain (e.g. "ovr")
     * @notice After a domain is transferred by the ENS base
     * registrar to this contract, the owner in the ENS registry contract
     * is still the old owner. Therefore, the owner should call `reclaimDomain`
     * to update the owner of the domain
     * @param _tokenId - erc721 token id which represents the node (domain)
     */
    function reclaimDomain(uint256 _tokenId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        base.reclaim(_tokenId, address(this));

        emit DomainReclaimed(_tokenId);
    }

    /**
     * @dev The contract owner can take away the ownership of any domain owned by this contract
     * @param _owner - new owner for the domain
     * @param _tokenId - erc721 token id which represents the node (domain)
     */
    function transferDomainOwnership(address _owner, uint256 _tokenId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        base.transferFrom(address(this), _owner, _tokenId);
        emit DomainTransferred(_owner, _tokenId);
    }

    /**
     * @dev Update owned domain resolver
     * @param _resolver - new resolver
     */
    function setResolver(address _resolver)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address resolver = registry.resolver(domainNameHash);

        require(_resolver.isContract(), "Should be a contract");
        require(_resolver != resolver, "Should be different");

        _checkNotAllowedAddresses(_resolver);

        registry.setResolver(domainNameHash, _resolver);

        emit ResolverUpdated(resolver, _resolver);
    }

    /**
     * @dev Forward calls to resolver
     * @param _data - data to be send in the call
     */
    function forwardToResolver(bytes memory _data)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address resolver = registry.resolver(domainNameHash);

        _checkNotAllowedAddresses(resolver);

        (bool success, bytes memory res) = resolver.call(_data);

        require(success, "Call failed");

        // Make sure this contract is still the owner of the domain
        _checkOwnerOfDomain();

        emit CallForwarwedToResolver(resolver, _data, res);
    }

    /**
     * @dev Update to new ENS registry
     * @param _registry The address of new ENS registry to use
     */
    function updateRegistry(IENSRegistry _registry)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(registry != _registry, "Should be different");
        require(address(_registry).isContract(), "Should be a contract");

        registry = _registry;

        emit RegistryUpdated(registry, _registry);
    }

    /**
     * @dev Update to new ENS base registrar
     * @param _base The address of new ENS base registrar to use
     */
    function updateBase(IBaseRegistrar _base)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(base != _base, "Should be different");
        require(address(_base).isContract(), "Should be a contract");

        base = _base;

        emit BaseUpdated(base, _base);
    }

    /**
     * @dev Set Base URI.
     * @param _baseURI - base URI for token URIs
     */
    function updateBaseURI(string memory _baseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            keccak256(abi.encodePacked((baseURI))) !=
                keccak256(abi.encodePacked((_baseURI))),
            "Should be different"
        );
        emit BaseURI(baseURI, _baseURI);
        baseURI = _baseURI;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _checkOwnerOfDomain() internal view {
        require(
            registry.owner(domainNameHash) == address(this) &&
                base.ownerOf(uint256(keccak256(abi.encodePacked(domain)))) ==
                address(this),
            "The contract does not own the domain"
        );
    }

    function _setContentHash(bytes32 _labelHash) internal {
        bytes32 node = keccak256(abi.encodePacked(domainNameHash, _labelHash));
        resolverSubnodes.setContenthash(node, contentHash);
    }

    function _checkNotAllowedAddresses(address _address) internal view {
        require(
            _address != address(base) &&
                _address != address(registry) &&
                _address != address(this),
            "Invalid address"
        );
    }

    function _isLetterOrNumber(bytes1 _char) internal pure returns (bool) {
        return
            (_char >= 0x41 && _char <= 0x5A) ||
            (_char >= 0x61 && _char <= 0x7A) ||
            (_char >= 0x30 && _char <= 0x39);
    }

    /**
     * @dev Check whether a name is available to be registered or not
     * @param _subdomainLabelHash - hash of the name to check
     * @return whether the name is available or not
     */
    function _available(bytes32 _subdomainLabelHash)
        internal
        view
        returns (bool)
    {
        // Create namehash for the subdomain (node)
        bytes32 subdomainNameHash = keccak256(
            abi.encodePacked(domainNameHash, _subdomainLabelHash)
        );
        // Make sure it is free
        return
            registry.owner(subdomainNameHash) == address(0) &&
            !_exists(uint256(_subdomainLabelHash));
    }

    /**
     * @dev Internal function to register a subdomain
     * @param _subdomain - subdomain  (e.g. "rome")
     * @param subdomainLabelHash - hash of the subdomain
     * @param _beneficiary - address that will become owner of this new subdomain
     */
    function _register(
        string memory _subdomain,
        bytes32 subdomainLabelHash,
        address _beneficiary,
        string memory _land
    ) internal {
        // Create new subdomain and assign the _beneficiary as the owner
        registry.setSubnodeOwner(
            domainNameHash,
            subdomainLabelHash,
            _beneficiary
        );
        // Mint an ERC721 token with the sud domain label hash as its id

        _mint(address(this), uint256(subdomainLabelHash));
        //set the resolver to the ENSResolver contract
        setResolver(subdomainLabelHash, address(resolverSubnodes));
        //set the landId inside the notice section
        changeNotice(subdomainLabelHash, _land);
        //set the content hash
        _setContentHash(subdomainLabelHash);
        //transfer the ownership of the token to the beneficiary
        _transfer(address(this), _beneficiary, uint256(subdomainLabelHash));
        // Map the ERC721 token id with the subdomain for reversion.
        subdomains[subdomainLabelHash] = _subdomain;
    }

    function restoreContentHash(string memory _subdomain) public {
        bytes32 subdomainLabelHash = keccak256(abi.encodePacked(_subdomain));
        require(
            _isApprovedOrOwner(_msgSender(), uint256(subdomainLabelHash)),
            "Not owner or approved"
        );
        approve(address(this), uint256(subdomainLabelHash));
        _transfer(_msgSender(), address(this), uint256(subdomainLabelHash));
        registry.setSubnodeOwner(
            domainNameHash,
            subdomainLabelHash,
            address(this)
        );

        _setContentHash(subdomainLabelHash);
        _transfer(address(this), _msgSender(), uint256(subdomainLabelHash));
        emit ContentHashRestored(
            _subdomain,
            _msgSender(),
            contentHash,
            block.timestamp
        );
    }

    function changeLand(string memory _subdomain, uint256 _landId) public {
        bytes32 subdomainLabelHash = keccak256(abi.encodePacked(_subdomain));
        require(
            _isApprovedOrOwner(_msgSender(), uint256(subdomainLabelHash)),
            "Not owner or approved"
        );
        approve(address(this), uint256(subdomainLabelHash));
        _transfer(_msgSender(), address(this), uint256(subdomainLabelHash));
        registry.setSubnodeOwner(
            domainNameHash,
            subdomainLabelHash,
            address(this)
        );
        string memory stringLand = uint2str(_landId);

        changeNotice(subdomainLabelHash, stringLand);
        _transfer(address(this), _msgSender(), uint256(subdomainLabelHash));
        emit LandChanged(_subdomain, _msgSender(), _landId, block.timestamp);
    }

    function changeContentHash(bytes memory _data)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contentHash = _data;
    }

    function reclaimAfterTransfer(
        uint256 _tokenId,
        address _owner,
        address _oldOwner
    ) internal {
        // Check if the sender is authorized to manage the subdomain
        require(_isApprovedOrOwner(_owner, _tokenId), "Not authorized");
        registry.setSubnodeOwner(domainNameHash, bytes32(_tokenId), _owner);

        emit ReclaimedAfterTransfer(_oldOwner, _owner, _tokenId);
    }

    /**
     * @dev The ERC721 smart contract calls this function everytime an NFT subnode
     * is transfered, this to pass the ownership of the subdomain
     * @notice Handle the receipt of an NFT. Used to claim ownership at the ENS registry contract
     * @param tokenId The NFT identifier which is being transferred
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 /*batchSize*/
    ) internal virtual override {
        // Re-claim to update the owner at the ENS Registry
        reclaimAfterTransfer(tokenId, to, from);
    }

    function setResolver(bytes32 _labelHash, address _resolver) internal {
        bytes32 node = keccak256(abi.encodePacked(domainNameHash, _labelHash));

        registry.setResolver(node, _resolver);
    }

    function changeNotice(bytes32 _labelHash, string memory _value) internal {
        bytes32 node = keccak256(abi.encodePacked(domainNameHash, _labelHash));
        resolverSubnodes.setText(node, "notice", _value);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Lowercase a string.
     * @param _str - to be converted to string.
     * @return string
     */
    function _toLowerCase(string memory _str)
        internal
        pure
        returns (string memory)
    {
        bytes memory bStr = bytes(_str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                // So we add 0x20 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 0x20);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Full, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}