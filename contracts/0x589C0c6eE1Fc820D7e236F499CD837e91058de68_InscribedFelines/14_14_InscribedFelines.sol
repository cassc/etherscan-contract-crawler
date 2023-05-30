// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "./ERC721A.sol";

error NoEOA();
error ActivityOff();
error SummonExceedsMaxSupply();
error AlreadyMinted();
error InsufficientPayment();
error NoETH();

contract InscribedFelines is ERC721A, Ownable {
    uint256 private constant MAX_SUPPLY = 1000;
    uint256 private constant PAID_SUMMON_PRICE = 0.029 ether;
    string private baseURI;

    address payable private _receiverOne;
    address payable private _receiverTwo;
    address payable private _receiverThree;
    bool private _activity = true;

    mapping(address => bool) private _isMinted;

    function receiverOne() public view returns (address) {
        return _receiverOne;
    }

    function receiverTwo() public view returns (address) {
        return _receiverTwo;
    }

    function receiverThree() public view returns (address) {
        return _receiverThree;
    }

    function activity() public view returns (bool) {
        return _activity;
    }

    function isMinted(address account) public view returns (bool) {
        return _isMinted[account];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return string(abi.encodePacked(_tokenURI, ".json"));
    }

    function checkUserNfts(address user) external view returns (uint[] memory) {
        uint256[] memory tokenIds = new uint256[](balanceOf(user));
        uint mark;
        for (uint256 i; i < balanceOf(user); i++) {
            for (uint256 j = mark + 1; j < currentIndex; j++) {
                if (ownerOf(j) == user) {
                    tokenIds[i] = j;
                    mark = j;
                    break;
                }
            }
        }
        return (tokenIds);
    }

    event Burned(uint256 tokenId, string accountBTC);

    constructor(
        string memory baseURI_,
        address receiverOne_,
        address receiverTwo_,
        address receiverThree_
    ) ERC721A("InscribedFelines", "FELS", 1, 1000) {
        require(receiverOne_ != address(0), "Receiver one is zero address");
        require(receiverTwo_ != address(0), "Receiver two is zero address");
        require(receiverThree_ != address(0), "Receiver three is zero address");
        _receiverOne = payable(receiverOne_);
        _receiverTwo = payable(receiverTwo_);
        _receiverThree = payable(receiverThree_);

        baseURI = baseURI_;
    }

    function changeActivityState() external onlyOwner returns (bool) {
        _activity = !_activity;
        return true;
    }

    function mint() external payable returns (bool) {
        if (msg.sender != tx.origin) revert NoEOA();
        if (!_activity) revert ActivityOff();
        if (_totalMinted() + 1 > MAX_SUPPLY) revert SummonExceedsMaxSupply();
        if (msg.value < PAID_SUMMON_PRICE) revert InsufficientPayment();
        if (_isMinted[msg.sender]) revert AlreadyMinted();

        _safeMint(msg.sender, 1, true, "");
        _isMinted[msg.sender] = true;
        return true;
    }

    function burn(uint256 tokenId, string memory accountBTC) external returns (bool) {
        _burn(tokenId);
        emit Burned(tokenId, accountBTC);
        return true;
    }

    function setBaseURI(string memory uri) external onlyOwner returns (bool) {
        baseURI = uri;
        return true;
    }

    function withdraw() external onlyOwner returns (bool) {
        if (address(this).balance == 0) revert NoETH();

        uint256 state = (address(this).balance * 3300) / 10000;

        (bool successOne, ) = _receiverOne.call{value: state}("");
        require(successOne, "Call to receiverOne failed");

        (bool successTwo, ) = _receiverTwo.call{value: state}("");
        require(successTwo, "Call to receiverTwo failed");

        (bool successThree, ) = _receiverThree.call{value: address(this).balance}("");
        require(successThree, "Call to receiverThree failed");

        return true;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return baseURI;
    }
}