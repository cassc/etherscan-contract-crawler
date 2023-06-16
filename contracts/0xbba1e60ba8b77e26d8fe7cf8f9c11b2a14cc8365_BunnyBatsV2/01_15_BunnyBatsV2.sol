//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./NonblockingReceiver.sol";

/***
 * 
 * This contract includes the following features
 * - Omnichain traversability via LZ
 * - Updatable LZ endpoint and gas estimate in case of omnichain protocol upgrades (e.g. solana support?)
 * - The whole project starts at ID #1, ends at ID #11111. Maximum 11111.
 * - The possibility to mint different tokenID ranges on other chains. 
 * 
 * - V2 of this contract enables Free Mint and One-mint-per-wallet
 * 
 * NOTE:
 * - When ready, call lock() to freeze the metadata forever.
***/


contract BunnyBatsV2 is Ownable, ERC721, NonblockingReceiver {

    bool public saleActive = false; // minting can't work until this is true
    bool public oneMintPerWallet = false; // when this is true, only one mint per wallet is allowed

    // Store the list of all addresses that have minted on this contract
    mapping(address => bool) public hasMinted;

    // These two set the range of IDs which are mintable on this chain.  
    uint16 public nextId = 1; // next tokenID to be minted on this chain 
    uint16 public mintLimit = 11111; // when it mints to this point, pause the sale

    uint16 public MAX = 11111; // the hard limit, maximum tokens to be ever be minted
    uint256 public price = 50 ether; // or whatever the network token is. 

    bool public locked = false; // lock the metadata forever  
    string public baseUri = ""; // IPFS baseURI

    // LZ 
    uint256 public gasForDestinationLzReceive = 350000;
    address public endpointAddress;

    constructor(address _new_owner) ERC721("BunnyBats", "BUNNYBATS") {
        transferOwnership(_new_owner);
    }

    // Run this after deploy to initialize
    function setupContract(address _endpointAddress, uint16 _firstId, uint16 _lastId) external onlyOwner {
        require(_lastId <= MAX, "Exceeds Maximum");
        require(_firstId <= MAX, "Exceeds Maximum");
        endpointAddress = _endpointAddress;
        endpoint = ILayerZeroEndpoint(_endpointAddress);
        nextId = _firstId;
        mintLimit = _lastId;
    }

    // set the ipfs link
    function setBaseUri(string memory newBaseUri) external onlyOwner {
        require(locked == false, "URI locked");
        baseUri = newBaseUri;
    }

    // lock the metadata forever
    function lock() external onlyOwner{
        locked = true;
    }

    // set the limit which is currently for sale
    function setMintLimit(uint16 _newLimit) external onlyOwner{
        require(_newLimit <= MAX, "Exceeds Maximum");
        require(_newLimit >= nextId, "Below nextId");
        mintLimit = _newLimit;
    }

    // set the price in wei 
    function setPrice(uint256 _newPrice) external onlyOwner{
        price = _newPrice;
    }

    // turn minting on (or off)
    function setSaleActive(bool _active) external onlyOwner {
        saleActive = _active;
    } 

    // set minting mode for one mint per wallet
    function setOneMintPerWallet(bool _oneMintPerWallet) external onlyOwner {
        oneMintPerWallet = _oneMintPerWallet;
    }

    // Mint!
    function mintMultiple(uint16 quantity) external payable {
        require(nextId <= MAX, "Sold out");
        require(saleActive, "Sale is not active");
        require(nextId - 1 + quantity <= MAX, "Exceeds supply");
        require(nextId - 1 + quantity <= mintLimit, "Exceeds mint limit");
        require(quantity >= 1 && quantity <= 10, "Please mint between 1 and 10");
        require(msg.value == quantity * price, "Payment amount is incorrect");
        require(!(oneMintPerWallet && hasMinted[msg.sender]), "Wallet has already minted");
        require(!(oneMintPerWallet && quantity != 1), "Please mint only 1 per wallet");

        for(uint16 i=0; i<quantity; i++){
            _safeMint(msg.sender, nextId);
            nextId += 1;
            hasMinted[msg.sender] = true;
        }

        // halt the sale if MAX is reached
        if(nextId>MAX){
            saleActive=false;
        }
        if(nextId>mintLimit){
            saleActive=false;
        }
    }


    // Misc
    function donate() external payable {
        // thank you
    }

    function withdraw(uint256 amt) external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: amt}("");
        require(sent, "Failed to withdraw");
    }

    //////////////
    // LZ functions

    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    // just this limits us from future integrations
    function setLzEndpointAddress(address _endpointAddress) external onlyOwner {
        endpointAddress = _endpointAddress;
        endpoint = ILayerZeroEndpoint(_endpointAddress);
    }

    // This function transfers the nft from your address on the
    // source chain to the same address on the destination chain
    function traverseChains(uint16 _chainId, uint256 tokenId) public payable {
        require(msg.sender == ownerOf(tokenId), "You must own the token to traverse");
        require(trustedRemoteLookup[_chainId].length > 0, "This chain is currently unavailable for travel");

        // burn NFT, eliminating it from circulation on src chain
        _burn(tokenId);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint256 messageFee, ) = endpoint.estimateFees(
            _chainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        require(
            msg.value >= messageFee,
            "msg.value not enough to cover messageFee. Send gas for message fees"
        );

        endpoint.send{value: msg.value}(
            _chainId, // destination chainId
            trustedRemoteLookup[_chainId], // destination address of nft contract
            payload, // abi.encoded()'ed bytes
            payable(msg.sender), // refund address
            address(0x0), // 'zroPaymentAddress' unused for this
            adapterParams // txParameters
        );
    }


    // ------------------
    // Internal Functions
    // ------------------

    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) override internal {
        // decode
        (address toAddr, uint tokenId) = abi.decode(_payload, (address, uint));

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
    }  

    function _baseURI() override internal view returns (string memory) {
        return baseUri;
    }


}