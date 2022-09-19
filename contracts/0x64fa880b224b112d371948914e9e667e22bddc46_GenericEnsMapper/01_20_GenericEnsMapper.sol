// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/console.sol";
import "./structs/Config.sol";
import "./structs/NftDetails.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "ens-contracts/registry/ENS.sol";
import "ens-contracts/resolvers/profiles/IAddressResolver.sol";
import "ens-contracts/resolvers/profiles/IAddrResolver.sol";
import "ens-contracts/resolvers/profiles/ITextResolver.sol";
import "ens-contracts/resolvers/profiles/INameResolver.sol";
import "ens-contracts/wrapper/INameWrapper.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "EnsPrimaryContractNamer/PrimaryEns.sol";
import "forge-std/console.sol";

contract GenericEnsMapper is
    IAddressResolver,
    IAddrResolver,
    ITextResolver,
    INameResolver,
    IERC1155Receiver,
    PrimaryEns
{
    using Strings for *;

    uint256 private constant COIN_TYPE_ETH = 60;
    address private immutable deployer;

    event addNftContractToEns(
        uint256 indexed _ensId,
        IERC721 indexed _nftContract
    );
    event updateEnsClaimConfig(
        uint256 indexed _ensId,
        bool _numericOnly,
        bool _canOverwriteSubdomains
    );

    INameWrapper public EnsNameWrapper;

    ENS public EnsContract = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    IERC721 public EnsToken =
        IERC721(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);

    mapping(bytes32 => Config) public EnsToConfig;
    mapping(bytes32 => NftDetails) public SubnodeToNftDetails;
    mapping(uint256 => Config) public ParentNodeToConfig;
    mapping(uint256 => IERC721[]) public ParentNodeToNftContracts;

    mapping(bytes32 => mapping(address => mapping(uint256 => bytes))) OtherAddresses;
    mapping(bytes32 => mapping(bytes32 => string)) TextMappings;

    mapping(bytes32 => bytes32) public SubdomainClaimMap;

    event SubdomainClaimed(
        bytes32 indexed _nodeHash,
        IERC721 indexed _nftContract,
        uint96 indexed _tokenId,
        string _name
    );

    event SubdomainRemoved(
        bytes32 indexed _nodeHash,
        IERC721 indexed _nftContract,
        uint96 indexed _tokenId,
        string _name
    );

    constructor() {
        deployer = msg.sender;
    }

    function addEnsContractMapping(
        string[] calldata _domainArray,
        uint256 _ensId,
        IERC721[] calldata _nftContracts,
        bool _numericOnly,
        bool _overWriteUnusedSubdomains
    ) external payable isEnsApprovedOrOwner(_ensId) {
        bytes32 domainHash = namehashFromId(_ensId);
        address owner = EnsContract.owner(domainHash);
        require(
            owner == address(this) ||
                (owner == address(EnsNameWrapper) && owner != address(0)),
            "controller of Ens not set to contract"
        );
        require(
            getDomainHash(_domainArray) == domainHash,
            "incorrect namehash"
        );
        require(_nftContracts.length < 6, "maximum 5 contracts per ENS");
        require(_nftContracts.length > 0, "need at least 1 NFT contract");
        require(
            !(_nftContracts.length > 1 && _numericOnly),
            "Numeric only not compatible with multiple contracts"
        );

        require(
            !ParentNodeToConfig[_ensId].Initialised,
            "already been configured"
        );
        checkNftContracts(_nftContracts);
        ParentNodeToConfig[_ensId] = Config(
            true,
            _numericOnly,
            _overWriteUnusedSubdomains,
            _domainArray
        );
        ParentNodeToNftContracts[_ensId] = _nftContracts;

        //output events
        emit updateEnsClaimConfig(
            _ensId,
            _numericOnly,
            _overWriteUnusedSubdomains
        );

        for (uint256 i; i < _nftContracts.length; ) {
            emit addNftContractToEns(_ensId, _nftContracts[i]);

            unchecked {
                ++i;
            }
        }
    }

    function addContractToExistingEns(uint256 _ensId, IERC721 _nftContract)
        external
        payable
        isEnsApprovedOrOwner(_ensId)
    {
        uint256 numberOfContracts = ParentNodeToNftContracts[_ensId].length;

        require(numberOfContracts < 5, "maximum 5 contracts per ENS");
        require(numberOfContracts > 0, "ens not configured");
        require(
            !isValidNftContract(_ensId, _nftContract),
            "duplicate NFT contract"
        );
        require(
            !ParentNodeToConfig[_ensId].NumericOnly,
            "Numeric only not compatible with multiple contracts"
        );

        ParentNodeToNftContracts[_ensId].push(_nftContract);
        emit addNftContractToEns(_ensId, _nftContract);
    }

    function updateSettingsToExistingEns(
        uint256 _ensId,
        bool _numericOnly,
        bool _overwriteUnusedSubdomains
    ) external payable isEnsApprovedOrOwner(_ensId) {
        require(
            !(ParentNodeToNftContracts[_ensId].length > 1 && _numericOnly),
            "Numeric only not compatible with multiple contracts"
        );
        Config memory config = ParentNodeToConfig[_ensId];
        require(config.Initialised, "ENS not configured");

        config.NumericOnly = _numericOnly;
        config.CanOverwriteSubdomains = _overwriteUnusedSubdomains;

        ParentNodeToConfig[_ensId] = config;

        emit updateEnsClaimConfig(
            _ensId,
            _numericOnly,
            _overwriteUnusedSubdomains
        );
    }

    /**
     * @notice Claim subdomain
     * @param _ensId parent token id of the subdomain
     * @param _nftId ID of ERC-721 NFT
     * @param _nftContract address of the ERC-721 NFT contract
     * @param _label label for the subdomain
     */
    function claimSubdomain(
        uint256 _ensId,
        uint96 _nftId,
        IERC721 _nftContract,
        string memory _label
    ) external payable isNftOwner(_nftContract, _nftId) {
        bytes32 claimHash = keccak256(
            abi.encodePacked(_ensId, address(_nftContract), _nftId)
        );
        require(
            SubdomainClaimMap[claimHash] == 0x0,
            "subdomain claimed for this token"
        );
        require(isValidNftContract(_ensId, _nftContract), "Not valid contract");
        Config memory config = ParentNodeToConfig[_ensId];
        require(config.Initialised, "configuration for ENS not enabled");
        bytes32 domainHash = namehashFromId(_ensId);
        string memory label = config.NumericOnly ? _nftId.toString() : _label;
        bytes32 subnodeHash = keccak256(
            abi.encodePacked(domainHash, keccak256(abi.encodePacked(label)))
        );
        require(
            SubnodeToNftDetails[subnodeHash].ParentTokenId == 0,
            "Subdomain has already been claimed"
        );
        require(
            !EnsContract.recordExists(subnodeHash) ||
                config.CanOverwriteSubdomains,
            "not allowed previously used subdomain"
        );

        NftDetails memory details = NftDetails(
            _ensId,
            label,
            _nftContract,
            _nftId
        );

        SubnodeToNftDetails[subnodeHash] = details;

        if (EnsToken.ownerOf(_ensId) == address(EnsNameWrapper)) {
            EnsNameWrapper.setSubnodeRecord(
                domainHash,
                label,
                address(this),
                address(this),
                0, //ttl
                0, //fuses
                type(uint64).max
            );
        } else {
            EnsContract.setSubnodeRecord(
                domainHash,
                keccak256(abi.encodePacked(label)),
                address(this),
                address(this),
                0
            );
        }

        SubdomainClaimMap[claimHash] = subnodeHash;

        emit AddrChanged(subnodeHash, _nftContract.ownerOf(_nftId));
        emit AddressChanged(
            subnodeHash,
            60,
            abi.encodePacked(_nftContract.ownerOf(_nftId))
        );
        emit SubdomainClaimed(
            subnodeHash,
            _nftContract,
            _nftId,
            name(subnodeHash)
        );
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key)
        external
        view
        returns (string memory)
    {
        NftDetails memory details = SubnodeToNftDetails[node];
        require(details.ParentTokenId != 0, "subdomain not configured");

        if (keccak256(abi.encodePacked(key)) == keccak256("avatar")) {
            string memory str = string(
                abi.encodePacked(
                    "eip155:1/erc721:",
                    address(details.NftAddress).toHexString(),
                    "/",
                    details.NftId.toString()
                )
            );
            return str;
        } else {
            return TextMappings[node][keccak256(abi.encodePacked(key))];
        }
    }


    /**
     * @notice removes the subdomain mapping from this resolver contract
     * @param _subdomainHash namehash of the subdomain
     */
    function removeSubdomain(bytes32 _subdomainHash)
        external
        payable
        authorised(_subdomainHash)
    {
        NftDetails memory details = SubnodeToNftDetails[_subdomainHash];
        require(details.ParentTokenId != 0, "subdomain not configured");

        string memory subdomainName = name(_subdomainHash);

        delete SubdomainClaimMap[
            keccak256(
                abi.encodePacked(
                    details.ParentTokenId,
                    address(details.NftAddress),
                    details.NftId
                )
            )
        ];
        delete SubnodeToNftDetails[_subdomainHash];

        emit AddrChanged(_subdomainHash, address(0));
        emit AddressChanged(_subdomainHash, 60, abi.encodePacked(address(0)));
        emit SubdomainRemoved(
            _subdomainHash,
            details.NftAddress,
            details.NftId,
            subdomainName
        );
    }

    //this doesn't need gating as it just outputs events
    //it's here because etherscan and ens.app both use events
    //for primary naming
    function outputEvents(bytes32 _subnodeHash) external payable {
        address owner = getOwnerFromDetails(_subnodeHash);

        emit AddrChanged(_subnodeHash, owner);
        emit AddressChanged(_subnodeHash, 60, abi.encodePacked(owner));
    }

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of the linked NFT
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external payable authorised(node) {
        TextMappings[node][keccak256(abi.encodePacked(key))] = value;
        emit TextChanged(node, key, value);
    }

    function addr(bytes32 node, uint256 coinType)
        external
        view
        returns (bytes memory)
    {
        address owner = getOwnerFromDetails(node);
        if (coinType == COIN_TYPE_ETH) {
            return abi.encodePacked(owner);
        } else {
            return OtherAddresses[node][owner][coinType];
        }
    }

    /**
     * Returns the address associated with an ENS node. Legacy method
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable) {
        return payable(getOwnerFromDetails(node));
    }

    function setAddr(
        bytes32 node,
        uint256 coinType,
        bytes memory a
    ) external authorised(node) {
        emit AddressChanged(node, coinType, a);
        require(coinType != COIN_TYPE_ETH, "cannot set eth address");
        address nftOwner = getOwnerFromDetails(node);
        OtherAddresses[node][nftOwner][coinType] = a;
    }

    //ERC1155 receiver

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        require(false, "cannot do batch transfer");
        return this.onERC1155BatchReceived.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == this.onERC1155Received.selector ||
            interfaceId == this.onERC1155BatchReceived.selector ||
            interfaceId == 0x3b3b57de || //addr
            interfaceId == 0x59d1d43c || //text
            interfaceId == 0x691f3431 || //name
            interfaceId == 0x01ffc9a7;
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) public view returns (string memory) {
        NftDetails memory details = SubnodeToNftDetails[node];
        string memory label = details.Label;
        string[] memory domainArray = ParentNodeToConfig[details.ParentTokenId]
            .DomainArray;

        require(
            address(details.NftAddress) != address(0),
            "subdomain not configured"
        );
        for (uint256 i; i < domainArray.length; ) {
            label = string(abi.encodePacked(label, ".", domainArray[i]));

            unchecked {
                ++i;
            }
        }

        return label;
    }

    ///['hodl', 'pcc', 'eth']
    function getDomainHash(string[] calldata _domainArray)
        public
        pure
        returns (bytes32 namehash)
    {
        namehash = 0x0;

        for (uint256 i = _domainArray.length; i > 0; ) {
            unchecked {
                --i;
            }
            namehash = keccak256(
                abi.encodePacked(
                    namehash,
                    keccak256(abi.encodePacked(_domainArray[i]))
                )
            );
        }
    }

    function checkNftContracts(IERC721[] calldata _nftContracts) private view {
        for (uint256 i; i < _nftContracts.length; ) {
            require(
                ERC165Checker.supportsInterface(
                    address(_nftContracts[i]),
                    type(IERC721).interfaceId
                ),
                "need to be IERC721 contracts"
            );

            unchecked {
                ++i;
            }
        }
    }

    function isValidNftContract(uint256 _ensId, IERC721 _nftContract)
        private
        view
        returns (bool)
    {
        IERC721[] memory contracts = ParentNodeToNftContracts[_ensId];
        uint256 total = contracts.length;
        for (uint256 i; i < total; ) {
            if (contracts[i] == _nftContract) {
                return true;
            }

            unchecked {
                ++i;
            }
        }
    }

    // ENS resolver interface methods
    //
    // ------------------------



    function getOwnerFromDetails(bytes32 _subnodeHash)
        private
        view
        returns (address)
    {
        NftDetails memory details = SubnodeToNftDetails[_subnodeHash];
        require(details.ParentTokenId != 0, "subdomain not configured");
        address owner = details.NftAddress.ownerOf(details.NftId);
        return owner;
    }

    modifier isNftOwner(IERC721 _nftContract, uint96 _id) {
        require(_nftContract.ownerOf(_id) == msg.sender, "not owner of NFT");
        _;
    }

    modifier isEnsApprovedOrOwner(uint256 _ensId) {
        try EnsToken.ownerOf(_ensId) returns (address owner) {
            require(
                owner == msg.sender ||
                    (EnsToken.isApprovedForAll(owner, msg.sender) &&
                        owner != address(EnsNameWrapper)) ||
                    (owner == address(EnsNameWrapper) &&
                        owner != address(0) &&
                        EnsNameWrapper.isTokenOwnerOrApproved(
                            bytes32(_ensId),
                            msg.sender
                        )),
                "not owner or approved"
            );
        } catch {
            require(false, "not owner or approved");
        }
        _;
    }

    function namehashFromId(uint256 _id)
        public
        view
        returns (bytes32 _namehash)
    {
        _namehash = bytes32(_id);
        if (
            !(address(EnsNameWrapper) != address(0) &&
                EnsNameWrapper.ownerOf(_id) != address(0))
        ) {
            _namehash = keccak256(
                abi.encodePacked(
                    bytes32(
                        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae
                    ),
                    _namehash
                )
            );
        }
    }

    function setNameWrapper(address _addr) external payable {
        require(msg.sender == deployer, "only deployer");
        EnsNameWrapper = INameWrapper(_addr);
    }

    //just in case we have any funds being accidently sent to the contract
    //payable functions are cheaper than none-payable.
    function withdraw() external payable {
        payable(deployer).transfer(address(this).balance);
    }

    modifier authorised(bytes32 _subnodeHash) {
        address owner = getOwnerFromDetails(_subnodeHash);
        require(owner == msg.sender, "not owner of subdomain");
        _;
    }
}