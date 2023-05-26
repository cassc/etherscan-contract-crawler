// SPDX-License-Identifier:Unlicensed
pragma solidity >= 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract Entropy is ERC721, Ownable {
    
    // Block data to be stored in structs
    struct Block {
    uint blockNumber;
    bytes32 blockHash;
    }

    // init a bunch of variables
    Block[] public blockDB;
    mapping(address => bool) public frameHolders;
    bool public isPublicMintingEnabled;

    address public zeroRendererAddress;
    address public streamRendererAddress;
    bool public isPrivateMintingEnabled;

    string public wsProvider;
    
    constructor(
        address zeroRendererAddress_,
        address streamRendererAddress_,
        address[] memory frameHolders_,
        string memory wsProvider_
    ) ERC721("Entropy by Nahiko", "ENTROPY") { 

        // the renderer addresses
        zeroRendererAddress = zeroRendererAddress_;
        streamRendererAddress = streamRendererAddress_;

        wsProvider = wsProvider_;

        // init the frame holders mapping
        for(uint i = 0; i < frameHolders_.length;i++){
            frameHolders[frameHolders_[i]] = true;
        }

        // mint the 12 curation tokens, sent to nahiko
        // filling the db with 0s until curation
        for(uint i=0; i < 12; i++){
            blockDB.push(Block({ blockNumber : 0 , blockHash : 0}));
            _mint(msg.sender,i);
        }

        isPrivateMintingEnabled = false;
        isPublicMintingEnabled = false;
    }

    //_________________________________________________________________________________
    //functions that are utils for the ERC721

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        bytes memory uriString;
        string memory rendered;
        
        if(tokenId == 0){
            return ICaller(streamRendererAddress).render("0","0" , wsProvider);
        }

        else{
            return ICaller(zeroRendererAddress).render( Strings.toString(blockDB[tokenId].blockNumber) , blockDB[tokenId].blockHash  , wsProvider);
        }
    }
    
    
    function contractURI() public view returns (string memory) {
        //concat data and return the json as a string
        bytes memory contractJson = abi.encodePacked('data:application/json;utf8,{"description":"Entropy is a visual representation of Entropy increasing on the blockchain.","name": "Entropy","image": "https://arweave.net/dGUeg1273m1qiHf4YAbIPUxRyChgtFE9BYw6AuiMr9U","external_link": "","seller_fee_basis_points": 500,"fee_recipient": "',Strings.toHexString(uint256(uint160(owner())), 20),'"}');
        return string(contractJson);
    }
    
    function setZeroRendererAddress(address _zeroRendererAddress) public onlyOwner {
        zeroRendererAddress = _zeroRendererAddress;
    }

    function setStreamRendererAddress(address _streamRendererAddress) public onlyOwner {
        streamRendererAddress = _streamRendererAddress;
    }

    function setNewProvider(string memory newProvider) public onlyOwner {
        wsProvider = newProvider;
    }

    function enablePrivateMinting() public onlyOwner {
        isPrivateMintingEnabled = true;
    }

    function disableMinting() public onlyOwner {
        isPrivateMintingEnabled = false;
        isPublicMintingEnabled = false;
    }
    
    function enablePublicMinting() public onlyOwner {
        isPrivateMintingEnabled = true; // when Public Minting is allowed, private should be allowed by default too
        isPublicMintingEnabled = true;
    }
    
    function curate(uint _idToUpdate , uint newBlock , bytes32 newHash ) public onlyOwner {
        require(_idToUpdate > 0 && _idToUpdate < 12); // id needs to be one of the curation tokens

        blockDB[_idToUpdate] = Block({ blockNumber : newBlock , blockHash : newHash});
    }

    function mint() public payable{
        
        require(msg.value >= 0.1 ether,"minimum mint price not reached");
        require(blockDB.length < 512, "The maximum number of mints is 512");
        require(isPrivateMintingEnabled, "No minting is currently possible");

        if(!isPublicMintingEnabled){
            // check if in frame holder list, otherwise revert
            require(frameHolders[msg.sender],"Minting is currently not open to the public");
        }

        uint lastMintedBlock = blockDB[blockDB.length - 1].blockNumber;
        require(lastMintedBlock + 1 < block.number, " no more blocks available right now, wait for the next block to be processed");

        uint blockToMint = block.number - 256; // we initialize the block to mint at the max range
        
        if(blockToMint <= lastMintedBlock){ // if the last minted block is inside our range, we just increment
            blockToMint = lastMintedBlock + 1;
        }
        
        // pushing the data to the new blockDB entry
        blockDB.push(Block({ blockNumber : blockToMint , blockHash : blockhash(blockToMint) }));

        _mint(msg.sender,blockDB.length - 1); // mint the actual token

        // once we hit 256 mint we turn minting off, only nahiko can turn it back on
        if(blockDB.length % 256 == 0){
            isPublicMintingEnabled = false;
            isPrivateMintingEnabled = false;
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

interface ICaller{
    function render(string memory blockNumber, bytes32 blockHash , string memory wsProvider) external view returns(string memory);
}