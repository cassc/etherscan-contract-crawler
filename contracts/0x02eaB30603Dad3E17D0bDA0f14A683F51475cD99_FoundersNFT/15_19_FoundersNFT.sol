//SPDX-License-Identifier = MIT
pragma solidity 0.8.17;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error CallerIsContract(address address_);
error ExceedingMaxTokensPerWallet(uint16 maxPerWallet);
error ExceedingMaxMintsPerTransaction(uint16 maxPerTransaction);
error ExceedingAllowlistAllowance(uint16 allowlistAllowance);
error InsufficientFunds(uint256 funds, uint256 cost);
error InsufficientSupplyAvailable(uint256 maxSupply);
error TransferNotAllowed(address to);
error InvalidAllowlistId(uint8 allowlistId);
error InvalidAllowlistPhase(uint8 allowlistPhase);
error InvalidAllowlistAllowance(uint8 allowlistAllowance);
error InvalidAllowlistTime();
error InvalidMaxPerTransaction(uint8 maxFoundersMintsPerTransaction, uint8 maxFoundersMintsPerWallet);
error TokenDoesNotExist(uint16 tokenId);
error MaxTotalSupplyCannotBeLessThanAlreadyMinted();
error NotAllowlisted();
error ApprovalNotAllowed();
error SaleNotActive();
error URIQueryForNonexistentToken();
error UnableToSendChange(uint256 cashChange);
error UnableToWithdraw(uint256 amount);
error NoContracts();

