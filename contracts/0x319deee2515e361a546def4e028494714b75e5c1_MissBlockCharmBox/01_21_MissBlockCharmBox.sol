//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interface/IMissBlockCharmBox.sol";

contract MissBlockCharmBox is ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, IMissBlockCharmBox {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier onlyNotPaused() {
        require(!paused, "Paused");
        _;
    }
    
    mapping(uint256 => bool) public blacklist;

    bool[] private _boxes; // contain box is opened
    mapping(address => Seller) _sellers;
    bool public paused;
    string private _uri;
    bool public isAllowOpenBox;

    function initialize(string memory baseURI) public initializer {
        __ERC721_init("MissBlockCharmBox", "MBCB");
        __Ownable_init();
        _uri = baseURI;
        isAllowOpenBox = false;
    }

    function setAllowOpenBox(bool _isAllowOpenBox) external onlyOwner {
        isAllowOpenBox = _isAllowOpenBox;
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _uri = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setBlacklistTokenId(uint256 tokenId, bool isBlacklist) external onlyOwner {
        blacklist[tokenId] = isBlacklist;
    }

    function setSeller(address sellerAddress, uint256 maxSupply) external onlyOwner {
        require(_sellers[sellerAddress].minted <= maxSupply);
        _sellers[sellerAddress].maxSupply = maxSupply;
    }

    function _createMBCBox(address owner) private returns (uint256 boxId) {
        _boxes.push(false);
        boxId = _boxes.length.sub(1);
        emit BoxCreated(boxId, owner);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        require(!paused, "paused");
        require(!blacklist[tokenId], "blacklisted");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function mint(uint256 amount, address buyer)
        external
        override
        payable
        onlyNotPaused
    {
        Seller memory seller = _sellers[msg.sender];
        require(seller.minted + amount <= seller.maxSupply, "exceeded max supply");

        for (uint256 i = 0; i < amount; i++) {
            uint256 boxId = _createMBCBox(buyer);
            _safeMint(buyer, boxId);
        }
    }

    function open(uint256[] memory boxIds) external onlyNotPaused {
        require(isAllowOpenBox, "cannot open this time");
        for (uint256 i = 0; i < boxIds.length; i++) {
            uint256 id = boxIds[i];
            require(!_boxes[id], "Box opened");
            require(!blacklist[id], "Box blacklisted");
            require(ownerOf(id) == msg.sender, "invalid owner");
            _boxes[id] = true;
            emit BoxOpened(id);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function withdrawToken(
        IERC20Upgradeable token,
        uint256 amount,
        address to
    ) external onlyOwner {
        token.safeTransfer(to, amount);
        emit TokenWithdrawn(address(token), amount, to);
    }

    function withdrawNativeToken(uint256 amount) external onlyOwner {
       (bool isTransferToOwner, ) = owner().call{value: amount}("");
        require(isTransferToOwner);
    }
}