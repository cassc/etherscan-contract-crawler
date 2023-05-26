/**  
 SPDX-License-Identifier: GPL-3.0

 ____      ____  _                               __            ___       ___   ________   _   __                             
|_  _|    |_  _|(_)                             |  ]         .'   `.   .' ..] |_   __  | / |_[  |                            
  \ \  /\  / /  __   ____   ,--.   _ .--.   .--.| |  .--.   /  .-.  \ _| |_     | |_ \_|`| |-'| |--.  .---.  .---.  _ .--.   
   \ \/  \/ /  [  | [_   ] `'_\ : [ `/'`\]/ /'`\' | ( (`\]  | |   | |'-| |-'    |  _| _  | |  | .-. |/ /__\\/ /__\\[ `.-. |  
    \  /\  /    | |  .' /_ // | |, | |    | \__/  |  `'.'.  \  `-'  /  | |     _| |__/ | | |, | | | || \__.,| \__., | | | |  
     \/  \/    [___][_____]\'-;__/[___]    '.__.;__][\__) )  `.___.'  [___]   |________| \__/[___]|__]'.__.' '.__.'[___||__] 

 Written by: afellanamedrob & thezman | Sage Labs
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./EIP712Whitelisting.sol";
import "erc721a/contracts/ERC721A.sol";

error CallerIsContract();
error CantMintZero();
error PublicSaleNotActive();
error PresaleNotActive();
error ExceedsMaxSupply();
error ExceedsPresaleSupply();
error ExceedsReserveSupply();
error MintingTooManyPerTxn();
error InsufficientPayment();
error NotOwnerOrDev();

contract WizardsOfEtheen is
    ERC721A,
    ReentrancyGuard,
    Ownable,
    EIP712Whitelisting
{
    using Counters for Counters.Counter;

    /** MINTING **/
    uint256 public price = 0.055 ether;
    uint256 public whitelistPrice = 0.045 ether;
    uint256 public maxSupply = 4508;
    uint256 public reserveSupply = 250;
    uint256 public maxMintCountPerTxn = 13;
    uint256 public maxWhitelistSupply = 2500;
    string private customBaseURI;
    bool public saleIsActive = false;
    bool public whitelistSaleIsActive = false;
    address private devWallet;
    address private ownerWallet;

    Counters.Counter private supplyCounter;
    Counters.Counter private reserveSupplyCounter;
    Counters.Counter private whitelistMintCounter;
    PaymentSplitter private splitter;

    constructor(
        string memory _customBaseURI,
        address[] memory _payees,
        uint256[] memory _shares,
        address dev,
        address owner
    ) ERC721A("Wizards of Etheen", "WZRDS") EIP712Whitelisting() {
        customBaseURI = _customBaseURI;
        splitter = new PaymentSplitter(_payees, _shares);
        devWallet = dev;
        ownerWallet = owner;
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContract();
        _;
    }

    /** COUNTERS */
    function totalTokenSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    function totalReserveSupply() public view returns (uint256) {
        return reserveSupplyCounter.current();
    }

    function totalWhitelistMints() public view returns (uint256) {
        return whitelistMintCounter.current();
    }

    /** MINTING **/
    function mint(uint256 _count) public payable callerIsUser {
        if (_count <= 0) revert CantMintZero();
        if (saleIsActive == false) revert PublicSaleNotActive();
        if (totalTokenSupply() + _count - 1 > maxSupply - reserveSupply) {
            revert ExceedsMaxSupply();
        }
        if (_count - 1 > maxMintCountPerTxn) revert MintingTooManyPerTxn();
        if (msg.value < price * _count) revert InsufficientPayment();

        for (uint256 i = 0; i < _count; i++) {
            supplyCounter.increment();
        }

        _mint(msg.sender, _count, "", true);
        payable(splitter).transfer(msg.value);
    }

    function mintReserve(uint256 _count) external onlyOwner {
        if (totalTokenSupply() + _count - 1 > maxSupply - reserveSupply) {
            revert ExceedsMaxSupply();
        }
        if (totalReserveSupply() + _count > reserveSupply)
            revert ExceedsReserveSupply();
        for (uint256 i = 0; i < _count; i++) {
            reserveSupplyCounter.increment();
        }

        _mint(msg.sender, _count, "", true);
    }

    function mintReserveToAddress(uint256 _count, address _account)
        external
        onlyOwner
    {
        if (totalTokenSupply() + _count - 1 > maxSupply - reserveSupply) {
            revert ExceedsMaxSupply();
        }
        if (totalReserveSupply() + _count > reserveSupply)
            revert ExceedsReserveSupply();
        for (uint256 i = 0; i < _count; i++) {
            reserveSupplyCounter.increment();
        }

        _mint(_account, _count, "", true);
    }

    function mintWhitelist(uint256 _count, bytes calldata signature)
        public
        payable
        requiresWhitelist(signature)
        callerIsUser
    {
        if (_count <= 0) revert CantMintZero();
        if (whitelistSaleIsActive == false) revert PresaleNotActive();
        if (totalWhitelistMints() + _count - 1 >= maxWhitelistSupply) {
            revert ExceedsPresaleSupply();
        }
        if (totalWhitelistMints() + _count - 1 >= maxSupply - reserveSupply) {
            revert ExceedsMaxSupply();
        }
        if (_count > maxMintCountPerTxn) revert MintingTooManyPerTxn();
        if (msg.value < whitelistPrice * _count) revert InsufficientPayment();

        for (uint256 i = 0; i < _count; i++) {
            supplyCounter.increment();
            whitelistMintCounter.increment();
        }

        _mint(_msgSender(), _count, "", true);
        payable(splitter).transfer(msg.value);
    }

    /** WHITELIST **/
    function checkWhitelist(bytes calldata signature)
        public
        view
        requiresWhitelist(signature)
        returns (bool)
    {
        return true;
    }

    /** ADMIN FUNCTIONS **/
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistSaleState() external onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        whitelistPrice = _price;
    }

    function setMaxWhitelistSupply(uint256 _maxSupply) external onlyOwner {
        maxWhitelistSupply = _maxSupply;
    }

    function setReserveSupply(uint256 _newReserve) external onlyOwner {
        reserveSupply = _newReserve;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        customBaseURI = _newBaseURI;
    }

    function setMaxSupply(uint256 _newSize) external onlyOwner {
        maxSupply = _newSize;
    }

    /** RELEASE PAYOUT **/
    function release(address payable _account) public virtual {
        if (msg.sender == devWallet || msg.sender == ownerWallet) {
            splitter.release(_account);
        } else {
            revert NotOwnerOrDev();
        }
    }
}