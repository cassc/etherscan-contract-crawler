// SPDX-License-Identifier: GPL-3.0

/// @title Wizards ERC-721 token

pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDescriptor} from "./descriptor/IDescriptor.sol";
import {ISeeder} from "./seeder/ISeeder.sol";
import {ERC721} from "../base/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IProxyRegistry} from "../external/opensea/IProxyRegistry.sol";
import {IWizardToken} from "./IWizards.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../external/rarible/RoyaltiesV2Impl.sol";
import "../external/rarible/LibPart.sol";
import "../external/rarible/LibRoyaltiesV2.sol";

contract WizardToken is IWizardToken, ERC721, Ownable, RoyaltiesV2Impl {
    // support ERC2981
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // The address of the creators of WizardDAO
    address public creatorsDAO;

    // An address who has permissions to mint Wizards
    address public minter;

    // The Wizards token URI descriptor
    IDescriptor public descriptor;

    // The Wizards token seeder
    ISeeder public seeder;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The max supply wof wizards - 1
    uint256 private supply;

    // The Wizards seeds
    mapping(uint256 => ISeeder.Seed) public seeds;

    // one of one tracker
    mapping(uint256 => uint8) private oneOfOneSupply;

    // The current wizard ID
    uint256 private _currentID;

    // The last wizard one of one ID
    uint48 public lastOneOfOneId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash =
        "QmYURRfzZH7UkUmffxYifyTbyQu5axg8tt9wG92wpSoigi";

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    // keep track of amont of one of ones to know when we upload more.
    // allows us to skip expensive one of one minting ops if we need have minted
    // all available one of ones
    uint256 public lastOneOfOneCount;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, "Minter is locked");
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, "Descriptor is locked");
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, "Seeder is locked");
        _;
    }

    /**
     * @notice Require that the sender is the creators DAO.
     */
    modifier onlyCreatorsDAO() {
        require(msg.sender == creatorsDAO, "Sender is not the creators DAO");
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    constructor(
        address _creatorsDAO,
        address _minter,
        IDescriptor _descriptor,
        ISeeder _seeder,
        IProxyRegistry _proxyRegistry,
        uint256 _supply
    ) ERC721("Wizards", "WIZ") {
        creatorsDAO = _creatorsDAO;
        minter = _minter;
        descriptor = _descriptor;
        seeder = _seeder;
        proxyRegistry = _proxyRegistry;
        supply = _supply;
    }

    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesReceipientAddress,
        uint96 _percentageBasisPoints
    ) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }

        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            // take a 10% royalty on secondary markets.
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }

        return (address(0), 0);
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("ipfs://", _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash)
        external
        onlyOwner
    {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(IERC721, ERC721)
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _currentID;
    }

    /**
     * @notice Mint a Wizard to the minter, along with a possible creators reward
     * Wizard. Creators reward Wizard are minted every 6 Wizards, starting at 0,
     * so that at the start of each auction one is minted to the creators,
     * until 54 creator Wizards have been minted. 1 wizard every day for 54 days.
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        // we start minting for creators at 0 so _currentID should fall
        // below (6*54)-6 which is 318.
        if (_currentID <= 318 && _currentID % 6 == 0) {
            _mintTo(creatorsDAO, _currentID++, false, 0);
        }

        return _mintTo(minter, _currentID++, false, 0);
    }

    /**
     * @notice Mint a one of one Wizard to the minter.
     * @dev Call _mintTo with the to address(es) with the one of one id to mint.
     */
    function mintOneOfOne(uint48 oneOfOneId)
        public
        override
        onlyMinter
        returns (uint256, bool)
    {
        uint256 oneCount = descriptor.oneOfOnesCount();

        // validation; ensure a valid one of one index is requested
        require(
            uint256(oneOfOneId) < oneCount && oneOfOneId >= 0,
            "one of one does not exist"
        );

        if (lastOneOfOneCount == oneCount) {
            // mint a generated wizard if we are out of one of ones.
            // skip expensive ops below.
            return (_mintTo(minter, _currentID++, false, 0), false);
        }

        // check if oneOfOneId > 0 in mapping if is 0 use it. if 1 then iterate from
        // 0 -> oneCount and find a oneOfOne with no value set. if we don't get any with a value set
        // then just mint a regular wizard
        uint8 oo = oneOfOneSupply[oneOfOneId];
        if (oo == 0) {
            uint256 wizardId = _mintTo(minter, _currentID++, true, oneOfOneId);
            // set that we have minted a one of one at index
            oneOfOneSupply[oneOfOneId] = 1;
            lastOneOfOneId = oneOfOneId;
            return (wizardId, true);
        }

        // find a unused one of one to mint
        for (uint256 i = 0; i < oneCount; i++) {
            uint8 ofo = oneOfOneSupply[i];
            if (ofo == 0) {
                uint256 wizardId = _mintTo(
                    minter,
                    _currentID++,
                    true,
                    uint48(i)
                );
                oneOfOneSupply[i] = 1;
                lastOneOfOneId = uint48(i);
                return (wizardId, true);
            }
        }

        // we have spent all one of ones in the descriptor. record descriptor count
        // so next time we try to mint a one of one and it hasn't changed (we know
        // because we check oneOfOne supply above) we can skip the expensive map
        // iteration above.
        lastOneOfOneCount = oneCount;

        // mint a generated wizard if we are out of one of ones.
        return (_mintTo(minter, _currentID++, false, 0), false);
    }

    /**
     * @notice Burn a wizard.
     */
    function burn(uint256 wizardId) public override onlyMinter {
        _burn(wizardId);
        emit WizardBurned(wizardId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // if this throws an error then this wizard was burned or does not exist yet.
        require(
            _exists(tokenId),
            "WizardsToken: URI query for nonexistent token"
        );
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "WizardsToken: URI query for nonexistent token"
        );
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the WizardsDAO address.
     * @dev Only callable by WizardsDAO.
     */
    function setCreatorsDAO(address _creatorsDAO)
        external
        override
        onlyCreatorsDAO
    {
        creatorsDAO = _creatorsDAO;
        emit CreatorsDAOUpdated(_creatorsDAO);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter)
        external
        override
        onlyOwner
        whenMinterNotLocked
    {
        minter = _minter;
        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;
        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(IDescriptor _descriptor)
        external
        override
        onlyOwner
        whenDescriptorNotLocked
    {
        descriptor = _descriptor;
        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor()
        external
        override
        onlyOwner
        whenDescriptorNotLocked
    {
        isDescriptorLocked = true;
        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(ISeeder _seeder)
        external
        override
        onlyOwner
        whenSeederNotLocked
    {
        seeder = _seeder;
        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;
        emit SeederLocked();
    }

    /**
     * @notice Set the wizard total supply.
     * @dev Only callable by the owner.
     */
    function setSupply(uint256 _supply) external override onlyOwner {
        supply = _supply;
        emit SupplyUpdated(_supply);
    }

    /**
     * @notice Mint a Wizard with `wizardId` to the provided `to` address.
     */
    function _mintTo(
        address to,
        uint256 wizardId,
        bool isOneOfOne,
        uint48 oneOfOneIndex
    ) internal returns (uint256) {
        // wizardId starts at 0 so should be less than 2000
        require(wizardId < supply, "All wizards have been minted");

        ISeeder.Seed memory seed = seeds[wizardId] = seeder.generateSeed(
            wizardId,
            descriptor,
            isOneOfOne,
            oneOfOneIndex
        );

        _mint(owner(), to, wizardId);
        emit WizardCreated(wizardId, seed);

        return wizardId;
    }
}