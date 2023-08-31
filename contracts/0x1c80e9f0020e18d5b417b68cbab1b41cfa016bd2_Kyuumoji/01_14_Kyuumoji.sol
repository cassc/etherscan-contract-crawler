/**
SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Kyuumoji is
    ERC721A,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    enum SaleState {
        Paused,
        Public
    }

    modifier onlyEOA() {
        require(!_isContract(msg.sender), "Contract is not allowed");
        require(msg.sender == tx.origin, "Proxy is not allowed");
        _;
    }

    ////////////////////////////////////////////////
    //                  STATE                    //
    //////////////////////////////////////////////

    uint256 public constant PUBLIC_SALE_MAX_TX = 3;
    uint256 public constant PUBLIC_SALE_PRICE = 0.0069 ether;
    uint256 public constant MAX_SUPPLY = 999;
    address private constant WITHDRAWAL_ADDRESS =
        0x3c67798Ed91BbFE187C668e3A478e9A8de2C6Ce9;

    SaleState public saleState;
    string public baseURI;

    mapping(address => bool) public permittedAccounts;

    constructor(string memory _baseURI) ERC721A("Kyuumoji", "KYUUMOJI") {
        baseURI = _baseURI;
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

    function gift(address[] calldata _to, uint256[] calldata _amount) external {
        require(
            msg.sender == owner() || permittedAccounts[msg.sender],
            "Not permitted account"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            require(
                totalSupply() + _amount[i] <= MAX_SUPPLY,
                "Maximum supply exceeded"
            );
            _mint(_to[i], _amount[i]);
        }
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

    function burn(uint256 _tokenId) external {
        require(permittedAccounts[msg.sender], "Not permitted account");
        _burn(_tokenId, true);
    }

    ////////////////////////////////////////////////
    //               STATE UPDATE                //
    //////////////////////////////////////////////

    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
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