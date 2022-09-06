// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract GucciNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string contractURL;
    string public baseExtension = ".json";
    address proxyRegistryAddress;
    uint256 maxNFTs = 500;
    using Counters for Counters.Counter;
    Counters.Counter public minted;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _contractURI,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setContractURI(_contractURI);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdrop(address[] memory _to) external virtual onlyOwner {
        uint256 supply = minted.current();
        require(supply + _to.length <= maxNFTs, "Not enough left to mint.");
        uint256 _amount = _to.length;
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to[i], supply + i);
            minted.increment();
        }
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

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
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