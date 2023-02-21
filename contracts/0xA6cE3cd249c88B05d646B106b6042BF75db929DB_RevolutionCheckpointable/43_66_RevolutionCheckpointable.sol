// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

import {IERC721Drop} from "./zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "./zora-drops-contracts/ERC721Drop.sol";
import {EditionMetadataRenderer} from "./zora-drops-contracts/metadata/EditionMetadataRenderer.sol";
import {DropMetadataRenderer} from "./zora-drops-contracts/metadata/DropMetadataRenderer.sol";
import {IMetadataRenderer} from "./zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {ERC721DropProxy} from "./zora-drops-contracts/ERC721DropProxy.sol";
//import {IERC721Votes} from "2022-09-nouns-builder/lib/interfaces/IERC721Votes.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC721CheckpointableStripped} from "./interfaces/IERC721CheckpointableStripped.sol";
import "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {OwnableSkeleton} from "./utils/OwnableSkeleton.sol";

contract RevolutionCheckpointable is OwnableSkeleton, AccessControlEnumerable {
    //bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public immutable implementation;
    EditionMetadataRenderer public immutable editionMetadataRenderer;
    DropMetadataRenderer public immutable dropMetadataRenderer;
    string private constant CANNOT_BE_ZERO = "Cannot be 0 address";
    //uint16 public SPLIT_BPS;
    IERC721CheckpointableStripped public immutable daoToken;
    address payable public fundsRecipient_;
    uint256 public MIN_VOTES;
    //seconds a prop has to be queued before it can be executed by the community
    uint256 public QUEUE_TIME = 86400;
    QueuedDrop queuedDrop;

    struct QueuedDrop {
        string name;
        string symbol;
        string description;
        string animationURI;
        string imageURI;
        uint104 mintPrice;
        address creator;
        uint256 queuedTime;
        string submissionId;
        bool isQueued;
    }

    event CreatedDrop(
        address indexed creator,
        address indexed editionContractAddress,
        string submissionId,
        uint256 editionSize
    );

    event MinVotesChanged(uint256 minVotes);

    event SplitChanged(uint16 split);

    //event RoyaltyAddressChanged(address royaltyAddress);

    constructor(
        address _implementation,
        EditionMetadataRenderer _editionMetadataRenderer,
        DropMetadataRenderer _dropMetadataRenderer,
        IERC721CheckpointableStripped _daoToken,
        address payable _fundsRecipient
    ) {
        require(_implementation != address(0), CANNOT_BE_ZERO);
        require(
            address(_editionMetadataRenderer) != address(0),
            CANNOT_BE_ZERO
        );
        require(address(_dropMetadataRenderer) != address(0), CANNOT_BE_ZERO);

        implementation = _implementation;
        editionMetadataRenderer = _editionMetadataRenderer;
        dropMetadataRenderer = _dropMetadataRenderer;
        daoToken = _daoToken;
        fundsRecipient_ = _fundsRecipient;

        //_setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setOwner(msg.sender);
        setMinVotes(2);
        //setSplit(50_00);
    }

    modifier hasVotesOrAdmin() {
        require(
            daoToken.getCurrentVotes(msg.sender) >= MIN_VOTES || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Does not have enough dao votes"
        );
        _;
    }


    //is admin or queue time has expired
    modifier canExecute() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                (queuedDrop.isQueued &&
                    block.timestamp >= queuedDrop.queuedTime + QUEUE_TIME),
            "You are not an admin or queue time has not expired"
        );
        _;
    }

    function setOwner(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setOwner(newOwner);
    }

    function hasVotesTest() external view hasVotesOrAdmin returns (uint64) {
        return 42;
    }

    function setMinVotes(uint256 newMinVotes) public onlyRole(DEFAULT_ADMIN_ROLE) {
        MIN_VOTES = newMinVotes;
        emit MinVotesChanged(MIN_VOTES);
    }

    //getter and setter for QUEUE_TIME
    function getQueueTime() external view returns (uint256) {
        return QUEUE_TIME;
    }

    function setQueueTime(uint256 newQueueTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        QUEUE_TIME = newQueueTime;
    }

    // function setSplit(uint16 newSplit) public isAdmin {
    //     SPLIT_BPS = newSplit;
    //     emit SplitChanged(SPLIT_BPS);
    // }

    function setFundsRecipient(address payable newFundsRecipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        fundsRecipient_ = newFundsRecipient;
        //emit RoyaltyAddressChanged(royaltyAddress);
    }

    function getMinVotes() external view returns (uint256) {
        return MIN_VOTES;
    }

    // function getSplit() external view returns (uint16) {
    //     return SPLIT_BPS;
    // }

    function getFundsRecipient() external view returns (address) {
        return fundsRecipient_;
    }

    function queueDrop(
        string memory name,
        string memory symbol,
        string memory description,
        string memory animationURI,
        string memory imageURI,
        uint104 mintPrice,
        address creator,
        string memory submissionId
    ) external hasVotesOrAdmin {
        QueuedDrop storage _queuedDrop = queuedDrop;
        _queuedDrop.name = name;
        _queuedDrop.symbol = symbol;
        _queuedDrop.description = description;
        _queuedDrop.animationURI = animationURI;
        _queuedDrop.imageURI = imageURI;
        _queuedDrop.mintPrice = mintPrice;
        _queuedDrop.creator = creator;
        _queuedDrop.queuedTime = block.timestamp;
        _queuedDrop.submissionId = submissionId;
        _queuedDrop.isQueued = true;
    }

    function getQueuedDrop()
        external
        view
        returns (QueuedDrop memory _queuedDrop)
    {
        return queuedDrop;
    }

    function rejectQueuedDrop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete queuedDrop;
    }

    function deployRevolutionDrop() external canExecute returns (address) {
        QueuedDrop memory _queuedDrop = queuedDrop;
        require(_queuedDrop.isQueued == true, "no queued drop present");
        delete queuedDrop;
        uint64 editionSize = type(uint64).max;
        address newDropAddress = 
            createEdition(
                _queuedDrop.name,
                _queuedDrop.symbol,
                editionSize,
                0,
                fundsRecipient_,
                owner(),
                IERC721Drop.SalesConfiguration({
                    publicSaleStart: uint64(block.timestamp),
                    publicSaleEnd: uint64(block.timestamp + 86400),
                    presaleStart: 0,
                    presaleEnd: 0,
                    publicSalePrice: _queuedDrop.mintPrice,
                    maxSalePurchasePerAddress: 0,
                    presaleMerkleRoot: bytes32(0)
                }),
                _queuedDrop.description,
                _queuedDrop.animationURI,
                _queuedDrop.imageURI
            );

        emit CreatedDrop({
            creator: msg.sender,
            editionSize: editionSize,
            editionContractAddress: newDropAddress,
            submissionId: _queuedDrop.submissionId
        });

        return newDropAddress;
    }

    function createEdition(
        string memory name,
        string memory symbol,
        uint64 editionSize,
        uint16 royaltyBPS,
        address payable fundsRecipient,
        address defaultAdmin,
        IERC721Drop.SalesConfiguration memory saleConfig,
        string memory description,
        string memory animationURI,
        string memory imageURI
    ) internal returns (address) {
        bytes memory metadataInitializer = abi.encode(
            description,
            imageURI,
            animationURI
        );

        return
            setupDropsContract({
                name: name,
                symbol: symbol,
                defaultAdmin: defaultAdmin,
                editionSize: editionSize,
                royaltyBPS: royaltyBPS,
                saleConfig: saleConfig,
                fundsRecipient: fundsRecipient,
                metadataRenderer: editionMetadataRenderer,
                metadataInitializer: metadataInitializer
            });
    }

    function createAndConfigureDrop(
        string memory name,
        string memory symbol,
        address defaultAdmin,
        uint64 editionSize,
        uint16 royaltyBPS,
        address payable fundsRecipient,
        bytes[] memory setupCalls,
        IMetadataRenderer metadataRenderer,
        bytes memory metadataInitializer
    ) internal returns (address payable newDropAddress) {
        ERC721DropProxy newDrop = new ERC721DropProxy(implementation, "");
        newDropAddress = payable(address(newDrop));
        ERC721Drop(newDropAddress).initialize({
            _contractName: name,
            _contractSymbol: symbol,
            _initialOwner: defaultAdmin,
            _fundsRecipient: fundsRecipient,
            _editionSize: editionSize,
            _royaltyBPS: royaltyBPS,
            _setupCalls: setupCalls,
            _metadataRenderer: metadataRenderer,
            _metadataRendererInit: metadataInitializer
        });
    }

    function setupDropsContract(
        string memory name,
        string memory symbol,
        address defaultAdmin,
        uint64 editionSize,
        uint16 royaltyBPS,
        address payable fundsRecipient,
        IERC721Drop.SalesConfiguration memory saleConfig,
        IMetadataRenderer metadataRenderer,
        bytes memory metadataInitializer
    ) internal returns (address) {
        bytes[] memory setupData = new bytes[](1);
        setupData[0] = abi.encodeWithSelector(
            ERC721Drop.setSaleConfiguration.selector,
            saleConfig.publicSalePrice,
            saleConfig.maxSalePurchasePerAddress,
            saleConfig.publicSaleStart,
            saleConfig.publicSaleEnd,
            saleConfig.presaleStart,
            saleConfig.presaleEnd,
            saleConfig.presaleMerkleRoot
        );
        address newDropAddress = createAndConfigureDrop({
            name: name,
            symbol: symbol,
            defaultAdmin: defaultAdmin,
            fundsRecipient: fundsRecipient,
            editionSize: editionSize,
            royaltyBPS: royaltyBPS,
            setupCalls: setupData,
            metadataRenderer: metadataRenderer,
            metadataInitializer: metadataInitializer
        });

        return newDropAddress;
    }
}