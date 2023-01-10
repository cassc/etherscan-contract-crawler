// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//    __    __  __      ____  ____   __   __ _  ____ 
//   (  )  (  )(  )    (  _ \(  __) / _\ (  ( \(__  )
//   / (_/\ )( / (_/\   ) _ ( ) _) /    \/    / / _/ 
//   \____/(__)\____/  (____/(____)\_/\_/\_)__)(____)


contract LilBeanz is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI = "ipfs://QmNsjDB9p5zgFHpNyfPUZRc97DRJxyQ4mbDsx2uTkQT4CU/";
    string public uriSuffix = ".json";

    uint256 public maxSupply = 4669;
    uint256 public mintPrice = 0.0029 ether;
    uint256 public mintLimit = 6;
    uint256 public limitFreeSupply = 2669;
    uint256 public freeMintLimit = 1;
    bool public mintPaused = true;

    address founder = 0xA519f3171BF012ca82aB6d95eE59eccc52dF985a;
    address dev = 0xdb30B78947e8D0B9E8e10280267c0561Eb580Ff1;

    mapping (address => uint256) public addressFreeMintCount;
    mapping (address => uint256) public addressMintCount;

    constructor(
    ) ERC721A("Lil Beanz", "LILBEANZ") {
        _safeMint(founder, 1);
    }

    function mintTeam(uint256 qty) external onlyOwner {
        _safeMint(founder, qty);
    }

    function mint(uint256 qty) external payable {
        require(!mintPaused, "Public sale paused");
        require(qty > 0 && qty <= mintLimit, "Invalid quantity");
        require(tx.origin == msg.sender, "Caller is a contract");
        require(addressMintCount[msg.sender] + qty <= mintLimit, "Max mint per wallet reached");
        require(totalSupply() + qty <= maxSupply, "Max supply reached");

        uint256 totalCost;

        if (totalSupply() <= limitFreeSupply) {

            uint256 freeMintsRemaining = freeMintLimit - addressFreeMintCount[msg.sender];
        
            if (freeMintsRemaining >= qty) {
                totalCost = 0;
                freeMintsRemaining -= qty;
            } else {
                totalCost = mintPrice * (qty - freeMintsRemaining);
                freeMintsRemaining = 0;
            }

            addressFreeMintCount[msg.sender] = freeMintLimit - freeMintsRemaining;

        } else {
            totalCost = mintPrice * qty;
        }

        require(msg.value >= totalCost, "Not enough ETH");

        addressMintCount[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function withdraw() public payable onlyOwner() {
      uint256 balanceContract = address(this).balance;
      require(balanceContract > 0, "Sales Balance = 0");

      uint256 balance1 = balanceContract / 10;
      uint256 balance2 = balanceContract*9 / 10;

      _withdraw(dev, balance1);
      _withdraw(founder, balance2);

    }

    function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
    }

    function toggleMintPaused() external onlyOwner {
        mintPaused = !mintPaused;
    }

    function setFreeMintLimit(uint256 _freeMintLimit) external onlyOwner {
        freeMintLimit = _freeMintLimit;
    }

    function setFreeSupplyLimit(uint256 _limitFreeSupply) external onlyOwner {
        limitFreeSupply = _limitFreeSupply;
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriSuffix))
        : "";
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}