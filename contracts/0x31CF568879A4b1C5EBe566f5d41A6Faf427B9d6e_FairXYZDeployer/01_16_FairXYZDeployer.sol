// SPDX-License-Identifier: MIT

// @ Fair.xyz dev

pragma solidity 0.8.7;

import "ERC721xyz.sol";
import "IFairXYZWallets.sol";
import "Pausable.sol";
import "ECDSA.sol";
import "Ownable.sol";

contract FairXYZDeployer is ERC721xyz, Pausable, Ownable{
    
    using ECDSA for bytes32;

    // Collection Name and ticker
    string private _name;
    string private _symbol;

    
    // Max number of tokens on sale
    uint256 public maxTokens;
    
    // Price per NFT
    uint256 internal nftPrice;

    // URI information
    string private baseURI;
    string private pathURI;
    string public preRevealURI;
    string private _overrideURI;
    bool public lockURI;

    // Bool to allow signature-less minting
    bool public mintReleased;

    // Interface into FairXYZWallets
    address public interfaceAddress;

    bool public isBase;

    // Burnable token bool
    bool public burnable;

    // Maximum number of mints per wallet
    uint256 public maxMintsPerWallet;
    mapping(address => uint256) public mintsPerWallet;

    // Royalty information
    address internal _primaryRoyaltyReceiver; 
    address internal _secondaryRoyaltyReceiver; 
    uint96 internal _secondaryRoyaltyValue;

    // Hash storage
    mapping(bytes32 => bool) private usedHashes;

    event NewPriceSet(uint256 newSetPrice);
    event NewMaxMintsPerWalletSet(uint256 newMaxMints);
    event NewTokenRoyaltySet(uint256 newRoyalty);
    event NewRoyaltyPrimaryReceiver(address newPrimaryReceiver);
    event NewRoyaltySecondaryReceiver(address newSecondaryReceiver);
    event NewTokenURI(string newTokenURI);
    event NewPathURI(string newPathURI);

    constructor() payable ERC721xyz(_name, _symbol){
        isBase = true;
        _name = "FairXYZ";
        _symbol = "FairXYZ";
        _pause();
        renounceOwnership();
    }
 
    /**
     * @dev Return Collection Name
     */
    function name() override public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Return Collection Ticker
     */
    function symbol() override public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Return list of contract variables
     */
    function viewAllVariables() public view returns(uint256, uint256, string memory){
        return(nftPrice, maxMintsPerWallet, pathURI);
    }

    /**
     * @dev View signer wallet for minting and variable overrides
     */
    function viewSigner() public view returns(address){
        address returnSigner = IFairXYZWallets(interfaceAddress).viewSigner(); 
        return(returnSigner);
    }

    /**
     * @dev Returns the wallet of Fair.xyz
     */
    function viewWithdraw() public view returns(address){
        address returnWithdraw = IFairXYZWallets(interfaceAddress).viewWithdraw(); 
        return(returnWithdraw);
    }

    /**
     * @dev Initialise a new Creator contract using proxy
     */
    function initialize(uint256 maxTokens_, uint256 nftPrice_, string memory name_, string memory symbol_,
                        bool burnable_, uint256 maxMintsPerWallet_, address interfaceAddress_,
                        string[] memory URIs_, uint96 royaltyPercentage_, address[] memory royaltyReceivers) external {
        
        require( !isBase , "This contract is not a base contract!");
        require( interfaceAddress_ != address(0), "Cannot set to 0 address!");
        _transferOwnership(tx.origin);
        maxTokens = maxTokens_;
        nftPrice = nftPrice_;
        _name = name_;
        _symbol = symbol_;
        burnable = burnable_; 
        maxMintsPerWallet = maxMintsPerWallet_;
        interfaceAddress = interfaceAddress_;
        preRevealURI = URIs_[0];
        baseURI = URIs_[1];
        pathURI = URIs_[2];
        isBase = true;
        _primaryRoyaltyReceiver = royaltyReceivers[0];
        _secondaryRoyaltyReceiver = royaltyReceivers[1];
        _secondaryRoyaltyValue = royaltyPercentage_;
        _setDefaultRoyalty(_secondaryRoyaltyReceiver, _secondaryRoyaltyValue);
    }

    /**
     * @dev Ensure number of minted tokens never goes above the sale limit
     */
    modifier saleIsOpen{
        require(_mintedTokens < maxTokens, "Sale end");
        _;
    }

    /**
     * @dev Lock the token metadata forever
     */
    function lockURIforever() external onlyOwner {
        lockURI = true;
    }
    
    /**
     * @dev View Token price
     */
    function price() external view returns (uint256) {
        return nftPrice; 
    }

    /**
     * @dev Hash the variables to be modified
     */
    function hashVariableChanges(address sender, string memory newURI, string memory newPathURI, 
        uint256 newPrice, uint256 newMaxMintsPerWallet, uint256 newRoyaltyPercentage) private pure returns(bytes32) 
    {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, newURI, newPathURI, newPrice, newMaxMintsPerWallet, newRoyaltyPercentage)))
          );    
          return hash;
    }

    /**
     * @dev Override royalty receivers
     */
    function changeRoyaltyReceivers(address newPrimaryRoyaltyReceiver, address newSecondaryRoyaltyReceiver, uint96 newRoyaltyValue) 
        external onlyOwner
    {
        bool requiresSecondaryChange; 

        if(_primaryRoyaltyReceiver != newPrimaryRoyaltyReceiver)
        {
            _primaryRoyaltyReceiver = newPrimaryRoyaltyReceiver;

            emit NewRoyaltyPrimaryReceiver(_primaryRoyaltyReceiver);
        }

        if(_secondaryRoyaltyReceiver != newSecondaryRoyaltyReceiver)
        {
            _secondaryRoyaltyReceiver = newSecondaryRoyaltyReceiver;

            requiresSecondaryChange = true;
            
            emit NewRoyaltySecondaryReceiver(_secondaryRoyaltyReceiver);
        }

        if(newRoyaltyValue != _secondaryRoyaltyValue )
        {
            _secondaryRoyaltyValue = newRoyaltyValue;

            requiresSecondaryChange = true;
            
            emit NewTokenRoyaltySet(newRoyaltyValue);
        }

        if(requiresSecondaryChange)
            _setDefaultRoyalty(_secondaryRoyaltyReceiver, _secondaryRoyaltyValue);
    }
        
     
    /**
     * @dev Override contract variables
     */
    function overrideVariables(bytes memory signature, string memory newURI, string memory newPathURI, 
        uint256 newPrice, uint256 newMaxMintsPerWallet, uint96 newRoyaltyPercentage)
        onlyOwner
        external
    {
        bytes32 messageHash = hashVariableChanges(msg.sender, newURI, newPathURI, 
                                                  newPrice, newMaxMintsPerWallet, newRoyaltyPercentage);
        address signAdd = viewSigner();
        require(messageHash.recover(signature) == signAdd, "Unrecognizable Hash");

        if(!lockURI)
        {
            if (bytes(newPathURI).length != 0)       
                pathURI = newPathURI;
                emit NewPathURI(pathURI);

            if(bytes(newURI).length != 0)
            {
                _overrideURI = newURI;
                baseURI = "";
                emit NewTokenURI(_overrideURI);
            }
        }

        if(newPrice!=nftPrice)
        {
            nftPrice = newPrice;
            emit NewPriceSet(nftPrice);
        }

        if(newMaxMintsPerWallet!=maxMintsPerWallet)
        {
            maxMintsPerWallet = newMaxMintsPerWallet;
            emit NewMaxMintsPerWalletSet(maxMintsPerWallet);
        }

        if(newRoyaltyPercentage!=_secondaryRoyaltyValue)
        {
            _secondaryRoyaltyValue = newRoyaltyPercentage;
            _setDefaultRoyalty(_secondaryRoyaltyReceiver, _secondaryRoyaltyValue);
            emit NewTokenRoyaltySet(_secondaryRoyaltyValue);
        }

    }
    
    /**
     * @dev Return the Base URI
     */
    function _baseURI() public view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Return the path URI - used for reveal experience
     */
    function _pathURI() public view override returns (string memory) {
        if(bytes(_overrideURI).length == 0)
        {
            return IFairXYZWallets(interfaceAddress).viewPathURI(pathURI);
        }
        else
        {
            return _overrideURI;
        }
    }

    /**
     * @dev Return the pre-reveal URI
     */
    function _preRevealURI() public view override returns (string memory) {
        return preRevealURI;
    }

    /**
     * @dev See the remaining mints for a wallet
     */
    function remainingMints(address minterAddress) public view returns(uint256) {
        
        if (maxMintsPerWallet == 0 ) {
            revert("Collection with no mint limit");
        }
            
        uint256 mintsLeft = maxMintsPerWallet - mintsPerWallet[minterAddress];

        return mintsLeft; 
    }
    
    /**
     * @dev Pause minting
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause minting
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Burn a token
     */
    function burn(uint256 tokenId) external returns(uint256)
    {
        require(burnable, "This contract does not allow burning");
        require(msg.sender == ownerOf(tokenId), "Burner is not the owner of token");
        _burn(tokenId);
        return tokenId;
    }

    /**
     * @dev Airdrop tokens to a list of addresses
     */
    function airdrop(address[] memory address_, uint256 tokenCount) onlyOwner external returns(uint256) 
    {
        require(_mintedTokens + address_.length * tokenCount <= maxTokens, "This exceeds the maximum number of NFTs on sale!");
        for(uint256 i = 0; i < address_.length; ) {
            _safeMint(address_[i], tokenCount);
            ++i;
        }
        return _mintedTokens;
    }

    /**
     * @dev Hash transaction data for minting
     */
    function hashTransaction(address sender, uint256 qty, uint256 nonce, uint256 phaseLimit, address address_) private pure returns(bytes32) 
    {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce, phaseLimit, address_)))
          );    
          return hash;
    }

    /**
     * @dev Mint token(s)
     */
    function mint(bytes memory signature, uint256 nonce, uint256 numberOfTokens, uint256 phaseLimit)
        payable
        external
        whenNotPaused
        saleIsOpen
        returns (uint256)
    {
        bytes32 messageHash = hashTransaction(msg.sender, numberOfTokens, nonce, phaseLimit, address(this));
        address signAdd = viewSigner();
        require(_mintedTokens < phaseLimit, "End of phase limit!");
        require(phaseLimit <= maxTokens, "Phase limit cannot be larger than max tokens");
        require(messageHash.recover(signature) == signAdd, "Unrecognizable Hash");
        require(!usedHashes[messageHash], "Reused Hash");
        require(msg.value  >= nftPrice * numberOfTokens, "You have not sent the required amount of ETH");
        require(numberOfTokens <= 20, "Token minting limit per transaction exceeded");
        require(block.number <= nonce  + 20, "Time limit has passed");
        require(msg.sender == tx.origin, "Cannot mint from contract");

        usedHashes[messageHash] = true;

        uint256 origMintCount = numberOfTokens;

        // If trying to mint more tokens than available -> reimburse for excess mints and allow for lower mint count
        // to avoid a failed tx

        if(maxMintsPerWallet > 0)
        {
            require(mintsPerWallet[msg.sender] < maxMintsPerWallet, "Exceeds number of mints per wallet");
            
            if(mintsPerWallet[msg.sender] + numberOfTokens > maxMintsPerWallet)
            {
                numberOfTokens = maxMintsPerWallet - mintsPerWallet[msg.sender];
            }            
        }
 
        if( (_mintedTokens + numberOfTokens > phaseLimit) )
        {
            numberOfTokens = phaseLimit - _mintedTokens;
        }
        
        uint256 reimbursementPrice = (origMintCount - numberOfTokens) * nftPrice;

        mintsPerWallet[msg.sender] += numberOfTokens;

        _mint(msg.sender, numberOfTokens);
        
        // cap reimbursement at msg.value in case something goes wrong
        if( 0 < reimbursementPrice && reimbursementPrice < msg.value)
        {
            (bool sent, ) = msg.sender.call{value: reimbursementPrice}("");
            require(sent, "Failed to send Ether");
        }
        
        return _mintedTokens;
    }

    /**
     * @dev Release a mint so no signature is required
     */
    function releaseMint() onlyOwner external
    {
        require(!mintReleased);
        mintReleased = true;
    }

    /**
     * @dev Mint a token with no signature - requires mint release
     */
    function mintNoSignature(uint256 numberOfTokens)
        payable
        external
        whenNotPaused
        saleIsOpen
        returns (uint256)
    {
        require(mintReleased, "Please use the mint function to buy your token");
        require(msg.value  >= nftPrice * numberOfTokens, "You have not sent the required amount of ETH");
        require(numberOfTokens <= 20, "Token minting limit per transaction exceeded");
        require(msg.sender == tx.origin, "Cannot mint from contract");

        uint256 origMintCount = numberOfTokens;

        // If trying to mint more tokens than available -> reimburse for excess mints and allow for lower mint count
        // to avoid a failed tx

        if(maxMintsPerWallet > 0)
        {
            require(mintsPerWallet[msg.sender] < maxMintsPerWallet, "Exceeds number of mints per wallet");
            
            if(mintsPerWallet[msg.sender] + numberOfTokens > maxMintsPerWallet)
            {
                numberOfTokens = maxMintsPerWallet - mintsPerWallet[msg.sender];
            }            
        }
 
        if( (_mintedTokens + numberOfTokens > maxTokens) )
        {
            numberOfTokens = maxTokens - _mintedTokens;
        }

        uint256 reimbursementPrice =  (origMintCount - numberOfTokens) * nftPrice;

        mintsPerWallet[msg.sender] += numberOfTokens;

        _mint(msg.sender, numberOfTokens);
        
        // cap reimbursement at msg.value in case something goes wrong
        if( 0 < reimbursementPrice && reimbursementPrice < msg.value)
        {
            (bool sent, ) = msg.sender.call{value: reimbursementPrice}("");
            require(sent, "Failed to send Ether");
        }
        
        return _mintedTokens;
    }
    
    /**
     * @dev Only owner or Fair.xyz - withdraw contract balance to owner wallet. 6% primary sale fee to Fair.xyz
     */
    function withdraw()
        public
        payable
    {
        require(msg.sender == owner() || msg.sender == viewWithdraw(), "Not owner or Fair.xyz!");
        uint256 contractBalance = address(this).balance;

        (bool sent, ) = viewWithdraw().call{value: contractBalance*3/50}("");
        require(sent, "Failed to send Ether");

        uint256 remainingContractBalance = address(this).balance;
        (bool sent_, ) = _primaryRoyaltyReceiver.call{value: remainingContractBalance}("");
        require(sent_, "Failed to send Ether");
    }


}