// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Pool.sol";
import "https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Factory.sol";
import "./IGoldz.sol";

contract FeudalzOrcz is ERC721, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IGoldz goldz = IGoldz(0x7bE647634A942e73F8492d15Ae492D867Ce5245c);
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV3Factory public constant factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public constant MAX_SUPPLY = 10000;
    bool public isSalesActive = true;
    uint[] public prices;

    constructor() ERC721("FeudalzOrcz", "ORCZ") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        prices = [
            0.03 ether, 
            0.04 ether, 
            0.06 ether, 
            0.08 ether, 
            0.10 ether, 
            0.15 ether, 
            0.20 ether, 
            0.30 ether
        ];

        _contractUri = "ipfs://QmZRN7LBJwEWoQWCbgv41zK5Phkx2SMUwQdaf3Cd6rrkKK";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(uint quantity) external {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out");
        
        goldz.transferFrom(msg.sender, address(this), currentPriceInGOLDZ() * quantity);
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function mint(uint quantity, address receiver) external onlyRole(ADMIN_ROLE) {
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out");

        for (uint i = 0; i < quantity; i++) {
            safeMint(receiver);
        }
    }

    function currentPriceInGOLDZ() public view returns (uint) {
        return currentPriceInETH().mul(10**18).div(goldzPrice());
    }

    function currentPriceInETH() public view returns (uint) {
        uint priceSteps = prices.length;
        uint increaseAt = MAX_SUPPLY / priceSteps;
        uint currentSupply = totalSupply();

        for (uint i = 0; i < priceSteps; i++) {
            if (currentSupply <= (i+1) * increaseAt) return prices[i];
        }

        return prices[priceSteps-1];
    }

    function goldzPrice() public view returns (uint price) {
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(WETH, address(goldz), 3000));
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        return uint(sqrtPriceX96).mul(uint(sqrtPriceX96)).mul(1e18) >> (96 * 2);
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyRole(ADMIN_ROLE) {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyRole(ADMIN_ROLE) {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyRole(ADMIN_ROLE) {
        isSalesActive = !isSalesActive;
    }
    
    function setPrices(uint[] memory newPrices) external onlyRole(ADMIN_ROLE) {
        prices = newPrices;
    }

    function burnGoldz() external onlyRole(ADMIN_ROLE) {
        uint balance = goldz.balanceOf(address(this));
        goldz.burn(balance);
    }

    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}