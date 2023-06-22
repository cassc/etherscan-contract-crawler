/**  
 SPDX-License-Identifier: GPL-3.0
*/
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Signature.sol";
import "./ERC721A.sol";

error CallerIsContract();
error SaleNotActive();
error SoldOut();
error ExceedsMaxMintPerWallet();
error InvalidQuantity();


contract OwnableDelegateProxy {}


contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


contract Goblincatz is
    ERC721A,
    Ownable,
    Signature
{
    // Proxy registery Address
    address public proxyAddress;

    /** VARIABLES **/
    uint public maxSupply = 9999;
    uint constant public MAX_MINT_COUNT_PER_TXN = 30;
    uint private maxMintsPerWallet = 2;
    string private customBaseURI;
    address private dev = 0x215De00630F5E89C3A219D2771e55dc49F28489f;
    enum SaleState {
        CLOSED,
        PRESALE,
        PUBLIC
    }
    SaleState public saleState = SaleState.CLOSED;
    
    constructor(bool isPaying, uint256 deploymentPrice) ERC721A("Goblincatz", "GCATZ") payable {
        if(isPaying){
            require(msg.value >= deploymentPrice);
            payable(dev).transfer(address(this).balance);
        }
    }

    /** MINTING **/
    function mint(uint64 count) external payable {
        if (saleState != SaleState.PUBLIC) revert SaleNotActive();
        if (tx.origin != msg.sender) revert CallerIsContract();
        if (count > MAX_MINT_COUNT_PER_TXN) revert InvalidQuantity();
        if (_nextTokenId() + (count - 1) > maxSupply) revert SoldOut();

        uint64 numPublicMints = _getAux(msg.sender) + count;
        if (numPublicMints > maxMintsPerWallet) revert ExceedsMaxMintPerWallet();
        _mint(msg.sender, count);
        _setAux(msg.sender, numPublicMints); 
    }

    function mintPresale(uint64 count, bytes calldata signature)
        external
        payable
        requiresAllowlist(signature)
    {
        if (saleState != SaleState.PRESALE) revert SaleNotActive();
        if (tx.origin != msg.sender) revert CallerIsContract();
        if (count > MAX_MINT_COUNT_PER_TXN) revert InvalidQuantity();
        if (_nextTokenId() + (count - 1) > maxSupply) revert SoldOut();

        uint64 numPresaleMints = _getAux(msg.sender) + count;
        if (numPresaleMints > maxMintsPerWallet) revert ExceedsMaxMintPerWallet();
        _mint(msg.sender, count);
        _setAux(msg.sender, numPresaleMints); 
    }

    function freeMintToAddress(address account, uint256 count) external onlyOwner {
        if (count > MAX_MINT_COUNT_PER_TXN) revert InvalidQuantity();
        if (_nextTokenId() + (count - 1) > maxSupply) revert SoldOut();
        _mint(account, count);
    }

    /** ALLOWLIST **/
    function checkAllowlist(bytes calldata signature)
        public
        view
        requiresAllowlist(signature)
        returns (bool)
    {
        return true;
    }

    /** ADMIN FUNCTIONS **/
    /**
     * @dev Sets sale state to CLOSED (0), PRESALE (1), PUBLIC (2).
     */
    function setSaleState(uint8 state) external onlyOwner {
        saleState = SaleState(state);
    }

    /**
     * @dev Set IPFS folder link
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        customBaseURI = newBaseURI;
    }

    /**
     * @dev Set Max Mints per wallet
     */
    function setMaxMintsPerWallet(uint256 newMaxMint) external onlyOwner {
        maxMintsPerWallet = newMaxMint;
    }

    /**
     * @dev Set the proxyAddress
     */
    function setProxyAddress(address newProxyAddress) external onlyOwner {
        proxyAddress = newProxyAddress;
    }
    
    /**
     * @dev Set new dev wallet
     */
    function setDev(address newDev) external {
        require(msg.sender == dev, "Only dev can call");
        require(newDev != address(0));
        dev = newDev;
    }

    function getSaleSlotsUsed(address wallet) external view returns (uint64) {
        return _getAux(wallet);
    }

    /** OVERRIDES **/
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /**
     * @dev minting starts at token ID #1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Override isApprovedForAll
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /** RELEASE PAYOUT **/
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}