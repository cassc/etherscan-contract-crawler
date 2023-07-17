// SPDX-License-Identifier: MIT

//       ██████╗        ███╗   ██╗        █████╗
//       ██╔══██╗       ████╗  ██║       ██╔══██╗
//       ██║  ██║       ██╔██╗ ██║       ███████║
//       ██║  ██║       ██║╚██╗██║       ██╔══██║
//       ██████╔╝       ██║ ╚████║       ██║  ██║
//       ╚═════╝        ╚═╝  ╚═══╝       ╚═╝  ╚═╝

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IDNAErrorCodes.sol";
import "./IERC721.sol";
import "./IITEM.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./operatorFilterer/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./operatorFilterer/RevokableOperatorFiltererUpgradeable.sol";

contract DNA is
    IDNAErrorCodes,
    Initializable,
    UUPSUpgradeable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    RevokableDefaultOperatorFiltererUpgradeable
{
    using StringsUpgradeable for uint256;

    // public variables
    mapping(uint256 => uint256) public maxTokens;
    mapping(uint256 => uint256) public mintedTokens;
    mapping(address => bool) public isBurnableContract;
    mapping(address => bool) public isASZContract;
    mapping(uint256 => mapping(address => bool)) public canCreateItem;
    mapping(address => mapping(uint256 => bool)) public ASZTokenUsed;
    uint256 public maxSupply;
    uint256 public currentDNAId;
    uint256 public price;
    uint256 public maxBatchAmount;
    bool public isCreatingItemActive;
    bool public isPublicActive;
    bool public isPreActive;
    bool public isContractSaleActive;
    string public name;
    string public symbol;
    IITEM public itemContract;

    // private variables
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => mapping(address => uint256))
        private _amountMintedByDNAId;
    mapping(uint256 => mapping(address => uint256))
        private _amountSaleTransferredByDNAId;
    uint256 private _totalMinted;
    uint256 private _burnCounter;
    bytes32 private _merkleRoot;

    // Events
    event MintAmount(
        uint256 _mintAmountLeft,
        uint256 _totalMinted,
        address _minter
    );
    event TransferredAmount(
        uint256 _transferAmountLeft,
        uint256 _contractBalance,
        address _caller
    );
    event ItemCreated(address indexed _caller, uint256 _itemId);
    event BatchItemCreated(address indexed _caller, uint256[] _itemIdList);
    event PublicMint(uint256 _totalMinted, address _minter);

    // Modifiers
    modifier mintCompliance(uint256 _mintAmount, uint256 _tokenId) {
        if (_mintAmount <= 0) revert DNA__MintAmountIsTooSmall();
        if (totalMinted() + _mintAmount > maxSupply)
            revert DNA__MustMintWithinMaxSupply();
        if (mintedTokens[_tokenId] + _mintAmount > maxTokens[_tokenId])
            revert DNA__ReachedMaxTokens();
        _;
    }

    modifier saleCompliance(uint256 _mintAmount, bool _isSaleActive) {
        if (!_isSaleActive) revert DNA__NotReadyYet();
        if (msg.value != price * _mintAmount)
            revert DNA__InsufficientMintPrice();
        _;
    }

    modifier merkleProofCompliance(
        uint256 _mintAmount,
        uint256 _maxMintableAmount,
        uint256 _processedAmount
    ) {
        if (_mintAmount > _maxMintableAmount - _processedAmount)
            revert DNA__InsufficientMintsLeft();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _maxSupply,
        uint256 _maxSupplyByDNAId,
        uint256 _price,
        uint256 _DNAId,
        bytes32 merkleRoot_
    ) public initializer {
        __ERC1155_init("");
        __ERC2981_init();
        __Ownable_init();
        __RevokableDefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();
        setRoyaltyInfo(_msgSender(), 750); // 750 == 7.5%
        name = "DNA";
        symbol = "DNA";
        currentDNAId = _DNAId;
        maxSupply = _maxSupply;
        maxTokens[_DNAId] = _maxSupplyByDNAId;
        price = _price;
        _merkleRoot = merkleRoot_;
    }

    /**
     * @dev For receiving ETH just in case someone tries to send it.
     */
    receive() external payable {}

    function ownerMint(
        address _to,
        uint256 _tokenId,
        uint256 _mintAmount
    ) external onlyOwner mintCompliance(_mintAmount, _tokenId) {
        mint_(_to, _tokenId, _mintAmount);
    }

    function airdrop(
        uint256 _tokenId,
        address[] memory _toList,
        uint256[] memory _amountList
    ) external onlyOwner {
        if (_toList.length != _amountList.length)
            revert DNA__MismatchedArrayLengths();
        uint256 maxCount = _toList.length;
        for (uint256 i = 0; i < maxCount; ) {
            mint_(_toList[i], _tokenId, _amountList[i]);
            unchecked {
                ++i;
            }
        }
    }

    function publicMint(
        uint256 _mintAmount
    )
        external
        payable
        mintCompliance(_mintAmount, currentDNAId)
        saleCompliance(_mintAmount, isPublicActive)
        nonReentrant
    {
        address caller = _msgSender();
        mint_(caller, currentDNAId, _mintAmount);
        emit PublicMint(mintedTokens[currentDNAId], caller);
    }

    function preMint(
        uint256 _amount,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        mintCompliance(_amount, currentDNAId)
        saleCompliance(_amount, isPreActive)
        merkleProofCompliance(
            _amount,
            _maxMintableAmount,
            amountMinted(currentDNAId, _msgSender())
        )
    {
        address to = _msgSender();
        if (!_verify(to, _maxMintableAmount, _merkleProof))
            revert DNA__InvalidMerkleProof();
        unchecked {
            _amountMintedByDNAId[currentDNAId][to] += _amount;
        }
        mint_(to, currentDNAId, _amount);
        uint256 mintAmountLeft;
        unchecked {
            mintAmountLeft =
                _maxMintableAmount -
                amountMinted(currentDNAId, to);
        }
        emit MintAmount(mintAmountLeft, mintedTokens[currentDNAId], to);
    }

    function createBatchItems(
        uint256 _DNAId,
        uint256[] memory _tokenIdList,
        address[] memory _contractAddressList
    ) external nonReentrant {
        if (
            _tokenIdList.length != _contractAddressList.length ||
            _tokenIdList.length == 0
        ) revert DNA__MismatchedArrayLengths();

        uint256 maxCount = _tokenIdList.length;
        if (maxBatchAmount < maxCount) revert DNA__AmountIsTooBig();
        uint256[] memory itemIdList = new uint256[](maxCount);
        for (uint256 i = 0; i < maxCount; ) {
            uint256 itemId = createItem(
                _DNAId,
                _tokenIdList[i],
                _contractAddressList[i]
            );
            itemIdList[i] = itemId;
            unchecked {
                ++i;
            }
        }
        emit BatchItemCreated(_msgSender(), itemIdList);
    }

    function contractSaleTransfer(
        uint256 _amount,
        uint256 _maxTransferableAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        saleCompliance(_amount, isContractSaleActive)
        merkleProofCompliance(
            _amount,
            _maxTransferableAmount,
            _amountSaleTransferredByDNAId[currentDNAId][_msgSender()]
        )
    {
        address to = _msgSender();
        if (!_verify(to, _maxTransferableAmount, _merkleProof))
            revert DNA__InvalidMerkleProof();
        unchecked {
            _amountSaleTransferredByDNAId[currentDNAId][to] += _amount;
        }
        _safeTransferFromByContract(to, currentDNAId, _amount);
        uint256 transferAmountLeft;
        unchecked {
            transferAmountLeft =
                _maxTransferableAmount -
                _amountSaleTransferredByDNAId[currentDNAId][to];
        }
        emit TransferredAmount(
            transferAmountLeft,
            balanceOf(address(this), currentDNAId),
            to
        );
    }

    function toggleCreatingItemActive() external onlyOwner {
        isCreatingItemActive = !isCreatingItemActive;
    }

    function togglePublicActive() external onlyOwner {
        isPublicActive = !isPublicActive;
    }

    function togglePreActive() external onlyOwner {
        isPreActive = !isPreActive;
    }

    function toggleContractSaleActive() external onlyOwner {
        isContractSaleActive = !isContractSaleActive;
    }

    /**
     * @notice Only the owner can withdraw all of the contract balance.
     * @dev All the balance transfers to the owner's address.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        if (!success) revert DNA__WithdrawFailed();
    }

    function transferERC1155To(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        _safeTransferFromByContract(_to, _tokenId, _amount);
    }

    function setItemContract(address _contractAddress) external onlyOwner {
        itemContract = IITEM(_contractAddress);
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMaxBatchAmount(uint256 _newMaxBatchAmount) external onlyOwner {
        maxBatchAmount = _newMaxBatchAmount;
    }

    function setBurnableContract(
        address _contractAddress,
        bool _isBurnable
    ) external onlyOwner {
        isBurnableContract[_contractAddress] = _isBurnable;
    }

    function setMerkleProof(bytes32 _newMerkleRoot) external onlyOwner {
        _merkleRoot = _newMerkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setURIs(
        uint256[] memory _tokenIds,
        string[] memory _newTokenURIs
    ) external onlyOwner {
        if (_tokenIds.length != _newTokenURIs.length || _tokenIds.length == 0)
            revert DNA__MismatchedArrayLengths();
        uint256 max = _tokenIds.length;
        for (uint256 i = 0; i < max; ) {
            setURI(_tokenIds[i], _newTokenURIs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setBatchMaxTokens(
        uint256[] memory _tokenIdList,
        uint256[] memory _maxList
    ) external onlyOwner {
        if (_tokenIdList.length != _maxList.length)
            revert DNA__MismatchedArrayLengths();
        uint256 maxCount = _tokenIdList.length;
        for (uint256 i = 0; i < maxCount; ) {
            setMaxTokens(_tokenIdList[i], _maxList[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setBatchASZContracts(
        address[] memory _addressList,
        bool[] memory _isASZList
    ) external onlyOwner {
        if (_addressList.length != _isASZList.length)
            revert DNA__MismatchedArrayLengths();
        uint256 maxCount = _addressList.length;
        for (uint256 i = 0; i < maxCount; ) {
            setASZContract(_addressList[i], _isASZList[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setBatchCreateContracts(
        address[] memory _addressList,
        bool[] memory _CanCreateItemList,
        uint256 _dnaId
    ) external onlyOwner {
        if (_addressList.length != _CanCreateItemList.length)
            revert DNA__MismatchedArrayLengths();
        uint256 maxCount = _addressList.length;
        for (uint256 i = 0; i < maxCount; ) {
            setCanCreateItem(_addressList[i], _CanCreateItemList[i], _dnaId);
            unchecked {
                ++i;
            }
        }
    }

    function setASZContract(address _address, bool _isASZ) public onlyOwner {
        isASZContract[_address] = _isASZ;
    }

    function setCanCreateItem(
        address _address,
        bool _canCreateItem,
        uint256 _dnaId
    ) public onlyOwner {
        canCreateItem[_dnaId][_address] = _canCreateItem;
    }

    function setURI(
        uint256 _tokenId,
        string memory _newTokenURI
    ) public onlyOwner {
        _tokenURIs[_tokenId] = _newTokenURI;
    }

    function setMaxTokens(uint256 _tokenId, uint256 _max) public onlyOwner {
        maxTokens[_tokenId] = _max;
    }

    /**
     * @dev Set the new royalty fee and the new receiver.
     */
    function setRoyaltyInfo(
        address _receiver,
        uint96 _royaltyFee
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    function setDNAId(uint256 _tokenId) public onlyOwner {
        currentDNAId = _tokenId;
    }

    function createItem(
        uint256 _DNAId,
        uint256 _tokenId,
        address _contractAddress
    ) public nonReentrant returns (uint256) {
        address caller = _msgSender();
        _validateItemCreation(_DNAId, _tokenId, _contractAddress, caller);
        bool isASZ = isASZContract[_contractAddress];
        if (isASZ) {
            _markASZTokenAsUsed(_contractAddress, _tokenId);
        } else {
            if (!canCreateItem[_DNAId][_contractAddress])
                revert DNA__InvalidAddress();
        }
        burn(caller, _DNAId, 1);
        uint256 itemId = itemContract.mint(caller, _DNAId, isASZ);
        emit ItemCreated(caller, itemId);
        return itemId;
    }

    function burn(address _account, uint256 _id, uint256 _amount) public {
        address caller = _msgSender();
        if (caller != _account && !isBurnableContract[caller])
            revert DNA__NotOwnerOrBurnableContract();
        unchecked {
            _burnCounter += _amount;
        }
        _burn(_account, _id, _amount);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyOwner {}

    function mint_(address _to, uint256 _tokenId, uint256 _amount) private {
        unchecked {
            _totalMinted += _amount;
            mintedTokens[_tokenId] += _amount;
        }
        _mint(_to, _tokenId, _amount, "");
    }

    function _markASZTokenAsUsed(
        address _contractAddress,
        uint256 _tokenId
    ) private {
        if (ASZTokenUsed[_contractAddress][_tokenId]) revert DNA__AlreadyUsed();
        ASZTokenUsed[_contractAddress][_tokenId] = true;
    }

    function _safeTransferFromByContract(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        this.safeTransferFrom(address(this), _to, _tokenId, _amount, "");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
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

    /**
     * @dev Returns the owner of the ERC1155 token contract.
     */
    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    /**
     * @dev Return tokenURI for the specified token ID.
     * @param _tokenId The token ID the token URI is returned for.
     */
    function uri(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return _tokenURIs[_tokenId];
    }

    /**
     * @dev Burned tokens are calculated here, use totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than totalMinted times
        unchecked {
            return totalMinted() - _burnCounter;
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted;
    }

    function amountMinted(
        uint256 _DNAId,
        address _address
    ) public view returns (uint256) {
        return _amountMintedByDNAId[_DNAId][_address];
    }

    function mintableAmount(
        uint256 _DNAId,
        address _address,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (uint256) {
        if (
            _verify(_address, _maxMintableAmount, _merkleProof) &&
            _amountMintedByDNAId[_DNAId][_address] < _maxMintableAmount
        ) return _maxMintableAmount - _amountMintedByDNAId[_DNAId][_address];
        else return 0;
    }

    function _verify(
        address _address,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(_address, _maxMintableAmount.toString())
        );

        return MerkleProofUpgradeable.verify(_merkleProof, _merkleRoot, leaf);
    }

    function _validateItemCreation(
        uint256 _DNAId,
        uint256 _tokenId,
        address _contractAddress,
        address caller
    ) private view {
        if (!isCreatingItemActive) revert DNA__NotReadyYet();
        if (balanceOf(caller, _DNAId) == 0) revert DNA__NotEnoughDNA();

        IERC721 erc721Contract = IERC721(_contractAddress);
        if (erc721Contract.ownerOf(_tokenId) != caller)
            revert DNA__NotOwnerOrBurnableContract();
    }
}