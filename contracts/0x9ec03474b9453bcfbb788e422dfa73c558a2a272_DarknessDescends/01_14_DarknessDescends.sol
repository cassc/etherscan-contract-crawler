// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import   "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

error InsufficientEth();
error SoldOut();
error SlowDown();
error LightStillBurns();
contract DarknessDescends is
    ERC721AQueryable,
    ERC721ABurnable,
    OperatorFilterer,
    Ownable,
    ERC2981
{
    bool public operatorFilteringEnabled;
    string public baseURI = "ipfs://QmUm5cRqUvDGfhRREY8DNNUCUUsshk1or7FUgAZw3uvaS9/";
    string public uriExtension  = ".json";
    uint constant private MAX_SUPPLY = 6666;
    uint public maxFreeMints = 1;
    uint public maxTotalMints = 11;
    uint public price = .0033 ether;
    
    uint private _saleStatus;
    uint private constant DARKNESS_ON = 1;

    constructor() ERC721A("Darkness Descends", "DD") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _mint(msg.sender,66);
        _setDefaultRoyalty(msg.sender, 666);
    }
    function _getPrice(uint numMints,uint numUserHasMinted) internal view returns(uint) {
        if(numUserHasMinted > maxFreeMints) {
            return price * (numMints);
        }
        uint numFreeMints = maxFreeMints - numUserHasMinted;
        return price * (numMints - numFreeMints);
    }

    function getPriceFrontend(address user, uint numMints) external view returns(uint) {
        return _getPrice(numMints,_numberMinted(user));
    }

    function mint(uint amount) external payable {
        if(_saleStatus != DARKNESS_ON) _revert(LightStillBurns.selector);
        uint totalMinted = _totalMinted();
        uint numUserMints = _numberMinted(msg.sender);
        if(msg.value < _getPrice(amount,numUserMints)) 
        _revert(InsufficientEth.selector);
        if(totalMinted+amount > MAX_SUPPLY)
        _revert(SoldOut.selector);
        if(numUserMints + amount > maxTotalMints) _revert(SlowDown.selector);
        _mint(msg.sender,amount);

        
    }

    function setDarknessStatus(uint status) public onlyOwner {
        _saleStatus = status;
    }

    function saleStatus() public view returns(uint) {
        if(totalSupply() == MAX_SUPPLY) return 2;
        return _saleStatus;
        
    }
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
    function setBaseExtension(string memory newExtension) public onlyOwner {
        uriExtension = newExtension;
    }
    function tokenURI(uint256 tokenId) public view override(IERC721A,ERC721A) returns (string memory) {
        return string(abi.encodePacked(baseURI,_toString(tokenId),uriExtension));
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }
    
    function withdraw() public onlyOwner {
      (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
      require(os, "Withdraw failed");
    }
    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}