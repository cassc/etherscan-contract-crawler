// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./AbstractERC1155Factory.sol";

contract ThirtyTwoDreams is AbstractERC1155Factory {

    uint256 public constant MAX_SUPPLY = 3232;

    uint256 public mintCost = 0.16 ether;
    uint256 public devMintCount;

    mapping (address => bool) addressHasMinted;

    bytes32 public allowlistMerkleRoot;
    uint256 public saleState; // 0 = paused , 1 = allowlist, 2 = allowlist + public

    event SaleStateChanged(uint256 newState);

    constructor(string memory _uri) ERC1155(_uri) {
        name_ = "32 DREAMS";
        symbol_ = "32DREAMS";
    }

    // MINT

    function mintFromAllowlist(bytes32[] calldata _merkleProof) external payable {
        require(totalSupply(0) < MAX_SUPPLY, "Total supply reached");
        require(saleState > 0, "Sale Inactive");
        require(!addressHasMinted[_msgSender()], "You have already minted a token");
        require(msg.value == mintCost, "Invalid ether amount provided");
        require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot ,keccak256(abi.encodePacked(msg.sender))), "Invalid Merkle proof supplied for address");
        addressHasMinted[_msgSender()] = true;
        _mint(_msgSender(), 0, 1, ""); // Mint 1 token of tokenId 0
    }

    function mintPublic() external payable {
        require(totalSupply(0) < MAX_SUPPLY, "Total supply reached");
        require(saleState == 2, "Public Sale Inactive");
        require(!addressHasMinted[_msgSender()], "You have already minted a token");
        require(msg.value == mintCost, "Invalid ether amount provided");
        addressHasMinted[_msgSender()] = true;
        _mint(_msgSender(), 0, 1, ""); // Mint 1 token of tokenId 0
    }

    function devMintToAddress(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply(0) + _amount <= MAX_SUPPLY, "Total supply reached");
        require(devMintCount + _amount <= 32, "Dev mint is capped at 32");
        devMintCount += _amount;
        _mint(_to, 0, _amount, ""); // Mint an _amount of tokenId 0 to _to
    }

    // SETTERS

    /** 
     * @dev IMPORTANT: Value should be entered in wei, not ether units
     */
    function setMintCost(uint256 _newMintCost) external onlyOwner {
        require(_newMintCost <= 0.16 ether, "Max price is 0.16 ether");
        mintCost = _newMintCost;
    }

    /** 
     * saleState :
     * 0 : Sale inactive (default) ,
     * 1 : Allowlist Sale ,
     * 2 : Public Sale ,
     * @dev To reduce failed transactions, mintFromAllowlist can also be called during public sale (1 total minted per wallet MAX)
     */
    function setSaleState(uint256 _intended) external onlyOwner {
        require(saleState != _intended, "This is already the value");
        saleState = _intended;
        emit SaleStateChanged(_intended);
    }

    function setAllowlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

    // OVERRIDES

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), "0"));
    }

    // HELPER

    function sendEth(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send ether");
    }

    function withdraw(address _to) external onlyOwner {
        sendEth(_to, address(this).balance);
    }

}