// SPDX-License-Identifier: MIT

/*
 * Contract by pr0xy.io
 *   ______    _                  ______             __
 *  /_  __/___(_)__  ___  __ __  /_  __/__  ___ ____/ /__
 *   / / / __/ / _ \/ _ \/ // /   / / / _ \/ _ `/ _  /_ /
 *  /_/ /_/ /_/ .__/ .__/\_, /   /_/  \___/\_,_/\_,_//__/
 *           /_/  /_/   /___/
 */

pragma solidity ^0.8.7;

import './ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract TrippyToadz is ERC721Enumerable, Ownable {
    bytes32 public merkleRoot;
    string public baseTokenURI;
    uint public price;
    uint public status;

    mapping(uint => mapping(address => bool)) public denylist;

    constructor() ERC721("TrippyToadz", "TT") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setStatus(uint _status) external onlyOwner {
        status = _status;
    }

    function claim(bytes32[] calldata _merkleProof, uint256 _amount) external {
        uint256 supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

        require(status == 1, 'Not Active');
        require(!denylist[0][msg.sender], 'Mint Claimed');
        require(supply + _amount < 6970, 'Supply Denied');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }

        denylist[0][msg.sender] = true;
    }

    function presale(bytes32[] calldata _merkleProof, uint _amount) external payable {
        uint supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(status == 2, 'Not Active');
        require(_amount < 4, 'Amount Denied');
        require(!denylist[1][msg.sender], 'Mint Claimed');
        require(supply + _amount < 6970, 'Supply Denied');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(msg.value >= price * _amount, 'Ether Amount Denied');
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

        for(uint i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }

        denylist[1][msg.sender] = true;
    }

    function mint(uint _amount) external payable {
        uint supply = totalSupply();

        require(status == 3, 'Not Active');
        require(_amount < 4, 'Amount Denied');
        require(supply + _amount < 6970, 'Supply Denied');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(msg.value >= price * _amount, 'Ether Amount Denied');

        for(uint i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function withdraw() external payable onlyOwner {
        uint256 p1 = address(this).balance * 23 / 100;
        uint256 p2 = address(this).balance * 19 / 100;
        uint256 p3 = address(this).balance * 16 / 100;
        uint256 p4 = address(this).balance * 1 / 25;
        uint256 p5 = address(this).balance * 7 / 200;

        require(payable(0xCfCF8357Df8f7D7C84a218312F815d3abBd11eb9).send(p1));
        require(payable(0xd926C3dC7FeCA623ab94680082c6882c9783Cdd7).send(p1));
        require(payable(0x3f2bc38758722916Fa074F9d4233cB44021f7702).send(p2));
        require(payable(0x802ca1586De059DD7713779fD89e456Fb12DA976).send(p3));
        require(payable(0x8b88130e3B6d99aC05e382C17bD28dcaD2F86D41).send(p4));
        require(payable(0xB8ad035de7A570E0198C2d2c5D825aB40f61c2B7).send(p4));
        require(payable(0xcfB2E8093438863d64735B7d71f4dcE8132B3b57).send(p4));
        require(payable(0x748864f29ab58Fcf34F2B7c79a4dadbB2CafAe51).send(p5));
        require(payable(0x3107719Bb181712a8C0ce25d7f6029efde10F90C).send(p5));
    }
}