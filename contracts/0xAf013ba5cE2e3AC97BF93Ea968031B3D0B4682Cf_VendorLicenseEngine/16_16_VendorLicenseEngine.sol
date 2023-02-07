// SPDX-License-Identifier: No License
/**
 * @title Vendor License Engine
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ILicenseEngine.sol";
import "./interfaces/IErrors.sol";

contract VendorLicenseEngine is
    IErrors,
    Ownable,
    ERC721,
    ERC721Enumerable,
    ILicenseEngine
{
    using Counters for Counters.Counter;

    /* ========== CONSTANT VARIABLES ========== */
    uint256 private constant HUNDRED_PERCENT = 100_0000; // 100% or max possible discount

    mapping(uint256 => LicenseInfo) public licenses;
    string public baseURI;
    address public factory;

    Counters.Counter private _tokenIdCounter;

    constructor(address _factory) ERC721("Vendor License", "VNDRL") {
        baseURI = "https://vendor.finance/license/";
        factory = _factory;
    }

    ///@notice                  Base URI for the license metadata
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    ///@notice                  Mints the licenses to a specified address
    ///@param _to               Address of the license receiver
    ///@param _expiry           Epoch timestamp till which the license will be active
    ///@param _maxPoolCount     Maximum amount of pools this license can be used on
    ///@param _discount         Discount applied to the interest made in lend token. From 0 to 100_0000
    ///@param _colDiscount      Discount applied to the defaulted collateral. From 0 to 100_0000
    function safeMint(
        address _to,
        uint48 _expiry,
        uint256 _maxPoolCount,
        uint48 _discount,
        uint48 _colDiscount
    ) public onlyOwner {
        if (_discount > HUNDRED_PERCENT) revert InvalidDiscount();
        if (_colDiscount > HUNDRED_PERCENT) revert InvalidDiscount();
        if (_expiry <= block.timestamp) revert InvalidDiscount();
        if (_maxPoolCount == 0) revert InvalidDiscount();
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        LicenseInfo memory lic = LicenseInfo({
            maxPoolCount: _maxPoolCount,
            currentPoolCount: 0,
            discount: _discount,
            colDiscount: _colDiscount,
            expiry: _expiry
        });
        licenses[tokenId] = lic;
        _safeMint(_to, tokenId);
    }
    
    /* ========== SETTERS ========== */
    ///@notice                  Update the base metadata URL
    ///@param baseURI_          New metadata URI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
    
    ///@notice                  Update the factory address
    ///@param _factory          New factory address
    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    ///@notice                  Update the lend interest discount for a license
    ///@param _lic              ID of the license to update
    ///@param _discount         New discount value
    function setDiscount(uint256 _lic, uint48 _discount) external onlyOwner {
        if (licenses[_lic].maxPoolCount == 0) revert LicenseNotFound();
        if (_discount < 0 || _discount > HUNDRED_PERCENT)
            revert InvalidDiscount();
        licenses[_lic].discount = _discount;
    }

    ///@notice                  Update the defaulted collateral discount for a license
    ///@param _lic              ID of the license to update
    ///@param _colDiscount      New discount value
    function setColDiscount(uint256 _lic, uint48 _colDiscount)
        external
        onlyOwner
    {
        if (licenses[_lic].maxPoolCount == 0) revert LicenseNotFound();
        if (_colDiscount < 0 || _colDiscount > HUNDRED_PERCENT)
            revert InvalidDiscount();
        licenses[_lic].colDiscount = _colDiscount;
    }

    ///@notice                  Update the expiry for a license
    ///@param _lic              ID of the license to update
    ///@param _expiry           New expiry in the epoch format
    function setExpiry(uint256 _lic, uint48 _expiry) external onlyOwner {
        if (licenses[_lic].maxPoolCount == 0) revert LicenseNotFound();
        if (_expiry <= block.timestamp) revert InvalidDiscount();
        licenses[_lic].expiry = _expiry;
    }

    ///@notice                  Update the max pool count for the license
    ///@param _lic              ID of the license to update
    ///@param _maxPoolCount     New max pool count
    function setMaxPoolCount(uint256 _lic, uint256 _maxPoolCount)
        external
        onlyOwner
    {
        if (licenses[_lic].maxPoolCount == 0) revert LicenseNotFound();
        if (_maxPoolCount == 0) revert InvalidDiscount();
        licenses[_lic].maxPoolCount = _maxPoolCount;
    }

    ///@notice                  Update the count of how many times this license has been used
    ///@dev                     Set this to maxPoolCount to disable the license
    ///@param _lic              ID of the license to update
    ///@param _currentPoolCount New current pool count 
    function setCurrentPoolCount(uint256 _lic, uint256 _currentPoolCount)
        external
        onlyOwner
    {
        if (licenses[_lic].maxPoolCount == 0) revert LicenseNotFound();
        if (_currentPoolCount > licenses[_lic].maxPoolCount)
            revert InvalidDiscount();
        licenses[_lic].currentPoolCount = _currentPoolCount;
    }

    ///@notice                  Increment the current pool count for the license by 1
    ///@dev                     Only factory can use this method on deployment of the new pool
    ///@param _lic              ID of the license to update
    function incrementCurrentPoolCount(uint256 _lic) external {
        if (msg.sender != factory) revert NotFactory();
        if (licenses[_lic].maxPoolCount == 0) revert LicenseNotFound();
        licenses[_lic].currentPoolCount += 1;
    }

    ///@notice                  Check if the license exists
    ///@param _tokenId          ID of the license to update
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /* ========== Overrides ========== */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}