// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract QubitsOnTheIce is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 200;
    uint256 private _price = 0.045 ether;
    uint256 private _qubinatorPrice = 0.00 ether;
    uint256 public _qubinatorStartCount = 10000;
    bool public _paused = true;
    bool public _qubinatorPaused = true;
    mapping(uint256 => bool) private unboxedQubit;

    // withdraw addresses
    address qubits = 0x054b2d6CaFA4AD47e80c913217304BB9AF29C306;
    address qubinator = 0xa70694d21262E20c61436523Ba953604196182dA;
    address qubiter = 0x0bF199da987F940563335434e0Fa218b12646255;

    // 9999 Qubits in total, might get reduced post the Qubinator
    constructor(string memory baseURI) ERC721("Qubits On The Ice", "QOTI")  {
        setBaseURI(baseURI);

        // team gets the first 3 qubits
        _safeMint( qubits, 0);
        _safeMint( qubinator, 1);
        _safeMint( qubiter, 2);

    }

    function purchase(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 21,                              "You can purchase a maximum of 20 Qubits" );
        require( supply + num < 10000 - _reserved,      "Exceeds maximum Qubits supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function setQubinatorPrice(uint256 _newPrice) public onlyOwner() {
        _qubinatorPrice = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function getQubinatorPrice() public view returns (uint256){
        return _qubinatorPrice;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Qubits supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function unboxQubit(uint256 tokenId, bool val) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Qubit does not belong to you.");
        unboxedQubit[tokenId] = val;
    }

    function isUnboxed(uint id) public view returns(bool) {
        return unboxedQubit[id];
    }


    function _qubinateProcess() private  {
        require( _qubinatorStartCount + 1 < 15000,             "Exceeds maximum Qubits that can be created" );
        require( msg.value >= _qubinatorPrice,             "Ether sent is not correct" );
        _safeMint( msg.sender, _qubinatorStartCount + 1 );
        _qubinatorStartCount = _qubinatorStartCount+1;
    }

    function sendQubinator(uint256 qubit1, uint256 qubit2) public {
        require( !_qubinatorPaused,                  "Qubinator is offline" );
        require(_exists(qubit1),                    "sendQubinator: Qubit 1 does not exist.");
        require(_exists(qubit2),                    "sendQubinator: Qubit 2 does not exist.");
        require(ownerOf(qubit1) == _msgSender(),    "sendQubinator: Qubit 1 caller is not token owner.");
        require(ownerOf(qubit2) == _msgSender(),    "sendQubinator: Qubit 2 caller is not token owner.");
        require( qubit1 <=  10000,             "Qubit 1 is not a genesis Qubit" );
        require( qubit2 <=  10000,             "Qubit 2 is not a genesis Qubit" );
        require( unboxedQubit[qubit1],              "Qubit 1 is not  unboxed" );
        require( unboxedQubit[qubit2],              "Qubit 2 is not  unboxed" );

        require(qubit1 != qubit2, "Both Qubits can't be the same ");
        _burn(qubit1);
        _burn(qubit2);
        _qubinateProcess();
    }
    
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
    
    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function qubinatorPause(bool val) public onlyOwner {
        _qubinatorPaused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 2;
        require(payable(qubits).send(_each));
        require(payable(qubinator).send(_each));
    }
}