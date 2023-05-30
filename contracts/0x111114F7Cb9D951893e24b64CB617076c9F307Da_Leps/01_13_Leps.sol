// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Leps is ERC721A, EIP712, Ownable {
    string _baseUri;
    string _contractUri;
    address _signerAddress;
    
    uint public maxSupply = 4777;
    uint public price = 0.1 ether;
    uint public publicSalesStartTimestamp = 1679947200;
    uint public whitelistSalesStartTimestamp = 1648411200;

    constructor() ERC721A("Leps", "LEPS") EIP712("LEPS", "1.0.0") {
        _contractUri = "ipfs://QmZhYQgfMtYAiNcwdrPYk1JX3caJSpcb1n6F5XymAiFc6a";
    }

    function mint(uint quantity) external payable {
        require(isPublicSalesActive(), "sale is not active");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(msg.value >= price * quantity, "ether send is under price");
        
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint quantity, bytes calldata signature) external payable {
        require(recoverAddress(msg.sender, signature) == _signerAddress, "account is not whitelisted");
        require(isWhitelistSalesActive(), "sale is not active");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(msg.value >= price * quantity, "ether send is under price");
        
        _safeMint(msg.sender, quantity);
    }
    
    function updateMaxSupply(uint newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function isPublicSalesActive() public view returns (bool) {
        return publicSalesStartTimestamp <= block.timestamp;
    }
    
    function isWhitelistSalesActive() public view returns (bool) {
        return whitelistSalesStartTimestamp <= block.timestamp;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function setPublicSalesStartTimestamp(uint newTimestamp) external onlyOwner {
        publicSalesStartTimestamp = newTimestamp;
    }
    
    function setWhitelistSalesStartTimestamp(uint newTimestamp) external onlyOwner {
        whitelistSalesStartTimestamp = newTimestamp;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _hash(address account) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("LEPS(address account)"),
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account), signature);
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}