//SPDX-License-Identifier: Unlicense
pragma solidity >0.7.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BetYourBeansNFT is ERC1155Supply, Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint public idCounter;
    string public baseURI;
    BetYourBeansNFTSale public sale;
    mapping(uint => uint) public tokenValues;

    modifier onlyMinter {
        require (hasRole(MINTER_ROLE, msg.sender) || msg.sender == owner(), "!minter");
        _;
    }

    constructor() ERC1155("https://storageapi2.fleek.co/{id}") {
        baseURI = "https://storageapi2.fleek.co/";
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, msg.sender);

        sale = new BetYourBeansNFTSale(address(this));

        _mint(address(sale), 1, 520, ""); sale.supply(1, 520);
        _mint(address(sale), 2, 220, ""); sale.supply(2, 220);
        _mint(address(sale), 3, 116, ""); sale.supply(3, 116);
        _mint(address(sale), 4, 24, ""); sale.supply(4, 24);

        idCounter = 4;

        sale.transferOwnership(msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMinter(address _account, bool _flag) public onlyOwner {
        _flag ? grantRole(MINTER_ROLE, _account) : revokeRole(MINTER_ROLE, _account);
    }

    function setSale(address _sale) external onlyOwner {
        sale = BetYourBeansNFTSale(payable(_sale));
    }

    function uri(uint _id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_id), ".json"));
    }

    function mint(uint _amount) public onlyMinter {
        require (_amount > 0, "!amount");

        idCounter++;
        _mint(address(sale), idCounter, _amount, "");
        sale.supply(idCounter, _amount);
    }

    function extraMint(uint _id, uint _amount) public onlyMinter {
        require (_amount > 0, "!amount");

        _mint(address(sale), _id, _amount, "");
        sale.supply(_id, _amount);
    }

    function setTokenValues(uint _id, uint _value) external onlyMinter {
        require (exists(_id) == true, "!existing");

        tokenValues[_id] = _value;
    }

    function getAllTokens(address _account) public view returns (uint[] memory, uint[] memory) {
        uint count = 0;
        for (uint i = 0; i <= idCounter; i++) {
            if (balanceOf(_account, i) > 0)  count++;
        }

        uint[] memory tokens = new uint[](count);
        uint[] memory balances = new uint[](count);
        uint counter = 0;
        for (uint i = 0; i <= idCounter; i++) {
            uint balance = balanceOf(_account, i);
            if (balance > 0) {
                tokens[counter] = i;
                balances[counter] = balance;
                counter++;
            }
        }

        return (tokens, balances);
    }
}

contract BetYourBeansNFTSale is Ownable, Pausable, ERC1155Holder, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    enum Type { NONE, CHARACTER, BACKGROUND, ACCESSORY, SKIN, SPECIAL }

    bytes32 public constant SUPPLIER_ROLE = keccak256("SUPPLIER_ROLE");

    IERC1155 public bybNFT;

    uint public price;
    uint public devPercent = 1000;

    address public ownerWallet = 0x89352214a56bA80547A2842bbE21AEdD315722Ca;
    uint public constant MAX_FEE = 10000;

    EnumerableSet.UintSet nfts;
    mapping (uint => uint) public supplies;
    uint public totalSupply;
    uint nonce;
    uint public onetimeLimit = 1;

    modifier onlySupplier {
        require (hasRole(SUPPLIER_ROLE, msg.sender) || msg.sender == owner(), "!supplier");
        _;
    }

    constructor(address _bybNFT) {
        bybNFT = IERC1155(_bybNFT);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(SUPPLIER_ROLE, msg.sender);
        grantRole(SUPPLIER_ROLE, _bybNFT);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getAllTokens() public view returns (uint[] memory, uint[] memory) {
        uint[] memory tokens = new uint[](nfts.length());
        uint[] memory counts = new uint[](nfts.length());

        for (uint i = 0; i < nfts.length(); i++) {
            tokens[i] = nfts.at(i);
            counts[i] = supplies[nfts.at(i)];
        }

        return (tokens, counts);
    }

    function supply(uint _id, uint _amount) external onlySupplier {
        require (_amount > 0, "invalid amount");

        if (!nfts.contains(_id)) nfts.add(_id);

        // bybNFT.safeTransferFrom(msg.sender, address(this), _id, _amount, "");

        totalSupply += _amount;
        supplies[_id] += _amount;
    }

    function purchase(uint _amount) external payable returns (uint[] memory) {
        require (msg.value > 0, "!budget");
        return airdrop(_amount);
    }
    
    function airdrop(uint _amount) internal nonReentrant whenNotPaused returns (uint[] memory) {
        require (_amount > 0 && _amount <= onetimeLimit, "invalid amount");
        require (_amount <= totalSupply, "exceeded amount");
        require (msg.value >= price.mul(_amount), "!enough payment");

        if (price > 0) {
            payable(ownerWallet).call{
                value: msg.value,
                gas: 30000
            }("");
        }

        if (bybNFT.isApprovedForAll(address(this), msg.sender) == false) {
            bybNFT.setApprovalForAll(msg.sender, true);
        }

        uint[] memory ids = new uint[](_amount);
        for (uint i = 0; i < _amount; i++) {
            ids[i] = _airdrop(msg.sender);
        }

        return ids;
    }

    function _airdrop(address _to) internal returns (uint) {
        uint randomNum = _random(totalSupply);

        uint id = 0;
        for (uint i = 0; i < nfts.length(); i++) {
            id = nfts.at(i);
            if (randomNum < supplies[id]) break;
            randomNum -= supplies[id];
        }

        bybNFT.safeTransferFrom(address(this), _to, id, 1, "");

        totalSupply--;
        supplies[id]--;
        if (supplies[id] == 0) nfts.remove(id);

        return id;
    }

    function _random(uint _max) internal returns (uint) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nonce++))) % _max;
    }

    function withdraw(uint _id, uint _amount) external onlySupplier {
        require (_amount > 0, "invalid amount");
        require (nfts.contains(_id), "!existing");
        require (_amount <= supplies[_id], "exceeded amount");

        if (bybNFT.isApprovedForAll(address(this), msg.sender) == false) {
            bybNFT.setApprovalForAll(msg.sender, true);
        }

        bybNFT.safeTransferFrom(address(this), msg.sender, _id, _amount, "");

        totalSupply -= _amount;
        supplies[_id] -= _amount;
        if (supplies[_id] == 0) nfts.remove(_id);
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setOwner(address _owner) external onlyOwner {
        ownerWallet = _owner;
    }

    function setSupplier(address _account, bool _flag) external onlyOwner {
        _flag ? grantRole(SUPPLIER_ROLE, _account) : revokeRole(SUPPLIER_ROLE, _account);
    }

    function setDevPercent(uint _percent) external onlyOwner {
        require (_percent <= MAX_FEE.div(2), "invalid value");
        devPercent = _percent;
    }

    function setOnetimeLimit(uint _limit) external onlyOwner {
        require (_limit > 0, "invlaid limit");
        onetimeLimit = _limit;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    receive() external payable {
        require (msg.value >= price, "!enough payment");
        airdrop(msg.value.div(price));
    }
}