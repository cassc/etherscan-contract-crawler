//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// File contracts/test.sol

contract othergoblinzwtf is ERC721A, Ownable {
    string private baseURI = "";
    string private constant baseExtension = ".json";
    string private notRevealedUri;    
    uint256 public MAX_PER_TX = 20;    
    uint256 public MAX_SUPPLY = 6969;    
    uint256 public price = 0.005 ether;
    uint256 public maxFreeMints = 2;
    bool public paused = true;
    bool public revealed = false;
    uint256 public freeMints = 1000;
    address public constant devAddress = 0x766Fa8C0B05B886B0C9A38931818142217613fD2;
    address public constant teamAddress =  0xE7756Cc7210bA26d6A8698a6764E1a5849900489;

    

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
        
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);

    }

    function mint(uint256 _amount) external payable {
        address _caller = msg.sender;
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        uint256 callerBalance = balanceOf(msg.sender);
        uint256 currSupply = totalSupply();
        if (_caller != owner()) {
            
                if (currSupply > freeMints) {
                    require(_amount * price == msg.value, "Invalid funds provided");
                
                } else  if (currSupply <= freeMints){
                    require(callerBalance + _amount <= maxFreeMints,'exceeds free mints');
                }
                require(MAX_PER_TX >= _amount, "Exceeds max Per Transaction");
            
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

    function maxMintAmount() public view returns (uint256) {      
            return MAX_PER_TX;
        
    }

    function getDevHex() public pure returns (string memory) {
        return "0x636865657a636861726d6572";
    }

    function currentPrice() public view returns (uint256) {
            if (totalSupply() > freeMints) {
                return price;
            } else {
                return 0;
            }
    }
    

    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 teamShare = (totalBalance * 20)/100;
        uint256 devShare = (totalBalance * 20 )/100;
        payable(devAddress).transfer(devShare);
        payable(teamAddress).transfer(teamShare);
        payable(msg.sender).transfer(address(this).balance);

    }

    function setPrice(uint256 _newCost) public onlyOwner {
        price = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        MAX_PER_TX = _newmaxMintAmount;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {        
            price = _newPrice;
        
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

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
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
            return notRevealedUri;
        }

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