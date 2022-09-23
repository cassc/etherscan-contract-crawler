// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GladiatorWolves is ERC721A, Ownable {
    using Strings for uint256;
    bool public private_sale_running = false;
    bool public public_sale_running = false;
    uint public MINT_PRICE = 0.0069 ether;
    bool public revealed = false;
    uint public constant MAX_SUPPLY = 2222;
    bytes32 public merkle_root;
    string public uriPrefix = "";
    string public hiddenMetadataUri;
    address public paymentSplitAddress;

    constructor (string memory _hiddenMetadataUri, address _paymentSplitAddress) ERC721A("Gladiator Wolves", "GW") {
        hiddenMetadataUri = _hiddenMetadataUri;
        paymentSplitAddress = _paymentSplitAddress;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function isWhitelisted(address _user, bytes32 [] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verify(_merkleProof, merkle_root, leaf);
    }

    function getNumClaimed(address _user) public view returns(uint64) {
        return _getAux(_user);
    }
    
    function whitelistMint(bytes32 [] calldata _merkleProof) external payable {
        require(tx.origin == msg.sender);
        require(private_sale_running, "PRIVATE_SALE_NOT_RUNNING");
        require(msg.value == MINT_PRICE, "INCORRECT_ETH_AMOUNT");
        require(_totalMinted() < MAX_SUPPLY, "TOTAL_SUPPLY_REACHED");
        require(isWhitelisted(msg.sender, _merkleProof), "INVALID_PROOF");

        uint64 num_claimed = _getAux(msg.sender);
        require(num_claimed == 0, "CAN_ONLY_MINT_1");
        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
    }

    function publicMint() external payable {
        require(tx.origin == msg.sender);
        require(public_sale_running, "PUBLIC_SALE_NOT_RUNNING");
        require(msg.value == MINT_PRICE, "INCORRECT_ETH_AMOUNT");
        require(_totalMinted() < MAX_SUPPLY, "TOTAL_SUPPLY_REACHED");
        _mint(msg.sender, 1);
    }

    function adminMint(address _to, uint256 _amount) external onlyOwner{
        require(_totalMinted() < MAX_SUPPLY, "TOTAL_SUPPLY_REACHED");
        require(_amount <= 30, "TO_MANY_PER_TX");
        _mint(_to, _amount);
    }

    function togglePrivateSale() external onlyOwner {
        private_sale_running = !private_sale_running;
    }

    function togglePublicSale() external onlyOwner{
        public_sale_running = !public_sale_running;
    }

    function updateWhitelistMerkleRoot(bytes32 _new_root) external onlyOwner {
        merkle_root = _new_root;
    }

    function updateMintingPrice(uint _new_price) external onlyOwner {
        MINT_PRICE = _new_price;
    }
        
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(revealed == false){
            return hiddenMetadataUri;
        }
            return
            bytes(uriPrefix).length > 0
                ? string(
                    abi.encodePacked(
                        uriPrefix,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    } 
    
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
            uriPrefix = _uriPrefix;
    }


    function toggleRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function withdraw() public onlyOwner {
    (bool os, ) = payable(paymentSplitAddress).call{value: address(this).balance}('');
    require(os);
  }
}