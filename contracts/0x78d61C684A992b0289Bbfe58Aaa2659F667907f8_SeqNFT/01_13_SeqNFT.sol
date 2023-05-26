// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract SeqNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string contractURL;
    string public baseExtension = ".json";
    uint256 public cost = 1.5 ether;
    uint256 public paused = 1;
    uint256 perUserLimit = 1;
    address proxyRegistryAddress;

    uint256 maxTypes = 10;
    uint256 maxPerType = 50;
    mapping(uint256 => uint256) mintingEnabled;
    mapping(uint256 => uint256) typeSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        proxyRegistryAddress = _proxyRegistryAddress;
        for (uint256 i = 0; i < maxTypes; i++) {
            mintingEnabled[i] = 0;
        }
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint8 _type) external onlyOwner {
        require(_type < maxTypes, "Type doesnt exist");
        require(
            typeSupply[_type] < maxPerType,
            "All of this type has been minted."
        );
        uint256 baseID = _type * maxPerType;
        _safeMint(_to, baseID + typeSupply[_type]);
        typeSupply[_type] += 1;
    }

    function mintBatch(address[] memory _to, uint8[] memory _type)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            require(_type[i] < maxTypes, "Type doesnt exist");
            require(
                typeSupply[_type[i]] < maxPerType,
                "All of this type has been minted."
            );
            uint256 baseID = _type[i] * maxPerType;
            _safeMint(_to[i], baseID + typeSupply[_type[i]]);
            typeSupply[_type[i]] += 1;
        }
    }

    function buy(uint256 _type) public payable {
        require(_type < maxTypes, "Type does not exist");
        require(paused == 0, "Contract is currently paused.");
        require(
            mintingEnabled[_type] == 1,
            "Minting is not enabled for this yet."
        );
        require(
            typeSupply[_type] < maxPerType,
            "All of this type has been minted."
        );
        require(balanceOf(msg.sender) < perUserLimit, "You can only buy one.");
        require(msg.value >= cost, "Not enough to pay for that.");
        uint256 baseID = _type * maxPerType;
        _safeMint(msg.sender, baseID + typeSupply[_type]);
        typeSupply[_type] += 1;
    }

    function setLimitPerUser(uint256 _count) public onlyOwner {
        perUserLimit = _count;
    }

    function setMintingEnabled(uint256 _type, uint256 _enabled)
        public
        onlyOwner
    {
        mintingEnabled[_type] = _enabled;
    }

    function setBatchMintingEnabled(uint256[] memory _types, uint256 _enabled)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _types.length; i++) {
            require(_types[i] < maxTypes, "Type doesnt exist");
            mintingEnabled[_types[i]] = _enabled;
        }
    }

    function ownerMint(uint256 _type) public onlyOwner {
        require(_type < maxTypes, "Type doesnt exist");
        require(
            typeSupply[_type] < maxPerType,
            "All of this type has been minted."
        );
        uint256 baseID = _type * maxPerType;
        _safeMint(msg.sender, baseID + typeSupply[_type]);
        typeSupply[_type] += 1;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function exists(uint256 _id) external view returns (bool) {
        return _exists(_id);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
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

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function allSupplies()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            typeSupply[0],
            typeSupply[1],
            typeSupply[2],
            typeSupply[3],
            typeSupply[4],
            typeSupply[5],
            typeSupply[6],
            typeSupply[7],
            typeSupply[8],
            typeSupply[9]
        );
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(uint256 _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     * Update it with setProxyAddress
     */
    function setProxyAddress(address _a) public onlyOwner {
        proxyRegistryAddress = _a;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
    }
}