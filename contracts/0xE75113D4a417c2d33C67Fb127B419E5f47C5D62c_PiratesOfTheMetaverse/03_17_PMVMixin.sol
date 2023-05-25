// contracts/PMV.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PMVMixin is Ownable {
    using Strings for uint256;
    using Address for address payable;

    uint256 public constant maxSupply = 10000;
    uint256 public maxPerTransaction = 10;
    uint public salePrice = 0.1 ether;
    uint public presalePrice = 0.077 ether;
    bool public presaleActive = false;
    bool public saleActive = false;
    string private tokenBaseURI;
    string internal notRevealedUri;
    bool private revealed = false;
    bytes32 public root;
    bytes32 public rootMintFree;
    bytes32 public provenanceHash;
    uint256 public offset;
    bool public offsetRequested = false;
    address public multiSigWallet;
    bool public letContractMint = false;
    uint256 public ownerMintBuffer = 200;

    function _tokenURI(uint256 tokenId) public view virtual returns (string memory) {

        if(revealed == false) {
            return notRevealedUri;
        }

        else {
            return string(abi.encodePacked(tokenBaseURI, tokenId.toString()));
        }
    }

    function setPresale(bool _presaleStatus) external onlyOwner {
        presaleActive = _presaleStatus;
    }

    function setSale(bool _saleStatus) external onlyOwner {
        saleActive = _saleStatus;
    }

    function setURIStatus(bool _revealed, string calldata _tokenBaseURI) external onlyOwner {
        require(bytes(_tokenBaseURI).length > 0, "_tokenBaseURI is empty");
        revealed = _revealed;
        tokenBaseURI = _tokenBaseURI;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        require(_root.length > 0, "_root is empty");
        root = _root;
    }

    function setRootMintFree(bytes32 _root) external onlyOwner {
        require(_root.length > 0, "_root is empty");
        rootMintFree = _root;
    }

    function withdraw() external onlyOwner {
        payable(multiSigWallet).sendValue(address(this).balance);
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner {
        require(_maxPerTransaction > 0, "maxPerTransaction should be positive");
        maxPerTransaction = _maxPerTransaction;
    }

    function setPrice(uint _salePrice) external onlyOwner {
        salePrice = _salePrice;
    }

    function setPresalePrice(uint _presalePrice) external onlyOwner {
        presalePrice = _presalePrice;
    }

    function setLetContractMint(bool _letContractMint) external onlyOwner {
        letContractMint = _letContractMint;
    }

    function setOwnerMintBuffer(uint256 _ownerMintBuffer) external onlyOwner {
        ownerMintBuffer = _ownerMintBuffer;
    }
}