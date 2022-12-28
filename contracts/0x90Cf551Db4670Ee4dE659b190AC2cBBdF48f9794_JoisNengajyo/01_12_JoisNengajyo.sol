//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract JoisNengajyo is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public immutable tokenAmount = 1;

    struct Item {
        bool mintable;
        bool transferable;
        uint256 maxSupply;
        string tokenURI;
        uint256 maxMintPerWallet; // 0 means user can mint how much they want. so no limitation with minting
    }

    string public contractURI;
    mapping(uint256 => Item) public items;
    mapping(uint256 => uint256) public totalSupply;
    event WithDraw(address indexed to, address token);
    event Mint(address indexed minter, uint256 indexed tokenId);
    event MintTo(
        address indexed minter,
        address indexed holder,
        uint256 indexed tokenId
    );
    event NewItem(uint256 indexed id, bool mintable);
    event UpdateItem(uint256 indexed id, bool mintable);
    event BurnItem(uint256 indexed id, address indexed holder);

    constructor() ERC1155("") {}

    function getItems() public view returns (Item[] memory) {
        Item[] memory ItemArray = new Item[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            ItemArray[i] = items[i + 1];
        }
        return ItemArray;
    }

    modifier onlyExistItem(uint256 _tokenId) {
        require(
            _tokenId > 0 && _tokenId <= _tokenIds.current(),
            "Item Not Exists"
        );
        _;
    }

    modifier onlyHolder(address _of, uint256 _tokenId) {
        require(balanceOf(_of, _tokenId) > 0, "Invalid: NOT HOLDER");
        _;
    }

    modifier onlyBelowMaxMintPerWallet(address _of, uint256 _tokenId) {
        require(
            (balanceOf(_of, _tokenId) < items[_tokenId].maxMintPerWallet) ||
                items[_tokenId].maxMintPerWallet == 0,
            "Invalid: EXCEED MAX MINT PER WALLET"
        );
        _;
    }

    modifier notExceedMaxSupply(uint256 _tokenId) {
        require(
            items[_tokenId].maxSupply > totalSupply[_tokenId],
            "Invalid: Exceed Supply"
        );
        _;
    }

    modifier onlyMintable(uint256 _tokenId) {
        require(items[_tokenId].mintable, "Invalid: To mint");
        _;
    }

    function createItem(Item memory _Item) public onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        items[newItemId] = _Item;
        totalSupply[newItemId] = 0;
        emit NewItem(newItemId, _Item.mintable);
    }

    function setContractURI(string memory _contractUri) public onlyOwner {
        contractURI = _contractUri;
    }

    function makeSVGTokenURL(
        string memory title,
        string memory description,
        string memory _svg
    ) private pure returns (string memory) {
        string memory finalSvg = string(abi.encodePacked(_svg));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        title,
                        '", "description": "',
                        description,
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return finalTokenUri;
    }

    function createOnChainItem(
        bool mintable,
        bool transferable,
        uint256 maxSupply,
        uint256 maxMintPerWallet,
        string memory title,
        string memory description,
        string memory _svg
    ) public onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        string memory _uri = makeSVGTokenURL(title, description, _svg);
        items[newItemId] = Item(
            mintable,
            transferable,
            maxSupply,
            _uri,
            maxMintPerWallet
        );
        totalSupply[newItemId] = 0;
        emit NewItem(newItemId, mintable);
    }

    function updateItemAttr(
        uint256 _tokenId,
        bool _mintable,
        string memory _tokenURI
    ) public onlyOwner onlyExistItem(_tokenId) {
        items[_tokenId].mintable = _mintable;
        if (bytes(_tokenURI).length >= 5) {
            items[_tokenId].tokenURI = _tokenURI;
        }
        emit UpdateItem(_tokenId, _mintable);
    }

    function lockMinting(uint256 _tokenId)
        public
        onlyOwner
        onlyExistItem(_tokenId)
    {
        items[_tokenId].mintable = false;
        emit UpdateItem(_tokenId, false);
    }

    function mint(uint256 _tokenId)
        public
        onlyExistItem(_tokenId)
        notExceedMaxSupply(_tokenId)
        onlyBelowMaxMintPerWallet(msg.sender, _tokenId)
        onlyMintable(_tokenId)
    {
        _mint(msg.sender, _tokenId, tokenAmount, "");
        totalSupply[_tokenId] += 1;
        emit Mint(msg.sender, _tokenId);
    }

    function mintTo(address _to, uint256 _tokenId)
        public
        onlyExistItem(_tokenId)
        notExceedMaxSupply(_tokenId)
        onlyBelowMaxMintPerWallet(_to, _tokenId)
        onlyMintable(_tokenId)
    {
        _mint(_to, _tokenId, tokenAmount, "");
        totalSupply[_tokenId] += 1;
        emit MintTo(msg.sender, _to, _tokenId);
    }

    // or use before transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public virtual override onlyExistItem(_tokenId) {
        require(items[_tokenId].transferable, "TRANSFER FORBIDDEN");

        _safeTransferFrom(_from, _to, _tokenId, _amount, _data);
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return items[_tokenId].tokenURI;
    }
}