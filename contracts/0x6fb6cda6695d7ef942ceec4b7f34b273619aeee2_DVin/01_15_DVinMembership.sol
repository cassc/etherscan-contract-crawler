// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EIP712Base.sol";
import "./erc721a/extensions/ERC721ABurnable.sol";

contract CloneFactory {
    // implementation of eip-1167 - see https://eips.ethereum.org/EIPS/eip-1167
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

error CallerIsNotMinter();
error MaxSupplyExceeded();
error NonceTooLow();
error RecoveredUnauthorizedAddress();
error DeadlineExpired();
error TransfersDisabled();

/// @title DVin Membership NFT
/// @notice NFT contract with upgradeable sale contract and signature based transfers
contract DVin is ERC721ABurnable, Ownable, EIP712Base, Initializable {
    using Strings for uint256; /*String library allows for token URI concatenation*/
    using ECDSA for bytes32; /*ECDSA library allows for signature recovery*/

    bool public tradingEnabled; /*Trading can be disabled by owner*/

    string public contractURI; /*contractURI contract metadata json*/
    string public baseURI; /*baseURI_ String to prepend to token IDs*/
    string private _name; /*Token name override*/
    string private _symbol; /*Token symbol override*/

    uint256 public maxSupply;

    address public minter; /*Contract that can mint tokens, changeable by owner*/

    mapping(address => uint256) public nonces; /*maps record of states for signing & validating signatures
        Nonces increment each time a permit is used.
        Users can invalidate a previously signed permit by changing their account nonce
    */

    /*EIP712 typehash for permit to allow spender to send a specific token ID*/
    bytes32 constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
        );

    /*EIP712 typehash for permit to allow spender to send a specific token ID*/
    bytes32 constant UNIVERSAL_PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 nonce,uint256 deadline)"
        );

    /// @notice constructor configures template contract metadata
    constructor() ERC721A("TEMPLATE", "DEAD") initializer {
        _transferOwnership(address(0xdead)); /*Disable template*/
    }

    /// @notice setup configures interfaces and production metadata
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param _contractURI Metadata location for contract
    /// @param baseURI_ Metadata location for tokens
    /// @param _minter Authorized address to mint
    /// @param _maxSupply Max supply for this token
    function setUp(
        string memory name_,
        string memory symbol_,
        string memory _contractURI,
        string memory baseURI_,
        address _minter,
        address _owner,
        uint256 _maxSupply
    ) public initializer {
        _name = name_;
        _symbol = symbol_;
        _setBaseURI(baseURI_); /*Base URI for token ID resolution*/
        contractURI = _contractURI; /*Contract URI for marketplace metadata*/
        minter = _minter; /*Address authorized to mint */
        _currentIndex = _startTokenId();
        maxSupply = _maxSupply;
        _transferOwnership(_owner);
        setUpDomain(name_);
    }

    function _startTokenId() internal view override(ERC721A) returns (uint256) {
        return 1;
    }

    /*****************
    Permissioned Minting
    *****************/
    /// @dev Mint the token for specified tier by authorized minter contract or EOA
    /// @param _dst Recipient
    /// @param _qty Number of tokens to send
    function mint(address _dst, uint256 _qty) external returns (bool) {
        if (msg.sender != minter) revert CallerIsNotMinter(); /*Minting can only be done by minter address*/
        if ((totalSupply() + _qty) > maxSupply) revert MaxSupplyExceeded(); /*Cannot exceed max supply*/
        _safeMint(_dst, _qty); /*Send token to new recipient*/
        return true; /*Return success to external caller*/
    }

    /*****************
    Permit & Guardian tools
    *****************/
    /// @notice Manually update nonce to invalidate previously signed permits
    /// @dev New nonce must be higher than current to prevent replay
    /// @param _nonce New nonce
    function setNonce(uint256 _nonce) external {
        if (_nonce <= nonces[msg.sender]) revert NonceTooLow(); /*New nonce must be higher to prevent replay*/
        nonces[msg.sender] = _nonce; /*Set new nonce for sender*/
    }

    /// @notice Transfer token on behalf of owner using signed authorization
    ///     Useful to help people authorize a guardian to rescue tokens if access is lost
    /// @dev Signature can be either per token ID or universal
    /// @param _owner Current owner of token
    /// @param _tokenId Token ID to transfer
    /// @param _dst New recipient
    /// @param _deadline Date the permit must be used by
    /// @param _signature Concatenated RSV of sig
    function transferWithUniversalPermit(
        address _owner,
        uint256 _tokenId,
        address _dst,
        uint256 _deadline,
        bytes calldata _signature
    ) external {
        bytes32 structHash = keccak256(
            abi.encode(
                UNIVERSAL_PERMIT_TYPEHASH,
                _owner,
                msg.sender,
                nonces[_owner]++, /*Increment nonce to prevent replay*/
                _deadline
            )
        ); /*calculate EIP-712 struct hash*/
        bytes32 digest = toTypedMessageHash(structHash); /*Calculate EIP712 digest*/
        address recoveredAddress = digest.recover(_signature); /*Attempt to recover signer*/
        if (recoveredAddress != _owner) revert RecoveredUnauthorizedAddress(); /*check signer is `owner`*/

        if (block.timestamp > _deadline) revert DeadlineExpired(); /*check signature is not expired*/

        _approve(msg.sender, _tokenId, _owner);
        safeTransferFrom(_owner, _dst, _tokenId); /*Move token to new wallet*/
    }

    /// @notice Transfer token on behalf of owner using signed authorization
    ///     Useful to help people authorize a guardian to rescue tokens if access is lost
    /// @dev Signature can be either per token ID or universal
    /// @param _owner Current owner of token
    /// @param _tokenId Token ID to transfer
    /// @param _dst New recipient
    /// @param _deadline Date the permit must be used by
    /// @param _signature Concatenated RSV of sig
    function transferWithPermit(
        address _owner,
        uint256 _tokenId,
        address _dst,
        uint256 _deadline,
        bytes calldata _signature
    ) external {
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                _owner,
                msg.sender,
                _tokenId,
                nonces[_owner]++, /*Increment nonce to prevent replay*/
                _deadline
            )
        ); /*calculate EIP-712 struct hash*/
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        ); /*calculate EIP-712 digest for signature*/
        address recoveredAddress = digest.recover(_signature); /*Attempt to recover signer*/
        if (recoveredAddress != _owner) revert RecoveredUnauthorizedAddress(); /*check signer is `owner`*/

        if (block.timestamp > _deadline) revert DeadlineExpired(); /*check signature is not expired*/

        _approve(msg.sender, _tokenId, _owner);
        safeTransferFrom(_owner, _dst, _tokenId); /*Move token to new wallet*/
    }

    /*****************
    CONFIG FUNCTIONS
    *****************/
    /// @notice Set new base URI for token IDs
    /// @param baseURI_ String to prepend to token IDs
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @notice Enable or disable trading
    /// @param _enabled bool to set state on or off
    function setTradingState(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
    }

    /// @notice Set minting contract
    /// @param _minter new minting contract
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /// @notice internal helper to update token URI
    /// @param baseURI_ String to prepend to token IDs
    function _setBaseURI(string memory baseURI_) internal {
        baseURI = baseURI_;
    }

    /// @notice Set new contract URI
    /// @param _contractURI Contract metadata json
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /*****************
    Public interfaces
    *****************/
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    ///@dev Support interfaces for Access Control and ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Hook for disabling trading
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (from != address(0) && to != address(0) && !tradingEnabled)
            revert TransfersDisabled();
    }
}

/// @title DVin Membership NFT Summoner
/// @notice Clone factory for new membership tiers
contract DVinSummoner is CloneFactory, Ownable {
    address public template; /*Template contract to clone*/

    constructor(address _template) public {
        template = _template;
    }

    event SummonComplete(
        address indexed newContract,
        string name,
        string symbol,
        address summoner
    );

    /// @notice Public interface for owner to create new membership tiers
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param _contractURI Metadata for contract
    /// @param baseURI_ Metadata for tokens
    /// @param _minter Authorized minting address
    /// @param _maxSupply Max amount of this token that can be minted
    /// @param _owner Owner address of new contract
    function summonDvin(
        string memory name_,
        string memory symbol_,
        string memory _contractURI,
        string memory baseURI_,
        address _minter,
        uint256 _maxSupply,
        address _owner
    ) external onlyOwner returns (address) {
        DVin dvin = DVin(createClone(template)); /*Create a new clone of the template*/

        /*Set up the external interfaces*/
        dvin.setUp(
            name_,
            symbol_,
            _contractURI,
            baseURI_,
            _minter,
            _owner,
            _maxSupply
        );

        emit SummonComplete(address(dvin), name_, symbol_, msg.sender);

        return address(dvin);
    }
}