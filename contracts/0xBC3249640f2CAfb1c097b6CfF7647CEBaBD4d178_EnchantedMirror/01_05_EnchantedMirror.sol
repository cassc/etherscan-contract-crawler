//            //-----------\\
//          //       | |   | \\
//        //  \__   /   \ /  | \\
//       ||       \|     |  / __||
//       ||         \    | |_/  ||
//       ||\     __  |   |/ __  ||
//       ||  \__/   \|   |_/  \_||
//       ||  _    ___|  /  \_   ||
//       ||_/ \__/   |/_     \_/||
//       ||          o  \      _||
//       ||\       / |    \___/ ||
//       ||  \___/   |     \   /||
//       ||     |   / \_    )-<_||
//       ||    /  /     \  /    ||
//        \\ /   |      _><    //
//        //\\   |     /   \ //\\
//       ||   \\-----------//   ||
//       ||                     ||
//      /||\                   /||\
//     /____\                 /____\

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ICabinet is IERC1155 {
    function create(
        address initialOwner,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) external returns (uint256);
}

contract EnchantedMirror {
    event VictimTrapped(
        uint256 victimId,
        address victimAddress,
        uint256 culprit,
        address culpritAddress
    );
    event VictimSaved(
        uint256 victim,
        address victimAddress,
        uint256 savior,
        address saviorAddress
    );
    event MirrorBroken(uint256 breakerId, address breakerAddress);
    event ShardFound(
        string code,
        uint256 finderId,
        address finderAddress,
        uint256 indexed counter,
        address owner
    );

    struct Epoch {
        mapping(string => bool) codesUsed;
        address[] pastOwners;
        uint256 allShardsFoundTimestamp;
        bool mirrorBroken;
    }

    /**
     * Keeps track of number of breaking - repairing epochs
     */
    uint256 public counter = 0;
    uint256 private constant MAX_INT = 2**256 - 1;
    uint256 public victimId = MAX_INT;

    uint256 public claimPrice = 0.013 ether;

    uint256 public TOTAL_SHARDS;

    uint256 public shardId = MAX_INT;

    address public victimAddress;

    address wizardsAddress;
    address poniesAddress;
    address soulsAddress;
    address warriorsAddress;
    address cabinetAddress;
    address managerAddress;

    bytes32 public merkleRoot;

    uint16 public shardsFound;
    uint8 public constant LORB_ID = 0;
    uint8 public constant MIRROR_ID = 1;

    mapping(uint256 => Epoch) public epochs;

    constructor(
        address _cabinetAddress,
        address _wizardsAddress,
        address _soulsAddress,
        address _warriorsAddress,
        address _poniesAddress,
        uint256 _totalShards
    ) {
        cabinetAddress = _cabinetAddress;
        wizardsAddress = _wizardsAddress;
        soulsAddress = _soulsAddress;
        warriorsAddress = _warriorsAddress;
        poniesAddress = _poniesAddress;
        TOTAL_SHARDS = _totalShards;
    }

    /**
     * The manager is the owner of the Mirror token, making the game
     * contract a tradable asset.
     */
    modifier onlyManager() {
        require(
            IERC1155(cabinetAddress).balanceOf(msg.sender, MIRROR_ID) == 1,
            "You are not the owner of the Enchanted Mirror"
        );
        if (managerAddress != msg.sender) {
            managerAddress = msg.sender;
        }
        _;
    }

    /**
     * breaking the mirror starts the game, by issuing the shards. Can only break
     * a non-broken mirror, a wizard has to be trapped inside, and only a wizard,
     * warrior, soul or pony can break the mirror.
     */
    function breakMirror(uint256 breakerId, address breakerAddress) external {
        require(!epochs[counter].mirrorBroken, "mirror is already broken");
        require(
            victimId != MAX_INT,
            "The mirror without a victim trapped is just an illusion"
        );
        string memory breakerAssetType = _getAssetType(breakerAddress);
        require(
            keccak256(abi.encodePacked(breakerAssetType)) !=
                keccak256(abi.encodePacked("invalid")) &&
                IERC721(breakerAddress).ownerOf(breakerId) == msg.sender,
            "Only creatures of the Runiverse can break the mirror"
        );
        epochs[counter].mirrorBroken = true;

        shardId = ICabinet(cabinetAddress).create(
            address(this),
            TOTAL_SHARDS,
            "ipfs://Qmbphxjagw1YDg3VWvhSZq2Uo3AErF1qC6HsVm48ncH914",
            ""
        );

        emit MirrorBroken(breakerId, breakerAddress);
    }

    function updatePastOwners(address account) external {
        require(
            msg.sender == cabinetAddress,
            "unauthorized to update past owners"
        );
        epochs[counter].pastOwners.push(account);
    }

    function getPastOwners(uint256 epoch)
        external
        view
        returns (address[] memory)
    {
        return epochs[epoch].pastOwners;
    }

    /**
     * A broken mirror can only be repaired by a wizard or a soul.
     * The repairer with the most shards can repair the mirror.
     * Repairing the mirror frees the trapped victim, and the caller
     * becomes its owner, and the owner of the mirror.
     */
    function repairMirror(uint256 repairerId, address repairerAddress) public {
        require(epochs[counter].mirrorBroken, "The mirror is not broken");
        require(shardsFound == TOTAL_SHARDS, "Not all shards were found");
        address _wizardsAddress = wizardsAddress;
        bool isWizardOrSoul = repairerAddress == _wizardsAddress ||
            repairerAddress == soulsAddress;
        require(
            isWizardOrSoul &&
                IERC721(repairerAddress).ownerOf(repairerId) == msg.sender,
            "Only magicians can fix the mirror"
        );

        bool isRepairerBiggestHolder = true;
        uint256[] memory ids = new uint256[](epochs[counter].pastOwners.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            ids[i] = shardId;
        }
        uint256[] memory shardBalance = IERC1155(cabinetAddress).balanceOfBatch(
            epochs[counter].pastOwners,
            ids
        );
        uint256 repairerBalance = IERC1155(cabinetAddress).balanceOf(
            msg.sender,
            shardId
        );
        for (uint256 i = 0; i < epochs[counter].pastOwners.length; ++i) {
            if (shardBalance[i] > repairerBalance) {
                isRepairerBiggestHolder = false;
                break;
            }
        }

        require(isRepairerBiggestHolder, "Repairer has to own the most shards");
        require(
            block.timestamp > epochs[counter].allShardsFoundTimestamp + 2 days,
            "two days has to pass after finding all shards"
        );

        // if any funds are left, transfer to the current manager
        payable(managerAddress).call{value: address(this).balance}("");

        // the mirror goes to the wizard who repaired it
        IERC1155(cabinetAddress).safeTransferFrom(
            managerAddress,
            msg.sender,
            MIRROR_ID,
            1,
            ""
        );
        IERC721(_wizardsAddress).safeTransferFrom(
            address(this),
            msg.sender,
            victimId
        );

        emit VictimSaved(victimId, victimAddress, repairerId, repairerAddress);
        epochs[counter].mirrorBroken = false;
        victimId = MAX_INT;
        victimAddress = address(0);
        shardsFound = 0;
        counter++;
    }

    /**
     * Claim shards by finding the codes which scattered across
     * the runiverse. Only broken mirrors have shards, and each
     * code can be used once.
     */
    function claimShard(
        string calldata code,
        bytes32[] calldata proof,
        address finderAddress,
        uint256 finderId
    ) external payable {
        require(epochs[counter].mirrorBroken, "The mirror is not broken");
        require(
            _verify(_leaf(code), proof),
            "Don't try to temper with magic you don't fully understand"
        );
        string memory finderAssetType = _getAssetType(finderAddress);
        require(
            keccak256(abi.encodePacked(finderAssetType)) !=
                keccak256(abi.encodePacked("invalid")) &&
                IERC721(finderAddress).ownerOf(finderId) == msg.sender,
            "Only creatures of the Runiverse can find the shards"
        );
        Epoch storage epoch = epochs[counter];
        require(
            epoch.codesUsed[code] == false,
            "This shard of the mirror has been already found"
        );
        require(msg.value >= claimPrice, "Ether value sent is not sufficient");
        epoch.codesUsed[code] = true;
        IERC1155(cabinetAddress).safeTransferFrom(
            address(this),
            msg.sender,
            shardId,
            1,
            ""
        );

        shardsFound++;

        if (shardsFound == TOTAL_SHARDS) {
            epoch.allShardsFoundTimestamp = block.timestamp;
        }

        emit ShardFound(code, finderId, finderAddress, counter, msg.sender);
    }

    /**
     * A wizard or a soul can use the mirror to trap a victim, which can be a wizard
     * or a warrior. The mirror may be broken, in which case all shards have to be
     * found to repair it and free the trapped victim.
     */
    function trap(
        uint256 _victimId,
        address _victimAddress,
        uint256 _culpritId,
        address _culpritAddress
    ) external onlyManager {
        address _wizardsAddress = wizardsAddress;

        bool _isVictimWizard = _victimAddress == _wizardsAddress;
        bool _isCulpritWizard = _culpritAddress == _wizardsAddress;

        require(
            (_isVictimWizard || _victimAddress == warriorsAddress) &&
                IERC721(_victimAddress).ownerOf(_victimId) == msg.sender,
            "Can only trap a wizard or a warrior"
        );
        require(
            (_isCulpritWizard || _culpritAddress == soulsAddress) &&
                IERC721(_culpritAddress).ownerOf(_culpritId) == msg.sender,
            "Only a wizard or a soul can use the mirror"
        );

        require(victimId == MAX_INT, "There's a victim already trapped");

        IERC721(wizardsAddress).transferFrom(
            msg.sender,
            address(this),
            _victimId
        );

        victimAddress = _victimAddress;
        victimId = _victimId;
        emit VictimTrapped(
            _victimId,
            _victimAddress,
            _culpritId,
            _culpritAddress
        );
    }

    function _getAssetType(address contractAddress)
        internal
        view
        returns (string memory)
    {
        return
            contractAddress == wizardsAddress
                ? "wizard"
                : contractAddress == warriorsAddress
                ? "warrior"
                : contractAddress == soulsAddress
                ? "soul"
                : contractAddress == poniesAddress
                ? "pony"
                : "invalid";
    }

    function _leaf(string calldata code) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(code));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyManager {
        merkleRoot = _merkleRoot;
    }

    function setClaimPrice(uint256 _claimPrice) external onlyManager {
        require(
            !epochs[counter].mirrorBroken,
            "Cannot set price when mirror is broken"
        );
        claimPrice = _claimPrice;
    }

    function withdraw() external onlyManager {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Failure, ETH not sent");
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}