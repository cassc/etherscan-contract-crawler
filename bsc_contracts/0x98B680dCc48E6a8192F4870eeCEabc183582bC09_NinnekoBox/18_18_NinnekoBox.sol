// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract NinnekoBox is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringsUpgradeable for uint256;

    uint256 public maxSupply;

    uint256 public constant BUY_BY_POINT = 1;

    uint256[] public pricePointPerBox; //  0: mata , 1: catbox
    uint256[] public totalBoxSwapPointToBox; //  0: mata , 1; catbox

    uint256[] public maxBoxBuyByPointPerUser;
    mapping(address => uint256) public addressBoughtBoxMataPoint;
    mapping(address => uint256) public addressBoughtBoxCotonPoint;

    string public baseURI;

    IERC20Upgradeable public tokenPoint;

    mapping(address => bool) public addressCanTransferOrReceiveToken;

    TypeBox[] public typeBoxs; // array type box
    struct TypeBox {
        uint256 typeBuy;
        uint256 typeBox;
    }

    bool public allowTransfer;
    mapping(address => bool) public operators;

    event NonFungibleTokenRecovery(address indexed token, uint256 tokenId);
    event TokenRecovery(address indexed token, uint256 amount);
    event MintBox(uint256 typeBuy, uint256 typeBox);
    event SwapPoint2Box(address indexed addr, uint256 _typeBox, uint256 _amount);

    function initialize(address _addPoint) public initializer {
        __ERC721Enumerable_init();
        __Ownable_init_unchained();
        __Pausable_init();
        __ERC721_init("Ninneko Box", "NEKO_BOX");

        maxSupply = 20000;
        addressCanTransferOrReceiveToken[address(0)] = true;
        tokenPoint = IERC20Upgradeable(_addPoint);
        allowTransfer = false;
        maxBoxBuyByPointPerUser = [uint256(20), 20];
        totalBoxSwapPointToBox = [uint256(10000), 10000];
        pricePointPerBox = [50 * 10**18, 600 * 10**18];
    }

    modifier notInBlacklist(uint256 _tokenId) {
        require(!isBlacklisted(_tokenId), "blacklisted");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender] || msg.sender == owner(), "Not the operator or owner");
        _;
    }

    function addOperator(address _operator) public onlyOwner {
        operators[_operator] = true;
    }

    function removeOperator(address _operator) external onlyOwner {
        operators[_operator] = false;
    }

    function isBlacklisted(uint256 _tokenId) public pure returns (bool) {
        return 7331 <= _tokenId && _tokenId <= 9940;
    }

    function gift(
        address _to,
        uint256 _typeBox,
        uint256 _id
    ) external onlyOperator {
        _mintBox(_to, _typeBox, _id);
    }

    function _mintBatchToAddress(
        address _to,
        uint256 _typeBuy,
        uint256[] memory _listTypeBoxs
    ) external onlyOperator {
        for (uint256 i = 0; i < _listTypeBoxs.length; i++) {
            _mintBox(_to, _typeBuy, _listTypeBoxs[i]);
        }
    }

    function _mintBox(
        address _to,
        uint256 _typeBuy,
        uint256 _typeBox
    ) private {
        require(totalSupply() < maxSupply, "Total supply reached");
        uint256 tokenId = totalSupply();
        _mint(_to, tokenId);
        typeBoxs.push(TypeBox(_typeBuy, _typeBox));
        emit MintBox(_typeBuy, _typeBox);
    }

    function getTypeBox(uint256 _tokenId) public view notInBlacklist(_tokenId) returns (TypeBox memory) {
        return typeBoxs[_tokenId];
    }

    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOperator {
        IERC721Upgradeable(_token).transferFrom(address(this), address(msg.sender), _tokenId);

        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    function recoverToken(address _token) external onlyOperator {
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20Upgradeable(_token).safeTransfer(address(msg.sender), balance);

        emit TokenRecovery(_token, balance);
    }

    function setBaseURI(string memory _uri) external onlyOperator {
        baseURI = _uri;
    }

    function setMaxBoxBuyByPointPerUser(uint256[] memory _maxBuy) external onlyOperator {
        maxBoxBuyByPointPerUser = _maxBuy;
    }

    function setAddressTransferOrReceive(address _add, bool _isTransfer) external onlyOperator {
        addressCanTransferOrReceiveToken[_add] = _isTransfer;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOperator {
        maxSupply = _maxSupply;
    }

    function setAllowTransfer(bool _allow) external onlyOperator {
        allowTransfer = _allow;
    }

    function setPause() external onlyOperator {
        _pause();
    }

    function unsetPause() external onlyOperator {
        _unpause();
    }

    function getTokensInfoOfAddress(address user) external view returns (uint256[] memory, TypeBox[] memory) {
        uint256 length = balanceOf(user);
        uint256 count = balanceNoBlacklisted(user);
        TypeBox[] memory types = new TypeBox[](count);
        uint256[] memory values = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            if (isBlacklisted(tokenId)) {
                continue;
            }
            values[j] = tokenId;
            types[j] = typeBoxs[tokenId];
            j++;
        }

        return (values, types);
    }

    function tokensOfOwnerBySize(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > balanceOf(user) - cursor) {
            length = balanceOf(user) - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = tokenOfOwnerByIndex(user, cursor + i);
        }

        return (values, cursor + length);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setPricePointBox(uint256[] memory _price) external onlyOperator {
        pricePointPerBox = _price;
    }

    function setTokenPoint(address _add) external onlyOperator {
        tokenPoint = IERC20Upgradeable(_add);
    }

    function setTotalBoxSwapByPoint(uint256[] memory _total) external onlyOperator {
        totalBoxSwapPointToBox = _total;
    }

    function SwapPointToBox(uint256 _typeBox, uint256 _amount) public whenNotPaused nonReentrant {
        uint256 price1 = pricePointPerBox[_typeBox];
        require(price1 > 0, "invalid price1");
        mapping(address => uint256) storage map = addressBoughtBoxMataPoint;
        if (_typeBox == 1) {
            map = addressBoughtBoxCotonPoint;
        }
        require(map[msg.sender] + _amount <= maxBoxBuyByPointPerUser[_typeBox], "out of quota");
        require(totalBoxSwapPointToBox[_typeBox] >= _amount, "amount error");
        uint256 allowancePoint = tokenPoint.allowance(msg.sender, address(this));

        uint256 price = price1 * _amount;
        require(allowancePoint >= price, "Check the token Point allowance");
        map[msg.sender] = map[msg.sender] + _amount;
        tokenPoint.transferFrom(msg.sender, owner(), price);
        for (uint256 i = 0; i < _amount; i++) {
            _mintBox(msg.sender, BUY_BY_POINT, _typeBox);
        }

        totalBoxSwapPointToBox[_typeBox] = totalBoxSwapPointToBox[_typeBox] - _amount;
        emit SwapPoint2Box(msg.sender, _typeBox, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(addressCanTransferOrReceiveToken[from] || addressCanTransferOrReceiveToken[to] || allowTransfer, "Your address for sending or receiving tokens is invalid");
    }

    function balanceNoBlacklisted(address addr) internal view returns (uint256 count) {
        uint256 length = balanceOf(addr);
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(addr, i);
            if (!isBlacklisted(tokenId)) {
                count++;
            }
        }
    }
}