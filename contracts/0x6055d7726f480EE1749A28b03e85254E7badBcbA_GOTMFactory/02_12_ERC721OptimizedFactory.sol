// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "../access/SharedOwnable.sol";
import "../interfaces/IERC721Optimized.sol";
import "../opensea/IERC721Factory.sol";
import "../opensea/ProxyRegistry.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721OptimizedFactory is Context, SharedOwnable, IERC721, IERC721Factory {
    using Strings for address;
    using Strings for uint256;

    struct OptionConfig {
        uint64[] mintAmount;
    }

    string private _name;
    string private _symbol;
    string private _baseURI;
    OptionConfig private _optionConfig;
    IERC721Optimized private _erc721Optimized;
    address private _proxyRegistryAddress;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_, string memory baseURI_, OptionConfig memory optionConfig_, address payable erc721OptimizedAddress_, address proxyRegistryAddress_) {
        require(bytes(name_).length > 0, "ERC721OptimizedFactory: name can't be empty");
        require(bytes(symbol_).length > 0, "ERC721OptimizedFactory: symbol can't be empty");
        require(bytes(baseURI_).length > 0, "ERC721OptimizedFactory: baseURI can't be empty");
        require(optionConfig_.mintAmount.length > 0, "ERC721OptimizedFactory: optionConfig's mintAmount can't be empty");
        require(erc721OptimizedAddress_ != address(0), "ERC721OptimizedFactory: erc721OptimizedAddress can't be null address");
        if (proxyRegistryAddress_ != address(0))
            ProxyRegistry(proxyRegistryAddress_).proxies(_msgSender());

        IERC721Optimized erc721Optimized = IERC721Optimized(erc721OptimizedAddress_);
        erc721Optimized.publicMintConfig();

        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _optionConfig = optionConfig_;
        _erc721Optimized = erc721Optimized;
        _proxyRegistryAddress = proxyRegistryAddress_;

        _fireTransferEvents(address(0), owner());
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Factory).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    function optionConfig() external view returns (OptionConfig memory) {
        return _optionConfig;
    }

    function erc721OptimizedAddress() external view returns (address) {
        return address(_erc721Optimized);
    }

    function proxyRegistryAddress() external view returns (address) {
        return _proxyRegistryAddress;
    }

    function numOptions() external view returns (uint256) {
        return _optionConfig.mintAmount.length;
    }

    function setBaseURI(string calldata baseURI_) external onlySharedOwners {
        require(bytes(baseURI_).length > 0, "ERC721OptimizedFactory: baseURI can't be empty");
        _baseURI = baseURI_;
    }

    function setOptionConfig(OptionConfig memory optionConfig_) external onlySharedOwners {
        require(optionConfig_.mintAmount.length > 0, "ERC721OptimizedFactory: optionConfig's mintAmount can't be empty");
        _fireTransferEvents(owner(), address(0));
        _optionConfig = optionConfig_;
        _fireTransferEvents(address(0), owner());
    }

    function setProxyRegistryAddress(address proxyRegistryAddress_) external onlySharedOwners {
        if (proxyRegistryAddress_ != address(0))
            ProxyRegistry(proxyRegistryAddress_).proxies(_msgSender());
        _proxyRegistryAddress = proxyRegistryAddress_;
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, "contract"));
    }
    
    function canMint(uint256 _optionId) external view returns (bool) {
        return _canMint(_optionId);
    }

    function tokenURI(uint256 _optionId) external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, _optionId.toString()));
    }

    function supportsFactoryInterface() external pure returns (bool) {
        return true;
    }

    function mint(uint256 _optionId, address _toAddress) external {
        _mint(_optionId, _toAddress);
    }

    function kill(address payable recipient) external onlyOwner {
        _fireTransferEvents(owner(), address(0));
        selfdestruct(recipient);
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        _fireTransferEvents(_prevOwner, newOwner);
    }

    function _canMint(uint256 _optionId) private view returns (bool) {
        if (_optionId >= _optionConfig.mintAmount.length)
            return false;

        IERC721Optimized.MintConfig memory publicMintConfig = _erc721Optimized.publicMintConfig();
        if (block.timestamp < publicMintConfig.mintStartTimestamp)
            return false;

        if (block.timestamp >= publicMintConfig.mintEndTimestamp)
            return false;

        uint64 amount = _optionConfig.mintAmount[_optionId];
        if (_erc721Optimized.totalMinted() + amount > publicMintConfig.maxTotalMintAmount)
            return false;

        return true;
    }

    function _mint(uint256 _optionId, address _toAddress) private {
        require((owner() == _msgSender()) || (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(owner())) == _msgSender()) || (_operatorApprovals[owner()][_msgSender()]), string(abi.encodePacked("ERC721OptimizedFactory: caller ", _msgSender().toHexString(), " is not permitted to mint")));
        require(_canMint(_optionId), "ERC721OptimizedFactory: can't mint");

        _erc721Optimized.publicMint(_toAddress, _optionConfig.mintAmount[_optionId]);
    }

    function _fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < _optionConfig.mintAmount.length; i++)
            emit Transfer(_from, _to, i);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use IERC721 so the frontend doesn't have to worry about different method names.
     */

    function approve(address, uint256) external {}
    function setApprovalForAll(address _operator, bool _approved) external {
        if (owner() == _msgSender())
            _operatorApprovals[_msgSender()][_operator] = _approved;
    }

    function transferFrom(address, address _to, uint256 _tokenId) external {
        _mint(_tokenId, _to);
    }

    function safeTransferFrom(address, address _to, uint256 _tokenId) external {
        _mint(_tokenId, _to);
    }

    function safeTransferFrom(address, address _to, uint256 _tokenId, bytes calldata) external {
        _mint(_tokenId, _to);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        if (owner() == _owner) {
            if (_owner == _operator)
                return true;

            if (_proxyRegistryAddress != address(0) && address(ProxyRegistry(_proxyRegistryAddress).proxies(_owner)) == _operator)
                return true;

            if (_operatorApprovals[_owner][_operator])
                return true;
        }

        return false;
    }

    function balanceOf(address _owner) external view returns (uint256 _balance) {
        if (owner() == _owner)
            _balance = _optionConfig.mintAmount.length;
    }

    function getApproved(uint256) external view returns (address) {
        return owner();
    }

    function ownerOf(uint256) external view returns (address) {
        return owner();
    }
}