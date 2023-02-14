// all mint proceeds go to fighting blindness because love is blind but that doesn't mean you have to be

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ProofOfValentine is Ownable, ERC721A {

    string public CONTRACT_URI = "ipfs://QmT41JxanXxqZTUgtZS3QsSXPeow5yzSgZLskZxFfr97Jq"; 
    string public BASE_URI = "https://unrevealed.s3.amazonaws.com/"; 

    bool public isPublicMintEnabled = false;

    uint256 public MINT_PRICE = 0.0069 ether;
    uint16 public MAX_BATCH_SIZE = 3;
    uint16 public COLLECTION_SIZE = 6969;

    constructor() ERC721A("ProofOfValentine", "POV") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract");
        _;
    }

    function mint(uint256 quantity, address receiver)
        external
        payable
        callerIsUser
    {
        uint256 price = MINT_PRICE * quantity;
        require(isPublicMintEnabled == true, "public sale has not begun yet");
        require(totalSupply() + quantity <= COLLECTION_SIZE, "max collection size has been reached!");
        require(quantity <= MAX_BATCH_SIZE, "tried to mint quanity over the limit, retry with a lower quantity");
        require(msg.value >= price, "must send enough eth for mint");
        _safeMint(receiver, quantity);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function setPublicMintEnabled(bool _isPublicMintEnabled) public onlyOwner {
        isPublicMintEnabled = _isPublicMintEnabled;
    }

    function setBaseURI(bool _revealed, string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId)));
    }
}