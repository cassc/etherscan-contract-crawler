// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Metazoku is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    // Address used in withdraw funds after mint and in royalty payments. Owner address by default
    address private _withdrawAddress;

    // Royalty value
    uint96 private _royaltyBPS;

    // Private sale current status. True if active, false if not
    bool private _isPrivateSaleActive;

    // Public sale current status. True if active false if not
    bool private _isPublicSaleActive;

    // Staking current status. True if active false if not
    bool private _isStakingActive;

    // Current status of the collection. True if freeze, false if not
    bool private _isCollectionFreeze;

    // Current status of transfer allowance
    bool private _isTransferAllowed;

    // Limit for all token emission
    uint256 private _limitEmission;

    // Token price in ETH
    uint256 private _tokenPrice;

    // Token metadata
    string private _tokenUri;

    // Staked token IDs
    uint256[] private _stakedTokens;

    // Mapping user address to nonce for signed mint
    mapping(address => uint256) private _signedMintNonce;

    // Triggered when private sale status changed
    event PrivateSaleStatusChanged(bool active, address caller);

    // Triggered when public sate status changed
    event PublicSaleStatusChanged(bool active, address caller);

    // Triggered when staking status changed
    event StakingStatusChanged(bool active, address caller);

    // Triggered when transfer allowance status changed
    event TransferAllowanceStatusChanged(bool active, address caller);

    // Triggered when collection is freeze
    event CollectionFreeze(bool freeze, address caller);

    // Triggered when emission is freeze
    event EmissionFreeze(uint256 totlaSupply, address caller);

    // Triggered when metadata was updated
    event MetadataUpdate(string metadata, address caller);

    // Triggered when token is staked
    event TokenStaked(uint256 tokenId, address caller);

    // Triggered when token is unstaked
    event TokenUnstaked(uint256 tokenId, address caller);

    // Triggered when tokens are minted during private sale
    event PreSaleMint(uint256 startTokenId, uint256 endTokenId, address to);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 limitEmission_,
        uint96 royalty_,
        address withdrawAddress_
    ) ERC721A(name_, symbol_) {
        _limitEmission = limitEmission_;
        _setDefaultRoyalty(withdrawAddress_, royalty_);
        _royaltyBPS = royalty_;
        _withdrawAddress = withdrawAddress_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC2981).interfaceId; // royalty
    }

    // Returns current limit emission
    function limitEmission() external view returns (uint256) {
        return _limitEmission;
    }

    // Allows to set new royalty for contract owner
    function setRoyalty(uint96 newRoyalty) external onlyOwner {
        _setDefaultRoyalty(_withdrawAddress, newRoyalty);
    }

    // Allows to set withdraw address
    function setWithdrawAddress(address to) external onlyOwner {
        _withdrawAddress = to;
        _setDefaultRoyalty(to, _royaltyBPS);
    }

    // Returns current withdraw address
    function getWithdrawAddress() external view returns (address) {
        return _withdrawAddress;
    }

    /*
     * Allows to add new metadata
     *
     * Requirements:
     * - caller should be a contract owner
     * - collection should not be freeze
     *
     * @param `metadata` - new metadata
     *
     * Emits `MetadataUpdate` event
     */
    function updateMetadata(string calldata metadata) external onlyOwner {
        require(!_isCollectionFreeze, "Metazoku: collection is freeze");

        _tokenUri = metadata;

        emit MetadataUpdate(_tokenUri, msg.sender);
    }

    // Returns current metadata
    function getMetadata() external view returns (string memory) {
        return _tokenUri;
    }

    /*
     * Allows to set new token price in ETH
     *
     * Requirements:
     * - caller should be a contract owner
     * - public sale should be inactive
     * - private sale should be inactive
     * - collection should not be freeze
     * - new price can not be 0
     *
     * @param `price` - new price for one token in ETH
     *
     */
    function setPrice(uint256 price) external onlyOwner {
        require(!_isCollectionFreeze, "Metazoku: collection is freeze");
        require(!_isPrivateSaleActive, "Metazoku: private sale is active");
        require(!_isPublicSaleActive, "Metazoku: public sale is active");
        require(price != 0, "Metazoku: price can not be 0");

        _tokenPrice = price;
    }

    // Returns current token price in ETH
    function getPrice() external view returns (uint256) {
        return _tokenPrice;
    }

    /*
     * Allows to mint `amount` of new NFT to caller
     *
     * Requirements:
     * - collection should not be freeze
     * - public sale should be active
     * - message value should be equal to token price * amount
     *
     * @param `amount` - amount of tokens to mint
     *
     * Emits `Transfer` event see {IERC721A}
     */
    function mint(uint256 amount) external payable {
        require(!_isCollectionFreeze, "Metazoku: collection is freeze");
        require(_isPublicSaleActive, "Metazoku: public sale is not active");
        require(_limitEmission >= amount + totalSupply(), "Metazoku: limit emission reached");
        require(amount > 0, "Metazoku: amount should be more than 0");
        require(msg.value == _tokenPrice * amount, "Metazoku: invalid funds amount");

        _mint(msg.sender, amount);
    }

    /*
     * Allows to mint `amount` of new NFT to caller while private sale, if caller
     * is in allow list. Can only be used with signature from contract owner. See {Metazoku - _checkSignature}
     * and valid params. Params are validating by comparing message hash
     * and hash from params - caller address, amount, value and nonce. See {Metazoku - _checkMessage}
     *
     * Requirements:
     * - should have valid signature from contract owner
     * - should have valid params and message
     * - collection should not be freeze
     * - private sale should be active
     * - amount should be more than 0
     *
     * @param `amount` - amount of tokens to mint
     * @param `hash` - message hash to prove signature
     * @param `signature` - signature hash to prove
     *
     * Emits `Transfer` event see {IERC721A}
     * Emits `PreSaleMint` event
     */
    function mintPresale(uint256 amount, bytes32 message, bytes calldata signature) external payable {
        require(!_isCollectionFreeze, "Metazoku: collection is freeze");
        require(amount > 0, "Metazoku: amount should be more than 0");
        require(_checkSignature(message, signature), "Metazoku: invalid signature");
        require(_checkMessage(message, address(msg.sender), amount, msg.value), "Metazoku: invalid message");
        require(_limitEmission >= amount + totalSupply(), "Metazoku: limit emission reached");
        require(_isPrivateSaleActive, "Metazoku: private sale is not active");
        _signedMintNonce[msg.sender]++;

        _mint(msg.sender, amount);

        emit PreSaleMint(_nextTokenId() - amount, _nextTokenId() - 1, msg.sender);
    }

    /*
     * Allows to withdraw all ETH from contract balance to `_withdrawAddress` (by default - contract owner address)
     *
     * Requirements:
     * - caller should be the contract owner
     *
     */
    function withdrawAll() external onlyOwner {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    // Returns current nonce for given address for signed mint
    function getNonce(address to) public view returns (uint256) {
        return _signedMintNonce[to];
    }

    /*
     * Allows to mint `amount` of NFT `to` address for contract owner
     *
     * Requirements:
     * - collection should not be freeze
     * - caller should be contract owner
     * - amount of tokens should be more than 0
     * - private sale should be not active
     * - public sale should be not active
     *
     * @param `amount` - amount of tokens to mint
     * @param `to` - address where to mint tokens
     *
     * Emits `Transfer` event see {IERC721A}
     */
    function mintReserved(uint256 amount, address to) external onlyOwner {
        require(!_isCollectionFreeze, "Metazoku: collection is freeze");
        require(_limitEmission >= amount + totalSupply(), "Metazoku: limit emission reached");
        require(amount > 0, "Metazoku: amount should be more than 0");
        require(!_isPrivateSaleActive, "Metazoku: private sale is active");
        require(!_isPublicSaleActive, "Metazoku: public sale is active");

        _mint(to, amount);
    }

    /*
     * Allows to stake given NFT `ids`. Staked tokens can not be transfer.
     *
     * Requirements:
     * - caller should be token owner for all token ids
     * - all tokens should not be staked
     * - staking should be active
     * - should be at least one token id in ids
     *
     * @param `ids` - token IDs
     *
     * Emits `TokenStaked` event for each token
     */
    function stakeTokens(uint256[] memory ids) external {
        require(_isStakingActive, "Metazoku: staking is not active");
        require(ids.length > 0, "Metazoku: ids should not be empty");

        for (uint256 i = 0; i < ids.length; i++) {
            require(ownerOf(ids[i]) == msg.sender, "Metazoku: you are not the owner of at least one token");
            require(!_isTokenStaked(ids[i]), "Metazoku: at least one token already staked");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            _stakedTokens.push(ids[i]);

            emit TokenStaked(ids[i], msg.sender);
        }
    }

    /*
     * Allows to unstake given NFT `ids`.
     *
     * Requirements:
     * - caller should be token owner of all token ids
     * - all tokens should be staked
     * - staking should be active
     * - should be at least one token id in ids
     *
     * @param `ids` - token IDs
     *
     * Emits `TokenUnstaked` event for each token
     */
    function unstakeTokens(uint256[] memory ids) external {
        require(_isStakingActive, "Metazoku: staking is not active");
        require(ids.length > 0, "Metazoku: ids should not be empty");

        for (uint256 i = 0; i < ids.length; i++) {
            require(ownerOf(ids[i]) == msg.sender, "Metazoku: you are not the owner of at least one token");
            require(_isTokenStaked(ids[i]), "Metazoku: at least one token is not staked");
        }

        // Get each token from given token `ids`
        for (uint256 j = 0; j < ids.length; j++) {
            // Get each token from `_stakedTokens`
            for (uint256 i = 0; i < _stakedTokens.length; i++) {
                if (_stakedTokens[i] == ids[j]) {
                    _stakedTokens[i] = _stakedTokens[_stakedTokens.length - 1];
                    _stakedTokens.pop();

                    emit TokenUnstaked(ids[j], msg.sender);
                    break;
                }
            }
        }
    }

    // Returns `_stakedTokens` array
    function getStakedTokens() external view returns (uint256[] memory) {
        return _stakedTokens;
    }

    // See {Metazoku `_isTokensStaked`}
    function isTokenStaked(uint256 id) external view returns (bool) {
        return _isTokenStaked(id);
    }

    /*
     * Allows to change status of the transfer allowance
     *
     * Requirements:
     * - caller should be a contract owner
     *
     * Emits `TransferAllowanceStatusChanged` event
     */
    function flipTransferAllowance() external onlyOwner {
        _isTransferAllowed = !_isTransferAllowed;

        emit TransferAllowanceStatusChanged(_isTransferAllowed, msg.sender);
    }

    // Returns true if transfer is allowed and false if not
    function isTransferAllowed() external view returns (bool) {
        return _isTransferAllowed;
    }

    /*
     * Allows to change status of the private sale
     *
     * Requirements:
     * - caller should be a contract owner
     * - public sale should be inactive
     *
     * Emits `PrivateSaleStatusChanged` event
     */
    function flipPrivateSaleStatus() external onlyOwner {
        require(!_isPublicSaleActive, "Metazoku: public sale is active");

        _isPrivateSaleActive = !_isPrivateSaleActive;
        emit PrivateSaleStatusChanged(_isPrivateSaleActive, msg.sender);
    }

    // Returns true if private sale is active and false if not
    function isPrivateSaleActive() external view returns (bool) {
        return _isPrivateSaleActive;
    }

    /*
     * Allows to change status of the public sale
     *
     * Requirements:
     * - caller should be a contract owner
     * - private sale should be inactive
     *
     * Emits `PublicSaleStatusChanged` event
     */
    function flipPublicSaleStatus() external onlyOwner {
        require(!_isPrivateSaleActive, "Metazoku: private sale is active");

        _isPublicSaleActive = !_isPublicSaleActive;
        emit PublicSaleStatusChanged(_isPublicSaleActive, msg.sender);
    }

    // Returns true if public sale is active and false if not
    function isPublicSaleActive() external view returns (bool) {
        return _isPublicSaleActive;
    }

    /*
     * Allows to change status of staking
     *
     * Requirements:
     * - caller should be a contract owner
     *
     * Emits `StakingStatusChanged` event
     */
    function flipStakingStatus() external onlyOwner {
        _isStakingActive = !_isStakingActive;

        emit StakingStatusChanged(_isStakingActive, msg.sender);
    }

    // Returns true if staking is active and false if not
    function isStakingActive() external view returns (bool) {
        return _isStakingActive;
    }

    /*
     * Allows to freeze collection
     *
     * Requirements:
     * - caller should be a contract owner
     * - private sale should be inactive
     * - public sale should be inactive
     *
     * Emits `CollectionFreeze` event
     */
    function freezeCollection() external onlyOwner {
        require(!_isPrivateSaleActive, "Metazoku: private sale is active");
        require(!_isPublicSaleActive, "Metazoku: public sale is active");

        _isCollectionFreeze = true;
        emit CollectionFreeze(_isCollectionFreeze, msg.sender);
    }

    /*
     * Allows to freeze emission
     *
     * Requirements:
     * - caller should be a contract owner
     * - limit emission should not be equal total supply
     *
     * Emits `EmissionFreeze` event
     */
    function freezeEmission() external onlyOwner {
        require(_limitEmission != totalSupply(), "Metazoku: emission is freeze");

        _limitEmission = totalSupply();

        emit EmissionFreeze(_limitEmission, msg.sender);
    }

    // Returns true if collection is freeze and false if not
    function isCollectionFreeze() external view returns (bool) {
        return _isCollectionFreeze;
    }

    /*
     * See {ERC721A - approve} and {DefaultOperatorFilterer - onlyAllowedOperatorApproval}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function approve(address to, uint256 tokenId) public payable override onlyAllowedOperatorApproval(to) {
        require(_isTransferAllowed, "Metazoku: transfer not allowed");
        ERC721A.approve(to, tokenId);
    }

    /*
     * See {ERC721A - setApprovalForAll} and {DefaultOperatorFilterer - onlyAllowedOperatorApproval}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override onlyAllowedOperatorApproval(operator) {
        require(_isTransferAllowed, "Metazoku: transfer not allowed");
        ERC721A.setApprovalForAll(operator, approved);
    }

    /*
     * See {ERC721A - transferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        require(_isTransferAllowed, "Metazoku: transfer not allowed");
        ERC721A.transferFrom(from, to, tokenId);
    }

    /*
     * See {ERC721A - safeTransferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        require(_isTransferAllowed, "Metazoku: transfer not allowed");
        ERC721A.safeTransferFrom(from, to, tokenId);
    }

    /*
     * See {ERC721A - safeTransferFrom} and {DefaultOperatorFilterer - onlyAllowedOperator}
     *
     * Additional requirements:
     * - transfer should be allowed
     *
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override onlyAllowedOperator(from) {
        require(_isTransferAllowed, "Metazoku: transfer not allowed");
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
    }

    // Returns token metadata
    function _baseURI() internal view override returns (string memory) {
        return _tokenUri;
    }

    // Returns the starting token ID.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * {ERC721A} override function
     * Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * In this contract implementation used to revert transfer transactions
     * with staked tokens
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        for (uint256 i = 0; i < _stakedTokens.length; i++) {
            require(_stakedTokens[i] != startTokenId, "Metazoku: token staked");
        }
    }

    // Returns true if given token `id` is staked and false if not
    function _isTokenStaked(uint256 id) internal view returns (bool) {
        for (uint256 i = 0; i < _stakedTokens.length; i++) {
            if (_stakedTokens[i] == id) return true;
        }

        return false;
    }

    /**
     * See {ECDSA - recover}
     * @return signer address
     */
    function _recoverSigner(bytes32 message, bytes calldata signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        return ECDSA.recover(messageDigest, signature);
    }

    /**
     * See {Metazoku - _recoverSigner}
     * Compares signer address and owner address. Returns true if signer is owner and false if not
     */
    function _checkSignature(bytes32 message, bytes calldata signature) internal view returns (bool) {
        return _recoverSigner(message, signature) == owner();
    }

    /**
     * Compares message hash from caller and hash from params - caller address, amount to mint, value and nonce.
     * If hash is not equal returns false, if it is equal (which means valid) - returns true
     */
    function _checkMessage(
        bytes32 message,
        address caller,
        uint256 amount,
        uint256 value
    ) internal view returns (bool) {
        return message == keccak256(abi.encodePacked(caller, amount, value, getNonce(caller)));
    }
}