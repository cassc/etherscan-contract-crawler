//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SSWW is
    ERC721A,
    Ownable,
    ReentrancyGuard
{
    string private baseURI = "";
    string private constant baseExtension = ".json";
    
    uint256 public MAX_SUPPLY = 10000;
    uint256 public price = 3 ether;
    bool public paused = false;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function mint(uint256 _amount) external payable {
        address _caller = msg.sender;
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        uint256 tradePrice = currentPrice(_amount);
        if (_caller != owner()) {
            require(tradePrice == msg.value, "Invalid funds provided");
        }

        _safeMint(_caller, _amount);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        return super.isApprovedForAll(owner, operator);
    }

    function currentPrice(uint256 _amount) public view returns (uint256) {
        uint256 mintPrice = price * _amount;
        return mintPrice;
    }

    function withdraw() external onlyOwner nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setPrice(uint256 _newCost) public onlyOwner {
        price = _newCost;
    }


    function setupOS() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
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

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }
}