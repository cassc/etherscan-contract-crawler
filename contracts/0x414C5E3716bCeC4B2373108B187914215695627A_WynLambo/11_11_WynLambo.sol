// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WynLambo is ERC721, Ownable { 
    
    bool public saleActive = false;
    bool public claimActive = false;

    string internal baseTokenURI;

    uint public price = 0.09 ether;
    uint public totalSupply = 9999;
    uint public mintSupply = 7242;
    uint public claimSupply = 2706;
    uint public nonce = 0;
    uint public maxTx = 20;
    
    mapping(address => uint[]) private ownership;
    mapping(address => uint) public holders;
    mapping(address => mapping(uint => uint)) internal blockMints;
    
    event Mint(address owner, uint qty);
    event Withdraw(uint amount);
    
    struct Holders {
        address wallet;
        uint qty;
    }
    
    modifier onlyHolders() {
        require(holders[_msgSender()] > 0, "ONLY HOLDERS");
        _;
    }
    
    constructor() ERC721("WynLambo", "WYN") {}
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }

    function setMintSupply(uint newSupply) external onlyOwner {
        mintSupply = newSupply;
    }

    function setClaimSupply(uint newSupply) external onlyOwner {
        claimSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
    }
    
    function getTokenIdsByOwner(address _owner) public view returns(uint[] memory) {
        return ownership[_owner];
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
    function buy(uint qty) external payable {
        require(saleActive, 'Sale is not active');
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        require(mintSupply >= qty, "Sold out");
        mintSupply -= qty;
        _create(_msgSender(), qty);
        emit Mint(_msgSender(), qty);
    }
    
    function addHolders(address[] calldata holders_, uint[] calldata qty) external onlyOwner {
        for(uint i=0; i< holders_.length; i++){
            holders[holders_[i]] = qty[i];
        }
    }
    
    function claim() external onlyHolders {
        require(claimActive, 'Claim is not active');
        uint qty = holders[_msgSender()];
        require(claimSupply > qty, "Claim over");
        require(nonce + qty <= totalSupply, "sold out");
        holders[_msgSender()] = 0;
        claimSupply -= qty;
        _create(_msgSender(), qty);
    }
    
    function giveaway(address to, uint qty, bool fromHolders) external onlyOwner {
        require(nonce + qty <= totalSupply, "sold out");
        if(fromHolders){
             require(claimSupply >= qty, "Claim over");
             claimSupply -= qty;
        }
        _create(to,qty);
        
    }
    
    function _create(address to, uint qty) internal {
        for(uint i = 0; i < qty; i++){
            nonce++;
            _safeMint(to, nonce);
        }
    }

    function withdrawTeam() external onlyOwner {
        uint balance = address(this).balance;
        payable(0x23A8b7F4cf5FB0D40Aa7DB57b8cd376d3332130e).transfer((balance * 40 )/100);
        payable(0x268F5Fa2aDeB3a904FA60D4FfB904738F0dfE3b4).transfer((balance * 15 )/100);
        payable(0xBcdc5969Ec1652Bf80fc15edFE50f9834a55067b).transfer((balance * 20 )/100);
        payable(0x9bad8C60d464c23C2BDF164C2fE42F85C9A000F2).transfer((balance * 25 )/100);
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if(from != address(0)){
            uint[] memory tokens = ownership[from];
            for(uint i=0;i<tokens.length;i++){
                if(tokens[i] == tokenId){
                    delete ownership[from][i];
                    break;
                }
            }
        }
        if(to != address(0)){
            ownership[to].push(tokenId);
        }
    }
    
}