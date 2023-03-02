/* 
This contract can be used to burn Polymon NFTs that are Eggs. The information if a Polymon NFT is an egg is provided via signed message by a trusted provider. 
*/

import "../utility-polymon-tracker/IUtilityPolymonTracker.sol";
import "../collection/MintableCollection.sol";
import "../common/interfaces/ITransferFromAndBurnFrom.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CrystalHatch is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    string public constant name = "CrystalHatch";
    address public trustedSigner;

    IUtilityPolymonTracker public utilityPolymonTracker;
    MintableCollection public collection;
    uint256 public currentId;

    uint256 public numOfHatches;
    uint256 public maxNumOfHatches;

    ITransferFrom public pmonToken;
    uint256 public pmonPerHatch;
    address rewardAddress;

    event CrystalHatch(
        address indexed owner,
        uint256 indexed burned,
        uint256 indexed minted
    );

    function initialize(
        IUtilityPolymonTracker _utilityPolymonTracker,
        MintableCollection _collection,
        uint256 _currentId,
        address _trustedSigner,
        uint256 _maxNumOfHatches,
        uint256 _pmonPerHatch,
        ITransferFrom _pmonToken,
        address _rewardAddress
    ) public initializer {
        utilityPolymonTracker = _utilityPolymonTracker;
        collection = _collection;
        currentId = _currentId;
        trustedSigner = _trustedSigner;
        maxNumOfHatches = _maxNumOfHatches;
        pmonPerHatch = _pmonPerHatch;
        pmonToken = _pmonToken;
        rewardAddress = _rewardAddress;

        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
    }

    // hatching for softminted tokens
    function hatchSoftminted(
        IUtilityPolymonTracker.SoftMintedData memory softMinted,
        bytes memory signature,
        uint256 expiryTimestamp
    ) external whenNotPaused {
        require(
            ++numOfHatches < maxNumOfHatches,
            "Max number of hatches reached"
        );
        _burn(softMinted);
        if (pmonPerHatch > 0)
            pmonToken.transferFrom(msg.sender, rewardAddress, pmonPerHatch);
        require(
            signatureVerification(
                msg.sender,
                softMinted.id,
                expiryTimestamp,
                signature
            ),
            "Invalid signer or signature"
        );
        emit CrystalHatch(msg.sender, softMinted.id, currentId);
        collection.mint(msg.sender, currentId++);
    }

    // hatching for hardminted tokens
    function hatch(
        uint256 hardMinted,
        bytes memory signature,
        uint256 expiryTimestamp
    ) external whenNotPaused {
        require(
            ++numOfHatches < maxNumOfHatches,
            "Max number of hatches reached"
        );
        _burn(hardMinted);
        if (pmonPerHatch > 0)
            pmonToken.transferFrom(msg.sender, rewardAddress, pmonPerHatch);
        require(
            signatureVerification(
                msg.sender,
                hardMinted,
                expiryTimestamp,
                signature
            ),
            "Invalid signer or signature"
        );
        emit CrystalHatch(msg.sender, hardMinted, currentId);
        collection.mint(msg.sender, currentId++);
    }

    // burning for softminted tokens
    function _burn(IUtilityPolymonTracker.SoftMintedData memory softMinted)
        internal
    {
        require(
            utilityPolymonTracker.isOwnerSoftMinted(msg.sender, softMinted),
            "Invalid soft minted token ID"
        );
        utilityPolymonTracker.burnToken(msg.sender, softMinted.id, false);
    }

    // burning for hardminted tokens
    function _burn(uint256 hardMinted) internal {
        require(
            utilityPolymonTracker.isOwnerHardMinted(msg.sender, hardMinted),
            "Invalid hard minted token ID"
        );
        utilityPolymonTracker.burnToken(msg.sender, hardMinted, true);
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
        require(signature.length == 65);

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
        uint256 id,
        uint256 expiryTimestamp,
        bytes memory signature
    ) private view returns (bool) {
        require(expiryTimestamp > block.timestamp, "Signature expired");
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        (sigV, sigR, sigS) = splitSignature(signature);
        bytes32 msg = keccak256(
            abi.encodePacked(
                id,
                sender,
                address(this),
                getChainId(),
                name,
                expiryTimestamp
            )
        );
        return
            trustedSigner ==
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", msg)
                ),
                sigV,
                sigR,
                sigS
            );
    }

    // internal method to get the chainId of the current network
    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /** ADMIN FUNCTIONS */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setUtilityPolymonTracker(
        IUtilityPolymonTracker _utilityPolymonTracker
    ) external onlyOwner {
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

    function setMaxNumOfHatches(uint256 _maxNumOfHatches) external onlyOwner {
        maxNumOfHatches = _maxNumOfHatches;
    }

    function setPmonPerHatch(uint256 _pmonPerHatch) external onlyOwner {
        pmonPerHatch = _pmonPerHatch;
    }

    function setPmonToken(ITransferFrom _pmonToken) external onlyOwner {
        pmonToken = _pmonToken;
    }

    function setRewardAddress(address _rewardAddress) external onlyOwner {
        rewardAddress = _rewardAddress;
    }
}