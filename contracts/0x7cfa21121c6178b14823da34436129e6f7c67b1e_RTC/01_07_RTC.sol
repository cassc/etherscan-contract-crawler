// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RTC is ERC721A, Ownable {
    using Strings for uint256;
    bool public private_sale_running = false;
    bool public public_sale_running = false;
    uint public WL_MINT_PRICE = 0.019 ether;
    uint public MINT_PRICE = 0.069 ether;
    bool public revealed = false;
    uint public constant MAX_SUPPLY = 666;
    bytes32 public merkle_root;
    string public uriPrefix = "";

    constructor () ERC721A("RTC", "RTC") {
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
    
    function whitelistMint(bytes32 [] calldata _merkleProof, uint64 _amount) external payable {
        require(tx.origin == msg.sender);
        require(private_sale_running, "PRIVATE_SALE_NOT_RUNNING");
        require(msg.value >= WL_MINT_PRICE * _amount, "INCORRECT_ETH_AMOUNT");
        require(_totalMinted() + _amount <= MAX_SUPPLY, "TOTAL_SUPPLY_REACHED");
        require(isWhitelisted(msg.sender, _merkleProof), "INVALID_PROOF");
        uint64 num_claimed = _getAux(msg.sender);
        require(num_claimed + _amount < 3, "CAN_ONLY_MINT_2");
        _setAux(msg.sender, num_claimed + _amount);
        _mint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount) external payable {
        require(tx.origin == msg.sender);
        require(public_sale_running, "PUBLIC_SALE_NOT_RUNNING");
        require(msg.value >= MINT_PRICE * _amount, "INCORRECT_ETH_AMOUNT");
        require(_totalMinted() + _amount <= MAX_SUPPLY, "TOTAL_SUPPLY_REACHED");
        _mint(msg.sender, _amount);
    }

    function adminMint(address _to, uint256 _amount) external onlyOwner{
        require(_totalMinted() + _amount <= MAX_SUPPLY, "TOTAL_SUPPLY_REACHED");
        require(_amount <= 50, "TO_MANY_PER_TX");
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

     function updateWhitelistMintingPrice(uint _new_price) external onlyOwner {
        WL_MINT_PRICE = _new_price;
    }
        
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
            return
            bytes(uriPrefix).length > 0
                ? string(
                    abi.encodePacked(
                        uriPrefix,
                        _tokenId.toString()
                    )
                )
                : "";
    } 
    
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
            uriPrefix = _uriPrefix;
    }
    function withdraw(address payable _to) public onlyOwner {
    require(_to != address(0), "Cannot send to zero address");
    (bool success, ) = _to.call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
}

}