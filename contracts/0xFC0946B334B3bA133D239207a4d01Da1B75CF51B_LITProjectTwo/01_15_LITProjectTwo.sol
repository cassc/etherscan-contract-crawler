// SPDX-License-Identifier: MIT

/**
*   @title Lit Project Two
*   @author Transient Labs, Copyright (C) 2021
*   @notice ERC721 smart contract with single owner, Merkle whitelist, and royalty info per EIP 2981.
*/

/*
 #######                                                      #                            
    #    #####    ##   #    #  ####  # ###### #    # #####    #         ##   #####   ####  
    #    #    #  #  #  ##   # #      # #      ##   #   #      #        #  #  #    # #      
    #    #    # #    # # #  #  ####  # #####  # #  #   #      #       #    # #####   ####  
    #    #####  ###### #  # #      # # #      #  # #   #      #       ###### #    #      # 
    #    #   #  #    # #   ## #    # # #      #   ##   #      #       #    # #    # #    # 
    #    #    # #    # #    #  ####  # ###### #    #   #      ####### #    # #####   #### 
    
0101010011100101100000110111011100101101000110010011011101110100 01001100110000011000101110011 
*/

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "Counters.sol";
import "MerkleProof.sol";
import "EIP2981.sol";

contract LITProjectTwo is EIP2981, ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;
    uint256 private _mintStartTimestamp;
    string private _baseTokenURI;
    mapping(address => uint256) public mintNum;
    uint256 public supply = 4620;
    bool public mintOpen;
    uint256 public mintPrice = 0.068 ether;
    bytes32 public immutable merkleRoot;

    /**
    *   @notice constructor for this contract
    *   @dev increments _nextTokenId so the first mint isn't more expensive
    *   @param root is the merkle root
    *   @param addr is the royalty payout address
    *   @param perc is the royalty payout percentage
    */
    constructor(bytes32 root, address addr, uint256 perc) EIP2981(addr, perc) ERC721("LIT Project Two", "LP2") Ownable() {
        merkleRoot = root;
        _nextTokenId.increment();
    }

    /**
    *   @notice overrides EIP721 and EIP2981 supportsInterface function
    *   @param interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    *   @return a boolean saying if this contract supports the interface or not
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, EIP2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    *   @notice function to view total supply
    *   @return uint256 with supply
    */
    function totalSupply() public view returns(uint256) {
        return supply;
    }

    /**
    *   @notice function to get next mint token id
    *   @return uint256 with number of next token id
    */
    function getNextTokenId() public view returns(uint256) {
        return _nextTokenId.current();
    }

    /**
    *   @notice sets the baseURI for the ERC721 tokens
    *   @dev requires owner
    *   @param uri is the base URI set for each token
    */
    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    /**
    *   @notice override standard ERC721 base URI
    *   @dev doesn't require access control since it's internal
    *   @return string representing base URI
    */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    *   @notice function to set the mint status
    *   @dev sets the timestamp for mint, if it hasn't been set yet
    *   @param status is the true/false flag for the mint status
    */
    function setMintStatus(bool status) public onlyOwner {
        mintOpen = status;
        if (mintOpen && _mintStartTimestamp == 0) {
            _mintStartTimestamp = block.timestamp;
        }
    }

    /**
    *   @notice whitelist mint function
    *   @dev requires mint to be open
    *   @dev requires merkle proof to be valid
    *   @dev requires mint price to be met
    *   @dev requires that the message sender hasn't already minted more than allowed at the time of the transaction
    *   @param  merkleProof is the proof provided by the minting site
    */
    function whitelistMint(bytes32[] calldata merkleProof) public payable {
        require(mintOpen, "Mint Not Open");
        require(_nextTokenId.current() <= supply, "Total Supply Reached");
        require(msg.value >= mintPrice, "Not Enough Ether");
        require(mintNum[msg.sender] < getMintAllowance(), "Reached Mint Limit");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not In Whitelist");

        _safeMint(msg.sender, _nextTokenId.current());
        _nextTokenId.increment();
        mintNum[msg.sender]++;
    }

    /**
    *   @notice function to calculate number of allowed mints per wallet
    *   @dev 1 mint in the first 48hrs, then 25 total allowed after that
    *   @return uint256 value for number of mints allowed per wallet
    */
    function getMintAllowance() public view returns(uint256) {
        return block.timestamp - _mintStartTimestamp < 48*3600 ? 1 : 25;
    }

    /**
    *   @notice owner mint function
    *   @dev mints to the contract owner wallet
    *   @dev requires ownership of the contract
    *   @dev minted pieces can be used for disputes or donated to the DAO
    *   @param num is the number of mints to perform
    */
    function mint(uint256 num) public onlyOwner {
        for (uint256 i = 0; i < num; i++) {
            if (_nextTokenId.current() > supply) {
                break;
            }
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    /**
    *   @notice function to withdraw minting ether from the contract
    *   @dev requires owner to call
    */
    function withdrawEther() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
    *   @notice function to update the royalty payout address
    *   @dev ownable
    *   @param addr is the new payout address
    */
    function updateRoyaltyAddress(address addr) public onlyOwner {
        require(addr != address(0), "Royalty address cannot be the zero address");
        royaltyAddr = addr;
    }

    /**
    *   @notice burn function for owners to use at their discretion
    *   @dev requires the msg sender to be the owner or an approved delegate
    *   @param tokenId is the token ID to burn
    */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not Approved or Owner");
        _burn(tokenId);
    }
}