contract FoundersNFT is ERC721A, AccessControl, ReentrancyGuard, OperatorFilterer, Ownable, ERC2981 {
    using Address for address;

    struct Allowlist {
        bytes32 root;
        uint256 startTime;
        uint256 endTime;
        uint8 allowance;
        uint8 mintPhase;
    }

    struct AllowlistProof {
        uint8 allowlist_id;
        bytes32[] proof;
    }

    uint8 private constant OMNIPOTENT_MINT = 1;
    uint8 private constant FOUNDERS_MINT = 2;

    uint8 public constant OMNIPOTENT_FOUNDERS_PASS = 1;
    uint8 public constant EDGE_FOUNDERS_PASS = 2;
    uint8 public constant PLATINUM_FOUNDERS_PASS = 3;
    uint8 public constant BLACK_FOUNDERS_PASS = 4;

    // Max amount of tokens addresses can mint in total during this phase (Includes wl mints and public).
    uint8 public maxOmnipotentMintsPerWallet = 3;
    uint8 public maxFoundersMintsPerWallet = 5;

    uint8 public maxFoundersMintsPerTransaction = 5;

    uint16 public maxOmnipotentSupply;
    uint16 public maxTotalSupply;
    uint256 public mintPrice;
    uint256 public omnipotentPublicMintStartTime;
    uint256 public foundersPublicMintStartTime;

    string public baseURI = "";
    string public baseExtension = ".json";

    bool public isTransferAllowed = false;

    // Maps allowlist_id / waitlist_id to allowlist object.
    mapping(uint8 => Allowlist) public allowlists;

    // Maps token id to token type, will be filled after reveal.
    mapping(uint256 => uint8) private tokenTypeMapping;

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    address public stakingAddress; 

    constructor(
        uint16 _maxOmnipotentSupply,
        uint16 _maxTotalSupply,
        uint16 _reservedOmnipotentTokens,
        uint256 _mintPrice,
        address _internalMintAddress,
        uint256 _omnipotentPublicMintStartTime,
        uint256 _foundersPublicMintStartTime
    ) ERC721A("Naffles Founders Keys", "NFLS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);

        maxOmnipotentSupply = _maxOmnipotentSupply;
        maxTotalSupply = _maxTotalSupply;
        mintPrice = _mintPrice;
        omnipotentPublicMintStartTime = _omnipotentPublicMintStartTime;
        foundersPublicMintStartTime = _foundersPublicMintStartTime;

        _mint(_internalMintAddress, _reservedOmnipotentTokens);
        // at 6.9% (default denominator is 10000).
        _setDefaultRoyalty(_internalMintAddress, 690);
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    modifier transferAllowed(address _to) {
        if (!isTransferAllowed && stakingAddress != _to) {
          revert TransferNotAllowed(_to);
        }
        _;
    }

    modifier approvalAllowed() {
        if (!isTransferAllowed) {
          revert ApprovalNotAllowed();
        }
        _;
    }

    modifier validateMint(uint16 _mintAmount, uint16 _maxSupply) {
        if (_totalMinted() + _mintAmount > _maxSupply) {
            revert InsufficientSupplyAvailable({
            maxSupply: _maxSupply
            });
        }
        _;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (operator != address(0) && operator == stakingAddress) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator transferAllowed(to) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator transferAllowed(to) { 
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator
        transferAllowed(to)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
  
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperator approvalAllowed {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperator approvalAllowed {
        super.approve(operator, tokenId);
    }

    function adminMint(
        address _to,
        uint16 _mintAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) validateMint(_mintAmount, maxTotalSupply) {
        _mint(_to, _mintAmount);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /** 
     * @dev Create allowlist with a an allocation for either of the allowlist phases.
     * @dev The same id as another allowlist can be given to override the previous allowlist.
     * @param _root The merkle root of the allowlist.
     * @param _allowlistId The id of the allowlist.
     * @param _allowance The amount of tokens a allowlisted address can mint.
     * @param _mintPhase The phase the allowlist is for.
     * @param _startTime The start time of the allowlist.
     * @param _endTime The end time of the allowlist.
    */
    function createAllowlist(
        bytes32 _root,
        uint8 _allowlistId,
        uint8 _allowance,
        uint8 _mintPhase,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_startTime >= _endTime) {
            revert InvalidAllowlistTime();
        }
        if (_mintPhase == OMNIPOTENT_MINT) {
            if (_allowance > maxOmnipotentMintsPerWallet) {
                revert InvalidAllowlistAllowance({
                    allowlistAllowance: _allowance
                });
            }
        }
        else if (_mintPhase == FOUNDERS_MINT) {
            if (_allowance > maxFoundersMintsPerWallet) {
                revert InvalidAllowlistAllowance({
                    allowlistAllowance: _allowance
                });
            }
        }
        else {
            revert InvalidAllowlistPhase({
                allowlistPhase: _mintPhase
            });
        }
        allowlists[_allowlistId] = Allowlist(_root, _startTime, _endTime, _allowance, _mintPhase);
    }

    function removeAllowlist(uint8 _id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete allowlists[_id];
    }

    /**
     * @notice Public mint function for omnipotent key mint phase
     */
    function omnipotentMint() external payable validateMint(1, maxOmnipotentSupply) nonReentrant callerIsUser {
        if (_numberMinted(msg.sender) + 1 > maxOmnipotentMintsPerWallet) {
            revert ExceedingMaxTokensPerWallet({
            maxPerWallet: maxOmnipotentMintsPerWallet
            });
        }
        if (block.timestamp < omnipotentPublicMintStartTime) {
            revert SaleNotActive();
        }
        _internalMint(1);
    }

    /**
     * @notice Public mint function for founders key mint phase
     * @param _mintAmount The amount of tokens to mint.
     */
    function foundersMint(
        uint8 _mintAmount
    ) external payable validateMint(_mintAmount, maxTotalSupply) nonReentrant callerIsUser {
        if (_mintAmount > maxFoundersMintsPerTransaction) {
            revert ExceedingMaxMintsPerTransaction({
                maxPerTransaction: maxFoundersMintsPerTransaction
            });
        }
        _setAux(msg.sender, _getAux(msg.sender) + _mintAmount);
        if (_getAux(msg.sender) > maxFoundersMintsPerWallet) {
            revert ExceedingMaxTokensPerWallet({
            maxPerWallet: maxFoundersMintsPerWallet
            });
        }
        if (block.timestamp < foundersPublicMintStartTime) {
            revert SaleNotActive();
        }
        _internalMint(_mintAmount);
    }

    /**
     * @notice Whilitest mint for the omnipotent key mint phase.
     * @param _proof The allowlist proof of sender address.
     */
    function omnipotentAllowlistMint(
        AllowlistProof calldata _proof
    ) public payable validateMint(1, maxOmnipotentSupply) nonReentrant callerIsUser {
        Allowlist memory allowlist = allowlists[_proof.allowlist_id];
        if (block.timestamp >= allowlist.endTime || block.timestamp < allowlist.startTime ) {
            revert SaleNotActive();
        }

        if (allowlist.mintPhase != OMNIPOTENT_MINT) {
            // This shouldn't be possible but is here for extra security measure.
            revert InvalidAllowlistId({allowlistId: _proof.allowlist_id});
        }

        _omnipotentAllowlistMintCheck(allowlist.allowance);
        _allowlistCheckAndMint(1, allowlist.root, _proof);
    }

    /**
     * @notice Whilitest mint for the founders key mint phase.
     * @param _mintAmount The amount of tokens to mint.
     * @param _proof The allowlist proof of sender address.
     */
    function foundersAllowlistMint(
        uint8 _mintAmount,
        AllowlistProof calldata _proof
    ) external payable validateMint(_mintAmount, maxTotalSupply) nonReentrant callerIsUser {
        Allowlist memory allowlist = allowlists[_proof.allowlist_id];
        if (block.timestamp >= allowlist.endTime || block.timestamp < allowlist.startTime ) {
            revert SaleNotActive();
        }

        if (allowlist.mintPhase != FOUNDERS_MINT) {
            revert InvalidAllowlistId({allowlistId: _proof.allowlist_id});
        }

        _foundersAllowlistMintCheck(_mintAmount, allowlist.allowance);
        _allowlistCheckAndMint(_mintAmount, allowlist.root, _proof);
    }

    function _allowlistCheckAndMint(
        uint8 _mintAmount, bytes32 _root, AllowlistProof calldata _proof
    ) internal {
        if (!MerkleProof.verify(_proof.proof, _root, keccak256(abi.encodePacked(msg.sender)))) {
            revert NotAllowlisted();
        }

        _internalMint(_mintAmount);
    }

    function _omnipotentAllowlistMintCheck(uint8 _allowance) internal view {
        if (_numberMinted(msg.sender) + 1 > _allowance) {
            revert ExceedingAllowlistAllowance({allowlistAllowance: _allowance});
        }
    }

    function _foundersAllowlistMintCheck(uint8 _mintAmount, uint8 _allowance) internal {
        _setAux(msg.sender, (_getAux(msg.sender) + _mintAmount));

        if (_getAux(msg.sender) > _allowance) {
            revert ExceedingAllowlistAllowance({allowlistAllowance: _allowance});
        }
    }

    function _internalMint(uint8 _mintAmount) internal {
        uint256 totalPrice = _mintAmount * mintPrice;
        if (msg.value < totalPrice) {
            revert InsufficientFunds(msg.value, totalPrice);
        }

        if (msg.value > totalPrice) {
            uint256 excess = msg.value - mintPrice;
            (bool returned, ) = msg.sender.call{ value: excess }("");
            if (!returned) { revert UnableToSendChange({cashChange: excess}); }
        }

        _mint(msg.sender, _mintAmount);
    }

    function exists(uint32 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl, ERC2981)
        returns (bool)
    {
        return (ERC721A.supportsInterface(_interfaceId) ||
        AccessControl.supportsInterface(_interfaceId)) ||
        ERC2981.supportsInterface(_interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        return
        bytes(_baseURI()).length != 0
        ? string(
            abi.encodePacked(baseURI, _toString(tokenId), baseExtension)
        )
        : "";
    }

    function withdraw() external onlyRole(WITHDRAW_ROLE) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) { revert UnableToWithdraw({amount: address(this).balance});}
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev checks if the token id is <= the omnipotent supply because the first maxOmnipotentSupply tokens are reserved for the omnipotent key.
     */
    function tokenType(uint16 _tokenId) public view returns(uint8) {
        if (!_exists(_tokenId)) {
            revert TokenDoesNotExist({tokenId: _tokenId});
        }
        if (_tokenId <= maxOmnipotentSupply) {
            return OMNIPOTENT_FOUNDERS_PASS;
        } else {
            return tokenTypeMapping[_tokenId];
        }
    }

    function setBaseURI(string memory _newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _newBaseURI;
    }

    /**
     * Sets the token type id for the founders passes. Starts at index maxOmnipotentSupply + 1 because we can't set the type for the first x maxOmnipotentSupply tokens.
     */
    function setTokenTypeMappingForFoundersPasses(uint8[] memory _tokenTypes) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 startNumber = maxOmnipotentSupply + 1;
        for (uint256 i = 0; i < _tokenTypes.length; i++) {
            tokenTypeMapping[i + startNumber] = _tokenTypes[i];
        }
    }
    
    function setBaseExtension(string memory _baseExtension)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseExtension = _baseExtension;
    }

    function setMaxFoundersMintsPerWallet(uint8 _maxFoundersMintsPerWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxFoundersMintsPerWallet = _maxFoundersMintsPerWallet;
    }

    function setMaxOmnipotentMintsPerWallet(uint8 _maxOmnipotentMintsPerWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxOmnipotentMintsPerWallet = _maxOmnipotentMintsPerWallet;
    }

    function setMaxFoundersMintsPerTransaction(uint8 _maxFoundersMintsPerTransaction)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_maxFoundersMintsPerTransaction > maxFoundersMintsPerWallet) {
            revert InvalidMaxPerTransaction({
                maxFoundersMintsPerTransaction: _maxFoundersMintsPerTransaction,
                maxFoundersMintsPerWallet: maxFoundersMintsPerWallet
            });
        }
        maxFoundersMintsPerTransaction = _maxFoundersMintsPerTransaction;
    }

    function setMaxTotalSupply(uint16 _maxTotalSupply)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_maxTotalSupply <= _totalMinted()) {
            revert MaxTotalSupplyCannotBeLessThanAlreadyMinted();
        }
        maxTotalSupply = _maxTotalSupply;
    }

    function setMintPrice(uint256 _mintPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintPrice = _mintPrice;
    }

    function setOmnipotentPublicMintStartTime(uint256 _omnipotentPublicMintStartTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        omnipotentPublicMintStartTime = _omnipotentPublicMintStartTime;
    }

    function setFoundersPublicMintStartTime(uint256 _foundersPublicMintStartTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        foundersPublicMintStartTime = _foundersPublicMintStartTime;
    }

    function getNumberMinted(address _address) external view returns (uint256) {
        return _numberMinted(_address);
    }

    function getFoundersKeysMinted(address _address) external view returns (uint256) {
        return _getAux(_address);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
      
    function setIsTransferAllowed(bool _isTransferAllowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isTransferAllowed = _isTransferAllowed;
    }

    function setStakingAddress(address _stakingAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingAddress = _stakingAddress;
    }
}