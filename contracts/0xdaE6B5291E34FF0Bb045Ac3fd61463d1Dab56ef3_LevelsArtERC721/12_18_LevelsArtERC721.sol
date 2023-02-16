// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "../opensea/upgradeable/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {ERC721AUpgradeable} from "../ERC721A/upgradeable/ERC721AUpgradeable.sol";
import {ILevelsArtERC721TokenURI} from "./ILevelsArtERC721TokenURI.sol";
import {LevelsArtERC721Storage} from "./LevelsArtERC721Storage.sol";
import {ERC4906} from "../utils/ERC4906.sol";

/*\      $$$$$$$$\ $$\    $$\ $$$$$$$$\ $$\      $$$$$$\                        $$\     
$$ |     $$  _____|$$ |   $$ |$$  _____|$$ |    $$  __$$\                       $$ |    
$$ |     $$ |      $$ |   $$ |$$ |      $$ |    $$ /  \__|   $$$$$$\   $$$$$$\$$$$$$\   
$$ |     $$$$$\    \$$\  $$  |$$$$$\    $$ |    \$$$$$$\     \____$$\ $$  __$$\_$$  _|  
$$ |     $$  __|    \$$\$$  / $$  __|   $$ |     \____$$\    $$$$$$$ |$$ |  \__|$$ |    
$$ |     $$ |        \$$$  /  $$ |      $$ |    $$\   $$ |  $$  __$$ |$$ |      $$ |$$\ 
$$$$$$$$\$$$$$$$$\    \$  /   $$$$$$$$\ $$$$$$$$\$$$$$$  |$$\$$$$$$$ |$$ |      \$$$$  |
\________\________|    \_/    \________|\________\______/ \__\_______|\__|       \___*/

