// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@CUSTOMERS
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&P..            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@Y.                    ^#@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@~                      !#@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@Y~^..                    [email protected]@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@G^~~^:                   Y&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@B~~~~^^^::..  .          [email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@P7^.......              [email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@!             [email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@!.....:::....:::::::::[email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@Y!!^::.     .:::.     [email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@BGGG7~~::.  .^^~~~:  .:^^~^[email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@?7JY7!~::. :~!^GM!:  ^!~!#[email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@?!J57!~:::.:~JPG>^:..:PNG:[email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@P7!J7!~:?5J^:^~~^^^^^^~^::?5#@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&##?~~:[email protected]@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@J~!~~!YYJ?7:[email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@Y!!!^:::^^^^^^^^^^::^~G&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@B~~~~^^^:::~77?!:!:[email protected]@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@#?777~~^^^~7???JGB&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@nftchef

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/ERC721A/contracts/ERC721A.sol";
import "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/finance/PaymentSplitter.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";

error InsufficientFunds();
error NotAllowed();
error AlreadyClaimed();
error MissingQuantity();
error ExceedsSupply();
error PresaleOnly();

contract BakersCustomers is ERC721A, ERC2981, Ownable, DefaultOperatorFilterer, Pausable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public LIMIT = 20;
    uint256 public PRICE = 0.005 ether;
    uint128 public SUPPLY = 10000;
    bool public revealed = false;
    bool public presaleOnly = true;

    mapping(address => bool) public bakers_claimed;
    mapping(address => uint256) public mintBalances;

    string public baseURI;
    address[] internal TEAM;
    address internal _SIGNER;

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address royaltyReceiver
    ) ERC721A(_name, _ticker) PaymentSplitter(_payees, _shares) {
        TEAM = _payees;
        baseURI = _uri;
        _pause();
        _setDefaultRoyalty(royaltyReceiver, 500);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function bakersClaim(uint256 _quantity, bytes32 _hash, bytes memory _signature) external whenNotPaused {
        if (bakers_claimed[msg.sender] == true) {
            revert AlreadyClaimed();
        }
        if (!checkHash(_hash, _signature, _SIGNER, _quantity)) {
            revert NotAllowed();
        }
        bakers_claimed[msg.sender] = true;
        mint(_quantity);
    }

   function presalePurchase(uint256 _quantity, bytes32 _hash, bytes memory _signature)
        external
        payable
        whenNotPaused
    {

        uint256 _qty = 1;

        if (!checkHash(_hash, _signature, _SIGNER, _qty)) {
            revert NotAllowed();
        }

        if (_quantity + mintBalances[msg.sender] > LIMIT) {
            revert ExceedsSupply();
        }

        if (msg.value < PRICE) {
            revert InsufficientFunds();
        }

        mint(_quantity);
    }

    function purchase(uint256 _quantity) external payable whenNotPaused {
        if (presaleOnly) {
            revert PresaleOnly();
        }

        if (msg.value < PRICE) {
            revert InsufficientFunds();
        }

        mint(_quantity);
    }

    function mint(uint256 _quantity) internal {
        if (_quantity < 1) {
            revert MissingQuantity();
        }
        if (totalSupply() + _quantity > SUPPLY) {
            revert ExceedsSupply();
        }

        mintBalances[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');
        if (revealed) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        } else {
            return baseURI;
        }
    }

    function airdrop(address[] calldata _wallets) external onlyOwner {
        uint256 wallets = _wallets.length;
        if (wallets + totalSupply() > SUPPLY) {
            revert ExceedsSupply();
        }

        for (uint256 i = 0; i < wallets; i++) {
            if (_wallets[i] != address(0)) {
                _safeMint(_wallets[i], 1);
            }
        }
    }

    function airdropMany(address _wallet, uint256 _quantity) external onlyOwner {
        if (_quantity + totalSupply() > SUPPLY) {
            revert ExceedsSupply();
        }

        _safeMint(_wallet, _quantity);
    }

    function senderMessageHash(uint256 _quantity) internal view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(address(this), msg.sender, _quantity))
            )
        );
        return message;
    }

    function checkHash(bytes32 _hash, bytes memory signature, address _account, uint256 _quantity)
        internal
        view
        returns (bool)
    {
        bytes32 senderHash = senderMessageHash(_quantity);

        if (senderHash != _hash) {
            return false;
        }
        return _hash.recover(signature) == _account;
    }

    function setSigner(address _address) external onlyOwner {
        _SIGNER = _address;
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setPresale(bool _state) external onlyOwner {
        presaleOnly = _state;
    }

    function setSupply(uint128 _supply) external onlyOwner {
        SUPPLY = _supply;
    }

    function setBaseURI(string memory _URI, bool _reveal) external onlyOwner {
        baseURI = _URI;
        revealed = _reveal;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw() external onlyOwner {
        for (uint256 i = 0; i < TEAM.length; i++) {
            release(payable(TEAM[i]));
        }
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}