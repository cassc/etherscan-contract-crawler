// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

//   ████████╗██╗  ██╗███████╗    ██╗  ██╗██╗██╗   ██╗███████╗
//   ╚══██╔══╝██║  ██║██╔════╝    ██║  ██║██║██║   ██║██╔════╝
//      ██║   ███████║█████╗      ███████║██║██║   ██║█████╗  
//      ██║   ██╔══██║██╔══╝      ██╔══██║██║╚██╗ ██╔╝██╔══╝  
//      ██║   ██║  ██║███████╗    ██║  ██║██║ ╚████╔╝ ███████╗
//      ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝
//  =============================================================

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HivePass is ERC1155Supply, Ownable
{
    bool public saleIsActive = false;
    uint public maxPerTransaction = 1;
    
    uint256 private constant FOUNDERS_PASS = 1;
    uint256 private constant ALPHA_PASS = 2;
    uint256 public maxFoundersPasses = 35;
    uint256 public maxAlphaPasses = 200;
    uint256 public currentFoundersPassCount = 0;
    uint256 public currentPassCount = 0;

    uint256 public FOUNDERS_PRICE = 330000000000000000; // 0.33 ETH
    uint256 public PASS_PRICE = 70000000000000000; // 0.07 ETH
    string public name = "Hive Alpha"; // Token name

    string public contractURIstr = "";

    mapping(address => uint8) private _passAllowList;
    mapping(address => uint8) private _foundersAllowList;
    
    constructor() ERC1155("ipfs://QmbkF9GCKZaQr1rw97EBViJzGSUbu5tFyDEEdFu1sGUj5Q/{id}") {} // this is your URI function which is inputed when contract is deployed, this is linked to the metadata share link that's uploaded on IPFS

    function contractURI() public view returns (string memory)
    {
       return contractURIstr;
    }

    function setContractURI(string memory newuri) external onlyOwner
    {
       contractURIstr = newuri;
    }

    function setURI(string memory newuri) external onlyOwner
    {
        _setURI(newuri);
    }

    function setName(string memory _name) public onlyOwner
    {
        name = _name;
    }

    function getName() public view returns (string memory)
    {
       return name;
    }

    function setPassAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _passAllowList[addresses[i]] = numAllowedToMint;
        }
    }

    function setFoundersAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _foundersAllowList[addresses[i]] = numAllowedToMint;
        }
    }

    function passesAvailableToMint(address addr) external view returns (uint8) {
        return _passAllowList[addr];
    }
    function foundersAvailableToMint(address addr) external view returns (uint8) {
        return _foundersAllowList[addr];
    }

    function mintToken(uint8 tokenId, uint8 amount) external payable //This function is for Public Mint Parameters and Error Messages
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint"); //Error displays if sale is not active
        require(amount > 0 && amount <= maxPerTransaction, "Max per transaction reached, sale not allowed"); //Error displays if user mints more than max per transaction set
                               
        require(tokenId == FOUNDERS_PASS ? currentFoundersPassCount + 1 <= maxFoundersPasses : currentPassCount + 1 <= maxAlphaPasses, "Max supply");
        require(tokenId == FOUNDERS_PASS || tokenId == ALPHA_PASS, "Bad ID");
        require(msg.value >= getPassPrice(tokenId) * amount, "Wrong amount of ETH"); //Error if not enough ETH to complete

        if(tokenId == FOUNDERS_PASS) {
            require(amount <= _foundersAllowList[msg.sender], "Exceeded max available to purchase");
            currentFoundersPassCount += amount;
            _foundersAllowList[msg.sender] -= amount;
        }
        else
        {
            require(amount <= _passAllowList[msg.sender], "Exceeded max available to purchase");
            currentPassCount  += amount;
            _passAllowList[msg.sender] -= amount;
        }

        _mint(msg.sender, tokenId, amount, "");
    }


    function ownerMint(address[] calldata addresses, uint256 tokenId, uint256 amount) external onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            tokenId == FOUNDERS_PASS ? currentFoundersPassCount += amount : currentPassCount += amount;
            _mint(addresses[i], tokenId, amount, "");
        }
    }

    function withdraw() external
    {
        require(msg.sender == owner(), "Invalid sender");

        payable(owner()).transfer(address(this).balance);
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function changeSaleDetails(uint tokenId, uint _price, uint _maxSupply) external onlyOwner
    {
        if(tokenId == FOUNDERS_PASS) {
            maxFoundersPasses = _maxSupply;
            FOUNDERS_PRICE = _price;
        }
        else
        {
            maxAlphaPasses = _maxSupply;
            PASS_PRICE = _price;
        }
        
        saleIsActive = false;
    }

    function getPassTotalSupply(uint tokenId) public view returns (uint256) {
        if(tokenId == FOUNDERS_PASS) {
            return maxFoundersPasses;
        }
        return maxAlphaPasses;
    }
    
    function getPassSupply(uint tokenId) public view returns (uint256) {
        if(tokenId == FOUNDERS_PASS) {
            return currentFoundersPassCount;
        }
        return currentPassCount;
    }
    
    function getPassPrice(uint tokenId) public view returns (uint256) {
        if(tokenId == FOUNDERS_PASS) {
            return FOUNDERS_PRICE;
        }
        return PASS_PRICE;
    }
    
    function setPassPrice(uint tokenId, uint price) external onlyOwner {
        if(tokenId == FOUNDERS_PASS)
            FOUNDERS_PRICE = price;
        else
            PASS_PRICE = price;
    }

}