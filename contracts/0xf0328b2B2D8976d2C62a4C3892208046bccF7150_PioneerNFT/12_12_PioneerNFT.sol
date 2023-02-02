// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DefaultOperatorFiltererUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ERC721AUpgradeable.sol";
import "./ITomi.sol";


contract PioneerNFT is Initializable, ERC721AUpgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    using SafeMathUpgradeable for uint256;
    
    address public saleContract;
    uint256 public epochInitalEnd;
    string public baseUri;
    ITomi public tomi;

    uint256 maxPurchaseInitial;

    event baseUriChanged(string _baseURI);

    modifier onlySale {
        require(_msgSender() == saleContract , "Not Authorized");
        _;
    }

    function initialize() initializerERC721A initializer public {
        __ERC721A_init("tomi Pioneers", "TPNR");
        __Ownable_init();
    }

    function setInitialization() public onlyOwner {
        __DefaultOperatorFilterer_init();
    }

    receive() external payable {
        revert();
    }

    function hasAuctionStarted() public view returns (bool) {
        if (
            totalSupply() > maxPurchaseInitial ||
            block.timestamp > epochInitalEnd
        ) {
            return true;
        }
        return false;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseUri = baseURI_;
        emit baseUriChanged(baseURI_);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}