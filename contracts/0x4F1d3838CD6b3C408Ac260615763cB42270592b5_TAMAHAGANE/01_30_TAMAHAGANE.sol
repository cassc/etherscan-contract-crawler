// SPDX-License-Identifier: MIT

// ████████╗ █████╗ ███╗   ███╗ █████╗   ██╗  ██╗ █████╗  ██████╗  █████╗ ███╗   ██╗███████╗
// ╚══██╔══╝██╔══██╗████╗ ████║██╔══██╗  ██║  ██║██╔══██╗██╔════╝ ██╔══██╗████╗  ██║██╔════╝
//    ██║   ███████║██╔████╔██║███████║  ███████║███████║██║  ███╗███████║██╔██╗ ██║█████╗
//    ██║   ██╔══██║██║╚██╔╝██║██╔══██║  ██╔══██║██╔══██║██║   ██║██╔══██║██║╚██╗██║██╔══╝
//    ██║   ██║  ██║██║ ╚═╝ ██║██║  ██║  ██║  ██║██║  ██║╚██████╔╝██║  ██║██║ ╚████║███████╗
//    ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ITAMAHAGANEErrorCodes.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./operatorFilterer/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./operatorFilterer/RevokableOperatorFiltererUpgradeable.sol";

contract TAMAHAGANE is
    ITAMAHAGANEErrorCodes,
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
    uint256 public maxSupply;
    uint256 public maxAmountAtOneTime;
    uint256 public currentTamaHaganeId;
    uint256 public price;
    bool public isCreatingKatanaActive;
    bool public isPreActive;
    bool public isContractSaleActive;
    string public name;
    string public symbol;

    // private variables
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256[]) private _availableTokensByTamaHagane;
    mapping(uint256 => mapping(address => uint256))
        private _amountMintedByTamaHaganeId;
    mapping(uint256 => mapping(address => uint256))
        private _amountSaleTransferredByTamaHaganeId;
    mapping(uint256 => bool) private _isTamaHagane;
    uint256 private _totalMinted;
    uint256 private _burnCounter;
    uint256 private _nonce;
    bytes32 private _merkleRoot;

    mapping(uint256 => uint256) public publicContractSalePrice;

    // Events
    event MintAmount(
        uint256 _mintAmountLeft,
        uint256 _totalMinted,
        address _minter
    );
   event TransferredAmount(
        uint256 _transferAmountLeft,
        uint256 _contractBalance,
        uint256 _tokenId,
        address _caller
    );

    // Modifiers
    modifier mintCompliance(uint256 _mintAmount, uint256 _tokenId) {
        if (_mintAmount <= 0) revert TAMAHAGANE__MintAmountIsTooSmall();
        if (totalSupply() + _mintAmount > maxSupply)
            revert TAMAHAGANE__MustMintWithinMaxSupply();
        if (mintedTokens[_tokenId] + _mintAmount > maxTokens[_tokenId])
            revert TAMAHAGANE__ReachedMaxTokens();
        _;
    }

    modifier saleCompliance(
        uint256 _mintAmount,
        uint256 _maxMintableAmount,
        uint256 _tokenId,
        uint256 _processedAmount,
        bool _isSaleActive
    ) {
        if (!_isSaleActive) revert TAMAHAGANE__NotReadyYet();
        if (_mintAmount > _maxMintableAmount - _processedAmount)
            revert TAMAHAGANE__InsufficientMintsLeft();
        if (msg.value != price * _mintAmount)
            revert TAMAHAGANE__InsufficientMintPrice();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _maxSupply,
        uint256 _maxSupplyByTokenId,
        uint256 _price,
        uint256 _tamaHaganeId,
        bytes32 merkleRoot_
    ) public initializer {
        __ERC1155_init("");
        __ERC2981_init();
        __Ownable_init();
        __RevokableDefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();
        setRoyaltyInfo(_msgSender(), 750); // 750 == 7.5%
        setTamaHaganeId(_tamaHaganeId, true);
        name = "TAMAHAGANE";
        symbol = "TH";
        maxAmountAtOneTime = 100;
        maxSupply = _maxSupply;
        maxTokens[_tamaHaganeId] = _maxSupplyByTokenId;
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
            revert TAMAHAGANE__MismatchedArrayLengths();
        uint256 maxCount = _toList.length;
        for (uint256 i = 0; i < maxCount; ) {
            mint_(_toList[i], _tokenId, _amountList[i]);
            unchecked {
                ++i;
            }
        }
    }

    function preMint(
        uint256 _amount,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        mintCompliance(_amount, currentTamaHaganeId)
        saleCompliance(
            _amount,
            _maxMintableAmount,
            currentTamaHaganeId,
            amountMinted(currentTamaHaganeId, _msgSender()),
            isPreActive
        )
    {
        address to = _msgSender();
        if (!_verify(to, _maxMintableAmount, _merkleProof))
            revert TAMAHAGANE__InvalidMerkleProof();
        unchecked {
            _amountMintedByTamaHaganeId[currentTamaHaganeId][to] += _amount;
        }
        mint_(to, currentTamaHaganeId, _amount);
        uint256 mintAmountLeft;
        unchecked {
            mintAmountLeft =
                _maxMintableAmount -
                amountMinted(currentTamaHaganeId, to);
        }
        emit MintAmount(mintAmountLeft, mintedTokens[currentTamaHaganeId], to);
    }

    function createKatana(
        uint256 _tamaHaganeId,
        uint256 _amount
    ) external nonReentrant {
        if (!isCreatingKatanaActive) revert TAMAHAGANE__NotReadyYet();
        if (maxAmountAtOneTime < _amount) revert TAMAHAGANE__AmountIsTooBig();
        if (_availableTokensByTamaHagane[_tamaHaganeId].length == 0)
            revert TAMAHAGANE__NoAvailableTokens();
        if (!isTamaHagane(_tamaHaganeId)) revert TAMAHAGANE__NotTamaHaganeId();
        address caller = _msgSender();
        if (balanceOf(caller, _tamaHaganeId) < _amount)
            revert TAMAHAGANE__NotEnoughTamaHagane();
        burn(caller, _tamaHaganeId, _amount);
        for (uint256 i; i < _amount; ) {
            uint256 tokenId = _randomTokenId(_tamaHaganeId);
            mint_(caller, tokenId, 1);
            unchecked {
                ++i;
            }
        }
    }

    function contractPublicSaleTransfer(
        uint256 _tokenId,
        uint256 _amount
    ) external payable nonReentrant {
        if (!isContractSaleActive) revert TAMAHAGANE__NotReadyYet();
        if (msg.value != publicContractSalePrice[_tokenId] * _amount)
            revert TAMAHAGANE__InsufficientMintPrice();
        if (!isTamaHagane(_tokenId)) revert TAMAHAGANE__NotTamaHaganeId();
        address to = _msgSender();
        _safeTransferFromByContract(to, _tokenId, _amount);

        uint256 balance = balanceOf(address(this), _tokenId);
        emit TransferredAmount(balance, balance, _tokenId, to);
    }

    function contractSaleTransfer(
        uint256 _amount,
        uint256 _maxTransferableAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        saleCompliance(
            _amount,
            _maxTransferableAmount,
            currentTamaHaganeId,
            _amountSaleTransferredByTamaHaganeId[currentTamaHaganeId][
                _msgSender()
            ],
            isContractSaleActive
        )
    {
        address to = _msgSender();
        if (!_verify(to, _maxTransferableAmount, _merkleProof))
            revert TAMAHAGANE__InvalidMerkleProof();
        unchecked {
            _amountSaleTransferredByTamaHaganeId[currentTamaHaganeId][
                to
            ] += _amount;
        }
        _safeTransferFromByContract(to, currentTamaHaganeId, _amount);
        uint256 transferAmountLeft;
        unchecked {
            transferAmountLeft =
                _maxTransferableAmount -
                _amountSaleTransferredByTamaHaganeId[currentTamaHaganeId][to];
        }
        emit TransferredAmount(
            transferAmountLeft,
            balanceOf(address(this), currentTamaHaganeId),
            currentTamaHaganeId,
            to
        );
    }

    function toggleCreatingKatanaActive() external onlyOwner {
        isCreatingKatanaActive = !isCreatingKatanaActive;
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
        if (!success) revert TAMAHAGANE__WithdrawFailed();
    }

    function transferERC1155To(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        _safeTransferFromByContract(_to, _tokenId, _amount);
    }

    function setPublicContractSalePrice(
        uint256 _tokenId,
        uint256 _newPrice
    ) external onlyOwner {
        publicContractSalePrice[_tokenId] = _newPrice;
    }

    function setMaxAmountAtOneTime(uint256 _newMax) external onlyOwner {
        maxAmountAtOneTime = _newMax;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
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
            revert TAMAHAGANE__MismatchedArrayLengths();
        uint256 max = _tokenIds.length;
        for (uint256 i = 0; i < max; ) {
            setURI(_tokenIds[i], _newTokenURIs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setBatchMaxAndAvailableTokens(
        uint256[] memory _tokenIdList,
        uint256[] memory _maxList,
        uint256 _tamaHaganeId
    ) external onlyOwner {
        if (_tokenIdList.length != _maxList.length)
            revert TAMAHAGANE__MismatchedArrayLengths();
        uint256 maxCount = _tokenIdList.length;
        for (uint256 i = 0; i < maxCount; ) {
            setMaxTokens(_tokenIdList[i], _maxList[i]);
            setAvailableTokens(_tokenIdList[i], _tamaHaganeId);
            unchecked {
                ++i;
            }
        }
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

    function setAvailableTokens(
        uint256 _tokenId,
        uint256 _tamaHaganeId
    ) public onlyOwner {
        if (mintedTokens[_tokenId] >= maxTokens[_tokenId])
            revert TAMAHAGANE__ReachedMaxTokens();
        uint256[] memory availableTokens = _availableTokensByTamaHagane[
            _tamaHaganeId
        ];
        for (uint256 i = 0; i < availableTokens.length; ) {
            if (availableTokens[i] == _tokenId)
                revert TAMAHAGANE__TokenIdAlreadyExists();
            unchecked {
                ++i;
            }
        }
        _availableTokensByTamaHagane[_tamaHaganeId].push(_tokenId);
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

    function setTamaHaganeId(
        uint256 _tokenId,
        bool _isTamaHaganeFlag
    ) public onlyOwner {
        _isTamaHagane[_tokenId] = _isTamaHaganeFlag;
        if (_isTamaHaganeFlag) currentTamaHaganeId = _tokenId;
    }

    function burn(address _account, uint256 _id, uint256 _amount) public {
        address caller = _msgSender();
        if (caller != _account && !isBurnableContract[caller])
            revert TAMAHAGANE__NotOwnerOrBurnableContract();
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

    function _safeTransferFromByContract(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        this.safeTransferFrom(address(this), _to, _tokenId, _amount, "");
    }

    function _randomTokenIdAndIndex(
        uint256[] memory availableTokens,
        uint256 availableTokensNum
    ) private returns (uint256, uint256) {
        unchecked {
            _nonce += availableTokensNum;
            uint256 index = uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, _nonce))
            ) % availableTokensNum;
            uint256 tokenId = availableTokens[index];
            return (tokenId, index);
        }
    }

    function _randomTokenId(uint256 _tamaHaganeId) private returns (uint256) {
        uint256[] memory availableTokens = _availableTokensByTamaHagane[
            _tamaHaganeId
        ];
        uint256 availableTokensNum = availableTokens.length;
        (uint256 tokenId, uint256 index) = _randomTokenIdAndIndex(
            availableTokens,
            availableTokensNum
        );
        uint256 totalMintingAmountByTokenId = mintedTokens[tokenId] + 1;

        if (totalMintingAmountByTokenId > maxTokens[tokenId])
            revert TAMAHAGANE__CannotMintAnymore();
        if (totalMintingAmountByTokenId == maxTokens[tokenId]) {
            availableTokens[index] = availableTokens[availableTokensNum - 1];
            _availableTokensByTamaHagane[_tamaHaganeId] = availableTokens;
            _availableTokensByTamaHagane[_tamaHaganeId].pop();
        }
        return tokenId;
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

    function isTamaHagane(uint256 _tokenId) public view returns (bool) {
        return _isTamaHagane[_tokenId];
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
        uint256 _tamaHaganeId,
        address _address
    ) public view returns (uint256) {
        return _amountMintedByTamaHaganeId[_tamaHaganeId][_address];
    }

    function mintableAmount(
        uint256 _tamaHaganeId,
        address _address,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (uint256) {
        if (
            _verify(_address, _maxMintableAmount, _merkleProof) &&
            _amountMintedByTamaHaganeId[_tamaHaganeId][_address] <
            _maxMintableAmount
        )
            return
                _maxMintableAmount -
                _amountMintedByTamaHaganeId[_tamaHaganeId][_address];
        else return 0;
    }

    function availableTokensByTamaHagane(
        uint256 _tamaHaganeId
    ) external view onlyOwner returns (uint256[] memory) {
        return _availableTokensByTamaHagane[_tamaHaganeId];
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
}