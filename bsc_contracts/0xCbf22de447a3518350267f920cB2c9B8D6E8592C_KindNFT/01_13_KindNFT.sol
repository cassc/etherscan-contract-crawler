//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "token/extensions/ERC721Enumerable.sol";
import "access/Ownable.sol";

contract KindNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public cost            = 1.74 ether;    // $500
    uint256 public presaleCost     = 0.174 ether;   // $50
    uint256 public privateSaleCost = 0.000174 ether; // $0.05
    uint256 public maxSupply       = 30;

    string private baseURI;
    string private baseExtension  = ".json";

    // Счетчик выпущенных токенов
    uint256 supplyCnt = 1;

    // Проданы ли все nft 
    bool saleFinished = false;

    // Ограничение mint на 1 адрес
    uint256 private mintLim = 5;

    // Общее количество выпущенных токенов
    mapping(address => uint256) private mintsCnt;

    // Пресейл
    mapping(address => bool) private whitelist;
    mapping(address => uint256) private presaleMintsCnt;
    uint256 private whitelistSize = 0;
    uint256 private presaleMintLim = 3;

    // Приватная продажа
    mapping(address => bool) private privWhitelist;
    mapping(address => uint256) private privSaleMintsCnt;
    uint256 private privWhitelistSize = 0;
    uint256 private privSaleMintLim = 2;

    // В Конструктор при деплое нужно передать
    // название коллекции, сокращенное название
    // и ссылку на репозиторий с картинками

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    // Ссылка на репозиторий с картинками

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Выпуск

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            if (whitelist[_to] != true && privWhitelist[_to] != true) {
                // не пресейл и не приватная продажа
                require(msg.value >= cost * _mintAmount);
                // mint не более <mintLim> токенов на адрес
                require(mintsCnt[_to] < mintLim);
                mintsCnt[_to]++;
            } else if (whitelist[_to] == true && privWhitelist[_to] != true) {
                // пресейл
                require(msg.value >= presaleCost * _mintAmount);
                // mint не более <presaleMintLim> токенов на адрес
                require(presaleMintsCnt[_to] < presaleMintLim);
                presaleMintsCnt[_to]++;
            } else if (whitelist[_to] != true && privWhitelist[_to] == true) {
                // приватная продажа
                require(msg.value >= privateSaleCost * _mintAmount);
                // mint не более <privSaleMintLim> токенов на адрес
                require(privSaleMintsCnt[_to] < privSaleMintLim);
                privSaleMintsCnt[_to]++;
            } else {
                // не пресейл и не приватная продажа
                require(msg.value >= cost * _mintAmount);
                // mint не более <mintLim> токенов на адрес
                require(mintsCnt[_to] < mintLim);
            }
        
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
                supplyCnt++;

                if (supplyCnt == maxSupply)
                    saleFinished = true; 
            }
        }
    }

    // Описание коллекции

    function description() public pure returns (string memory) {
        string memory desc = "We're happy to present the first children's drawings within the KindNFT project, created with the participation of the Astrakhan Region government. Children put their soul into each work. Children's drawings reflect their perception of life, society and the world as a whole.";
        return desc;
    }

    // Возвращает список id токенов по адресу

    function addrTokens(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // Ссылка на метаданные с токеном

    function tokenURI(uint256 tokenId) public view virtual override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
 
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";      
    }

    // Изменить базовый путь к расположению метаданных
    // (Вызов только собственником)

    function chMetadataBasePath(string memory newPath) public onlyOwner {
        baseURI = newPath;
    }

    // Изменить базовое расширение файлов метаданных
    // (Вызов только собственником)

    function chMetadataBaseExt(string memory newExt) public onlyOwner {
        baseExtension = newExt;
    }

    // Поменять стоимость nft (Вызов только собственником)

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    // Поменять стоимость nft на пресейле (Вызов только собственником)

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    // Установка url репозитория гдe находятся изображения (Вызов только собственником)

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // Установка расширения (png, jpeg...) (Вызов только собственником)

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // Установка ограничения на mint (Вызов только собственником)

    function setMintLim(uint256 _newMintLim) public onlyOwner
    {
        mintLim = _newMintLim;
    }

    // Установка ограничения на mint пресейл (Вызов только собственником)

    function setPresaleMintLim(uint256 _newPresaleMintLim) public onlyOwner
    {
        presaleMintLim = _newPresaleMintLim;
    }

    // Добавление адресов в белый список пресейла (1111 чел) (Вызов только собственником)

    function addPresaleUsers(address[] memory _wl) public onlyOwner {
        for (uint256 i = 0; i <= _wl.length -1; i++) {
            whitelist[_wl[i]] = true;
            whitelistSize++;
        }
    }

    // Добавление адресов в белый список приватной продажи (333 чел) (Вызов только собственником)

    function addPrivateSaleUsers(address[] memory _pswl) public onlyOwner {
        for (uint256 i = 0; i <= _pswl.length -1; i++) {
            privWhitelist[_pswl[i]] = true;
            privWhitelistSize++;
        }
    }

    // Есть ли адрес с белом списке пресейла

    function isPresaleAddr(address addr) public view returns (bool) {
        bool res = false;
        if (whitelistSize < 1) 
            return res;

        if (whitelist[addr] == true)
            res = true;

        return res;
    }

    // Есть ли адрес в белом списке приватной продажи

    function isPrivateSaleAddr(address addr) public view returns (bool) {
        bool res = false;
        if (privWhitelistSize < 1) 
            return res;

        if (privWhitelist[addr] == true)
            res = true;

        return res;
    }

    // Снятие баланса (Вызов только собственником)

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

}