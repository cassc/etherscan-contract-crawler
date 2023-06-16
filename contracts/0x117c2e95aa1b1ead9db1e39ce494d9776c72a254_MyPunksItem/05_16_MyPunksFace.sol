// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MyPunksItem.sol";
import "./ERC721A.sol";

/**
  __  ____   _____ _   _ _  _ _  _____ 
 |  \/  \ \ / / _ \ | | | \| | |/ / __|
 | |\/| |\ V /|  _/ |_| | .` | ' <\__ \
 |_|  |_| |_| |_|  \___/|_|\_|_|\_\___/
                                       
        Customize Your Own Punks                                        
 */

contract MyPunksFace is ERC721A, IERC721Receiver, AccessControl {
    using ECDSA for bytes32;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public immutable collectionSize;
    uint256 public immutable amountReserved;
    uint256 public reserveMinted;

    bool public stakingPaused;
    bool public mintingPaused;

    string private _currentBaseURI;

    address public itemContract;
    address public cSigner;
    address private owner;

    mapping(uint256 => uint256[]) private items;
    mapping(uint256 => string) public customNames;

    struct SaleConfig {
        uint32 saleStartTime;
        uint256 amountSale;
        uint256 amountMinted;
        uint256 maxClaim;
        bool isPublicSale;
    }

    SaleConfig public faceSale;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountReserved_,
        bool stakingPaused_,
        bool mintingPaused_,
        address cSigner_
    ) ERC721A("MyPunks Face", "MPFACE", maxBatchSize_) {
        collectionSize = collectionSize_;
        amountReserved = amountReserved_;
        stakingPaused = stakingPaused_;
        mintingPaused = mintingPaused_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        cSigner = cSigner_;
        owner = msg.sender;
    }

    modifier mintable() {
        require(mintingPaused == false, "Mint is disabled");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * ======================================================================================
     *
     *  Token Minting
     *
     * ======================================================================================
     */

    function claimFace(bytes memory _signature) external mintable callerIsUser {
        uint256 saleStartTime = uint256(faceSale.saleStartTime);
        require(
            numberMinted(msg.sender) < faceSale.maxClaim,
            "You've already claimed, mate."
        );
        require(
            (faceSale.amountMinted < faceSale.amountSale) &&
                (totalSupply() < collectionSize),
            "Faces are all minted"
        );
        require(
            saleStartTime != 0 && saleStartTime <= block.timestamp,
            "Time Locked"
        );
        if (!faceSale.isPublicSale) {
            require(isMsgValid(_signature) == true, "Invalid Signature"); // Signed Whitelist Minting Only
        }
        _safeMint(msg.sender, 1);
        faceSale.amountMinted++;
    }

    /**
        @dev Reserved Token Minting
    */
    function mintReserved(address _to, uint256 _amount)
        external
        mintable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(totalSupply() < collectionSize, "All Faces are minted");
        require(
            reserveMinted + _amount < amountReserved + 1,
            "Reserved are all minted"
        );
        _safeMint(_to, _amount);
        reserveMinted += _amount;
    }

    /**
        @dev This is used to plugin other contract to mint the item, eg. staking contract
    */
    function mintByMinter(address _to, uint256 _amount)
        external
        mintable
        onlyRole(MINTER_ROLE)
    {
        require(totalSupply() < collectionSize, "All Faces are minted");
        _safeMint(_to, _amount);
    }

    /**
     * ======================================================================================
     *
     *  Item Equipment and Staking
     *
     * ======================================================================================
     */

    function getOwnedTokens(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_address);
        uint256[] memory result = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            result[i] = tokenOfOwnerByIndex(_address, i);
        }
        return result;
    }

    /**
     * @dev Receiver function to receive the NFT Tokens, and then added to item collection associated with Face Token Id
     * @param _from address of the stakeholder
     * @param _tokenId the token id
     * @return selector
     */
    function onERC721Received(
        address _from,
        address,
        uint256 _tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        // locate the face which the item should be put
        uint256 faceId = toUint256(data);
        require(msg.sender == itemContract, "Invalid ERC721 Transferred");
        require(
            ownerOf(faceId) == _from,
            "Invalid Staking. Face does not belongs to the staker."
        );
        items[faceId].push(_tokenId);
        return this.onERC721Received.selector;
    }

    /**
     * @dev Get staked items
     * @param _tokenId  The Face Token Id
     * @return array of staked token id
     */
    function stakedItems(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return items[_tokenId];
    }

    /**
     * @dev Check if current user staked the item, and return the index of staked item
     * @notice if it returns an invalid index(eg. index > arr.length), then the item is absense in this array.
     * @notice we use this method because it can perform find and return the index within one operation.
     * @param _itemTokenId Mypunks Item Token Id
     * @param _faceTokenId Face Token Id
     * @return index of the token id, if no item present, return a invalid number
     */
    function isItemStaked(uint256 _itemTokenId, uint256 _faceTokenId)
        public
        view
        returns (uint256)
    {
        // Default value is invalid
        uint256 index = items[_faceTokenId].length + 1;

        for (uint256 i = 0; i < items[_faceTokenId].length; i++) {
            if (items[_faceTokenId][i] == _itemTokenId) {
                index = i;
            }
        }

        return index;
    }

    /**
     * @dev Remove an index from an array
     * @param _index item index
     * @param _faceTokenId the face token id
     */
    function remove(uint256 _index, uint256 _faceTokenId) private {
        // move array elements
        for (uint256 i = _index; i < items[_faceTokenId].length - 1; i++) {
            items[_faceTokenId][i] = items[_faceTokenId][i + 1];
        }
        // pop the last element
        items[_faceTokenId].pop();
    }

    /**
     * @dev Remove an index from an array
     * @param _itemTokenIds ids of item to withdraw
     * @param _faceTokenId id of face to withdraw from
     */
    function withdraw(uint256[] memory _itemTokenIds, uint256 _faceTokenId)
        public
    {
        require(stakingPaused == false, "Staking Paused");
        require(
            ownerOf(_faceTokenId) == msg.sender,
            "Unauthorized withdrawal. You must be the owner."
        );

        for (uint256 i = 0; i < _itemTokenIds.length; i++) {
            uint256 itemIndex = isItemStaked(_itemTokenIds[i], _faceTokenId);
            // Check if the item has staked by user
            require(
                itemIndex < items[_faceTokenId].length,
                "Invalid withdrawal. This face does not have the item."
            );
            // Remove the item from staking
            remove(itemIndex, _faceTokenId);
            MyPunksItem Item = MyPunksItem(itemContract);
            Item.unstakeItem(msg.sender, _itemTokenIds[i]);
        }
    }

    /**
     * ======================================================================================
     *
     *  Naming
     *
     * ======================================================================================
     */

    /**
        @dev Set a customized name of token. Caller must be the token owner.
    */
    function setName(uint256 _tokenId, string memory _customName) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You're not authorized to set the name"
        );
        require(bytes(_customName).length <= 20, "Exceed Maximum Name Length");
        customNames[_tokenId] = _customName;
    }

    /**
     * ======================================================================================
     *
     *  Contract Configurations
     *
     * ======================================================================================
     */

    function setFaceSale(
        uint32 _saleStartTime,
        uint256 _amountSale,
        uint256 _amountMinted,
        uint256 _maxClaim,
        bool _isPublicSale
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _amountSale <
                collectionSize - (faceSale.amountMinted + amountReserved) + 1,
            "Exceeding Sale Limit"
        );
        faceSale.amountSale = _amountSale;
        faceSale.amountMinted = _amountMinted;
        faceSale.saleStartTime = _saleStartTime;
        faceSale.maxClaim = _maxClaim;
        faceSale.isPublicSale = _isPublicSale;
    }

    function pauseMint(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintingPaused = _paused;
    }

    function pauseStaking(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingPaused = _paused;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory _URI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _currentBaseURI = _URI;
    }

    function setItemContract(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        itemContract = _address;
    }

    function setMinter(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, _address);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isMsgValid(bytes memory _signature) private view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(address(this), msg.sender)
        );
        address signer = messageHash.toEthSignedMessageHash().recover(
            _signature
        );
        return cSigner == signer;
    }

    function setSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cSigner = _signer;
    }
}