//SPDX-License-Identifier: Unlicense
// Creator: Pixel8 Labs
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@sigpub/signatures-verify/Signature.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

error InvalidSignature();
error InvalidSigner(address signer);
error InvalidAmount(uint amount);
error InvalidOffer(uint256 price, uint256 offer);
error ExceededMaxSupply();
error ExceededMintQuota(uint amount, uint quota);
error InvalidSource();

contract Metaseed is
    ERC721A,
    ERC2981,
    PaymentSplitter,
    Ownable,
    AccessControl,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    uint private constant MAX_SUPPLY = 10000;
    uint private maxPerTx = 20;
    string public baseURI;

    // Phases
    enum Phases {
        CLOSED,
        WHITELIST,
        PUBLIC
    }
    mapping(Phases => bool) public phase;
    mapping(Phases => address) public signer;

    // Pricing
    mapping(Phases => uint256) public price;
    address[] public _payees = [
        0x22291086A1d5ad54E14aD34aC6e335A0eCb159EB,
        0x34ce61BD95D6c9dA056c7A58944Fb9A0ff932a7e
    ];
    uint256[] private _shares = [925, 75];

    // canMint modifier should contain the most common usecase between mint functions
    // (e.g. public mint, private mint, free mint, airdrop)
    modifier canMint(uint amount, uint256 p) {
        uint256 supply = totalSupply();
        if (amount > maxPerTx) revert InvalidAmount(maxPerTx);
        if (msg.value != p * amount) revert InvalidOffer(p * amount, msg.value);
        if (supply + amount > MAX_SUPPLY) revert ExceededMaxSupply();
        if (msg.sender != tx.origin) revert InvalidSource();
        _;
    }

    modifier canWhitelistMint(uint amount) {
        uint256 supply = totalSupply();
        if (amount > maxPerTx) revert InvalidAmount(maxPerTx);
        if (supply + amount > MAX_SUPPLY) revert ExceededMaxSupply();
        if (msg.sender != tx.origin) revert InvalidSource();
        _;
    }

    constructor(
        string memory uri,
        address receiver
    )
        ERC721A('MetaseedWorldSingularity', 'MWS')
        PaymentSplitter(_payees, _shares)
        Ownable()
    {
        baseURI = uri;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(receiver, 700); // 1000 = 10%
        _transferOwnership(receiver);
        price[Phases.PUBLIC] = 0.07 ether;
        price[Phases.WHITELIST] = 0 ether;
        phase[Phases.CLOSED] = true;
        phase[Phases.PUBLIC] = false;
        phase[Phases.WHITELIST] = false;
    }

    // Metadata
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length == 0) return '';

        return
            string(abi.encodePacked(baseURI, '/', _toString(tokenId), '.json'));
    }

    function mint(
        uint amount
    ) external payable canMint(amount, price[Phases.PUBLIC]) nonReentrant {
        require(
            phase[Phases.PUBLIC] && !phase[Phases.CLOSED],
            'Public mint is not open'
        );

        _safeMint(msg.sender, amount);
    }

    function whitelistMint(
        uint64 amount,
        uint64 maxAmount,
        bytes memory signature
    ) external canWhitelistMint(amount) nonReentrant {
        require(
            phase[Phases.WHITELIST] && !phase[Phases.CLOSED],
            'Whitelist mint is not open'
        );

        uint64 aux = _getAux(msg.sender);
        if (
            Signature.verify(maxAmount, msg.sender, signature) !=
            signer[Phases.WHITELIST]
        ) revert InvalidSignature();
        if (aux + amount > maxAmount)
            revert ExceededMintQuota(aux + amount, maxAmount);

        _setAux(msg.sender, aux + amount);
        _safeMint(msg.sender, amount);
    }

    function airdrop(
        address wallet,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 supply = totalSupply();
        if (supply + amount > MAX_SUPPLY) revert ExceededMaxSupply();
        _safeMint(wallet, amount);
    }

    function claimed(address target) external view returns (uint256) {
        return _getAux(target);
    }

    // Minting fee
    function setPrice(
        Phases _p,
        uint amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price[_p] = amount;
    }

    function claim() external {
        release(payable(msg.sender));
    }

    function setTokenURI(
        string calldata uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    function setSigner(
        Phases _p,
        address value
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer[_p] = value;
    }

    function setPhase(
        Phases _phase,
        bool _status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_phase != Phases.CLOSED) phase[Phases.CLOSED] = false;
        phase[_phase] = _status;
    }

    // Set default royalty to be used for all token sale
    function setDefaultRoyalty(
        address _receiver,
        uint96 _fraction
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _fraction);
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _fraction
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(_tokenId, _receiver, _fraction);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // Operator Filter Registry
    bool filter;

    function setFilter(bool v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        filter = v;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        if (filter) {
            filteredTransferFrom(from, to, tokenId);
        } else {
            super.transferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        if (filter) {
            filteredSafeTransferFrom(from, to, tokenId);
        } else {
            super.safeTransferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override {
        if (filter) {
            filteredSafeTransferFrom(from, to, tokenId, data);
        } else {
            super.safeTransferFrom(from, to, tokenId, data);
        }
    }

    function filteredTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function filteredSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function filteredSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}