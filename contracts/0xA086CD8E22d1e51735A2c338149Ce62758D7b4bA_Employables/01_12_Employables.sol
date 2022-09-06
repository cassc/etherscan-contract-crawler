// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Strings.sol";
import "MerkleProof.sol";

contract Employables is ERC721A {
    uint256 public mint_status;

    uint256 public MAX_SUPPLY;
    uint256 public TEAM_SUPPLY = 150;
    uint256 public PUBLIC_SUPPLY = 250;

    address public owner;
    string private baseURI;

    uint256 public public_price;

    mapping(address => bool) public FreeMintClaimed;
    mapping(uint256 => bytes32) public FreeMintRootMap;

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        owner = msg.sender;
        setMintStatus(3);
        setMintMaxSupply(5000);
        setMintPublicPrice(69000000000000000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setMintStatus(uint256 _status) public onlyOwner {
        mint_status = _status;
    }

    function setMintMaxSupply(uint256 _max_supply) public onlyOwner {
        MAX_SUPPLY = _max_supply;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMintPublicPrice(uint256 _price) public onlyOwner {
        public_price = _price;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function setFreeMintRoot(uint256 _root, uint256 _amount) public onlyOwner {
        FreeMintRootMap[_amount] = bytes32(_root);
    }

    function isList(
        address addr,
        bytes32 merkleRoot,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function canMint(address addr, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        if (mint_status == 3) return false;
        if (mint_status == 0) return true;
        if (mint_status == 1) {
            if (isList(addr, FreeMintRootMap[1], _merkleProof)) return true;
            if (isList(addr, FreeMintRootMap[2], _merkleProof)) return true;
        }
        if (mint_status == 2) {
            if (isList(addr, FreeMintRootMap[2], _merkleProof)) return true;
        }
        return false;
    }

    function claim(bytes32[] calldata _merkleProof, uint256 amount) public {
        require(
            totalSupply() + amount <=
                (MAX_SUPPLY - TEAM_SUPPLY - PUBLIC_SUPPLY),
            "This will exceed the total supply."
        );
        require(
            canMint(msg.sender, _merkleProof),
            "You are not allowed to claim"
        );
        require(!FreeMintClaimed[msg.sender], "Address has already claimed.");
        _safeMint(msg.sender, amount);
        FreeMintClaimed[msg.sender] = true;
    }

    function mint(bytes32[] calldata _merkleProof, uint256 amount)
        external
        payable
    {
        require(
            canMint(msg.sender, _merkleProof),
            "You are not allowed to mint"
        );
        require(
            amount <= 3,
            string(abi.encodePacked("The maximum amount of NFT per Tx is 3"))
        );
        require(
            totalSupply() + amount <= MAX_SUPPLY - TEAM_SUPPLY,
            "This will exceed the total supply."
        );
        require(msg.value >= amount * public_price, "Not enought ETH sent");
        _safeMint(msg.sender, amount);
    }

    function giveaway(address[] calldata _to, uint256 amount)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], amount);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}