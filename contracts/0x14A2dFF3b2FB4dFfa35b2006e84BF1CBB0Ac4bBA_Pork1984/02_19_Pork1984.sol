pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
import "./ClaimableWithSvin.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Pork1984Minting is ERC721Enumerable {
    function _mintPork1984(address owner, uint256 startingIndex, uint16 number) internal {
        for (uint i = 0; i < number; i++) {
            _safeMint(owner, startingIndex + i);
        }
    }
}

abstract contract Pork1984Selling is Pork1984Minting, Pausable, ContextMixin, NativeMetaTransaction, ClaimableWithSvin {
    uint256 constant maxPork1984 = 9840;
    uint constant sellablePork1984StartingIndex = 600;
    uint constant giveawayPork1984StartingIndex = 20;
    uint constant specialPork1984StartingIndex  = 1;
    uint16 constant maxPork1984ToBuyAtOnce = 10;

    uint constant singlePork1984Price = 45100000 gwei;  // 0.0451 eth for one pork

    uint256 public nextPork1984ForSale;
    uint public nextPork1984ToGiveaway;
    uint public nextSpecialPork1984;

    constructor() {
        nextPork1984ForSale = sellablePork1984StartingIndex;
        nextPork1984ToGiveaway = giveawayPork1984StartingIndex;
        nextSpecialPork1984    = specialPork1984StartingIndex;
        initSvinBalances();
    }

    function claimPork1984() public {
        uint16 porksToMint = howManyFreePorks();

        require(porksToMint > 0, "You cannot claim pork1984 tokens");
        require(leftForSale() >= porksToMint, "Not enough porks left on sale");
        _mintPork1984(msg.sender, nextPork1984ForSale, porksToMint);
        cannotClaimAnymore(msg.sender);

        nextPork1984ForSale += porksToMint;
    }

    function buyPork1984(uint16 porksToBuy)
        public
        payable
        whenNotPaused
        {
            require(porksToBuy > 0, "Cannot buy 0 porks");
            require(leftForSale() >= porksToBuy, "Not enough porks left on sale");
            require(porksToBuy <= maxPork1984ToBuyAtOnce, "Cannot buy that many porks at once");
            require(msg.value >= singlePork1984Price * porksToBuy, "Insufficient funds sent.");
            _mintPork1984(msg.sender, nextPork1984ForSale, porksToBuy);

            nextPork1984ForSale += porksToBuy;
        }

    function leftForSale() public view returns(uint256) {
        return maxPork1984 - nextPork1984ForSale;
    }

    function leftForGiveaway() public view returns(uint) {
        return sellablePork1984StartingIndex - nextPork1984ToGiveaway;
    }

    function leftSpecial() public view returns(uint) {
        return giveawayPork1984StartingIndex - nextSpecialPork1984;
    }

    function giveawayPork1984(address to) public onlyOwner {
        require(leftForGiveaway() >= 1);
        _mintPork1984(to, nextPork1984ToGiveaway++, 1);
    }

    function mintSpecialPork1984(address to) public onlyOwner {
        require(leftSpecial() >= 1);
        _mintPork1984(to, nextSpecialPork1984++, 1);
    }

    function startSale() public onlyOwner whenPaused {
        _unpause();
    }

    function pauseSale() public onlyOwner whenNotPaused {
        _pause();
    }
}

contract Pork1984 is Pork1984Selling {
    string _provenanceHash;
    string baseURI_;
    address proxyRegistryAddress;

    constructor(address _proxyRegistryAddress) ERC721("Pork1984", "PORK1984") {
        proxyRegistryAddress = _proxyRegistryAddress;
        _pause();
        setBaseURI("https://api.pork1984.io/api/svin/");
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.pork1984.io/contract/opensea-pork1984";
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner
    {
        _provenanceHash = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseURI_ = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function isApprovedOrOwner(address target, uint256 tokenId) public view returns (bool) {
        return _isApprovedOrOwner(target, tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensInWallet(address wallet) public view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(wallet));

        for (uint i = 0; i < tokens.length; i++) {
            tokens[i] = tokenOfOwnerByIndex(wallet, i);
        }

        return tokens;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Pork1984: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}