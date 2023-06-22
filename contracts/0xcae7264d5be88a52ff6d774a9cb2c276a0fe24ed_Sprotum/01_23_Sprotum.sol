/**
SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.15;

import "erc721a/ERC721A.sol";
import "openzeppelin/token/common/ERC2981.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/utils/cryptography/draft-EIP712.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

contract Sprotum is
    ERC721A,
    ERC2981,
    Ownable,
    EIP712,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using ECDSA for bytes32;

    enum SaleState {
        Paused,
        Presale,
        Public
    }

    modifier onlyEOA() {
        require(!_isContract(msg.sender), "Contract is not allowed");
        require(msg.sender == tx.origin, "Proxy is not allowed");
        _;
    }

    modifier onlyPermittedAccounts() {
        require(
            msg.sender == owner() || permittedAccounts[msg.sender],
            "Not permitted account"
        );
        _;
    }

    ////////////////////////////////////////////////
    //                  STATE                    //
    //////////////////////////////////////////////

    uint256 public constant PRESALE_PRICE = 0 ether;
    uint256 public constant PUBLIC_SALE_MAX_TX = 5;
    uint256 public constant PUBLIC_SALE_PRICE = 0.002 ether;
    uint256 public constant MAX_SUPPLY = 16665;
    address private constant WITHDRAWAL_ADDRESS =
        0x33380D5FeB98B26bD659023B80BB7aCdEb5d6103;
    bytes32 public constant PRESALE_TYPEHASH =
        keccak256("Presale(address minter,uint256 allocation)");

    SaleState public saleState;
    address public signerAddress;
    string public baseURI;

    mapping(address => uint256) public presaleCount;
    mapping(address => bool) public permittedAccounts;

    constructor(
        string memory _baseURI,
        address _signerAddress
    ) ERC721A("Sprotum", "SPROTUM") EIP712("Sprotum", "1.0.0") {
        saleState = SaleState.Paused;
        baseURI = _baseURI;
        signerAddress = _signerAddress;
        _setDefaultRoyalty(WITHDRAWAL_ADDRESS, 500);
    }

    ////////////////////////////////////////////////
    //             OPERATOR FILTERER             //
    //////////////////////////////////////////////

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

    ////////////////////////////////////////////////
    //                   MINT                    //
    //////////////////////////////////////////////

    function gift(
        address[] calldata _to,
        uint256[] calldata _amount
    ) external onlyPermittedAccounts {
        for (uint256 i = 0; i < _to.length; i++) {
            require(
                totalSupply() + _amount[i] <= MAX_SUPPLY,
                "Maximum supply exceeded"
            );
            _mint(_to[i], _amount[i]);
        }
    }

    function mintPresale(
        uint256 _quantity,
        uint256 _allocation,
        bytes calldata _signature
    ) external payable onlyEOA nonReentrant {
        require(
            saleState == SaleState.Presale || saleState == SaleState.Public,
            "State doesn't match"
        );
        require(
            signerAddress ==
                _verifyPresaleSignature(msg.sender, _allocation, _signature),
            "Invalid signature"
        );
        require(
            presaleCount[msg.sender] + _quantity <= _allocation,
            "Maximum mint exceeded"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Maximum supply exceeded"
        );
        require(
            msg.value >= (PRESALE_PRICE * _quantity),
            "Invalid transaction value"
        );

        presaleCount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function mintPublicSale(
        uint256 _quantity
    ) external payable onlyEOA nonReentrant {
        require(saleState == SaleState.Public, "State doesn't match");
        require(_quantity <= PUBLIC_SALE_MAX_TX, "Maximum tx exceeded");
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Maximum supply exceeded"
        );
        require(
            msg.value >= (PUBLIC_SALE_PRICE * _quantity),
            "Invalid transaction value"
        );

        _mint(msg.sender, _quantity);
    }

    function burn(uint256 _tokenId) external onlyPermittedAccounts {
        _burn(_tokenId);
    }

    function _verifyPresaleSignature(
        address _minter,
        uint256 _allocation,
        bytes calldata _signature
    ) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(PRESALE_TYPEHASH, _minter, _allocation))
        );
        return ECDSA.recover(digest, _signature);
    }

    ////////////////////////////////////////////////
    //               STATE UPDATE                //
    //////////////////////////////////////////////

    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        signerAddress = _signer;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setAccountPermit(
        address _account,
        bool _permit
    ) external onlyOwner {
        permittedAccounts[_account] = _permit;
    }

    function setRoyalty(address _receiver, uint96 _amount) external onlyOwner {
        _setDefaultRoyalty(_receiver, _amount);
    }

    ////////////////////////////////////////////////
    //                 WITHDRAW                  //
    //////////////////////////////////////////////

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Zero balance");

        sendEther(WITHDRAWAL_ADDRESS, address(this).balance);
    }

    function sendEther(address _receiver, uint256 _amount) internal {
        require(address(this).balance >= _amount, "Insufficient balance");

        (bool success, ) = payable(_receiver).call{value: _amount}("");
        require(success, "Transfer failed");
    }

    ////////////////////////////////////////////////
    //                   VIEW                    //
    //////////////////////////////////////////////

    function _isContract(address _address) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 _id
    ) public view override returns (string memory) {
        require(_exists(_id), "Token doesn't exist");

        return string(abi.encodePacked(baseURI, _toString(_id)));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}