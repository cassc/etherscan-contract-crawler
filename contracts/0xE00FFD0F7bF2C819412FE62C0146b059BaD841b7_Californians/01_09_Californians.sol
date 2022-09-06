// SPDX-License-Identifier: MIT

/*

#######                   #####                                                                        #     # ####### ####### 
   #    #    # ######    #     #   ##   #      # ######  ####  #####  #    # #   ##   #    #  ####     ##    # #          #    
   #    #    # #         #        #  #  #      # #      #    # #    # ##   # #  #  #  ##   # #         # #   # #          #    
   #    ###### #####     #       #    # #      # #####  #    # #    # # #  # # #    # # #  #  ####     #  #  # #####      #    
   #    #    # #         #       ###### #      # #      #    # #####  #  # # # ###### #  # #      #    #   # # #          #    
   #    #    # #         #     # #    # #      # #      #    # #   #  #   ## # #    # #   ## #    #    #    ## #          #    
   #    #    # ######     #####  #    # ###### # #       ####  #    # #    # # #    # #    #  ####     #     # #          #    


*/

pragma solidity ^0.8.15;


import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol'; 

contract Californians is ERC721AQueryable, Ownable, ReentrancyGuard {

    event TokenClaimed(uint256 _totalClaimed, address _owner, uint256 _numOfTokens);


    bytes32 public merkleRoot;

    uint public maxSupply = 5555;
    uint public maxPerAddress = 10;

    bool public publicMint = false;
    bool public whitelistMint = false;

    string private _baseTokenURI;

    
    constructor(string memory _metadataBaseURL) ERC721A("The Californians", "CAS") {
        _baseTokenURI = _metadataBaseURL;
    }

    function verify(bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function mint(uint256 quantity, bytes32[] memory proof) external {
        require(tx.origin == msg.sender, "Cannot mint from a contract");
        require(whitelistMint || publicMint, "Cannot claim now");
        require(_numberMinted(msg.sender) + quantity <= maxPerAddress, "Cannot claim more tokens");
        require(quantity > 0, "Invalid token count");
        require(totalSupply() + quantity <= maxSupply, "Cannot claim these many tokens");
        if(whitelistMint){
            require(verify(proof), "Wallet not whitelisted");
        }

        _safeMint(msg.sender, quantity);

        emit TokenClaimed(totalSupply(), msg.sender, quantity);
    }

    function tokenExists(uint _tokenid) public view returns (bool) {
        return _exists(_tokenid);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mintToAddress(address _address, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Cannot mint these many tokens");
        _safeMint(_address, quantity);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function flipPublicMintState() external onlyOwner {
        publicMint = !publicMint;
    }

    function flipWhitelistState() external onlyOwner {
        whitelistMint = !whitelistMint;
    }

    function setMaxSupply(uint _supply) external onlyOwner {
        maxSupply = _supply;
    }

    function setMaxPerAddress(uint _max) external onlyOwner {
        maxPerAddress = _max;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}