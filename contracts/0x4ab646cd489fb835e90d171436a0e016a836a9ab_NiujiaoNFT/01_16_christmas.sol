// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NiujiaoNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    address public minter;
    uint public curEvent;

    struct _event {
        uint price;
        uint kickoff;
        uint deadline;
        uint startId;
        uint endId;
        bytes32 root;
        bool whitelist;
    }

    _event[] events;
    mapping (address => bool)[] minted;

    constructor(string memory initBaseURI)
        ERC721("Niujiao Christmas", "NJXMAS")
    {
        setBaseURI(initBaseURI);
    }

    function isMinted(uint eventId, address user) public view returns (bool) {
        require(eventId < events.length, "event not found");
        return minted[eventId][user];
    }
    
    function mint(bytes32[] calldata merkleProof) public payable nonReentrant {

        if(events[curEvent].whitelist) {
            require(
                MerkleProof.verify(
                    merkleProof,
                    events[curEvent].root,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "Address does not exist in list"
            );
            require(minted[curEvent][msg.sender] == false, "minted");
            minted[curEvent][msg.sender] = true;
        }

        if(events[curEvent].price == 0 && !events[curEvent].whitelist) {
            require(minted[curEvent][msg.sender] == false, "minted");
            minted[curEvent][msg.sender] = true;
        }

        require(msg.value >= events[curEvent].price, "!price");
        require(block.timestamp >= events[curEvent].kickoff, "!kickoff");
        require(block.timestamp <= events[curEvent].deadline, "!deadline");
        uint index = totalSupply() + 1;
        require(index >= events[curEvent].startId, "!startId");
        require(index <= events[curEvent].endId, "!endId");

        _mintNFT(1);
    }

    function _mintNFT(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
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

        string memory base = _baseURI();

        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //only owner
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function addEvent(uint _price, uint _kickoff, uint _deadline, uint _startId, uint _endId, bytes32 _root, bool _whitelist) public onlyOwner {
        events.push(
            _event({
                price: _price,
                kickoff: _kickoff,
                deadline: _deadline,
                startId: _startId,
                endId: _endId,
                root: _root,
                whitelist: _whitelist
            }));
        minted.push();
    }

    function setCurrentEvent(uint _curEvent) public onlyOwner {
        curEvent = _curEvent;
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    // only minter
    function minterMint(address to, uint256 mintIndex) external {
        require( msg.sender == minter, "!minter");
        _mint(to, mintIndex);
    }
}