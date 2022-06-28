//SPDX-License-Identifier: MIT License (MIT)
pragma solidity ^0.8.15;

import "./access/AdminControl.sol";
import "./token/ERC721Optimized/ERC721.sol";
import "./token/ERC721Optimized/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ============ Errors ============

error ExceedsMaxSupply();

contract VVOneAndOnly is ERC721, ERC721Enumerable, ERC2981, AdminControl, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 1;
    string baseURI = "";

    address payable private _paymentAddress;

    // Proxies
    mapping(address => bool) public projectProxy;

    constructor(
        address payable _splitterAddress
    ) ERC721("Vegas Vickie NFT One and Only", "VVONEANDONLY") {

        // For Secondary Royalties
        _paymentAddress = _splitterAddress;
        // Percentage is in basis points
        _setDefaultRoyalty(_splitterAddress, 1000);
    }

    function ownerMint(address _to) public onlyAdmin {
        if(_totalMinted() == MAX_SUPPLY) revert ExceedsMaxSupply();
        _mint(_to, _totalMinted() + 1);
    }

    // ============ Public Functions ============

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    // ============ Admin Functions ============

    function setBaseURI(string calldata _baseURI) public onlyAdmin {
        baseURI = _baseURI;
    }

    function setPaymentAddress(address _newAddress) public onlyAdmin {
        _paymentAddress = payable(_newAddress);
    }

    // ============ ERC2981 Royality Methods ============

    function setDefaultRoyalty(address _royaltyAddress, uint96 _feeNumerator) external onlyAdmin {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    // ============ Withdrawal Methods ============

    function withdraw() external onlyAdmin {
        uint256 balance = address(this).balance;

        Address.sendValue(_paymentAddress, balance);
    }

    // ============ Proxy Functions ============

    function flipProxyState(address proxyAddress) public onlyAdmin {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    // ============ Overrides ========

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AdminControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, id);
    }

    function _mint(address account, uint256 id) internal override(ERC721) {
        super._mint(account, id);
    }

    function _burn(uint256 id) internal override(ERC721) {
        super._burn(id);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _tokenId > 0 && _tokenId <= MAX_SUPPLY,
            "URI requested for invalid token"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tokenId.toString()))
                : baseURI;
    }

    function isApprovedForAll(address _owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        if(projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}