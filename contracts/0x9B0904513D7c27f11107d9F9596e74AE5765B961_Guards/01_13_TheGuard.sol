// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Guards is Ownable, ERC721Burnable {
    using Strings for uint256;

    uint public lastTokenId;

    uint256 public mintStartAt;
    uint256 public mintEndAt;

    uint public mintPrice;
    uint public mintFee;
    address public moneyReceiver;

    string public baseURI;

    mapping(address => uint) public userMinted;
    uint public maxMintPerUser;
    uint public maxSupply;

    mapping(address => bool) public adminList;

    mapping(address => bool) public firstPriorityWhitelist;
    mapping(address => bool) public secondPriorityWhitelist;

    uint firstPriorityWhitelistStarTime;
    uint secondPriorityWhitelistStartTime;

    event TokenRedeemed(address indexed account, uint indexed tokenId, uint indexed amount, bytes metadata);
    event ErrorMoneySend();
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    modifier withinMintWindow(address userAddress) {
        require(isSaleActiveFor(userAddress), "Not a mint window");
        _;
    }

    modifier adminOrOwnerOnly() {
        require(msg.sender == owner() || adminList[msg.sender], "admin or owner only");
        _;
    }

    constructor() ERC721("Devon DeJardin's Guardians", "GUARDS")  {
        maxSupply = 998;
        maxMintPerUser = 3;
        moneyReceiver = 0xa16913a5072919eDbd511a8915DB11E4b8792D54;
        adminList[0xDD0669B6A7992D623d8f5FD441138B699360007A] = true;

        firstPriorityWhitelistStarTime = 1683637200;
        secondPriorityWhitelistStartTime = 1683651600;

        mintStartAt = 1683666000;
        mintEndAt = 1683680400;

        mintPrice = 0.5 ether;
        mintFee = 0;
    }

    function isSaleActiveFor(address userAddress) public view returns(bool) {
        if(firstPriorityWhitelist[userAddress]) {
            return firstPriorityWhitelistStarTime < block.timestamp && block.timestamp < mintEndAt;
        }

        if(secondPriorityWhitelist[userAddress]) {
            return secondPriorityWhitelistStartTime < block.timestamp && block.timestamp < mintEndAt;
        }

        return mintStartAt < block.timestamp && block.timestamp < mintEndAt;
    }

    function changeWhitelistStartDates(uint _firstPriorityWhitelistStarTime, uint _secondPriorityWhitelistStarTime) public adminOrOwnerOnly {
        firstPriorityWhitelistStarTime = _firstPriorityWhitelistStarTime;
        secondPriorityWhitelistStartTime = _secondPriorityWhitelistStarTime;
    }

    function changeFirstPriorityWhitelist(address[] memory addresses, bool status) public adminOrOwnerOnly {
        for(uint i = 0; i < addresses.length; i++) {
            firstPriorityWhitelist[addresses[i]] = status;
        }
    }

    function changeSecondPriorityWhitelist(address[] memory addresses, bool status) public adminOrOwnerOnly {
        for(uint i = 0; i < addresses.length; i++) {
            secondPriorityWhitelist[addresses[i]] = status;
        }
    }

    function changeAdminList(address[] memory addresses, bool status) public onlyOwner {
        for(uint i = 0; i < addresses.length; i++) {
            adminList[addresses[i]] = status;
        }
    }

    function setPrices(uint _mintPrice, uint _mintFee) public adminOrOwnerOnly {
        mintPrice = _mintPrice;
        mintFee = _mintFee;
    }

    function setMintWindow(uint _mintStartAt, uint _mintEndAt) public adminOrOwnerOnly {
        mintStartAt = _mintStartAt;
        mintEndAt = _mintEndAt;
    }

    function setBaseURI(string memory __baseURI) public adminOrOwnerOnly {
        baseURI = __baseURI;
        emit BatchMetadataUpdate(1, type(uint).max);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function mint() external payable withinMintWindow(msg.sender) {
        require(msg.value == mintPrice + mintFee, "invalid value");
        require(userMinted[msg.sender] + 1 <= maxMintPerUser, "max mint per user exceed");
        userMinted[msg.sender]+= 1;

        (bool success, ) = moneyReceiver.call{value: address(this).balance}("");
        if(!success) {
            emit ErrorMoneySend();
        }

        lastTokenId++;
        require(lastTokenId <= maxSupply, "max limit reached");
        _mint(msg.sender, lastTokenId);
        
    }

    function mintBatch(uint amount) external payable withinMintWindow(msg.sender) {
        require(msg.value == (mintPrice + mintFee) * amount, "invalid value");
        require(userMinted[msg.sender] + amount <= maxMintPerUser, "max mint per user exceed");
        userMinted[msg.sender]+= amount;

        (bool success, ) = moneyReceiver.call{value: address(this).balance}("");
        if(!success) {
            emit ErrorMoneySend();
        }

        for(uint i = 0; i < amount; i++) {
            lastTokenId++;
            require(lastTokenId <= maxSupply, "max limit reached");
            _mint(msg.sender, lastTokenId);
        }
    }

    function crossmint(address to, uint count) public payable  {
        mintBatchTo(to, count);
    }

    function mintBatchTo(address to, uint amount) public payable withinMintWindow(to) {
        require(msg.value == (mintPrice + mintFee) * amount, "invalid value");
        require(userMinted[to] + amount <= maxMintPerUser, "max mint per user exceed");
        userMinted[to]+= amount;

        (bool success, ) = moneyReceiver.call{value: address(this).balance}("");
        if(!success) {
            emit ErrorMoneySend();
        }

        for(uint i = 0; i < amount; i++) {
            lastTokenId++;
            require(lastTokenId <= maxSupply, "max limit reached");
            _mint(to, lastTokenId);
        }
    }


    function mintBatchOwnable(uint amount) external adminOrOwnerOnly {
        for(uint i = lastTokenId + 1; i <= lastTokenId + amount; i++) {
            _safeMint(msg.sender, i);
        }
        lastTokenId+= amount;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    pure
    override(ERC721)
    returns(bool)
    {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
        interfaceId == 0x5b5e139f;  // ERC165 Interface ID for ERC721Metadata
    }
}