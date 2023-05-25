// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.17;

import "@ERC721A/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PLOOSHIES is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    error CallerIsContractError();
    error ContractPausedError();
    error ContractFrozenError();
    error InnerCircleMintClosedError();
    error WhitelistMintClosedError();
    error WhitelistPhaseClosedError();
    error AllowanceAmountError();
    error ExceedsMaxSupplyError();
    error MintClosedError();
    error IncorrectAmountError();
    error MintAmountError();
    error InvalidBoxIDError();
    error InvalidSignatureError();
    error BelowCurrentSupplyError();
    error CannotIncreaseSupplyError();
    error AlreadyMintedPlooshlistError();
    error TokenTransferLockedError();

    bool public paused;
    bool public minting;
    bool public whitelistminting;
    bool public innercircleminting;
    bool public revealed;
    bool public frozen;
    uint256 public maxBatchSize = 10;
    uint256 public maxMintAmountPerTx = 1;
    uint256 public cost = 0.12 ether;
    uint256 public maxSupply = 3333;
    uint256 public currentWhitelistPhase = 1;
    uint16 public UnlockTime;
    address public signer;
    string private _baseTokenURI;
    string private _placeholderTokenURI =
        "ipfs://QmcWCi9W45DomN4uSwCq6ruermLwZ9rx5u7qT6KTGTmBEh/";

    event TokenLocked(uint256 indexed tokenId, uint256 unlockTimeDay);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor(
        address _signer,
        uint16 _unlockTime
    ) ERC721A("The Plooshies", "PLOOSHY") {
        paused = true;
        signer = _signer;
        UnlockTime = _unlockTime;
        _setDefaultRoyalty(msg.sender, 690);
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContractError();
        _;
    }

    function flipPause() external onlyOwner {
        paused = !paused;
    }

    function flipMint() external onlyOwner {
        minting = !minting;
    }

    function flipInnerCircleMint() external onlyOwner {
        innercircleminting = !innercircleminting;
    }

    function flipWhitelistMint() external onlyOwner {
        whitelistminting = !whitelistminting;
    }

    function setItemPrice(uint256 _price) external onlyOwner {
        cost = _price;
    }

    function setNumPerMint(uint256 _max) external onlyOwner {
        maxMintAmountPerTx = _max;
    }

    function setWhitelistPhase(uint256 _phase) external onlyOwner {
        currentWhitelistPhase = _phase;
    }

    function setMaxBatchSize(uint256 _size) external onlyOwner {
        maxBatchSize = _size;
    }

    function setMaxSupply(uint256 _max) external onlyOwner {
        if (frozen) revert ContractFrozenError();
        if (_max > maxSupply) revert CannotIncreaseSupplyError();
        if (_max < totalSupply()) revert BelowCurrentSupplyError();
        maxSupply = _max;
    }

    function reveal(string calldata baseURI) external onlyOwner {
        setBaseURI(baseURI);
        revealed = true;
    }

    function freezeContract() external onlyOwner {
        frozen = true;
    }

    function mintReserves(uint256 quantity, uint256 _box) external onlyOwner {
        if (_totalMinted() + quantity > maxSupply)
            revert ExceedsMaxSupplyError();
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            uint256 nextId = _nextTokenId();
            _mint(msg.sender, maxBatchSize);
            _setExtraDataAt(nextId, uint24(_box));
        }
        uint256 remainder = quantity % maxBatchSize;
        if (remainder != 0) {
            uint256 nextId = _nextTokenId();
            _mint(msg.sender, remainder);
            _setExtraDataAt(nextId, uint24(_box));
        }
    }

    function innercircleMint(
        uint256 _box,
        bytes calldata _sig
    ) external callerIsUser {
        if (paused) revert ContractPausedError();
        if (!innercircleminting) revert InnerCircleMintClosedError();
        if (_getAux(msg.sender) != 0) revert AlreadyMintedPlooshlistError();

        if (_totalMinted() >= maxSupply) revert ExceedsMaxSupplyError();
        address sig_recover = keccak256(
            abi.encodePacked(msg.sender, uint256(1), uint256(1))
        ).toEthSignedMessageHash().recover(_sig);

        if (sig_recover != signer) revert InvalidSignatureError();

        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
        _setExtraDataAt(
            _totalMinted(),
            uint24(uint8(_box) | (uint24(UnlockTime) << 8))
        );
        emit TokenLocked(_totalMinted(), UnlockTime);
    }

    function plooshlistMint(
        uint256 _mintAmount,
        uint256 _allowance,
        uint256 _phase,
        uint256 _box,
        bytes calldata _sig
    ) external payable callerIsUser {
        uint64 _whitelistClaimed = _getAux(msg.sender);
        if (paused) revert ContractPausedError();
        if (!whitelistminting) revert WhitelistMintClosedError();
        if (
            _phase > currentWhitelistPhase ||
            (currentWhitelistPhase == 2 && _phase == 1)
        ) revert WhitelistPhaseClosedError();
        if (_whitelistClaimed + _mintAmount > _allowance)
            revert AllowanceAmountError();
        if (_totalMinted() + _mintAmount > maxSupply)
            revert ExceedsMaxSupplyError();
        if (msg.value != cost * _mintAmount) revert IncorrectAmountError();
        address sig_recover = keccak256(
            abi.encodePacked(msg.sender, _allowance, _phase)
        ).toEthSignedMessageHash().recover(_sig);

        if (sig_recover != signer) revert InvalidSignatureError();

        uint256 nextId = _nextTokenId();
        _setAux(msg.sender, uint64(_whitelistClaimed + _mintAmount));
        _mint(msg.sender, _mintAmount);
        _setExtraDataAt(nextId, uint24(_box));
    }

    function mint(
        uint256 _mintAmount,
        uint256 _box
    ) external payable callerIsUser {
        if (paused) revert ContractPausedError();
        if (!minting) revert MintClosedError();
        if (_mintAmount > maxMintAmountPerTx) revert MintAmountError();
        if (_totalMinted() + _mintAmount > maxSupply)
            revert ExceedsMaxSupplyError();
        if (msg.value != cost * _mintAmount) revert IncorrectAmountError();
        if (_box == 0 || _box > 3) revert InvalidBoxIDError();

        uint256 nextId = _nextTokenId();
        _mint(msg.sender, _mintAmount);
        _setExtraDataAt(nextId, uint24(_box));
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        if (frozen) revert ContractFrozenError();
        _baseTokenURI = baseURI;
    }

    function _placeholderURI() internal view returns (string memory) {
        return _placeholderTokenURI;
    }

    function setPlaceholderURI(
        string calldata placeholderURI
    ) external onlyOwner {
        if (frozen) revert ContractFrozenError();
        _placeholderTokenURI = placeholderURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (revealed) {
            return
                string(
                    abi.encodePacked(
                        _baseURI(),
                        _toString(tokenId),
                        string("/metadata.json")
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        _placeholderURI(),
                        _toString(uint8(_getExtraDataAt(tokenId))),
                        string(".json")
                    )
                );
        }
    }

    function updateMetadata() external onlyOwner {
        emit BatchMetadataUpdate(1, _totalMinted());
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function getExtraDataAt(uint256 tokenId) public view returns (uint256) {
        return _getExtraDataAt(tokenId);
    }

    function getBoxId(uint256 tokenId) public view returns (uint8) {
        return uint8(_getExtraDataAt(tokenId));
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        return previousExtraData;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        // expiration time represented in days. multiply by 24 * 60 * 60, or 86400 to convert to block.timestamp.
        if (_exists(tokenId)) {
            if (
                uint256(_getExtraDataAt(tokenId) >> 8) * 86400 > block.timestamp
            ) revert TokenTransferLockedError();
        }
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(
        address payable receiver,
        uint96 numerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}