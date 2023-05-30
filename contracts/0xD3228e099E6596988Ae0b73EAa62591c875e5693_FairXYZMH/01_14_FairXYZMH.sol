// SPDX-License-Identifier: MIT
// @ Fair.xyz dev

pragma solidity 0.8.7;

import "ERC721xyz.sol";
import "Ownable.sol";
import "Pausable.sol";
import "Ownable.sol";
import "ECDSA.sol";
import "ReentrancyGuard.sol";


contract FairXYZMH is ERC721xyz, Pausable, Ownable, ReentrancyGuard{
    
    string private _name;
    string private _symbol;

    using ECDSA for bytes32;
    
    uint256 public maxTokens;
    
    uint256 internal NFT_price;

    string private baseURI;
    bool internal lockURI;

    address public immutable ukraineAddress = 0x165CD37b4C644C2921454429E7F9358d18A45e14;

    // set this number to 0 for unlimited mints per wallet (also saves gas when minting)
    uint256 internal Max_mints_per_wallet; 

    address public interface_address;

    mapping(bytes32 => bool) private usedHashes;

    mapping(address => uint256) internal mintsPerWallet;

    constructor(uint256 price_, uint max_, string memory name_, string memory symbol_,
                        uint256 mints_per_wallet, address interface_,
                        uint256 _instant_airdrop, string memory URI_base) payable ERC721xyz(_name, _symbol) {
        NFT_price = price_;
        maxTokens = max_;
        _name = name_;
        _symbol = symbol_;
        //Set to 0
        Max_mints_per_wallet = mints_per_wallet;
        interface_address = interface_;
        baseURI = URI_base; 
        // For auction
        _mint(msg.sender, _instant_airdrop);
        _pause();
    }

    // Collection Name
    function name() override public view returns (string memory) {
        return _name;
    }

    // Collection ticker
    function symbol() override public view returns (string memory) {
        return _symbol;
    }

    // Limit on NFT sale
    modifier saleIsOpen{
        require(viewMinted() < maxTokens, "Sale end");
        _;
    }

    // Lock metadata forever
    function lock_URI() external onlyOwner {
        lockURI = true;
    }

    // Modify sale price
    function change_NFT_price(uint new_price) public onlyOwner returns(uint)
    {
        NFT_price = new_price;
        return(NFT_price);
    }
    
    // View price
    function price() public view returns (uint256) {
        return NFT_price; 
    }
    
    // modify the base URI 
    function change_base_URI(string memory new_base_URI)
        onlyOwner
        public
    {   
        require(!lockURI, "URI change has been locked");
        baseURI = new_base_URI;
    }
    
    // return Base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    // pause minting 
    function pause() public onlyOwner {
        _pause();
    }
    
    // unpause minting 
    function unpause() public onlyOwner {
        _unpause();
    }

    function change_interface(address new_address) external onlyOwner returns(address)
    {
        interface_address = new_address;
        return interface_address;
    }

    // Airdrop a token
    function airdrop(address[] memory address_, uint256 token_count) onlyOwner public returns(uint256)
    {
        require(viewMinted() + address_.length * token_count <= maxTokens, "This exceeds the maximum number of NFTs on sale!");
        for(uint256 i = 0; i < address_.length; i++) {
            _mint(address_[i], token_count);
        }
        return viewMinted();
    }

    function hashTransaction(address sender, uint256 qty, uint256 nonce, address address_) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce, address_)))
          );
          
          return hash;
    }

    // Change the maximum number of mints per wallet
    function changeMaxMints(uint256 new_MAX) onlyOwner public returns(uint256)
    {
        Max_mints_per_wallet = new_MAX;
        return(Max_mints_per_wallet);
    }
    
    // View block number
    function view_block_number() public view returns(uint256){
        return(block.number);
    }

    // View remaining mints per wallet
    function view_remaining_mints(address address_) public view returns(uint256){
        return(Max_mints_per_wallet - mintsPerWallet[address_]);
    }

    // Mint tokens
    function mint(bytes memory signature, uint256 nonce, uint256 numberOfTokens)
        payable
        public
        whenNotPaused
        saleIsOpen
        returns (uint256)
    {
        bytes32 messageHash = hashTransaction(msg.sender, numberOfTokens, nonce, address(this));
        address sign_add = IFairXYZWallets(interface_address).view_signer();
        require(messageHash.recover(signature) == sign_add, "Unrecognizable Hash");
        require(!usedHashes[messageHash], "Reused Hash");
        require(viewMinted() + numberOfTokens <= maxTokens, "This amount exceeds the maximum number of NFTs on sale!");
        require(msg.value >= NFT_price * numberOfTokens, "You have not sent the required amount of ETH");
        require(numberOfTokens <= 20, "Token minting limit per transaction exceeded");
        require(block.number <= nonce  + 20, "Time limit has passed");

        if(Max_mints_per_wallet > 0)
            require(mintsPerWallet[msg.sender] + numberOfTokens <= Max_mints_per_wallet, "Exceeds number of mints per wallet");

        _mint(msg.sender, numberOfTokens);

        usedHashes[messageHash] = true;

        if(Max_mints_per_wallet > 0)
            mintsPerWallet[msg.sender] += numberOfTokens;
        
        return viewMinted();
    }

    // view the address of the Ukraine wallet
    function view_Ukraine() view public returns(address)
        {return(ukraineAddress);}

    // anybody - withdraw contract balance to ukraineAddress
    function withdraw()
        public
        payable
        nonReentrant
    {   
        require(msg.sender == tx.origin, "Sender must be a wallet");
        uint256 bal_ = address(this).balance;
        payable(ukraineAddress).transfer(bal_);
    }
}