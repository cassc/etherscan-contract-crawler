import "../utility-polymon-tracker/IUtilityPolymonTracker.sol";
import "../IERC20Burnable.sol";
import "../collection/MintableCollection.sol";
import "../common/interfaces/IRewardable.sol";
import "../common/interfaces/ITransferFromAndBurnFrom.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CursedIngredientFusion is Initializable, OwnableUpgradeable, PausableUpgradeable {

    struct FusionData {
        uint256[] originIds;
        string typeString;
    }

    IUtilityPolymonTracker public utilityPolymonTracker;
    MintableCollection public collection;
    mapping(uint256 => FusionData) public _fusionData;
    uint256 public currentId;
    
    uint256 public numOfFusions; 
    uint256 public maxNumOfFusions;

    string public typeString;

    address public trustedSigner;

    event FuseCursedIngridients(address indexed owner, uint256 indexed tokenId, string typeString, uint256 timestamp, uint256[] burnedIds);

    function initialize(
        IUtilityPolymonTracker _utilityPolymonTracker,
        MintableCollection _collection,
        uint256 _currentId,
        address _trustedSigner,
        uint256 _maxNumOfFusions,
        string memory _typeString
    ) public initializer {
        utilityPolymonTracker = _utilityPolymonTracker;
        collection = _collection;
        currentId = _currentId;
        trustedSigner = _trustedSigner;
        maxNumOfFusions = _maxNumOfFusions;
        typeString = _typeString;

        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
    }

   

    /** Fusing the Ingridients */
    function fuse(
        IUtilityPolymonTracker.SoftMintedData[] memory softMinted,
        uint256[] memory hardMinted,
        bytes memory signature,
        uint256 expiryTimestamp
    ) external whenNotPaused {
        // num of fusions has to be less than maxNumOfFusions
        require(numOfFusions < maxNumOfFusions, "Max number of fusions reached");

        uint256 numberOfIds = softMinted.length + hardMinted.length;

        if (numberOfIds != 4) revert("Invalid burn count");

        uint256[] memory idList = new uint256[](numberOfIds);
        uint256 counter;
        
        // burn soft minted tokens
        for (uint256 i = 0; i < softMinted.length; i++) {
            require(utilityPolymonTracker.isOwnerSoftMinted(msg.sender, softMinted[i]), "Invalid soft minted token ID");
            utilityPolymonTracker.burnToken(msg.sender, softMinted[i].id, false);
            idList[counter] = softMinted[i].id;
            counter++;
        }

        // burn hard minted tokens
        for (uint256 i = 0; i < hardMinted.length; i++) {
            require(utilityPolymonTracker.isOwnerHardMinted(msg.sender, hardMinted[i]), "Invalid hard minted token ID");
            utilityPolymonTracker.burnToken(msg.sender, hardMinted[i], true);
            idList[counter] = hardMinted[i];
            counter++;
        }

        require(signatureVerification(msg.sender, idList, "fuse", expiryTimestamp, signature), "Invalid signer or signature");

        collection.mint(msg.sender, currentId);

        _fusionData[currentId] = FusionData(idList, typeString);

        emit FuseCursedIngridients(msg.sender, currentId, typeString, block.timestamp, idList);
        ++currentId;
        ++numOfFusions;
    }

    /** PRIVATE VIEWER FUNCTIONS */ 
    function splitSignature(bytes memory signature)
        private
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        assembly {
            sigR := mload(add(signature, 32))
            sigS := mload(add(signature, 64))
            sigV := byte(0, mload(add(signature, 96)))
        }
        return (sigV, sigR, sigS);
    }

    function signatureVerification(
        address sender,
        uint256[] memory idList,
        string memory functionString,
        uint256 expiryTimestamp,
        bytes memory signature
    ) private view returns (bool) {
        require(expiryTimestamp > block.timestamp, "Signature expired");
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        (sigV, sigR, sigS) = splitSignature(signature);
        bytes32 msg = keccak256(abi.encodePacked(sender, idList, address(this), getChainId(), "fuse", expiryTimestamp));
        return trustedSigner == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msg)), sigV, sigR, sigS);
    }

    // internal method to get the chainId of the current network
    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /** EXTERNAL CLIENT VIEWER FUNCTIONS */
    
    function fusionData(uint256 id) external view returns (FusionData memory data) {
        return _fusionData[id];
    }

    function fusionDataList(uint256[] calldata ids) external view returns (FusionData[] memory) {
        FusionData[] memory list = new FusionData[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            list[i] = _fusionData[ids[i]];
        }
        return list;
    }

     /** ADMIN FUNCTIONS */

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setUtilityPolymonTracker(IUtilityPolymonTracker _utilityPolymonTracker) external onlyOwner {
        utilityPolymonTracker = _utilityPolymonTracker;
    }

    function setCollection(MintableCollection _collection) external onlyOwner {
        collection = _collection;
    }

    function setCurrentId(uint256 _currentId) external onlyOwner {
        currentId = _currentId;
    }

    function setTrustedSigner(address _trustedSigner) external onlyOwner {
        trustedSigner = _trustedSigner;
    }

    function setMaxNumberOfFusion(uint256 _maxNumberOfFusion) external onlyOwner {
        maxNumOfFusions = _maxNumberOfFusion;
    }

    function setTypeString(string calldata _typeString) external onlyOwner {
        typeString = _typeString;
    }
   
}