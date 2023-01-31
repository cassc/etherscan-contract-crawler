// contracts/Ancestor.sol
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./IAccessory.sol";

error InvalidMinter();
error TokenNotExist();
error AccessoryAddressNotSet();
error AccessoryTypeMismatch();
error AccessoryNotEquipped();
error NotTokenOwner();
error ContractPaused();

/// @title KPK Ancestor NFT
/// @author Teahouse Finance
contract Ancestors is
    ERC721,
    Ownable,
    ERC1155Receiver,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    using ECDSA for bytes32;

    struct Accessory {
        uint224 encodedAccessories;
        bool[6] isEquipped;
    }

    address public immutable scroll;
    address public accessoryAddress;

    //Is the contract paused ?
    bool public paused = false;
    string private baseURI;

    mapping(uint256 => Accessory) public tokenAccessoryData;

    event AccessoryWrapped(
        address indexed requestFrom,
        uint256 indexed tokenId,
        bool[6] isEquipedBefore,
        uint256[6] accessoriesIdsBefore,
        bool[6] isEquiped,
        uint256[6] accessoriesIds
    );

    event AccessoryUnwrapped(
        address indexed requestFrom,
        uint256 indexed tokenId,
        uint256[6] accessoriesIds,
        uint256[] UnequippedTokenIds
    );

    /// @param _name Name of Ancestor NFT collection
    /// @param _symbol Symbol of Ancestor NFT collection
    /// @param _scroll Address of Scroll contract
    constructor(
        string memory _name,
        string memory _symbol,
        address _scroll
    ) ERC721(_name, _symbol) {
        scroll = _scroll;
    }

    /// @notice Set token base URI
    /// @param _baseURI New token base URI
    /// @dev _baseURI sholud end with "/"
    /// @dev Only owner can do this
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Set pause to true or false
     *
     * @param _paused True or false if you want the contract to be paused or not
     **/
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /// @notice Set accessory address
    /// @param _accessoryAddress accessory address
    /// @dev Only owner can do this
    /// @dev This should be an ERC1155 NFT address
    /// @dev If accessory address is set as zero address, accessory cannot be equipped.
    function setAccessoryAddress(address _accessoryAddress) external onlyOwner {
        accessoryAddress = _accessoryAddress;
    }

    /// @notice Burn Scroll NFT and mint an Ancestor NFT with the same token ID
    /// @param _to Address to send the tokens to
    /// @param _tokenId Token ID same as Scroll NFT
    /// @param _isEquipped Specify if each accessory type (0~6) is equipped.
    /// @param _accessoryTokenIds Accessory token IDs of each accessory type
    /// @dev Only Scroll contract can do this
    function mint(
        address _to,
        uint256 _tokenId,
        bool[6] calldata _isEquipped,
        uint256[6] calldata _accessoryTokenIds
    ) external nonReentrant {
        if (msg.sender != scroll) revert InvalidMinter();

        _mint(_to, _tokenId);
        _wrap(_to, _tokenId, _isEquipped, _accessoryTokenIds);
    }

    /// @notice Wrap Ancestor by adjusting equipped accessories.
    /// @param _tokenId Ancestor Token ID
    /// @param _isEquipped Array of accessory equipped setting of each type of accessory
    /// @param _isEquipped Specify if each accessory type (0~5) is equipped.
    /// @param _accessoryTokenIds Array of accessory token IDs of each accessory type
    /// @param _accessoryTokenIds If the corresponding type of accessory will not be equipped, just simply specify 0.
    /// @dev Accessory needs to be approved to this contract first
    /// @dev Only token owner can do this
    function wrap(
        uint256 _tokenId,
        bool[6] calldata _isEquipped,
        uint256[6] calldata _accessoryTokenIds
    ) external nonReentrant {
        if (ownerOf(_tokenId) != msg.sender) revert NotTokenOwner();

        _wrap(msg.sender, _tokenId, _isEquipped, _accessoryTokenIds);
    }

    /// @notice Unwrap Ancestor by unequipping all accessories.
    /// @param _tokenId Ancestor Token ID
    /// @dev Unequipped accessories will send to token owner
    /// @dev Only token owner can do this
    function unwrap(uint256 _tokenId) external nonReentrant {
        if (ownerOf(_tokenId) != msg.sender) revert NotTokenOwner();
        if (paused) revert ContractPaused();

        (
            bool[6] memory isEquipped,
            uint256[6] memory accessoryTokenIds
        ) = _tokenEquippedAccessories(_tokenId);

        uint256 unequippedCounter;
        uint256[6] memory batchUnequippedTokenIds;

        for (uint256 i; i < 6; i++) {
            if (isEquipped[i]) {
                batchUnequippedTokenIds[unequippedCounter] = accessoryTokenIds[
                    i
                ];
                unequippedCounter += 1;
            }
        }

        uint256[] memory unequippedTransferedTokens = _batchTransferAccessories(
            address(this),
            msg.sender,
            batchUnequippedTokenIds,
            unequippedCounter
        );
        delete tokenAccessoryData[_tokenId];

        emit AccessoryUnwrapped(
            msg.sender,
            _tokenId,
            accessoryTokenIds,
            unequippedTransferedTokens
        );
    }

    function _wrap(
        address _requestFrom,
        uint256 _tokenId,
        bool[6] calldata _isEquipped,
        uint256[6] calldata _accessoryTokenIds
    ) private {
        if (accessoryAddress == address(0)) revert AccessoryAddressNotSet();
        if (paused) revert ContractPaused();

        (
            bool[6] memory isEquipped,
            uint256[6] memory accessoryTokenIds
        ) = _tokenEquippedAccessories(_tokenId);

        uint256 equippedCounter;
        uint256 unequippedCounter;
        uint256[6] memory batchEquippedTokenIds;
        uint256[6] memory batchUnequippedTokenIds;

        for (uint256 i; i < 6; i++) {
            if (_isEquipped[i]) {
                if (isEquipped[i]) {
                    if (_accessoryTokenIds[i] == accessoryTokenIds[i]) {
                        continue;
                    }
                    batchUnequippedTokenIds[
                        unequippedCounter
                    ] = accessoryTokenIds[i];
                    unequippedCounter += 1;
                }
                if (
                    IAccessory(accessoryAddress).accessoryType(
                        _accessoryTokenIds[i]
                    ) != i
                ) revert AccessoryTypeMismatch();
                batchEquippedTokenIds[equippedCounter] = _accessoryTokenIds[i];
                equippedCounter += 1;
            } else if (isEquipped[i]) {
                batchUnequippedTokenIds[unequippedCounter] = accessoryTokenIds[
                    i
                ];
                unequippedCounter += 1;
            }
        }

        _batchTransferAccessories(
            _requestFrom,
            address(this),
            batchEquippedTokenIds,
            equippedCounter
        );
        _batchTransferAccessories(
            address(this),
            _requestFrom,
            batchUnequippedTokenIds,
            unequippedCounter
        );

        uint224 encodedAccessories = 0;
        for (uint256 i; i < 6; i++) {
            encodedAccessories |= SafeCast.toUint32(_accessoryTokenIds[i]);
            encodedAccessories <<= 32;
        }

        Accessory storage accessoryData = tokenAccessoryData[_tokenId];
        accessoryData.isEquipped = _isEquipped;
        accessoryData.encodedAccessories = encodedAccessories;

        emit AccessoryWrapped(
            _requestFrom,
            _tokenId,
            isEquipped,
            accessoryTokenIds,
            _isEquipped,
            _accessoryTokenIds
        );
    }

    function _batchTransferAccessories(
        address _from,
        address _to,
        uint256[6] memory _ids,
        uint256 _transferCounter
    ) private returns (uint256[] memory tokenIds) {
        if (_transferCounter > 0) {
            tokenIds = new uint256[](_transferCounter);
            uint256[] memory amount = new uint256[](_transferCounter);

            for (uint256 i; i < _transferCounter; i++) {
                tokenIds[i] = _ids[i];
                amount[i] = 1;
            }

            IAccessory(accessoryAddress).safeBatchTransferFrom(
                _from,
                _to,
                tokenIds,
                amount,
                ""
            );
        }
    }

    function _tokenEquippedAccessories(uint256 _tokenId)
        private
        view
        returns (bool[6] memory, uint256[6] memory)
    {
        uint256[6] memory accessoryTokenIds;

        Accessory storage accessoryData = tokenAccessoryData[_tokenId];
        uint224 accessories = accessoryData.encodedAccessories;

        for (uint256 i; i < 6; i++) {
            accessories >>= 32;
            accessoryTokenIds[5 - i] = accessories & 0xfffffff;
        }

        return (accessoryData.isEquipped, accessoryTokenIds);
    }

    /// @notice Returns token accessory information
    /// @param _tokenId Token Id
    /// @return isEquipped Array of accessory equipped status of each type of accessory
    /// @return accessoryTokenIds Array of accessory token ID
    /// @dev Ignore token ID if accessory is not equipped.
    function tokenEquippedAccessories(uint256 _tokenId)
        public
        view
        returns (bool[6] memory, uint256[6] memory)
    {
        bool[6] memory isEquipped;
        uint256[6] memory accessoryTokenIds;

        (isEquipped, accessoryTokenIds) = _tokenEquippedAccessories(_tokenId);

        for (uint256 i; i < 6; i++) {
            if (!isEquipped[i]) {
                accessoryTokenIds[i] = 0;
            }
        }

        return (isEquipped, accessoryTokenIds);
    }

    /// @notice Returns token URI of a token
    /// @param _tokenId Token Id
    /// @return uri Token URI
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        if (!_exists(_tokenId)) revert TokenNotExist();

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    // IERC1155Receiver
    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    // IERC1155BatchReceiver
    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}