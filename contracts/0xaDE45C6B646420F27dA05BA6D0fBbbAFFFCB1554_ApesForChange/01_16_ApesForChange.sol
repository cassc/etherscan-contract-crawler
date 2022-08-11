// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//   __      _  ___  __  ____  ____  __ _   __   _  _  ____  _  _  _   __   _  _  _  _  _       __   __  __  __ _  ____ 
//  / _\    / )/ __)/  \(    \(  __)(  ( \ / _\ ( \/ )(  __)(_)/ )( \ / _\ ( \/ )( \/ )( \    _(  ) /  \(  )(  ( \(_  _)
// /    \  ( (( (__(  O )) D ( ) _) /    //    \/ \/ \ ) _)  _ ) __ (/    \/ \/ \/ \/ \ ) )  / \) \(  O ))( /    /  )(  
// \_/\_/   \_)\___)\__/(____/(____)\_)__)\_/\_/\_)(_/(____)(_)\_)(_/\_/\_/\_)(_/\_)(_/(_/   \____/ \__/(__)\_)__) (__) 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ApesForChange is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    IERC20 public tokenAddress;

    uint256 public maxMint = 100; 
    uint256 public immutable maxSupply = 10000; 
    uint256 public claimReserved = 2000;  

    uint256 public price = 1 * 10 ** 18;
    string public baseURI = "";
    bytes32 public root;
    
    struct MintHistory {
        uint64 ownerFreeClaim;
    }
    mapping(address => MintHistory) public mintHistory;

    Counters.Counter private _tokenIdCounter;

    constructor(address _tokenAddress) ERC721("Apes For Change", "A4C") {
        tokenAddress = IERC20(_tokenAddress);
        }

    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount < maxMint + 1, "Error - TX Limit Exceeded");
        require(supply + _mintAmount < maxSupply - claimReserved + 1, "Error - Max Supply Exceeded");
        require(supply + _mintAmount < maxSupply + 1, "Error - Max Supply Exceeded");

        for (uint256 i = 0; i < _mintAmount; i++) {
            tokenAddress.transferFrom(msg.sender, address(this), price);
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function claim(bytes32[] memory _proof, uint8 _maxAllocation, uint256 _mintAmount) public {
        uint256 supply = totalSupply();
        require(supply + _mintAmount < maxSupply + 1, "Error - Max Supply Exceeded");
        require(MerkleProof.verify(_proof,root,keccak256(abi.encodePacked(msg.sender, _maxAllocation))),"Error - Verify Qualification");
        require(mintHistory[msg.sender].ownerFreeClaim + _mintAmount < _maxAllocation + 1,"Error - Wallet Claimed");

        mintHistory[msg.sender].ownerFreeClaim += uint64(_mintAmount);
        claimReserved -= uint64(_mintAmount);

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 _tokenId) override public view returns(string memory) {
        return string(
            abi.encodePacked(
                baseURI,
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _baseURI() internal view override(ERC721) virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice * 10 ** 18;
    }

    function withdrawToken() public onlyOwner {
        tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
    }

    function setRoot(bytes32 root_) public onlyOwner {
        root = root_;
    }

    function setReserved(uint256 claimReserved_) public onlyOwner {
        claimReserved = claimReserved_;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}