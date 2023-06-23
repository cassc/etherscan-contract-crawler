//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Arties is ERC721Burnable, Ownable {

    using Strings for uint256;
    using ECDSA for Arties;

    uint public mint_fee = 0;
    uint public burn_fee = 0;

    AggregatorInterface public chainlinkRef = AggregatorInterface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);

    mapping(uint => uint) public nonces;

    event Bridge2Stacks(uint tokenId, string dstAddress, uint nonce);
    event SetMintFee(uint fee);
    event SetBurnFee(uint fee);

    constructor() ERC721("Arties", "Arties") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://ipfs/QmWhLJ7D3xEGKUpDymxCWZRUj2VCZxaBC8Yfx6kZ5hLjBL/";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function bridge2Eth(uint256 tokenId, bytes memory signature) external payable {
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(abi.encodePacked(msg.sender, address(this), tokenId, nonces[tokenId]));
        (address signer, ) = ECDSA.tryRecover(msgHash, signature);
        require(signer == owner(), "Not signed by owner");
        require(msg.value >= mint_fee, "Must pay fee");
        if(msg.value > mint_fee)
            payable(msg.sender).transfer(msg.value - mint_fee);
        if(_exists(tokenId))
            _transfer(address(this), msg.sender, tokenId);
        else
            _safeMint(msg.sender, tokenId);
        nonces[tokenId] ++;
    }

    function bridge2Stacks(uint256 tokenId, string memory dstAddress) external payable {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Arties: caller is not owner nor approved");
        require(msg.value >= burn_fee, "Must pay fee");
        if(msg.value > burn_fee)
            payable(msg.sender).transfer(msg.value - burn_fee);
        _transfer(msg.sender, address(this), tokenId);
        emit Bridge2Stacks(tokenId, dstAddress, nonces[tokenId]);
    }

    function setMintFee(uint fee) external onlyOwner {
        mint_fee = fee;
        emit SetMintFee(fee);
    }
    
    function setBurnFee(uint fee) external onlyOwner {
        burn_fee = fee;
        emit SetBurnFee(fee);
    }

    function withdrawFee() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

interface AggregatorInterface{
    function latestAnswer() external view returns (uint256);
}