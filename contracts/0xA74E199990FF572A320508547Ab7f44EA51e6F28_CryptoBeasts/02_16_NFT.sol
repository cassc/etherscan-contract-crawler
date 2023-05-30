pragma solidity ^0.7.3;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
    using SafeMath for uint256;
    
    bool[10000] public _locations;

    string public _provenance_hash = "";
    uint256 public _price = 0; 
    uint256 public _max_supply = 0; 
    string public _baseURI = "";
    uint256 public _initial_purchase_index = 0;
    uint256 public _current_purchase_index = 0;
    address public _owner;

    constructor(string memory name, string memory symbol, string memory provenance_hash, uint256 price, uint256 max_supply, uint256 initial_purchase_index, string memory base_uri) ERC721(name, symbol) {
        _owner = msg.sender;
        
        _provenance_hash = provenance_hash;
        _price = price;
        _max_supply = max_supply;
        
        _initial_purchase_index = initial_purchase_index;
        _current_purchase_index = initial_purchase_index;
       
        updateBaseTokenURI(string(abi.encodePacked(base_uri)));
    }

    function update(string memory provenance_hash, uint256 price, uint256 max_supply, uint256 initial_purchase_index, uint256 current_purchase_index, string memory base_uri) public onlyOwner {
        _provenance_hash = provenance_hash;
        _price = price;
        _max_supply = max_supply; 
        
        _initial_purchase_index = initial_purchase_index;
        _current_purchase_index = current_purchase_index;

        updateBaseTokenURI(string(abi.encodePacked(base_uri)));
    }

    function updateBaseTokenURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
        _baseURI = baseURI;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
    function ownerMint(uint tokenId) public onlyOwner {
        _secureMint(msg.sender, tokenId);
    }
    
    function ownerMint(uint[] memory tokenIds) public onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            _secureMint(msg.sender, tokenId);
        }
    }
    
    function ownerMint(uint tokenId, address to) public onlyOwner {
        _secureMint(to, tokenId);
    }
    
    function ownerMint(uint[] memory tokenIds, address to) public onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            _secureMint(to, tokenId);
        }
    }
    
    function purchaseToken(uint tokenId) public payable {
        require(tokenId >= _initial_purchase_index, "Token index out of bounds");
        require(_price <= msg.value, "Ether value sent is not correct");
        
        _secureMint(msg.sender, tokenId);
    }
    
    function purchaseTokens(uint[] memory tokenIds) public payable {
        require(_price.mul(tokenIds.length) <= msg.value, "Ether value sent is not correct");
        
        for (uint i = 0; i < tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            
            require(tokenId >= _initial_purchase_index, "Token index out of bounds");
            _secureMint(msg.sender, tokenId);
        }
    }
    
    function purchaseNextToken() public payable {
        purchaseNextTokens(1);
    }
    
    function purchaseNextTokens(uint numberOfTokens) public payable {
         require(_price.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
         require(totalSupply().add(numberOfTokens) <= _max_supply, "Minting would exceed max supply");
         
         uint tokensMinted = 0;
     
         for(uint i = _current_purchase_index; i < _max_supply; i++) {
             if (tokensMinted == numberOfTokens){
                 break;
             }
             else if (!_exists(i)){
                _secureMint(msg.sender, i);
                tokensMinted += 1;
                _current_purchase_index = i;
             }
         }
         
         require(tokensMinted == numberOfTokens, "Not enough tokens to mint");
    }
    
    function claimTokenForAddress(uint256 tokenId, bytes memory sig) public{
        require(verifySignature(tokenId, sig, true));
        
        _secureMint(msg.sender, tokenId);
    }
    
    function claimTokenNoAddress(uint256 tokenId, bytes memory sig) public {
        require(verifySignature(tokenId, sig, false));
        
        _secureMint(msg.sender, tokenId);
    }
    
    function _secureMint(address to, uint256 tokenId) internal virtual {
        require(tokenId < _max_supply, "Token index out of bounds");
        require(tokenId >= 0, "Token index out of bounds");
        
        _mint(to, tokenId);
        _locations[tokenId] = true;
    }

    function verifySignature(uint256 tokenId, bytes memory sig, bool addr) internal view returns (bool)
    {
        bytes32 message;
        
        if (addr){
            message = prefixed(keccak256(abi.encodePacked(tokenId, msg.sender)));
        }
        else{
            message = prefixed(keccak256(abi.encodePacked(tokenId)));
        }
        
        address signer = recoverSigner(message, sig);

        return signer == _owner;
    }

    // Signature methods
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    function getBaseURI() public view returns (string memory) {
        return _baseURI;
    }

    function getProvenanceHash() public view virtual returns (string memory) {
        return _provenance_hash;
    }

    function getPrice() public view virtual returns (uint256) {
        return _price;
    }

    function getMaxSupply() public view virtual returns (uint256) {
        return _max_supply;
    }
    
    function getLocations() public view virtual returns (bool[10000] memory) {
        return _locations;
    }
    
}