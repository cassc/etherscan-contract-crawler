// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Ethernals is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 constant public MAX_ETHERNALS = 10101;
    string _baseTokenURI = "";
    uint256 private _reserved = 101;
    uint256 private _price = 0.08 ether;
    address private _signerWalet = 0x9b38A4F0E758BC3c47dBEabcD98a04C1805D2f1a;
    bool public _paused = true;
    bool public _presale = false;
    bool public isURIFrozen = false;
    mapping(bytes32 => bool) public usedHashes;
    mapping(address => uint256) private presaleUsage;

    // owners
    address t1 = 0x107dAb1a4117b36128e0140a1dB993D89b46708C;
    address t2 = 0x435691EA5fcF5d91dd74c7f366601e6d2186D696;
    address t3 = 0xb7745c5852Edd5d0a0B64485A17c65285fbC4D2C;
    address t4 = 0x4dC2D0E1053654B7ee655F5634DDcf8bd40a589a;

    modifier canWithdraw(){
        require(address(this).balance > 0.2 ether);
        _;
    }

    struct ContractOwners {
        address payable addr;
        uint percent;
    }

    ContractOwners[] contractOnwers;

    constructor() ERC721("Ethernals", "ETHR")  {
        contractOnwers.push(ContractOwners(payable(address(t1)), 30));
        contractOnwers.push(ContractOwners(payable(address(t2)), 30));
        contractOnwers.push(ContractOwners(payable(address(t3)), 20));
        contractOnwers.push(ContractOwners(payable(address(t4)), 20));
    }

    function mintEthernals(uint256 quantity, bytes calldata signature, uint256 nonce) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                                          "Sale paused" );
        require( quantity < 4,                                      "Maximum of 3 mints per transaction" );
        require( supply + quantity < MAX_ETHERNALS - _reserved,     "Sold Out" );
        require( msg.value >= _price * quantity,                    "Ether sent is not correct" );

        bytes32 messageHash = hashMessage(msg.sender, quantity, nonce);
        require( messageHash.recover(signature) == _signerWalet, "Unrecognizable Hash" );
        require( !usedHashes[messageHash], "Reused Hash" );

        usedHashes[messageHash] = true;

        for(uint256 i; i < quantity; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function mintEthernalsPreSale(uint256 quantity, bytes calldata signature, uint256 maxLimit) public payable {
        uint256 supply = totalSupply();
        require( _presale,                                           "Presale is not active" );
        require( presaleUsage[msg.sender] + quantity <= maxLimit,    "Mint Overflow" );
        require( quantity < 4,                                       "Max of 3 mints per transaction" );
        require( supply + quantity < MAX_ETHERNALS - _reserved,      "Sold Out" );
        require( msg.value >= _price * quantity,                     "Ether sent is not correct" );

        bytes32 messageHash = hashMessagePresale(msg.sender, maxLimit);
        require( messageHash.recover(signature) == _signerWalet, "Unrecognizable Hash" );

        presaleUsage[msg.sender] += quantity;

        for(uint256 i; i < quantity; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function getPresaleUsage(address _to) public view returns (uint256){
        return presaleUsage[_to];
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require( !isURIFrozen, "URI is Frozen" );
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Ethernals supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function togglePresale(bool val) public onlyOwner {
        _presale = val;
    }

    function withdraw() external payable onlyOwner() canWithdraw() {
        uint nbalance = address(this).balance - 0.1 ether;
        for(uint i = 0; i < contractOnwers.length; i++){
            ContractOwners storage o = contractOnwers[i];
            o.addr.transfer((nbalance * o.percent) / 100);
        }
    }

    function freezeURI() external onlyOwner {
        isURIFrozen = true;
    }

    /*
    // In case the private key gets compromised
    */
    function setSignatureWallet(address newSignerWallet) external onlyOwner {
        _signerWalet = newSignerWallet;
    }

    function hashMessage(address sender, uint256 quantity, uint256 nonce) internal pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, quantity, nonce))));
        return hash;
    }

    function hashMessagePresale(address sender, uint256 maxLimit) internal pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, maxLimit))));
        return hash;
    }
}