// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AlphaTime is ERC1155, Ownable, Pausable, ERC1155Supply {
    string public name = "Alpha Time";
    string public symbol = "ALPHA";
    string private BASE_URI;

    uint16 public SUPPLY = 100;
    uint8 public RESERVED_SUPPLY = 10;
    uint8 public MAX_MINT_PER_TX = 1;
    uint256 public maxPerWallet = 1;

    uint8 TOKEN_INDEX = 0;

    bytes32 public root;

    uint16 public supplyLeft = SUPPLY;
    bool saleActive;
    string private contractUri = "http://api.alphatime.io/metadata/contract.json";

    uint256 private _price = 0.2 ether;
    uint256 private _discountedPrice = 0.15 ether;  

    struct MintHistory {
        uint256 amountMinted;
    }

    mapping(address => MintHistory) public mintHistory;

    event Mint(address indexed _address, uint8 amount, uint16 supplyLeft);

    modifier isMintable(uint256 amount) {
        require(saleActive, "Sale is not active");
        require(amount > 0, "Amount must be positive integer");
        require(amount <= MAX_MINT_PER_TX, "Can't mint that many tokens at once");
        require(supplyLeft - amount >= 0, "Can't mint over supply limit");
        _;
    }

    constructor(bool _saleActive, bytes32 _root) ERC1155("") {
        saleActive = _saleActive;
        root = _root;

        ownerMint(msg.sender, RESERVED_SUPPLY);

    }


/*
===================================================================================================

░██████╗░███████╗████████╗  ███████╗██╗░░░██╗███╗░░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
██╔════╝░██╔════╝╚══██╔══╝  ██╔════╝██║░░░██║████╗░██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
██║░░██╗░█████╗░░░░░██║░░░  █████╗░░██║░░░██║██╔██╗██║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
██║░░╚██╗██╔══╝░░░░░██║░░░  ██╔══╝░░██║░░░██║██║╚████║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
╚██████╔╝███████╗░░░██║░░░  ██║░░░░░╚██████╔╝██║░╚███║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
░╚═════╝░╚══════╝░░░╚═╝░░░  ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

===================================================================================================
*/

    function getSaleActive() external view returns (bool) {
        return saleActive;
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }

    function getDiscountedPrice() external view returns (uint256) {
        return _discountedPrice;
    }

    function getContractUri() public view returns (string memory) {
        return contractUri;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

/*
========================================================================================================

███╗░░░███╗██╗███╗░░██╗████████╗  ███████╗██╗░░░██╗███╗░░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
████╗░████║██║████╗░██║╚══██╔══╝  ██╔════╝██║░░░██║████╗░██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
██╔████╔██║██║██╔██╗██║░░░██║░░░  █████╗░░██║░░░██║██╔██╗██║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
██║╚██╔╝██║██║██║╚████║░░░██║░░░  ██╔══╝░░██║░░░██║██║╚████║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
██║░╚═╝░██║██║██║░╚███║░░░██║░░░  ██║░░░░░╚██████╔╝██║░╚███║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝░░░╚═╝░░░  ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

========================================================================================================
*/


    function mint(
        address account, 
        uint8 amount
    )
        public
        payable
        whenNotPaused
        isMintable(amount)
    {
        require(
            mintHistory[account].amountMinted + amount <= maxPerWallet,
            "Already Minted Max Per Wallet"
        );
        require(
            msg.value >= amount * _price,
             "Wrong amount sent"
        );
        _mint(account, TOKEN_INDEX, amount, "");

        supplyLeft -= amount;

        emit Mint(account, amount, supplyLeft);
        mintHistory[account].amountMinted += uint8(amount);
    }


    function discountMint(bytes32[] memory _proof,address account, uint8 amount)
        public
        payable
        whenNotPaused
        isMintable(amount)
    {

        require(
           isValid(_proof,
            keccak256(
                abi.encodePacked(
                    account
                    )
                )
            ),
            "Not On Allowlist For Discounted Mint."
        );
        require(
            mintHistory[account].amountMinted + amount <= maxPerWallet,
            "Already Minted Max Per Wallet"
        );
        require(
            msg.value >= amount * _discountedPrice, 
            "Wrong amount sent"
        );
        _mint(account, TOKEN_INDEX, amount, "");

        supplyLeft -= amount;

        emit Mint(account, amount, supplyLeft);
        mintHistory[account].amountMinted += uint8(amount);
    }

    function ownerMint(address account, uint8 amount) public onlyOwner {
        _mint(account, TOKEN_INDEX, amount, "");

        supplyLeft -= amount;
        
        emit Mint(account, amount, supplyLeft);
        mintHistory[account].amountMinted += uint8(amount);
    }

/*
==================================================================================================

░██████╗███████╗████████╗  ███████╗██╗░░░██╗███╗░░██╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
██╔════╝██╔════╝╚══██╔══╝  ██╔════╝██║░░░██║████╗░██║██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
╚█████╗░█████╗░░░░░██║░░░  █████╗░░██║░░░██║██╔██╗██║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
░╚═══██╗██╔══╝░░░░░██║░░░  ██╔══╝░░██║░░░██║██║╚████║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
██████╔╝███████╗░░░██║░░░  ██║░░░░░╚██████╔╝██║░╚███║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
╚═════╝░╚══════╝░░░╚═╝░░░  ╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

==================================================================================================
*/

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setRoot(bytes32 root_) public onlyOwner {
        root = root_;
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function setDiscountedPrice(uint256 discountPrice) public onlyOwner {
        _discountedPrice = discountPrice;
    }

    function updateMaxPerWallet(uint256 newMaxPerWallet) public onlyOwner {
        maxPerWallet = newMaxPerWallet;
    }


    function setContractUri(string calldata _contractUri) public onlyOwner {
        contractUri = _contractUri;
    }

    function setSaleStatus(bool _saleActive) public onlyOwner {
        saleActive = _saleActive;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}