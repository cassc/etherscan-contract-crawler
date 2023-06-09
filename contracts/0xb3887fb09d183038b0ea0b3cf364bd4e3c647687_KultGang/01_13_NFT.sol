/**
 ____  __.     .__   __      ________                       
|    |/ _|__ __|  |_/  |_   /  _____/_____    ____    ____  
|      < |  |  \  |\   __\ /   \  ___\__  \  /    \  / ___\ 
|    |  \|  |  /  |_|  |   \    \_\  \/ __ \|   |  \/ /_/  >
|____|__ \____/|____/__|    \______  (____  /___|  /\___  / 
        \/                         \/     \/     \//_____/  
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract KultGang is Ownable, ERC721A {
    using Strings for uint256;

    uint256 public privatelistStart; // privatelist sale
    uint256 public whitelistStart; // whitelist sale
    uint256 public publicStart; // Start time
    uint256 public pricePub; // Price of each tokens
    uint256 public pricePriv; // Price of each tokens
    uint256 public priceWL; // Price of each tokens
    string public baseTokenURI; // Placeholder during mint
    string public revealedTokenURI; // Revealed URI
    mapping(address => uint256) public purchased; // # of bought per address

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), 'contract not allowed');
        require(msg.sender == tx.origin, 'proxy contract not allowed');
        _;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /** @dev whitelistMint
        @param signature {bytes}
        @param max {uint256}
        note To save in gas cost, i use a whitelist and a private mint function even though they are identical almost 
    */
    function whitelistMint(bytes memory signature, uint256 max) external payable notContract {
        // Wait until whitelist start
        require(whitelistStart <= block.timestamp, 'Mint: Whitelist sale not yet started');

        // Ensure whitelist
        bytes32 messageHash = sha256(abi.encode(msg.sender, max, 1));
        require(
            ECDSA.recover(messageHash, signature) == owner(),
            'Mint: Invalid Signature, are you whitelisted bud?'
        );

        listMint(max, priceWL);
    }

    /** @dev privateMint
        @param signature {bytes}
        @param max {uint256}
        note To save in gas cost, i use a whitelist and a private mint function even though they are identical almost 
    */
    function privateMint(bytes memory signature, uint256 max) external payable notContract {
        // Wait until whitelist start
        require(privatelistStart <= block.timestamp, 'Mint: Whitelist sale not yet started');

        // Ensure whitelist
        bytes32 messageHash = sha256(abi.encode(msg.sender, max, 2));
        require(
            ECDSA.recover(messageHash, signature) == owner(),
            'Mint: Invalid Signature, are you whitelisted bud?'
        );

        listMint(max, pricePriv);
    }

    /** @notice Public mint  */
    function publicMint() external payable notContract {
        // Wait until public start
        require(publicStart <= block.timestamp, 'Mint: Public sale not yet started, bud.');

        listMint(maxBatchSize, pricePub);
    }

    /** @dev ListMint
        @param max {uint256}
        @param price {uint256}
        note listMint price is calculated by the msg.value 
    */
    function listMint(uint256 max, uint256 price) internal {
        uint256 mintAmount = getMintAmount(price);
        require(mintAmount > 0, 'Mint: Can not mint 0 fren.');

        purchased[msg.sender] += mintAmount;
        require(purchased[msg.sender] <= max, "Mint: Don't be greedy share the love!");

        _safeMint(msg.sender, mintAmount);
    }

    /** @dev get mint amount and return unused eth */
    function getMintAmount(uint256 price) internal returns (uint256 mintAmount) {
        mintAmount = msg.value / price; // rounds down ;)
        if (totalSupply() + mintAmount > collectionSize) {
            uint256 over = (totalSupply() + mintAmount) - collectionSize;
            safeTransferETH(msg.sender, over * price);
            mintAmount = collectionSize - totalSupply(); // Last person gets the rest.
        }
    }

    /** @notice Allow owner to mint */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount < collectionSize, 'Mint: Bruh you are overminting.');
        _safeMint(to, amount);
    }

    /** @notice Set Start time */
    function setStart(uint256 time, uint256 which) external onlyOwner {
        if (which == 0) {
            whitelistStart = time;
        } else if (which == 1) {
            privatelistStart = time;
        } else if (which == 2) {
            publicStart = time;
        }
    }

    /** @notice Set Reveal URI */
    function setPrice(uint256 newPrice, uint256 which) external onlyOwner {
        if (which == 0) {
            priceWL = newPrice;
        } else if (which == 1) {
            pricePriv = newPrice;
        } else if (which == 2) {
            pricePub = newPrice;
        }
    }

    /** @notice Set Base URI */
    function setBaseTokenURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    /** @notice Set Reveal URI */
    function setRevealedTokenUri(string memory uri) external onlyOwner {
        revealedTokenURI = uri;
    }

    /** @notice Withdraw Ethereum */
    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;

        safeTransferETH(to, balance);
    }

    /** @notice function to allow for transfer of eth from addresses and contracts safely */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    /** @notice get collection size */
    function getCollectionSize() external view returns (uint256) {
        return collectionSize;
    }

    /** @notice allow updates to collection size */
    function setCollectionSize(uint256 size) external onlyOwner {
        collectionSize = size;
    }

    /** @notice allow updates to batch size */
    function setMaxBatchSize(uint256 size) external onlyOwner {
        maxBatchSize = size;
    }

    /** @notice Image URI */
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), 'URI: Token does not exist');

        // Convert string to bytes so we can check if it's empty or not.
        return
            bytes(revealedTokenURI).length > 0
                ? string(abi.encodePacked(revealedTokenURI, tokenId.toString()))
                : baseTokenURI;
    }

    /** @notice external data */
    function getData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            privatelistStart,
            whitelistStart,
            publicStart,
            pricePriv,
            priceWL,
            pricePub,
            collectionSize,
            totalSupply()
        );
    }

    function getUserData(address account) external view returns (uint256, uint256) {
        return (balanceOf(account), purchased[account]);
    }

    /** @notice initialize contract */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxBatchSize,
        uint256 _collectionSize,
        uint256 _wlStart,
        uint256 _privStart,
        uint256 _publicStart
    ) ERC721A(_name, _symbol, _maxBatchSize, _collectionSize) {
        baseTokenURI = 'ipfs://QmYCGkaA25qRYP6vUcqWenAT9fPxpCUpqjhqfv4ESdvSEn';

        whitelistStart = _wlStart;
        privatelistStart = _privStart;
        publicStart = _publicStart;
        priceWL = 0.06 ether;
        pricePriv = 0.07 ether;
        pricePub = 0.08 ether;
    }
}