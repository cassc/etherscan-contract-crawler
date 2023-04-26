// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "Ownable.sol";
import "ERC721.sol";

import "IBundleToken.sol";

contract BundleToken is 
    IBundleToken,
    ERC721,
    Ownable
{
    string public constant NAME = "GIF Bundle Token";
    string public constant SYMBOL = "BTK";

    mapping(uint256 /** tokenId */ => uint256 /** bundleId */) public bundleIdForTokenId;
    address private _bundleModule;
    uint256 private _totalSupply;

    modifier onlyBundleModule() {
        require(_bundleModule != address(0), "ERROR:BTK-001:NOT_INITIALIZED");
        require(_msgSender() == _bundleModule, "ERROR:BTK-002:NOT_BUNDLE_MODULE");
        _;
    }

    constructor() ERC721(NAME, SYMBOL) Ownable() { }

    function setBundleModule(address bundleModule)
        external
    {
        require(_bundleModule == address(0), "ERROR:BTK-003:BUNDLE_MODULE_ALREADY_DEFINED");
        require(bundleModule != address(0), "ERROR:BTK-004:INVALID_BUNDLE_MODULE_ADDRESS");
        _bundleModule = bundleModule;
    }


    function mint(uint256 bundleId, address to) 
        external
        onlyBundleModule
        returns(uint256 tokenId)
    {
        _totalSupply++;
        tokenId = _totalSupply;
        bundleIdForTokenId[tokenId] = bundleId;        
        
        _safeMint(to, tokenId);
        
        emit LogBundleTokenMinted(bundleId, tokenId, to);           
    }


    function burn(uint256 tokenId) 
        external
        onlyBundleModule
    {
        require(_exists(tokenId), "ERROR:BTK-005:TOKEN_ID_INVALID");        
        _burn(tokenId);
        
        emit LogBundleTokenBurned(bundleIdForTokenId[tokenId], tokenId);   
    }

    function burned(uint tokenId) 
        external override
        view 
        returns(bool isBurned)
    {
        isBurned = tokenId <= _totalSupply && !_exists(tokenId);
    }

    function getBundleId(uint256 tokenId) external override view returns(uint256) { return bundleIdForTokenId[tokenId]; }
    function getBundleModuleAddress() external view returns(address) { return _bundleModule; }

    function exists(uint256 tokenId) external override view returns(bool) { return tokenId <= _totalSupply; }
    function totalSupply() external override view returns(uint256 tokenCount) { return _totalSupply; }
}