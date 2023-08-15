// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Store is ERC1155Supply, AccessControl, ReentrancyGuard {
    event StartItemSale(Item);
    event StopItemSale(Item);
    event ItemCreated(Item);

    struct Item {
        uint256 id;
        uint256 maxSupply;
        uint256 unitPrice;
        uint256 maxPerWallet;
        bool active;
        bool transfersEnabled;
    }

    Item[] private items;
    bool public onChainChecks = true;
    uint256 private itemId = 0;
    uint256 constant MINIMUM_PVNK_BALANCE = 1;
    string public contractURI = "http://api.store.io/contract";
    mapping(address => uint256) private nonces;

    address public beneficiary;
    address public operator = 0xa0274B3f6D61Ba4188Af7D938666Cf4b048ceFFA;
    address public defaultAdmin = 0xAE2573d714D4df7DB925776aCF90065BBc12531A;
    ERC20 private Ammolite = ERC20(0xBcB6112292a9EE9C9cA876E6EAB0FeE7622445F1);
    ERC721 private Skvllpvnkz =
        ERC721(0xB28a4FdE7B6c3Eb0C914d7b4d3ddb4544c3bcbd6);

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    modifier verifyOrder(uint256 _itemId, bytes memory _signature) {
        require(
            operator ==
                getSignerFromMessage(
                    operator,
                    msg.sender,
                    _itemId,
                    nonces[msg.sender],
                    _signature
                ),
            "Invalid request"
        );
        _;
    }

    constructor() ERC1155("http://api.store.io/getItem?id=") {
        beneficiary = address(this);
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _setupRole(CREATOR_ROLE, defaultAdmin);
    }

    function createItem(
        uint256 _maxSupply,
        uint256 _unitPrice,
        uint256 _maxPerWallet
    ) public onlyRole(CREATOR_ROLE) {
        items.push(
            Item(itemId, _maxSupply, _unitPrice, _maxPerWallet, false, false)
        );
        emit ItemCreated(items[itemId]);
        itemId++;
    }

    function updatePrice(uint256 id, uint256 _unitPrice)
        external
        onlyRole(CREATOR_ROLE)
    {
        items[id].unitPrice = _unitPrice;
    }

    function updateMaxPerWallet(uint256 id, uint256 _maxPerWallet)
        external
        onlyRole(CREATOR_ROLE)
    {
        items[id].maxPerWallet = _maxPerWallet;
    }

    function updateMaxSupply(uint256 id, uint256 _maxSupply)
        external
        onlyRole(CREATOR_ROLE)
    {
        items[id].maxSupply = _maxSupply;
    }

    function toggleItemSale(uint256 id) external onlyRole(CREATOR_ROLE) {
        items[id].active = !items[id].active;
        if (items[id].active) emit StartItemSale(items[id]);
        else emit StopItemSale(items[id]);
    }

    function toggleTransfers(uint256 id) external onlyRole(CREATOR_ROLE) {
        items[id].transfersEnabled = !items[id].transfersEnabled;
    }

    function getItems() external view returns (Item[] memory) {
        Item[] memory storeItems = new Item[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            storeItems[i] = Item(
                i,
                items[i].maxSupply,
                items[i].unitPrice,
                items[i].maxPerWallet,
                items[i].active,
                items[i].transfersEnabled
            );
        }
        return items;
    }

    function _beforeTokenTransfer(
        address optr,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(optr, from, to, ids, amounts, data); // Call parent hook
        for (uint256 id = 0; id < ids.length; id++) {
            if (from != address(0) && to != address(0))
                require(items[id].transfersEnabled, "Transfers are disabled");
        }
    }

    function buyItem(uint256 id, bytes memory _signature)
        external
        verifyOrder(id, _signature)
        nonReentrant
    {
        if (onChainChecks) {
            require(items[id].active, "Item is not on sale");
            require(
                totalSupply(id) + 1 <= items[id].maxSupply,
                "Item has reached max supply"
            );
            require(
                balanceOf(msg.sender, id) < items[id].maxPerWallet,
                "You already own enough"
            );
            require(
                Ammolite.balanceOf(msg.sender) >= items[id].unitPrice,
                "Not enough Ammo"
            );
            require(
                Skvllpvnkz.balanceOf(msg.sender) >= MINIMUM_PVNK_BALANCE,
                "You must be a Skvllpvnkz owner"
            );
        }
        _buyItem(id);
    }

    function _buyItem(uint256 _id) internal {
        nonces[msg.sender]++;
        Ammolite.transferFrom(msg.sender, beneficiary, items[_id].unitPrice);
        _mint(msg.sender, _id, 1, "");
    }

    function getNonce(address wallet) external view returns (uint256) {
        return nonces[wallet];
    }

    function remainingSupply(uint256 id) external view returns (uint256) {
        return items[id].maxSupply - totalSupply(id);
    }

    function setAmmoliteContract(address _ammoContract)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Ammolite = ERC20(_ammoContract);
    }

    function setSkvllpvnkzContract(address _skvllpvnkzContract)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Skvllpvnkz = ERC721(_skvllpvnkzContract);
    }

    function setBeneficiary(address _beneficiary)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        beneficiary = _beneficiary;
    }

    function setOperator(address _operator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        operator = _operator;
    }

    function toggleOnChainChecks() external onlyRole(DEFAULT_ADMIN_ROLE) {
        onChainChecks = !onChainChecks;
    }

    function setContractURI(string memory _contractURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contractURI = _contractURI;
    }

    function setURI(string memory newUri) external {
        super._setURI(newUri);
    }

    function getSignerFromMessage(
        address _operator,
        address _user,
        uint256 _itemId,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 _ethMessageHash = getEthMessageHash(
            getMessageHash(_operator, _user, _itemId, _nonce)
        );
        (bytes32 r, bytes32 s, uint8 v) = _split(_signature);
        return ecrecover(_ethMessageHash, v, r, s);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    super.uri(_id),
                    Strings.toString(items[_id].id)
                )
            );
    }

    function withdrawAmmolite() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Ammolite.transfer(msg.sender, Ammolite.balanceOf(address(this)));
    }

    function getMessageHash(
        address _operator,
        address _user,
        uint256 _itemId,
        uint256 _nonce
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(_operator, _user, address(this), _itemId, _nonce)
            );
    }

    function getEthMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function _split(bytes memory _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}