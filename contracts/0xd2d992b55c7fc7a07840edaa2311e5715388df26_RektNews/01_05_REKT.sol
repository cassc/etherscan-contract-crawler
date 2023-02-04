// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RektNews is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 6969;
    uint256 public constant PRICE = .022 ether;
    uint256 public constant PRICE_WL = .011 ether;

    bool public isRevealed = false;
    string private baseUrl = "wait till revealed";
    string public unrevealedUrl = "https://ipfs.io/ipfs/QmchV2Jf2eZVxYgx7k9pBUb2dWkS6g5xt4R2cauwtvf7BR";

    bool public isStage1 = true;
    bool public isStage2 = false;
    address[] private whiteList;
    address[] private freeList;

    constructor() ERC721A("RektNews", "REKT") {}

    function mint(uint256 qty) external payable {
        if (isFreelisted(msg.sender)) {
            _mint(msg.sender, qty);
            return;
        }

        if (!isStage1) {
          require(isWhitelisted(msg.sender), "GET REKT! GO MAKE IT TO THE WHITE LIST!");
        } 

        require(qty > 0, "GET REKT! WTF YOU MINTED ZERO?");
        require((totalSupply() + qty) <= MAX_SUPPLY, "GET REKT! REKTS ARE OUT OF STOCK!");
        if (isStage2) {
          require(msg.value >= PRICE * qty, "GET REKT! NOT ENOUGH ETH!");
        } else {
          require(msg.value >= PRICE_WL * qty, "GET REKT! NOT ENOUGH ETH!");
        }

        _mint(msg.sender, qty);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "GET REKT! DAT TOKEN DON'T EXIST!");

        if (!isRevealed) return unrevealedUrl;

        return
            bytes(baseUrl).length > 0
                ? string(abi.encodePacked(baseUrl, _toString(tokenId), ".json"))
                : "";
    }

    function isWhitelisted(address _address) public view returns (bool) {
      for (uint i = 0; i < whiteList.length; i++) {
        if (whiteList[i] == _address) {
            return true;
        }
      }
      return false;
    }

    function isFreelisted(address _address) public view returns (bool) {
      for (uint i = 0; i < freeList.length; i++) {
        if (freeList[i] == _address) {
            return true;
        }
      }
      return false;
    }

    /* OWNERS ZONE. NO TRESPASSING! */
    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function toggleStage1() external onlyOwner {
        isStage1 = !isStage1;
    }

    function toggleStage2() external onlyOwner {
        isStage2 = !isStage2;
    }

    function setBaseUrl(string memory _baseUrl) external onlyOwner {
        baseUrl = _baseUrl;
    }

    function setUnrevealedUrl(string memory _unervealedUrl) external onlyOwner {
        unrevealedUrl = _unervealedUrl;
    }

    function setWhiteList(address[] calldata _whiteList) public onlyOwner {
        delete whiteList;
        whiteList = _whiteList;
    }

    function setFreeList(address[] calldata _freeList) public onlyOwner {
        delete freeList;
        freeList = _freeList;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}