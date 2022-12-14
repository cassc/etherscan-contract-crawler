// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@thirdweb-dev/contracts/extension/Upgradeable.sol";

import "./MinterACLs.sol";
import "./OwnableRoyalties.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//  ██████╗██╗████████╗██╗   ██╗    ██╗  ██╗██╗██████╗ ███████╗
// ██╔════╝██║╚══██╔══╝╚██╗ ██╔╝    ██║ ██╔╝██║██╔══██╗██╔════╝
// ██║     ██║   ██║    ╚████╔╝     █████╔╝ ██║██║  ██║███████╗
// ██║     ██║   ██║     ╚██╔╝      ██╔═██╗ ██║██║  ██║╚════██║
// ╚██████╗██║   ██║      ██║       ██║  ██╗██║██████╔╝███████║
//  ╚═════╝╚═╝   ╚═╝      ╚═╝       ╚═╝  ╚═╝╚═╝╚═════╝ ╚══════╝

// ███████╗██████╗ ███████╗ █████╗ ██╗  ██╗     ██████╗ ███╗   ██╗    ██╗     ██╗██████╗ ███████╗██████╗ ████████╗██╗   ██╗
// ██╔════╝██╔══██╗██╔════╝██╔══██╗██║ ██╔╝    ██╔═══██╗████╗  ██║    ██║     ██║██╔══██╗██╔════╝██╔══██╗╚══██╔══╝╚██╗ ██╔╝
// ███████╗██████╔╝█████╗  ███████║█████╔╝     ██║   ██║██╔██╗ ██║    ██║     ██║██████╔╝█████╗  ██████╔╝   ██║    ╚████╔╝
// ╚════██║██╔═══╝ ██╔══╝  ██╔══██║██╔═██╗     ██║   ██║██║╚██╗██║    ██║     ██║██╔══██╗██╔══╝  ██╔══██╗   ██║     ╚██╔╝
// ███████║██║     ███████╗██║  ██║██║  ██╗    ╚██████╔╝██║ ╚████║    ███████╗██║██████╔╝███████╗██║  ██║   ██║      ██║
// ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝      ╚═╝

contract CityKids is
    Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableRoyalties,
    MinterACLs,
    DefaultOperatorFiltererUpgradeable
{
    using Counters for Counters.Counter;
    Counters.Counter public totalMinted;

    string baseURI;
    address proxyRegistryAddress;
    string contractURL;
    address public buyContract;

    uint256 private _useBuyContract;
    uint256 private _allowBuyingSpecificId;

    uint256 public price;
    uint256 public paused;
    uint256 public maxNFTs;
    string public baseExtension;
    address public deployer;

    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == deployer);
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _limit,
        address _proxyRegistryAddress,
        string memory _IPFSURL
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __OwnableRoyalties_init();
        __DefaultOperatorFilterer_init();
        proxyRegistryAddress = _proxyRegistryAddress;
        maxNFTs = _limit;
        setBaseURI(string(abi.encodePacked("ipfs://", _IPFSURL, "/")));
        setContractURI(
            string(abi.encodePacked("ipfs://", _IPFSURL, "/metadata.json"))
        );
        _useBuyContract = 1;
        _allowBuyingSpecificId = 0;

        price = 1 ether;
        paused = 1;
        baseExtension = ".json";
        deployer = msg.sender;
    }

    function setUpgrader(address _newAuthorizedUpgrader) public onlyOwner {
        deployer = _newAuthorizedUpgrader;
    }

    function airdrop(address[] memory _addrs) external onlyOwner {
        uint256 _amount = _addrs.length;
        require(
            (totalMinted.current() + _amount) <= maxNFTs,
            "Not enough left to mint that many items"
        );
        for (uint256 i = 1; i <= _amount; i++) {
            require(canMint(totalMinted.current() + 1), "Can't mint that NFT");
            _safeMint(tx.origin, totalMinted.current() + 1);
            totalMinted.increment();
        }
    }

    function buy(uint256 _qty) public payable {
        require(msg.value >= price * _qty, "Not enough to pay for that.");
        for (uint256 i = 1; i <= _qty; i++) {
            _buy(totalMinted.current() + 1);
        }
    }

    function _buy(uint256 _id) private {
        require(paused == 0, "Contract is currently paused!");
        require(
            (_useBuyContract == 1 && msg.sender == buyContract) ||
                _useBuyContract == 0,
            "Must use the buy contract."
        );
        require(totalMinted.current() < maxNFTs, "All have been minted.");
        require(canMint(_id), "Can't mint that NFT");

        _safeMint(tx.origin, _id);
        totalMinted.increment();
    }

    function setMaxNFTs(uint256 _max) public onlyOwner {
        maxNFTs = _max;
    }

    function pause(uint256 _state) public onlyOwner {
        paused = _state;
    }

    function setBuyContract(address _newAddress) public onlyOwner {
        buyContract = _newAddress;
    }

    function setUseBuyContract(uint256 _state) public onlyOwner {
        _useBuyContract = _state;
    }

    function canMint(uint256 _id) public view virtual returns (bool) {
        return !_exists(_id) && _id > 0 && _id <= maxNFTs;
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
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
                        StringsUpgradeable.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC721Upgradeable.isApprovedForAll(_owner, _operator);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}