// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 

contract ZeroXZeroFactory is ERC721, ERC721URIStorage, Ownable { 
    
    bool public presaleActive = true;
    bool public saleActive = false;
    bool public claimActive = true;

    string internal baseTokenURI = "https://0x0.gg/metadata/NSS/";

    uint public presalePrice = 0 ether;
    uint public price = 0 ether;
    uint public mintSupply = 36;
    uint public claimSupply = 33;
    uint public nonce = 0;
    uint public maxTx = 1;
    address public signerAddress = 0x82078e077526409D7057d533bD9eb722ea8Da2F2;
    
    mapping(address => uint[]) private ownership;
    mapping(address => uint) public holders;
    mapping(address => mapping(uint => uint)) internal blockMints;
    mapping(bytes => bool) public _ticketUsed;
    
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
///////////
    constructor() ERC721("Neon Steam Soundtracks", "NSS") {}

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
///////////////    
    
    function setPresalePrice(uint newPrice) external onlyOwner {
        presalePrice = newPrice;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
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

    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
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
/////////////// Presale
    function presale(
        bytes memory _ticket,
        bytes memory _signature,
        uint qty
    ) public payable {
        require(!_ticketUsed[_ticket], "ticket has already been used");

        require(
            isAuthorized(
                msg.sender,
                _ticket,
                _signature,
                signerAddress
            ),
            "WL authorization failed"
        );
        require(presaleActive, 'presale is not active');
        require(qty <= maxTx || qty < 1, "TX: qty of mints not allowed");
        require(msg.value == presalePrice * qty, "PAYMENT: invalid value");
        require(mintSupply >= qty, "Sold out");
        mintSupply -= qty;
        _create(_msgSender(), qty);
        emit Mint(_msgSender(), qty);
        _ticketUsed[_ticket] = true;
    }
    using ECDSA for bytes32;
    function isAuthorized(
        address sender, 
        bytes memory ticket, 
        bytes memory signature,
        address _signerAddress 
    ) private pure returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(ticket, sender));
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();
        return _signerAddress == ethSignedHash.recover(signature);
    }
/////////////// Public Sale        
    function buy(uint qty) external payable {
        require(saleActive, 'Sale is not active');
        require(qty <= maxTx || qty < 1, "TX: qty of mints not allowed");
        require(msg.value >= price * qty, "PAYMENT: invalid value");
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
        require(claimSupply >= qty, "Claim over");
        holders[_msgSender()] = 0;
        claimSupply -= qty;
        _create(_msgSender(), qty);
    }
    
    function giveaway(address to, uint qty, bool fromHolders) external onlyOwner {
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
        payable(0x84FEf9a9D40C27bc6C269EC9227B5451F495EF34).transfer((balance * 70 )/100);
        payable(0x9612460DC35a7261c6FdB193A722cFb2dA2E5b3c).transfer((balance * 30 )/100);
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