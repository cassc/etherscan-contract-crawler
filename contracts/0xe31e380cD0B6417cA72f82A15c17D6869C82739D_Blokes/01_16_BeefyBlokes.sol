// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/FrankNFT-labs/ERC721F/blob/v4.7.0/contracts/token/ERC721/ERC721FCOMMON.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/utils/cryptography/MerkleProof.sol";


/**
 * @title Beefy Blokes contract
 * @dev Extends ERC721FCOMMON Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankNFT.eth
 * 
 */

contract Blokes is ERC721FCOMMON {
    
    uint256 public tokenPrice = 0.055 ether; 
    uint256 public preSaleTokenPrice = 0.050 ether; 
    uint256 public constant MAX_TOKENS=4110;
    uint public constant MAX_RESERVE = 101; // set 1 to high to avoid some gas
    // 0: sale off
    // 1: claim
    // 2: presale
    // 3: public
    uint public saleState;

    bytes32 public preSaleMerkleRoot;
    bytes32 public claimlistMerkleRoot;

    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant ONEPERC = 0xb3E86A37cc734B1cd463568D1F9E3219D52D8d18;  
    mapping(address => uint256) private userBalance;
    
    event priceChange(address _by, uint256 price);
    
    constructor() ERC721FCOMMON("Beefy Blokes", "BBL") {
        setBaseTokenURI("ipfs://QmQjnhP8dsqjntLRsgcU6Sw6mBrL8S8hss2F7qgQknZiwE/"); 
        _mint( FRANK, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function airdrop(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 100 tokens at a time");
        for (uint i = 0; i < numberOfTokens;) {
            _safeMint(to, supply + i);
            unchecked{ i++;}
        }
    }
     /**
     * Mint Tokens to the owners reserve.
     */   
    function reserveTokens() external onlyOwner {    
        airdrop(owner(),MAX_RESERVE-1);
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
        preSaleTokenPrice = price - 0.005 ether;
        emit priceChange(msg.sender, tokenPrice);
    }

    /**
     * @notice  Set one of the merkle roots
     * @param   _ID         2 for whitelist root, 1 for claimlist root
     * @param   _newRoot    New Merkle tree root
     */
    function setMerkleRoot(uint256 _ID, bytes32 _newRoot) external onlyOwner {
        require(_ID < 3 && _ID > 0, "!id");
        if (_ID == 2) {
            preSaleMerkleRoot = _newRoot;
        } else if (_ID == 1) {
            claimlistMerkleRoot = _newRoot;
        }
    }

    /**
     * Changes the state of saleIsActive from true to false and false to true
     * 0: sale off
     * 1: claim
     * 2: presale
     * 3: public
     * @dev If saleIsActive becomes `true` sets preSaleIsActive to `false`
     */
    function setSaleState(uint256 _id) external onlyOwner {
        require(_id < 4, "!id");
        saleState=_id;
    }

    /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 30
     */
    function mint(uint256 numberOfTokens) external payable {
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require(msg.sender == tx.origin, "No Contracts allowed.");
        require( numberOfTokens < 21,
            "Can only mint 20 tokens at a time"
        );
        require(
            tokenPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );
        require(saleState==3, "Sale NOT active yet");
        uint256 supply = totalSupply();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );

        for (uint256 i; i < numberOfTokens; ) {
            _mint(msg.sender, supply + i); // no need to use safeMint as we don't allow contracts.
            unchecked {
                i++;
            }
        }
    }


    /**
     * @notice Claims a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 4
     * @param merkleProof Proof that an address is part of the whitelisted pre-sale addresses
     * @dev Uses MerkleProof to determine whether an address is allowed to mint during the pre-sale, non-mint name is due to hardhat being unable to handle function overloading
     */
    function claim(uint256 numberOfTokens, bytes32[] calldata merkleProof) external payable  {
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require(userBalance[msg.sender]+numberOfTokens<5,"max claim is 4 tokens");
        require(saleState==1, "claim is not active yet");
        require(
            preSaleTokenPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );
        uint256 supply = totalSupply();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        require(checkValidity(merkleProof, claimlistMerkleRoot), "Invalid Merkle Proof");
        userBalance[msg.sender] += numberOfTokens;
        for (uint256 i; i < numberOfTokens; ) {
            _safeMint(msg.sender, supply + i);
            unchecked {
                i++;
            }
        }
    }
    /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 6
     * @param merkleProof Proof that an address is part of the whitelisted pre-sale addresses
     * @dev Uses MerkleProof to determine whether an address is allowed to mint during the pre-sale, non-mint name is due to hardhat being unable to handle function overloading
     */
    function mintPreSale(uint256 numberOfTokens, bytes32[] calldata merkleProof) external payable {
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require( numberOfTokens < 7,
            "Can only mint 6 tokens at a time"
        );
        require(saleState==2, "PreSale is not active yet");
        require(
            tokenPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );
        uint256 supply = totalSupply();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        require(checkValidity(merkleProof, preSaleMerkleRoot), "Invalid Merkle Proof");

        for (uint256 i; i < numberOfTokens; ) {
            _safeMint(msg.sender, supply + i);
            unchecked {
                i++;
            }
        }
    }

    function checkValidity(bytes32[] calldata merkleProof, bytes32 root)
        internal
        view
        returns (bool)
    {
        bytes32 leafToCheck = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, root, leafToCheck);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        _withdraw(ONEPERC,balance/100);
        _withdraw(owner(), address(this).balance);
    }
}