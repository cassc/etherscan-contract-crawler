// SPDX-License-Identifier: MIT

// /ᐠ｡▿｡ᐟ\*ᵖᵘʳʳ*
// KatWalkerz
// author: sadat.eth

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";


contract KatWalkerz is ERC721, ReentrancyGuard, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    // KW supply info
    uint256 public maxKatWalkerz;
    uint256 public maxPerWallet;
    uint256 public totalSupply;
    
    // KW metadata server
    string private kwServer;

    // KW burning rewards
    address private kwRewards;

    // KW royalty info
    address private vault;
    uint96 private royaltyBps = 770; // 7.7%
    bytes4 private constant IERC2981 = 0x2a55205a;

    // KW minting information
    bytes32 private katlist;
    mapping(address => uint256) public claimed;
    mapping(address => uint256) public minted;

    // Kat dev stuff
    enum Switch { STOP, WHITELIST, PUBLIC, BURN }
    Switch public phase;
    constructor() ERC721("KatWalkerz", "KW") { }


    // Mint, burn and airdrop functions

    function privateMint(uint256 combination, uint256 freeMints, bytes32[] calldata purr) external payable {
        require(phase == Switch.WHITELIST, "Whitelist not started");
        require(maxKatWalkerz > totalSupply, "sold out");
        require(combination >= 0 && combination <= 99999, "invalid combination");
        require(_katlist(_verify(msg.sender, freeMints), purr), "not in list");
        require(claimed[msg.sender] < freeMints, "no mints left");
        require(!_exists(combination), "try another");
        _mint(msg.sender, combination);
        totalSupply += 1;
        claimed[msg.sender] += 1;
    }

    function publicMint(uint256 combination) external payable {
        require(phase == Switch.PUBLIC, "public sale not started");
        require(maxKatWalkerz > totalSupply, "sold out");
        require(combination >= 0 && combination <= 99999, "invalid combination");
        require(minted[msg.sender] < maxPerWallet, "max minted");
        require(!_exists(combination), "try another");
        _mint(msg.sender, combination);
        totalSupply += 1;
        minted[msg.sender] += 1;
    }

    function katdrop(address to, uint256 amount) external onlyOwner {
        require(amount <= 10, "not allowed");
        require(amount + totalSupply <= maxKatWalkerz, "supply n/a");
        for (uint256 i; i < amount; i++) {
            bytes32 rand = keccak256(abi.encodePacked(block.timestamp, block.difficulty, i));
            uint256 kitty = uint256(uint256(rand) % 100000);
            require(!_exists(kitty));
            _mint(to, kitty);
        }
        totalSupply += amount;
    }

    function burn(uint256[] memory tokenIds) external payable {
        require(phase == Switch.BURN, "burning not started");
        IKatMonstarzReward rewardContract = IKatMonstarzReward(kwRewards);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "you can't burn this");
            _burn(tokenId);
            rewardContract.getReward(msg.sender);
        }
    }

    // Custom KatWalkerz functions to manage and configure

    function startWhitelist() public onlyOwner {
        phase = Switch.WHITELIST;
    }

    function startPublic() public onlyOwner {
        phase = Switch.PUBLIC;
    }

    function startBurn() public onlyOwner {
        phase = Switch.BURN;
    }

    function meow() public onlyOwner {
        phase = Switch.STOP;
    }

    function setKatlist(bytes32 _root) public onlyOwner {
        katlist = _root;
    }

    function setPayments(address _vault, uint96 _royaltyBps) external onlyOwner {
        vault = _vault;
        royaltyBps = _royaltyBps;
    }

    function setReward(address _rewardAddr) external onlyOwner {
        kwRewards = _rewardAddr;
    }

    function setMetadata(string memory _server) public onlyOwner {
        kwServer = _server;
    }

    function saleConfig(uint256 newSupply, uint256 newMaxMints) public onlyOwner {
        maxKatWalkerz = newSupply;
        maxPerWallet = newMaxMints;
    }

    function wagmi() public onlyOwner nonReentrant {
        (bool moon, ) = payable(vault).call{value: address(this).balance}("");
        require(moon);
    }

    function kwAvailability(uint256 tokenId) public view returns (bool) {
        return !_exists(tokenId);
    }

    // Standard contract functions for marketplaces and dapps

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Nonexistent token");
        return (vault, (_salePrice * royaltyBps) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        if (interfaceId == IERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        // Special trait based on your KW balance
        uint256 evolve;
        address holder = ownerOf(tokenId);
        uint256 balance = balanceOf(holder);
        if (balance == 1) { evolve = 0; }
        else if (balance == 2) { evolve = 1; }
        else if (balance == 3) { evolve = 2; }
        else if (balance > 3 && balance < 8) { evolve = 3; }
        else if (balance > 7 && balance < 12) { evolve = 4; }
        else if (balance >= 12) { evolve = 5; }
        
        string memory combinationNo = _kitty(tokenId);
        
        return string(abi.encodePacked(kwServer, combinationNo, (evolve).toString()));
    }

    // Custom internal functions for contract

    function _kitty(uint256 tokenId) internal pure returns (string memory) {
        uint256[5] memory layers;
        for (uint256 i = 0; i < 5; i++) {
            layers[4 - i] = tokenId % 10;
            tokenId /= 10;
        }
        return string(abi.encodePacked(
            (layers[0]).toString(), (layers[1]).toString(), (layers[2]).toString(), (layers[3]).toString(), (layers[4]).toString()
        ));
    }

    function _verify(address account, uint256 freeMints) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, freeMints));
    }

    function _katlist(bytes32 kat_, bytes32[] memory purr) internal view returns (bool) {
        return MerkleProof.verify(purr, katlist, kat_);
    }

}

interface IKatMonstarzReward {
    function getReward(address _address) external;
}