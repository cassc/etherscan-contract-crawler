// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BearSwap is Ownable, ERC1155Holder {
    using Address for address;
    enum AssetType {
        UNSET,
        BACKGROUND,
        MUSIC
    }

    enum State {
        Open,
        Closed
    }

    struct BearLocked {
        uint256 background;
        uint256 music;
    }

    State private _state;
    IERC721 public bearAddress;
    IERC1155 public sceneSoundAddress;
    bytes32 private merkleRoot;

    mapping(uint256 => BearLocked) public bearLock;

    mapping(uint256 => bool) public bearHasDefault;

    mapping(uint256 => AssetType) public assetTypes;

    event Swap(
        address by,
        uint256 backgroundAssetLockIn,
        uint256 musicAssetLockIn,
        uint256 indexed tokenId
    );

    event BearAddressUpdated(address _address);
    event SceneSoundAddressUpdated(address _address);
    event AssetTypeUpdated(uint256 assetId, AssetType assetType);
    event RootUpdated(bytes32 _merkleRoot);
    event DefaultForAssetSet(uint256 indexed _tokenId);
    event EmergencyAssetsWithdrawn(uint256[] _ids, uint256[] _amounts);
    event StateUpdated(State _val);

    constructor(
        bytes32 _merkleRoot,
        address _bearAddress,
        address _sceneSoundAddress
    ) {
        bearAddress = IERC721(_bearAddress);
        sceneSoundAddress = IERC1155(_sceneSoundAddress);
        merkleRoot = _merkleRoot;
        _state = State.Closed;
    }

    /* @dev: Setter for Partybear
     * @param: Address location of Partybear
     */
    function setBearAddress(address _address) external onlyOwner {
        bearAddress = IERC721(_address);
        emit BearAddressUpdated(_address);
    }

    /* @dev: Setter for Scenes and Sounds
     * @param: Address of Scene Sounds ERC1155
     */
    function setSceneSoundAddress(address _address) external onlyOwner {
        sceneSoundAddress = IERC1155(_address);
        emit SceneSoundAddressUpdated(_address);
    }

    /* @dev: Setter for AssetType
     * @param: AssetId and the AssetType (Background or Sound)
     */
    function setAssetType(uint256 assetId, AssetType assetType)
        external
        onlyOwner
    {
        assetTypes[assetId] = assetType;
        emit AssetTypeUpdated(assetId, assetType);
    }

    /* @dev: Setter for MerkleTree Root Hash
     * @param: Bytes root hash
     */
    function setRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit RootUpdated(_merkleRoot);
    }

    /* @dev: Allow Swaps to happen
     */
    function setOpen() external onlyOwner {
        _state = State.Open;
        emit StateUpdated(State.Open);
    }

    /* @dev: Disallow Swaps from happening
     */
    function setClosed() external onlyOwner {
        _state = State.Closed;
        emit StateUpdated(State.Closed);
    }

    /* @dev: Setter for AssetTypes in batches
     * @param: AssetId as array and the AssetType as array (Background or Sound)
     */
    function setAssetTypeBatch(
        uint256[] calldata _assetIds,
        AssetType[] calldata _assetTypes
    ) external onlyOwner {
        require(
            _assetIds.length == _assetTypes.length,
            "array lengths not identical"
        );
        for (uint256 i = 0; i < _assetIds.length; i++) {
            assetTypes[_assetIds[i]] = _assetTypes[i];
            emit AssetTypeUpdated(_assetIds[i], _assetTypes[i]);
        }
    }

    /* @dev: Sets the intial vault value for a bear
     * @param: The proof, tokenId, default background and default sound
     */
    function setDefaultForBear(
        bytes32[] calldata proof,
        uint256 _tokenId,
        uint256 _defaultBackground,
        uint256 _defaultMusic
    ) internal isBackground(_defaultBackground) isMusic(_defaultMusic) {
        require(!bearHasDefault[_tokenId], "asset already has default");
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(
                    abi.encodePacked(
                        _tokenId,
                        _defaultBackground,
                        _defaultMusic
                    )
                )
            ),
            "invalid merkle proof"
        );
        bearLock[_tokenId].background = _defaultBackground;
        bearLock[_tokenId].music = _defaultMusic;
        bearHasDefault[_tokenId] = true;
        emit DefaultForAssetSet(_tokenId);
    }

    function adminSetDefaultForBear(
        uint256 _tokenId,
        uint256 _defaultBackground,
        uint256 _defaultMusic
    ) external onlyOwner {
        bearLock[_tokenId].background = _defaultBackground;
        bearLock[_tokenId].music = _defaultMusic;
        bearHasDefault[_tokenId] = true;
        emit DefaultForAssetSet(_tokenId);
    }

    /* @dev: Perform a swap
     * @param: The tokenId, the background you want to lock in, and the music asset you want to lock in
     */
    function swap(
        bytes32[] calldata proof,
        uint256 tokenId,
        uint256 backgroundAssetLockIn,
        uint256 musicAssetLockIn,
        uint256 _defaultBackground,
        uint256 _defaultMusic
    ) external isBackground(backgroundAssetLockIn) isMusic(musicAssetLockIn) {
        require(_state == State.Open, "swaps not open");
        require(msg.sender == tx.origin, "contracts not allowed");
        require(!Address.isContract(msg.sender), "contracts not allowed");
        require(
            bearAddress.ownerOf(tokenId) == msg.sender,
            "you can't mess with other peoples bears"
        );
        if (!bearHasDefault[tokenId]) {
            setDefaultForBear(
                proof,
                tokenId,
                _defaultBackground,
                _defaultMusic
            );
        }
        require(bearHasDefault[tokenId], "asset default was not set yet");
        require(
            sceneSoundAddress.isApprovedForAll(msg.sender, address(this)),
            "not approved to transfer"
        );

        // If the background is the same no need to do it
        bool doBackground = backgroundAssetLockIn !=
            bearLock[tokenId].background;
        // If the music one is the same there is no need to do it
        bool doMusic = musicAssetLockIn != bearLock[tokenId].music;
        require(doBackground || doMusic, "no need to swap");

        uint256 itemsToSwap = 1;
        if (doBackground && doMusic) {
            itemsToSwap = 2;
        }

        uint256[] memory idsToVault = new uint256[](itemsToSwap);
        uint256[] memory idsToUser = new uint256[](itemsToSwap);
        uint256[] memory amounts = new uint256[](itemsToSwap);

        if (doBackground) {
            idsToVault[0] = backgroundAssetLockIn;
            idsToUser[0] = bearLock[tokenId].background;
            amounts[0] = 1;
            bearLock[tokenId].background = backgroundAssetLockIn;
        }

        if (doMusic) {
            idsToVault[itemsToSwap - 1] = musicAssetLockIn;
            idsToUser[itemsToSwap - 1] = bearLock[tokenId].music;
            amounts[itemsToSwap - 1] = 1;
            bearLock[tokenId].music = musicAssetLockIn;
        }

        sceneSoundAddress.safeBatchTransferFrom(
            msg.sender,
            address(this),
            idsToVault,
            amounts,
            ""
        );
        sceneSoundAddress.safeBatchTransferFrom(
            address(this),
            msg.sender,
            idsToUser,
            amounts,
            ""
        );

        emit Swap(msg.sender, backgroundAssetLockIn, musicAssetLockIn, tokenId);
    }

    /* @dev: Emergency withdrawal
     * @param: The Ids and Amounts
     */
    function emergencyWithdrawAssets(
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        address _to
    ) external onlyOwner {
        sceneSoundAddress.safeBatchTransferFrom(
            address(this),
            _to,
            _ids,
            _amounts,
            ""
        );
        emit EmergencyAssetsWithdrawn(_ids, _amounts);
    }

    /* @dev: Verify whether asset is background
     */
    modifier isBackground(uint256 assetId) {
        require(
            assetTypes[assetId] == AssetType.BACKGROUND,
            "Not Background Asset"
        );
        _;
    }

    /* @dev: Verify whether asset is music
     */
    modifier isMusic(uint256 assetId) {
        require(assetTypes[assetId] == AssetType.MUSIC, "Not Music Asset");
        _;
    }
}