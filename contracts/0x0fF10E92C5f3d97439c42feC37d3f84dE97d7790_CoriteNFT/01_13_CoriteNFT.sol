// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoriteNFT is ERC721Enumerable, Ownable {
    uint public nftCounter;
    uint public nftPrice;
    uint public nftCap;
    uint public nftBatchCap;
    uint public nftPerAddress;

    address private receiveFunds;

    bool public freeForAllMint = false;

    mapping(address=>uint) public hasMinted;

    event minted(address indexed to, uint tokeId);

    constructor (uint _nftPrice, uint _nftCap, uint _nftBatchCap, uint _nftPerAddress, address payable _receiveFunds) ERC721 ("Corite x Emery Kelly - Emotions Collection", "EMOTIONS") Ownable(){
        require(_nftBatchCap <= _nftCap, "nftBatchCap > nftCap");
        require(_nftPerAddress >= 0, "nftPerAddress not >= 0");
        require(_nftPrice >= 0, "nftPrice not >= 0");
        nftCounter = 0;
        nftPrice = _nftPrice;
        nftCap = _nftCap;
        nftBatchCap = _nftBatchCap;
        nftPerAddress = _nftPerAddress;
        receiveFunds = _receiveFunds;
    }

    function mintWL(uint8 _v, bytes32 _r, bytes32 _s, uint _nrToMint) public payable {
        require(_verifySignature(_v, _r, _s), "Invalid whitelist signature");
        _mintProcess(_nrToMint);
    }

    function mintFFA(uint _nrToMint) public payable {
        require(freeForAllMint, "Free for all mint is not enabled");
        _mintProcess(_nrToMint);
    }

    function mintO(uint _nrToMint) public onlyOwner(){
        require((nftCounter+_nrToMint) <= nftBatchCap, "Cap overflow.");
        uint target = nftCounter + _nrToMint;

        _mint(target, owner());
    }

    function _verifySignature(uint8 _v, bytes32 _r, bytes32 _s) internal view returns (bool){
        bytes memory prefix = "\x19Ethereum Signed Message:\n20";

        bytes32 msgh = keccak256(abi.encodePacked(prefix, msg.sender));
        return ecrecover(msgh, _v, _r, _s) == owner();
    }

    function _mintProcess(uint _nrToMint) private {
        require(msg.value == (nftPrice * _nrToMint), "Wrong ETH amount.");
        require((hasMinted[msg.sender] + _nrToMint) <= nftPerAddress, "One address in not allowed to mint more than nftPerAddress");
        uint target = nftCounter + _nrToMint;
        require(target <= nftBatchCap, "Cap reached.");

        hasMinted[msg.sender] = hasMinted[msg.sender] + _nrToMint;

        payable(receiveFunds).transfer(msg.value);

        _mint(target, msg.sender);
    }

    function _mint(uint _target, address _to) private {
        for (uint idToMint = nftCounter; idToMint < _target; idToMint++){
            _safeMint(_to, idToMint);
            emit minted(_to, idToMint);
            nftCounter = nftCounter + 1;
        }
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return IChromiaNetResolver(0x04410C1874B7d1C13B47396B8e4b4fC5b778c1E6).getNFTURI(address(this), tokenId);
    }

    function changeNftPrice(uint _newNftPrice) public onlyOwner(){
        require(_newNftPrice >= 0);
        nftPrice = _newNftPrice;
    }

    function changeNftBatchCap(uint _newNftBatchCap) public onlyOwner(){
        require(_newNftBatchCap <= nftCap, "nftBatchCap can not be greater than nftCap");
        nftBatchCap = _newNftBatchCap;
    }

    function changeNftPerAddress(uint _newNftPerAddress) public onlyOwner(){
        require(_newNftPerAddress >= 0);
        nftPerAddress = _newNftPerAddress;
    }

    function toggleFreeForAllMint() public onlyOwner(){
        if(freeForAllMint){
            freeForAllMint = false;
        }else{
            freeForAllMint = true;
        }
    }

    function endSale() public onlyOwner() {
        nftCap = nftCounter;
        nftBatchCap = nftCounter;
    }
}

interface IChromiaNetResolver {
     function getNFTURI(address contractAddress, uint id) external view returns (string memory);
}