//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// by: stormwalkerz ⭐️

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface iFutureContract {
    function mintTransfer(address to) external returns(uint256);
}

contract UtopiaClub is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable {
    // Supply
    uint256 public immutable mintPrice;
    uint256 public immutable maxSupply;
    uint256 public immutable maxPerTxn;
    uint256 public immutable maxPerWallet;

    // Variables
    bytes32 public merkleRoot;
    uint256 constant TOKEN_ID = 1;

    // Project
    string public name;
    string public symbol;
    string public tokenUri;
    
    // Track
    mapping(address => uint256) public walletMints;

    // Authorized
    address public authorizedFutureContract = 0x70AaAB03d2cA0F69a5C0F5385304D5ee90BA28Fd; // @todo Future updated smart contract (currently only placeholder)
    bool public migrationActive = false;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 maxSupply_
    ) 
        ERC1155("")
    {
        //Project
        name = name_;
        symbol = symbol_;
        tokenUri = uri_;

        // Immutable
        maxSupply = maxSupply_;
        mintPrice = 0.2 ether;
        maxPerWallet = 2;
        maxPerTxn = 2;
    }

    // MODIFIERS
    modifier isUser {
        require(msg.sender == tx.origin, "Disable from SC"); _;
    }

    // MINT
    function whitelistMint(uint256 quantity_, bytes32[] memory proof_) external payable isUser isWhitelisted { 
        require(MerkleProof.verify(proof_, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You're not invited");
        require(quantity_ <= maxPerTxn, "Max per txn exceeded");
        require(totalSupply(TOKEN_ID) + quantity_ <= maxSupply, "Max supply exceeded");
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, "Max per wallet reached");
        require(msg.value == mintPrice * quantity_, "Wrong value!");
        
        walletMints[msg.sender] += quantity_;
        _mint(msg.sender, TOKEN_ID, quantity_, "");
    }

    // INVITATION MINT STATUS
    bool public whitelistMintEnabled;
    uint256 public whitelistMintTime;
    function setWhitelistMint(bool bool_, uint256 epochTime_) external onlyOwner {
        whitelistMintEnabled = bool_;
        whitelistMintTime = epochTime_;
    }
    modifier isWhitelisted {
        require(whitelistMintEnabled && block.timestamp >= whitelistMintTime, "Whitelist sale not started"); _; }
    function whitelistMintIsEnabled() public view returns (bool) {
        return(whitelistMintEnabled && block.timestamp >= whitelistMintTime);
    }

    // FUTURE MIGRATION
    function setMigrationStatus(bool bool_) external onlyOwner {
        migrationActive = bool_;
    }
    function migrateToken() external isUser {
        require(migrationActive, "Migration is not enabled at this time");
        require(balanceOf(msg.sender, TOKEN_ID) > 0, "You don't own the token"); // Check if the user own one of the ERC-1155
        burn(msg.sender, TOKEN_ID, 1); // Burn one the ERC-1155 token
        iFutureContract futureContract = iFutureContract(authorizedFutureContract);
        futureContract.mintTransfer(msg.sender); // Mint the ERC-721 token
    }

    // OWNER
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }
    function setTokenUri(string calldata newUri_) public onlyOwner {
        tokenUri = newUri_;
    }
    function setAuthorizedFutureContract(address futureContractAddress_) external onlyOwner {
        authorizedFutureContract = futureContractAddress_;
    }
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // OVERRIDE
    function uri(uint256) public view virtual override returns (string memory) {
        return tokenUri;
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}