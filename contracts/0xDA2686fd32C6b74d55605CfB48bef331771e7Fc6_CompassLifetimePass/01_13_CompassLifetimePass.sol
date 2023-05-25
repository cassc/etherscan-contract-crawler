// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title CompassLifetimePass
 * CompassLifetimePass - Lifetime access to all Compass features for it's holders
 */
contract CompassLifetimePass is ERC721Enumerable, Ownable {

    /**
     * @dev Emitted when `to` receives a payout in the amount of `amount`.
     */
    event AffiliatePayout(address indexed to, uint256 amount);

    /**
     * Constants
     */

    // Max number of tokens ever allowed to exist
    uint256 public constant MAX_SUPPLY = 1000;

    // Max mints a wallet can do in total
    uint256 public constant MAX_MINTS_PER_ADDRESS = 5;

    /**
     * Config
     */

    // Number of tokens reserved for team
    uint256 private _reserveSupply;

    // Affiliate comission basis points
    uint256 private _affiliateComissionRate;

    // Mint state flag
    bool private _isMintEnabled;

    // Array of token price tiers
    uint256[5] private _prices;

    // Array of starting token indexes for each price tier
    uint256[5] private _priceSteps;

    // Base URI of all tokens
    string private _baseTokenUri;

    /**
     * State
     */

    // Mapping minter address to mint count
    mapping(address => uint256) _mintedByAddress;

    // Mapping addres to boolean indicating whether
    // an address is banned from the affiliate program
    mapping(address => bool) _affiliateBlocklist;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseTokenUri
    ) ERC721(_name, _symbol) {
        _isMintEnabled = false;
        _reserveSupply = 50;
        _affiliateComissionRate = 10;
        _baseTokenUri = baseTokenUri;

        _prices = [0 ether, 0.1 ether, 0.15 ether, 0.2 ether, 0.3 ether];

        _priceSteps = [
            1, // 1-50
            1 + _reserveSupply, // 51-100
            51 + _reserveSupply, // 101-300
            251 + _reserveSupply, // 301-500
            451 + _reserveSupply // 501-1000
        ];
    }

    /**
     * @dev Mints the reserved tokens to the owner and enables public minting
     */
    function reserveMint() external onlyOwner {
        for (uint256 i = 0; i < _reserveSupply; i++) {
            _mint(msg.sender, i + 1);
        }

        _isMintEnabled = true;
    }

    /**
     * @dev Pauses the minting process
     */
    function pause() external onlyOwner {
        _isMintEnabled = false;
    }

    /**
     * @dev Un-pauses the minting process
     */
    function unpause() external onlyOwner {
        _isMintEnabled = true;
    }

    /**
     * @dev Adds an address to the affiliate blocklist
     * @param affiliate The wallet address of the affiliate to block
     */
    function blockAffiliate(address affiliate) external onlyOwner {
        _affiliateBlocklist[affiliate] = true;
    }

    /**
     * @dev Mints a token while paying referral commission if affiliate is valid
     * @param referredBy An affiliate address
     */
    function mint(address payable referredBy) external payable {
        uint256 price = currentPrice();
        require(_isMintEnabled == true, "Public mint is not enabled yet");
        require(
            _mintedByAddress[msg.sender] + 1 <= MAX_MINTS_PER_ADDRESS,
            "Mint would exceed max allowed tokens per wallet"
        );
        require(msg.value == price, "Incorrect amount of funds");

        _mintTo(msg.sender);

        if (isValidAffiliate(referredBy)) {
            uint256 comission = (price * _affiliateComissionRate) / 100;
            referredBy.transfer(comission);

            emit AffiliatePayout(referredBy, comission);
        }
    }

    /**
     * @dev Mints a single token to the address passed.
     * This method only enforces max supply constraints,
     * so additional sanity checks must be done before calling it.
     */
    function _mintTo(address to) internal {
        uint256 currentTokenId = totalSupply() + 1;
        require(
            currentTokenId <= MAX_SUPPLY,
            "Mint would exceed max allowed supply"
        );
        _mintedByAddress[to] += 1;
        _safeMint(to, currentTokenId);
    }

    /**
     * @dev Returns the price of token with index
     */
    function getPriceForId(uint256 tokenId) public view returns (uint256) {
        for (uint256 i = 0; i < _priceSteps.length; i++) {
            if (_priceSteps[i] > tokenId) {
                return _prices[i - 1];
            }
        }

        return _prices[_prices.length - 1];
    }

    /**
     * @dev Returns the price of the next token
     */
    function currentPrice() public view returns (uint256) {
        uint256 currentTokenId = totalSupply() + 1;

        return getPriceForId(currentTokenId);
    }

    /**
     * @dev Check if minting is enabled
     */
    function isMintEnabled() external view returns (bool) {
        return _isMintEnabled;
    }

    /**
     * @dev Performs affiliate sanity check on address
     */
    function isValidAffiliate(address affiliate) public view returns (bool) {
        return
            affiliate != address(0) &&
            affiliate != msg.sender &&
            _affiliateBlocklist[affiliate] == false &&
            this.balanceOf(affiliate) > 0;
    }

    /**
     * @dev Returns metadata url for token with provided id
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(_baseTokenUri, Strings.toString(_tokenId)));
    }

    /**
     * @dev Sends all funds to the specified address
     */
    function drain(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }
}