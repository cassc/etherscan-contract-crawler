//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract EBCCard is EIP712, Ownable, ERC721URIStorage {
    mapping(address => bool) private operators;
    mapping(address => bool) private _minted;

    event AddOperator(address operator);
    event RemoveOperator(address operator);

    string private _metadata_baseuri;

    constructor(string memory name) ERC721(name,"EBC") EIP712("EBC","1.0"){
        _metadata_baseuri = "https://www.alphaz.pro/api/ebc/metadata/";
    }

    function addOperator(address _operator)public onlyOwner{
        require(operators[_operator] == false);
        operators[_operator] = true;
        emit AddOperator(_operator);
    }

    function removeOperator(address _operator)public onlyOwner{
        require(operators[_operator] == true);
        delete operators[_operator];
        emit RemoveOperator(_operator);
    }

    function isOperator(address _operator)public view returns(bool){
        return operators[_operator];
    }

    function mint(address to, uint256 tokenId,bytes memory signature)public{

        address operator = recoverV4(to, tokenId, signature);
        require(isOperator(operator),"only operators can mint");

        require(balanceOf(to)<maxHoldAmount(),"only one card per address");

        require(_minted[to]==false,"only 1 mint chance per address");
        _minted[to] = true;

        _safeMint(to, tokenId);

    }

    function recoverV4(address to,uint256 tokenId,bytes memory signature)public view returns(address){
        bytes32 digest = _hashTypedDataV4((keccak256(abi.encode(
            keccak256("Mint(address to,uint256 tokenId)"),
            to,
            tokenId
        ))));
        return ECDSA.recover(digest, signature);
    }


    function _baseURI() override(ERC721) internal view virtual returns (string memory) {
        return _metadata_baseuri;
    }

    function setBaseURI(string memory baseURI)public onlyOwner{
        _metadata_baseuri = baseURI;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) override(ERC721) internal virtual {
        require(balanceOf(to)<maxHoldAmount(),"only one card per address");
        ERC721._transfer(from, to, tokenId);
    }

    function maxHoldAmount()public pure virtual returns(uint256){
        return 1;
    }

    function getChainId() public view returns(uint256){
        return block.chainid;
    }

    function minted(address owner)public view returns(bool){
        return _minted[owner];
    }

}