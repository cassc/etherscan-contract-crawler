// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Reddlt is Ownable, ERC2981, ERC721AQueryable, ReentrancyGuard {
    string private _baseTokenURI;

    uint256 public MAX_SUPPLY = 7777;
    uint256 public MAX_MINT = 10;
    uint256 public PRICE = 0.003 ether;
    bool public isSaleActive = false;

    mapping(address => bool) public transferBlock;

    constructor() ERC721A("Reddlt", "Reddlt") {
        transferBlock[0xF849de01B080aDC3A814FaBE1E2087475cF2E354] = true;
    }

    function mint(uint256 _amount) external payable nonReentrant {
        require(isSaleActive, "Sale is not active");

        require(tx.origin == msg.sender, "No contracts");

        require(
            _numberMinted(msg.sender) + _amount <= MAX_MINT,
            "Exceeds max amount per wallet"
        );

        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );

        if (_numberMinted(msg.sender) == 0) {
            require(
                msg.value >= PRICE * (_amount - 1),
                "Insufficient payment for mint"
            );
        } else {
            require(
                msg.value >= PRICE * _amount,
                "Insufficient payment for mint"
            );
        }
        _mint(msg.sender, _amount);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        require(
            !transferBlock[msg.sender],
            " You are not allowed to transfer tokens"
        );
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function setMinPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setBlockTransfer(address _address, bool _block)
        external
        onlyOwner
    {
        transferBlock[_address] = _block;
    }

    function setIsSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function withdraw(address _reciver) external onlyOwner {
        payable(_reciver).transfer(address(this).balance);
    }

    function numberMinted(address _address) external view returns (uint256) {
        return _numberMinted(_address);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}