contract LevelsArtERC721 is
    ERC4906,
    OwnableUpgradeable,
    RevokableDefaultOperatorFiltererUpgradeable,
    ERC721AUpgradeable
{
    using LevelsArtERC721Storage for LevelsArtERC721Storage.Layout;

    // Errors
    error MaxSupplyMinted();
    error TokenHasNotBeenMinted();

    // Events
    event UpdateTokenURIContract(address newTokenURIContractAddress);
    event UpdateMaxEditions(uint256 newMaxEditions);
    event UpdateContractMetadata(string description, string externalLink);
    event UpdateAdmin(address admin);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _tokenUriContract,
        uint256 _maxEditions,
        string calldata _description,
        string calldata _externalLink,
        address _minter
    ) public virtual initializer initializerERC721A {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        __RevokableDefaultOperatorFilterer_init();
        _setVersion(0x1);
        _initializeHelper(
            _tokenUriContract,
            _maxEditions,
            _description,
            _externalLink,
            _minter
        );
    }

    function _initializeHelper(
        address _tokenUriContract,
        uint256 _maxEditions,
        string calldata _description,
        string calldata _externalLink,
        address _minter
    ) internal {
        _setTokenURIContract(_tokenUriContract);
        _setMaxEditions(_maxEditions);
        _setContractDescription(_description);
        _setContractExternalLink(_externalLink);
        _setMinter(_minter);
    }

    function setupCollection(address _ownerAddress) public onlyOwner {
        require(
            ADMIN() == address(0),
            "Can only be called before ADMIN exists"
        );

        _setAdmin(msg.sender);
        _setTokenURISeed();

        if (_ownerAddress != owner()) {
            transferOwnership(_ownerAddress);
        }
    }

    /**
     * @notice Sets the account that gets the ADMIN role
     *
     * @param _admin the account that gets the ADMIN role
     */
    function setAdmin(address _admin) public onlyAdmin {
        _setAdmin(_admin);
        emit UpdateAdmin(_admin);
    }

    /**
     * @notice Sets the contract to read the tokenURIs from
     *
     * @param _tokenUriContract the address of the contract
     */
    function setTokenURIContract(address _tokenUriContract) public onlyAdmin {
        _setTokenURIContract(_tokenUriContract);
        emit UpdateTokenURIContract(_tokenUriContract);
    }

    /**
     * @notice Sets the version of the NFT logic to use.
     *
     * @param _version The version we're upgrading to
     *
     * @dev As we make updates for further collections, certain features might
     * get added that old games don't support (maybe they will but require
     * updates first). The version value will be used to determine which
     * features are turned on/off
     */
    function setVersion(uint16 _version) public onlyAdmin {
        _setVersion(_version);
    }

    /**
     * @notice Sts the tokenURISeed is used to shuffle the attributes of the
     * tokenURIs
     */
    function setTokenURISeed() public onlyAdmin {
        _setTokenURISeed();
    }

    //
    // Getter functions
    //

    /**
     * @notice The address that holds the MINTER role.
     *
     * @dev This address has the ability to mint from this contract. Should
     * always be held by the sale contract.
     */
    function MINTER() public view returns (address) {
        return LevelsArtERC721Storage.layout()._MINTER;
    }

    /**
     * @notice The address that holds the ADMIN role.
     *
     * @dev This address has limited ability to update values in the contract
     */
    function ADMIN() public view returns (address) {
        return LevelsArtERC721Storage.layout()._ADMIN;
    }

    /**
     * @notice The version of the NFT logic to use.
     *
     * @dev As we make updates for further collections, certain features might
     * get added that old games don't support (maybe they will but require
     * updates first). The version value will be used to determine which
     * features are turned on/off
     */
    function version() public view returns (uint16) {
        return LevelsArtERC721Storage.layout()._version;
    }

    /**
     * @notice The description that's included in the ContractURI metadata
     */
    function description() public view returns (string memory) {
        return LevelsArtERC721Storage.layout()._description;
    }

    /**
     * @notice The externalLink that's included in the ContractURI metadata
     */
    function externalLink() public view returns (string memory) {
        return LevelsArtERC721Storage.layout()._externalLink;
    }

    /**
     * @notice The MAX number of editions that can be minted as part of this
     * collection
     */
    function maxEditions() public view returns (uint256) {
        return LevelsArtERC721Storage.layout()._maxEditions;
    }

    /**
     * @notice The tokenUriContract that generates the game + attributes.
     * When requesting a tokenURI, this contract acts as a proxy of sorts. We
     * make a request for the game's code from another deployed contract.
     */
    function tokenURIContract() public view returns (address) {
        return address(LevelsArtERC721Storage.layout()._tokenUriContract);
    }

    /**
     * @notice The tokenURISeed is used to shuffle the attributes of the tokenURIs
     */
    function tokenURISeed() public view returns (uint256) {
        return LevelsArtERC721Storage.layout()._tokenUriSeed;
    }

    /**
     * @notice This is used to determin the timestamp that an individual token
     * was minted.
     *
     * @dev Since all tokens are minted chronologically (and potentially
     * in batches), we only need to store the timestamp in the index of the
     * first edition in a batch. To retrieve any token's mint time, we can just
     * loop back from that token's index until a timestamp is found.
     */
    function tokenIdMintedAt(uint256 _tokenId) public view returns (uint256) {
        require(_tokenId < totalSupply(), "Token has not been minted");

        uint256 i = _tokenId;
        mapping(uint256 => uint256) storage mintedAt = LevelsArtERC721Storage
            .layout()
            ._tokenIdMintedAt;

        while (i > 0) {
            if (mintedAt[i] != 0) return mintedAt[i];
            unchecked {
                i--;
            }
        }

        return mintedAt[i];
    }

    //
    // Internal Setters
    //

    /**
     * @notice Sets the version of the NFT logic to use.
     *
     * @param _version The version of the contract that we're setting.
     *
     * @dev As we make updates for further collections, certain features might
     * get added that old games don't support (maybe they will but require
     * updates first). The version value will be used to determine which
     * features are turned on/off
     */
    function _setVersion(uint16 _version) internal {
        LevelsArtERC721Storage.layout()._version = _version;
    }

    /**
     * @notice Sets the tokenUriContract that generates the game + attributes.
     *
     * @param _tokenUriContract The address that we're proxying tokenURI
     *
     * @dev When requesting a tokenURI, this contract acts as a proxy of sorts.
     * We make a request for the game's code from another deployed contract.
     * Whenever this is updated we will request that marketplaces refresh oll
     * of the items' metadata requests to.
     */
    function _setTokenURIContract(address _tokenUriContract) internal {
        LevelsArtERC721Storage
            .layout()
            ._tokenUriContract = ILevelsArtERC721TokenURI(_tokenUriContract);
        _refreshMetadata();
    }

    /**
     * @notice Sets the MAX number of editions that can be minted from this
     * contract
     */
    function _setMaxEditions(uint256 _maxEditions) internal {
        LevelsArtERC721Storage.layout()._maxEditions = _maxEditions;
    }

    /**
     * @notice Sets the description that is returned in the Contract URI
     */
    function _setContractDescription(string calldata _description) internal {
        LevelsArtERC721Storage.layout()._description = _description;
    }

    /**
     * @notice Sets the externalLink that is returned in the Contract URI
     */
    function _setContractExternalLink(string calldata _externalLink) internal {
        LevelsArtERC721Storage.layout()._externalLink = _externalLink;
    }

    /**
     * @notice Sets the address that willd hold the MINTER role.
     *
     * @param _minter The new address that will hold the MINTER role
     *
     * @dev This address has the ability to mint from this contract. Should
     * always be held by the sale contract.
     */
    function _setMinter(address _minter) internal {
        LevelsArtERC721Storage.layout()._MINTER = _minter;
    }

    /**
     * @notice Sets the address of the ADMIN role.
     * @param _admin The new address that will hold the ADMIN role
     *
     * @dev This address has limited ability to update values in the contract
     */
    function _setAdmin(address _admin) internal {
        LevelsArtERC721Storage.layout()._ADMIN = _admin;
    }

    /**
     * @notice Sets the tokenURISeed to a pseudorandom number
     *
     * @dev Can only be set once.
     */
    function _setTokenURISeed() internal {
        require(tokenURISeed() == 0, "Token URI seed already set");
        uint256 hashnumber = uint256(blockhash(block.number - 1));
        LevelsArtERC721Storage.layout()._tokenUriSeed = hashnumber;
        _refreshMetadata();
    }

    /**
     * @notice Tells marketplaces to refresh metadata
     */
    function _refreshMetadata() internal {
        uint256 _maxEditions = maxEditions();

        if (_maxEditions > 0) {
            emit BatchMetadataUpdate(0, _maxEditions - 1);
        }
    }

    //
    // URI Functions
    //

    /**
     * @notice Function that returns the Contract URI
     */
    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name(),
                                    '", ',
                                    '"description": "',
                                    description(),
                                    '", ',
                                    '"external_link": "',
                                    externalLink(),
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Function that returns the Token URI from the TokenURI contract
     *
     * @param tokenId The tokenId that the returned tokenURI is tied to
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Querying nonexistent token");

        ILevelsArtERC721TokenURI _tokenUriContract = LevelsArtERC721Storage
            .layout()
            ._tokenUriContract;

        if (tokenURISeed() == 0) return _tokenUriContract.tokenURI(tokenId);

        return _tokenUriContract.tokenURI(tokenId, tokenURISeed());
    }

    /**
     * @notice Function that mints tokens
     *
     * @param to The address that will receive the tokens
     * @param quantity The amount of tokens to mint
     */
    function mint(address to, uint quantity) public onlyMinter {
        uint256 nextTokenId = totalSupply();

        require(nextTokenId < maxEditions(), "Max supply minted.");
        require(
            nextTokenId + quantity <= maxEditions(),
            "Cannot mint more than supply."
        );

        super._mint(to, quantity);

        LevelsArtERC721Storage.layout()._tokenIdMintedAt[nextTokenId] = block
            .timestamp;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            super.supportsInterface(interfaceId);
    }

    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    /*
     * Modifiers
     */

    modifier onlyMinter() {
        require(msg.sender == MINTER(), "Caller must be MINTER");
        _;
    }

    modifier onlyAdmin() {
        if (ADMIN() != address(0)) {
            require(msg.sender == ADMIN(), "Caller must be ADMIN");
        } else {
            require(msg.sender == owner(), "Caller must be OWNER");
        }
        _;
    }
}