// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlEnumerableUpgradeable, IAccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {ERC721AUpgradeable} from "./ERC721A/ERC721AUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IAnomuraEquipment, EquipmentMetadata, EquipmentType, EquipmentRarity} from "./interfaces/IAnomuraEquipment.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import {LicenseVersion, CantBeEvilUpgradable} from "./CantBeEvilUpgradable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import { IERC5050Receiver } from "@sharedstate/verbs/contracts/interfaces/IERC5050.sol";

/// @notice Anomura Equipment contract
contract AnomuraEquipment is
    Initializable,
    ERC721AUpgradeable,
    AccessControlEnumerableUpgradeable,
    EIP712Upgradeable,
    CantBeEvilUpgradable,
    IAnomuraEquipment
{
    using ECDSAUpgradeable for bytes32;
    
    event ControllerApprovalForAll(
        address indexed _controller,
        bool _approved
    );
    /// @dev Emit an event when a new merkle root is set
    event UpdatedMerkleRootOfClaim(bytes32 newHash, address updatedBy);

    /// @dev Emit an event when the contract is deployed
    event ContractDeployed(address owner);

    /// @dev Emit an event when proxy is approved 
    event ProxyApprovalSet(address proxy, bool isApproved);

    /// @dev Emit an event when metadata is reveal so an offchain source can build the metadata equipment
    event EquipmentMetadataSet(
        uint256 indexed equipmentId,
        string equipmentName,
        EquipmentType equipmentType,
        EquipmentRarity equipmentRarity
    );

     /// @dev Emit an event when contract is paused 
    event UpdatedPauseContract(bool isPaused, address updatedBy);

    /**
     * @dev Used to validate merke root
     */
    bytes32 private _claimMerkleRoot;
    bytes32 public constant SET_METADATA_ROLE = keccak256("SET_METADATA_ROLE");

    address private _signerAddress;
    address private actionDelegate;
    string private _equipmentURI;

    bool public claimLive;
    bool public isPaused;

    mapping(address => bool) public proxyToApproved;

    mapping(string => bool) private _usedNonces;

    /**
     * @dev Keep track of which tokenId has meta reveal
     */
    mapping(uint256 => bool) private _isMetadataReveal;

    /**
     * @dev Keep track of which address has claimed the equipment
     */
    mapping(address => bool) public claimed;

    /**
    * @dev Keep track of which action delegate methods are allowed for fallback
    */
    mapping(bytes4 => bool) public actionDelegateMethods;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    /**
     * @dev Throw when the submitted proof not valid under its root
     */
    modifier isValidMerkleProof(
        bytes32[] calldata _merkleProof,
        bytes32 _root
    ) {
        require(_root != "", "root is empty");
        require(
            MerkleProofUpgradeable.verify(
                _merkleProof,
                _root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function initialize() external initializer {
        __ERC721A_init("Anomura Equipment", "AEQP");
        __AccessControlEnumerable_init();
        __CantBeEvil_init(LicenseVersion.PUBLIC);
        __EIP712_init("AnomuraEquipment", "1");
       
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SET_METADATA_ROLE, _msgSender());

        claimLive = false;
        isPaused = false;

        actionDelegateMethods[bytes4(keccak256("onActionReceived(Action,uint256)"))] = true;
        actionDelegateMethods[bytes4(keccak256("receivableActions()"))] = true;
        actionDelegateMethods[bytes4(keccak256("setControllerApproval(address,bytes4,bool)"))] = true;
        actionDelegateMethods[bytes4(keccak256("setControllerApprovalForAll(address,bool)"))] = true;
        actionDelegateMethods[bytes4(keccak256("isApprovedController(address,bytes4)"))] = true;
        actionDelegateMethods[bytes4(keccak256("setProxyRegistry(address)"))] = true;
        actionDelegateMethods[bytes4(keccak256("__ERC5050_init()"))] = true;

        emit ContractDeployed(msg.sender);
    }

    function isTokenExists(uint256 tokenId) external view returns (bool) {
        if (_exists(tokenId)) {
            return true;
        }
        return false;
    }

    function claim(
        bytes32[] calldata claimProof,
        bytes memory signature,
        uint256 quantity,
        string memory nonce
    ) external isValidMerkleProof(claimProof, _claimMerkleRoot) {
        require(claimLive, "Claim is not live");
        require(!_usedNonces[nonce], "Nonce used.");
        require(!claimed[msg.sender], "Already claim.");

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Claim(address sender,uint256 quantity,string nonce)"
                    ),
                    msg.sender,
                    quantity,
                    keccak256(bytes(nonce))
                )
            )
        );

        require(ECDSAUpgradeable.recover(digest, signature) == _signerAddress, "Wrong signer");

        _safeMint(msg.sender, quantity);
        _usedNonces[nonce] = true;
        claimed[msg.sender] = true;
    }

    /**
    @notice Airdrop mystery parts to receiver.
    @param receiver Address of the receiver
    @param amount Number of token to receive
    */
    function airDropMysteryPart(address receiver, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _safeMint(receiver, amount);
    }

    function isMetadataReveal(uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isMetadataReveal[_tokenId];
    }

    /** 
        @dev to be called from anomuraSeeder through automation registry node 
    **/
    function revealMetadataForToken(bytes calldata performData)
        external
        onlyRole(SET_METADATA_ROLE)
    {
        require(!isPaused, "Is Paused");

        (uint256 tokenId, EquipmentMetadata memory metaData) = abi.decode(
            performData,
            (uint256, EquipmentMetadata)
        );

        _isMetadataReveal[tokenId] = true;

        emit EquipmentMetadataSet(
            tokenId,
            metaData.name,
            metaData.equipmentType,
            metaData.equipmentRarity
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            AccessControlEnumerableUpgradeable,
            ERC721AUpgradeable,
            CantBeEvilUpgradable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            type(IAccessControlEnumerableUpgradeable).interfaceId ==
            interfaceId ||
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            CantBeEvilUpgradable.supportsInterface(interfaceId) ||
             type(IERC5050Receiver).interfaceId  == interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     *
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override (ERC721AUpgradeable, IERC721Upgradeable)
        returns (bool)
    {
        if (proxyToApproved[operator]) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256[] memory a = new uint256[](balanceOf(owner));
            uint256 end = _currentIndex;
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            for (uint256 i; i < end; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    a[tokenIdsIdx++] = i;
                }
            }
            return a;
        }
    }

    // ============ ONLY ADMIN FUNCTIONS ============
     
    /**
    @notice To set new _equipmentURI for tokenId
    @param baseURI_ new base URI
    */
    function setBaseURI(string calldata baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _equipmentURI = baseURI_;
    }

    function setProxyState(address proxyAddress_, bool isApproved_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        proxyToApproved[proxyAddress_] = isApproved_;
        emit ProxyApprovalSet(proxyAddress_, isApproved_);
    }

    function setSignerAddress(address signerAddress_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _signerAddress = signerAddress_;
    }

    /**
    @notice Manual set a new claim merkle root
    @param merkleRoot_ new merkle root
    */
    function setClaimMerkleRoot(bytes32 merkleRoot_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _claimMerkleRoot = merkleRoot_;
        emit UpdatedMerkleRootOfClaim(merkleRoot_, msg.sender);
    }

    function toggleClaimStatus() 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        claimLive = !claimLive;
    }

    // ======================= ERC5050 ACTION DELEGATE LOGIC ======================= 
    function setActionDelegate(address actionDelegate_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        actionDelegate = actionDelegate_;
    }

    // Check if the function is delegated and execute the
    // function using the delegate and return any value.
    fallback() external payable {
        // require(actionDelegateMethods[msg.sig], "Function does not exist");
        address _actionDelegate = actionDelegate;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _actionDelegate, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // ============INTERNAL ============

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _equipmentURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}