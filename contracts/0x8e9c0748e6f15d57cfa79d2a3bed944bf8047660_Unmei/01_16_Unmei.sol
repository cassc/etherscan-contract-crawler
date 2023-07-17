// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error InsufficientEth();
error SoldOut();
error MaxMints();
error SaleNotActive();
error InvalidSignature();

contract Unmei is ERC721AQueryable, OperatorFilterer, Ownable, ERC2981 {
    using ECDSA for bytes32;

    uint256 constant public MAX_SUPPLY = 3333;
    uint256 public maxMintsPublic = 10;
    uint256 public price = 0.004 ether;
    uint256 public whitelistPrice = .004 ether;
    bool public operatorFilteringEnabled;
    address public signer = 0xf7D6bAd4f9685d4172CF5e9479fe8EFdC5D842e2;
    string private __baseURI;
    string private _baseExtension;
    string private _unrevealedURI = "ipfs://QmWWJQRSvfFzKqjE9To5JjwX1Q7MaVTwNP1dB6uu8nyXLq";
    bool public whitelistOn;
    bool public publicOn;
    bool public revealed;



    constructor() ERC721A("Unmei", "UNM") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(tx.origin, 500);
        _mintERC2309(tx.origin, 20);
       
    }

    function mint(uint256 amount) external payable {
        if (!publicOn) _revert(SaleNotActive.selector);
        if(_numberMinted(msg.sender)> maxMintsPublic) _revert(MaxMints.selector);
        if (msg.value < price * amount) {
            _revert(InsufficientEth.selector);
        }
        if(_totalMinted() + amount > MAX_SUPPLY) _revert(SoldOut.selector);
        _mint(msg.sender, amount);
    }
    

    function whitelistMint(uint256 amount, uint256 max, bytes calldata signature) external payable {
        if(!whitelistOn) _revert(SaleNotActive.selector);
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, max, "WL"));
        uint _numAlreadyMinted = _numberMinted(msg.sender);
        if(msg.value < getWhitelistPrice(amount,_numAlreadyMinted)) _revert(InsufficientEth.selector);
        if(_totalMinted() + amount > MAX_SUPPLY) _revert(SoldOut.selector);
        if (hash.toEthSignedMessageHash().recover(signature) != signer) _revert(InvalidSignature.selector);
        if(_numAlreadyMinted + amount > max) _revert(MaxMints.selector);
        _mint(msg.sender, amount);
      
        
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function getWhitelistPrice(uint amount,uint numAlreadyMinted) public view returns(uint) {
        if(numAlreadyMinted == 0) {
            return (amount-1) * whitelistPrice;
        }
        return amount * whitelistPrice;
    }
    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
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

    function setPrice(uint256 _price) public onlyOwner {
        assembly {
            sstore(price.slot, _price)
        }
    }

    function setPublicStatus(bool _publicOn) public onlyOwner {
        publicOn = _publicOn;
    }

    function setWhitelistStatus(bool _whitelistOn) public onlyOwner {
        whitelistOn = _whitelistOn;
    }
    function setMaxPublicMints(uint256 _maxMintsPublic) public onlyOwner {
        assembly {
            sstore(maxMintsPublic.slot, _maxMintsPublic)
        }
    }



  
    function withdraw() public onlyOwner {
        assembly {
            if iszero(call(gas(), 
            caller(), 
            balance(address()), 
            0x0, 
            0x0, 
            0x0, 
            0x0)) 
            { revert(0x0, 0x0) }
        }
    }

  

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        if(!revealed) {
            return _unrevealedURI;
        }
        return string(abi.encodePacked(__baseURI, _toString(tokenId), _baseExtension));
    }

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        __baseURI = baseURI;
    }



    function setBaseExtension(string memory baseExtension) public onlyOwner {
        _baseExtension = baseExtension;
    }

    function baseURI() public view returns (string memory) {
        return __baseURI;
    }   

    function _revert(bytes4 selector) internal pure {
        assembly {
            mstore(0x0, selector)
            revert(0x0, 0x4)
        }
    }

    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setUnrevealedURI(string memory __unrevealedURI) public onlyOwner {
        _unrevealedURI = __unrevealedURI;
    }
   

}