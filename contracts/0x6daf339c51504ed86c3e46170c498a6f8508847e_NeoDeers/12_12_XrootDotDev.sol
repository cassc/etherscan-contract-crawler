pragma solidity 0.8.14;
// SPDX-License-Identifier: MIT
import "./ERC721A.sol";
import "./Ownable.sol";

contract NeoDeers is ERC721A, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public publicCost = 0.003 ether;
    bool public paused = false;
    uint256 public maxPublic = 10;
    uint256 public maxAmount = 10;
    uint256 public maxSupply = 3000;
    string public UnrevealedURI;
    bool public revealed = false;
    uint256 public freeQuantity = 300;
    uint256 public startTime = 1654185600;

    constructor() ERC721A("NeoDeers", "NEODEERS") {
        setBaseURI("ipfs://QmbAqLZxkmPP6kg1Wp2yiDNSBtmZ3zEeWsmbvnFEot3pfc/");
        setUnrevealedUri("ipfs://QmUdQTNBSBSsthDKk4MKXNrLJCCryo4RE4coPrXJX1c8h4/");
    }

    function mint(uint256 quantity) external payable {
        uint256 supply = totalSupply();
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        require(supply + quantity <= maxSupply, "Max Supply Reached");

        if (msg.sender != owner()) {
            require(block.timestamp >= startTime , "Mint didn't start yet");
            require(balanceOf(msg.sender) + quantity <= maxAmount , "youre not allowed to hold that much");
            require(
                quantity <= maxPublic,
                "You're Not Allowed To Mint more than maxMint Amount"
            );
            if(supply + quantity >= freeQuantity && supply >= freeQuantity){
                require(msg.value >= publicCost * quantity, "Insufficient Funds");
            }else{
                require(supply + quantity <= freeQuantity , "Please try with a lower amount to get it for free");
            }
        }
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
            return UnrevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function Set(uint256 _publicCost, uint256 _publicMax , uint256 _maxAmount) public onlyOwner {
        publicCost = _publicCost;
        maxPublic = _publicMax;
        maxAmount = _maxAmount;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setFreeQuantity(uint256 _freeQuantity) public onlyOwner {
        freeQuantity = _freeQuantity;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setUnrevealedUri(string memory _UnrevealedUri) public onlyOwner {
        UnrevealedURI = _UnrevealedUri;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public onlyOwner {
        (bool ts, ) = payable(owner()).call{value: address(this).balance}("");
        require(ts);
    }
}
