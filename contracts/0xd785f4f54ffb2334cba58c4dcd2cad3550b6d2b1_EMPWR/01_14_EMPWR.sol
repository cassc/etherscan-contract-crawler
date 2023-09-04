//SPDX-License-Identifier: MIT
//@dev: @null.eth & @brougkr

pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy { }
contract ProxyRegistry { mapping(address => OwnableDelegateProxy) public proxies; }

contract EMPWR is ERC721A, Ownable, ReentrancyGuard 
{
    bool public whitelistMintState = true;
    bool public publicMintState = false;
    string public baseURI;
    uint256 public MAX_SUPPLY;
    address public proxyRegistryAddress;
    uint256 public immutable maxWhitelistAmount;
    uint256 public immutable mintPrice;
    mapping(address => uint256) public whitelist;
    event WLAdded(address[] wallets, uint256[] amounts);

    /**
     * @dev Constructor
     */
    constructor() ERC721A("EmpwrByElla", "EMPWR") 
    {
        baseURI = "ipfs://QmY8JsidAomLS5djVGyeeeVKvAjRm7Z1ULkX18DB1s7Qds/";
        MAX_SUPPLY = 2050;
        maxWhitelistAmount = 1050;
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
        mintPrice = 0.05 ether;
    }

    /**
     * @dev Returns Whitelist Allocation
     */
    function checkWhitelist(address _addr) external view returns(uint256) { return whitelist[_addr]; }

    /**
     * @dev Returns Base URI
     */
    function _baseURI() internal view virtual override returns (string memory) { return baseURI; }

    /**
     * @dev Public Mint
     */
    function mintPublic() public payable nonReentrant 
    {
        require(tx.origin == msg.sender, "Bad.");
        require(publicMintState, "Public mint is currently paused.");
        uint256 currentSupply = totalSupply();
        require(currentSupply < MAX_SUPPLY, "Maximum amount of NFTs have been minted.");
        require(msg.value >= mintPrice, "Not enough Ether sent to mint an NFT.");
        _safeMint(msg.sender, 1);
    }

    /**
     * @dev Whitelist Mint
     */
    function mintWhitelist(uint256 _amount) public nonReentrant 
    {
        require(tx.origin == msg.sender, "Bad.");
        require(whitelistMintState, "Whitelist mint is currently paused.");
        uint256 currentSupply = totalSupply();
        require(_amount <= whitelist[msg.sender], "You can't mint that many NFT's");
        require((currentSupply + _amount) < maxWhitelistAmount, "Max whitelist NFTs minted.");
        require(_amount > 0, "Amount must be greater than zero.");
        whitelist[msg.sender] -= _amount;
        _safeMint(msg.sender, _amount);
    }

    /**
     * @dev Sets Base URI
     */
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner { baseURI = _baseTokenURI; }

    /**
     * @dev Toggles Whitelist Mint
     */
    function toggleWhitelistMint() external onlyOwner { whitelistMintState = !whitelistMintState; }

    /**
     * @dev Toggles Public Mint
     */
    function togglePublicMint() external onlyOwner { publicMintState = !publicMintState; }

    /**
     * @dev Adds Wallet To Whitelist
     */
    function addToWhiteList(address _addr, uint256 _amount) external onlyOwner { whitelist[_addr] = _amount; }

    /**
     * @dev Batch Adds Wallets To Whitelist With Amounts
     */
    function batchWhitelist(address[] calldata _users, uint256[] calldata _holdings) external onlyOwner 
    {
        uint256 size = _users.length;
        for(uint256 i=0; i < size; i++) { whitelist[_users[i]] = _holdings[i]; }
        emit WLAdded(_users, _holdings);
    }

    /**
     * @dev Withdraws Ether From Contract To Address
     */
    function _withdraw(address _account) external onlyOwner 
    {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(_account), balance);
    }

    /**
     * @dev Withdraws Ether From Contract To Message Sender
     */
    function __withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Sets Max Supply
     */
    function __setMaxSupply(uint256 supply) external onlyOwner { MAX_SUPPLY = supply; }

    /**
     * @dev Changes Proxy Address
     */
    function __changeProxyAddress(address proxyAddress) external onlyOwner { proxyRegistryAddress = proxyAddress; }

    /**
     * @dev Override Is Approved For All
     */
    function isApprovedForAll(address account, address operator) override public view returns (bool) 
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(account)) == operator) { return true; }
        return ERC721A.isApprovedForAll(account, operator);
    }
}