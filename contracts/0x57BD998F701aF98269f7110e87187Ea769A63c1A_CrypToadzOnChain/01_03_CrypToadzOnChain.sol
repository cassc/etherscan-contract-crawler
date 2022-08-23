// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.10;

/**
 * CrypToadz on Chain
 * These Toadz are 100% on-chain and each token is bound to their
 * corresponding legacy Toad. This means that these Toadz are untradeable.
 * The only purpose of these is to make sure of CrypToadz persistence on 
 * the blockchain. 
 * 
 * Contract written by: @0xBori 
 * Art brought on-chain by: @Wattsyart 
 */

import "@openzeppelin/contracts/access/Ownable.sol";

interface ICrypToadzChained {
    function tokenURIWithPresentation(uint256 _tokenId, uint8 _presentation) external view returns (string memory);
}

interface IToadz {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address _address) external view returns (uint256);
}

interface IEIP2309 {
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}

error SpecialsMinted();

contract CrypToadzOnChain is Ownable, IEIP2309 { 

    // Variables
    string public name = "CrypToadz on Chain";
    string public symbol = "OCTOAD";

    ICrypToadzChained public CTC = ICrypToadzChained(0xE8D8C0A6f174e08C44aB399b7CE810Bc4Dce096A);
    IToadz public TOADZ = IToadz(0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6);
    bool specialsMinted;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor(){
        // Initialize EIP2309 which will mint tokens from 1 - 6969.
        _initEIP2309(1, 6969);
    }

    /** 
     * @dev Sets a new address for CrypToadz on Chain URI implementation.
     * This contract address holds the on chain data for URI rendering. 
     */
    function setCTC(address _address) external onlyOwner {
        CTC = ICrypToadzChained(_address);
    }

    /**
     * @dev Sets a new address for CrypToadz.
     * This should always point towards the official CrypToadz address unless
     * desired otherwise. This could be called with the 0x00 address in order to
     * stop linking this to Cryptoadz and thus effectively removing the collection.
     */
    function setToadz(address _address) external onlyOwner {
        TOADZ = IToadz(_address);
    }

    /** 
     * @dev Mints tokens with ID's 1 000 000 - 56 000 000,
     * each token ID gets incremented by 1 000 000. This is something funky on 
     * the original CrypToadz contract for special tokens that were minted in a 
     * dev mint. 
     *
     * Emits {Transfer} event.
     */
    function mintSpecials() external {
        if (specialsMinted) revert SpecialsMinted();
        unchecked {
            for (uint i = 1; i < 57; ++i) {
                emit Transfer(address(0), address(this), i * 1000000);
            } 
        }

        specialsMinted = true;
    }

    function totalSupply() external view returns (uint256) {
        if (address(TOADZ) == address(0)) return 0;
        return TOADZ.totalSupply();
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        if (address(TOADZ) == address(0)) return address(0);
        return TOADZ.ownerOf(_tokenId);
    }

    function balanceOf(address _address) external view returns (uint256) {
        if (address(TOADZ) == address(0)) return 0;
        return TOADZ.balanceOf(_address);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return CTC.tokenURIWithPresentation(_tokenId, 1);
    }

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return (_interfaceId == 0x80ac58cd || _interfaceId == 0x5b5e139f);
    }

     /** 
     * @dev Mints tokens from `_start` to `_end` and emits one {ConsecutiveTransfer}
     * event as defined in EIP2309 (https://eips.ethereum.org/EIPS/eip-2309).  
     *
     * Emits {ConsecutiveTransfer} event.
     */
    function _initEIP2309(uint256 _start, uint256 _end) internal virtual { 
        emit ConsecutiveTransfer(_start, _end, address(0), address(this));       
    }
}