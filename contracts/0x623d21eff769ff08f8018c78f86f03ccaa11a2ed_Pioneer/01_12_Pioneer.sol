// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Counters.sol";
import "Strings.sol";
import "MerkleProof.sol";

contract Pioneer is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    uint256 totalMinted;
    bool public reveal = false;
    uint256 public constant totalSupply = 1000;
    address public owner = msg.sender;
    string private baseURI_;
    string private blindURI_ =
        "ipfs://QmerxvxsCLmoLozg3k1LgavkPin85WTWHuoUchXpi4XuhL";
    mapping(address => bool) public mintClaimed;
    mapping(uint256 => bytes32) public rootMap;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function revealNow() external onlyOwner {
        reveal = true;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI_ = _uri;
    }

    function setBlindURI(string memory _uri) external onlyOwner {
        blindURI_ = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    function _blindURI() internal view virtual returns (string memory) {
        return blindURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!reveal) {
            return string(abi.encodePacked(_blindURI()));
        } else {
            return
                string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
        }
    }

    function setRoot(uint256 _root, uint256 _amount) public onlyOwner {
        rootMap[_amount] = bytes32(_root);
    }

    function mint(bytes32[] calldata _merkleProof, uint256 amount) public {
        require(
            totalMinted + amount <= totalSupply,
            "This will exceed the total supply."
        );
        require(!mintClaimed[msg.sender], "Address has already claimed.");
        bytes32 merkleRoot = rootMap[amount];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "You are not allowed to mint."
        );
        if (amount == 0) {
            amount = 1;
        }
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
            totalMinted++;
        }
        mintClaimed[msg.sender] = true;
    }

    function mintByOwner(address _to, uint256 amount) public onlyOwner {
        require(
            totalMinted + amount <= totalSupply,
            "This will exceed the total supply."
        );
        for (uint256 i = 0; i < amount; i++) {
            _mint(_to, _tokenIds.current());
            _tokenIds.increment();
            totalMinted++;
        }
        mintClaimed[_to] = true;
    }

    function getTotalMinted() public view returns (uint256) {
        return totalMinted;
    }
}