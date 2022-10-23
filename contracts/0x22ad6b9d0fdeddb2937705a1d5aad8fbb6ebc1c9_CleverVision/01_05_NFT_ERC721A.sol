pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";

contract CleverVision is ERC721A, Ownable {
    mapping(address => uint256) public Claimed;
    string public baseURI;
    uint256 public publicCost = 0.003 ether;
    bool public paused = true;
    string public UnrevealedURI;
    bool public revealed = false;
    uint256 public free = 5;
    uint256 public maxSupply = 10000;

    constructor() ERC721A("CleverVision", "CLEVERS") {
        setUnrevealedUri("ipfs://bafybeib4hdl66dgt2kxwys2mustda4ezfxuyy3oey5souekarwvm4h2kcu/");
        ownerMint(1);
    }


    function mint(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        uint256 claimed = Claimed[msg.sender];
        require(!paused, "The contract is paused!");
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        if (claimed < free){
            if(quantity > free){
            uint256 newQuantity = quantity - free;
            require(msg.value >= publicCost * newQuantity, "Insufficient Funds");
            }
        }else{
            require(msg.value >= publicCost * quantity, "Insufficient Funds");
        }

        Claimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "Max Supply Reached");
        _safeMint(msg.sender, quantity);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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

        if (revealed == false) {
            return
                bytes(UnrevealedURI).length > 0
                    ? string(
                        abi.encodePacked(
                            UnrevealedURI,
                            _toString(tokenId)
                        )
                    )
                    : "";
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId)
                    )
                )
                : "";
    }

    function Set(uint256 _publicCost , uint256 _freeAmount)
        public
        onlyOwner
    {
        publicCost = _publicCost;
        free = _freeAmount;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setUnrevealedUri(string memory _UnrevealedUri) public onlyOwner {
        UnrevealedURI = _UnrevealedUri;
    }


    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public onlyOwner {
        (bool ts, ) = payable(owner()).call{value: address(this).balance}("");
        require(ts);
    }
}