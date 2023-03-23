// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";
import "solmate/tokens/ERC1155.sol";
import "solmate/Auth/Owned.sol";
import "solmate/utils/LibString.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract Uniblocks is ERC1155, Owned {
    event Redemption(bytes32 indexed info, uint256 amount);

    string private _baseURI;
    uint256 public price = 0.1 ether;

    uint256 public totalSupply = 0;
    uint256 public totalRedeemed = 0;

    bool public finalized = false;
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 private constant checkpoint1 = 666;
    uint256 private constant checkpoint2 = 1332;

    uint256 public premintStartTime;
    uint256 public constant PREMINT_DURATION = 1 hours;

    bytes32 public merkleRoot;

    constructor(
        string memory baseURI,
        bytes32 _merkleRoot,
        uint256 _premintStartTime,
        address owner
    ) Owned(owner) {
        _baseURI = baseURI;
        merkleRoot = _merkleRoot;
        premintStartTime = _premintStartTime;
    }

    function isPremintActive() public view returns (bool) {
        return
            block.timestamp >= premintStartTime &&
            block.timestamp <= premintStartTime + PREMINT_DURATION;
    }

    modifier onlyDuringPremint() {
        require(isPremintActive(), "Premint is not active");
        _;
    }

    modifier onlyWhitelist(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                toBytes32(msg.sender)
            ) == true,
            "Invalid merkle proof"
        );
        _;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
        emit URI(uriForSupply(totalSupply), 0);
        emit URI(string.concat(_baseURI, "f"), 1);
    }

    function _getCheckpoint(uint256 supply) internal pure returns (uint256) {
        if (supply < checkpoint1) return 1;
        if (supply < checkpoint2) return 2;
        if (supply < MAX_SUPPLY) return 3;
        return 4;
    }

    // set the URI based on the current checkpoint
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (tokenId == 1) return string.concat(_baseURI, "r");

        return uriForSupply(totalSupply);
    }

    function uriForSupply(
        uint256 supply
    ) internal view returns (string memory) {
        if (finalized) return string.concat(_baseURI, "f");

        uint256 checkPoint = _getCheckpoint(supply);

        if (checkPoint == 4) return string.concat(_baseURI, "f");

        return string.concat(_baseURI, LibString.toString(checkPoint));
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function premint(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public payable onlyDuringPremint onlyWhitelist(merkleProof) {
        require(msg.value == price * amount, "Wrong amount of ETH sent");
        require(!finalized, "Minting has ended");
        require(totalSupply + amount <= MAX_SUPPLY, "Max supply reached");

        _mintTokens(msg.sender, amount);
    }

    function publicMint(uint256 amount) public payable {
        require(totalSupply + amount <= MAX_SUPPLY, "Max supply reached");
        require(msg.value == price * amount, "Wrong amount of ETH sent");
        require(
            block.timestamp >= premintStartTime + PREMINT_DURATION,
            "Public mint hasn't opened yet"
        );
        require(!finalized, "Minting has ended");

        _mintTokens(msg.sender, amount);
    }

    // burn tokenId 0 tokens and receive tokenId 1 tokens
    function redeem(uint256 amount, bytes32 info) public {
        require(
            amount <= balanceOf[msg.sender][0],
            "Not enough tokens to redeem"
        );
        _burn(msg.sender, 0, amount);
        _mint(msg.sender, 1, amount, "");
        totalRedeemed += amount;

        emit Redemption(info, amount);
    }

    function _mintTokens(address to, uint256 amount) internal {
        require(amount <= MAX_SUPPLY, "Minting more than max supply");
        require(totalSupply + amount <= MAX_SUPPLY, "Max supply reached");

        uint256 checkPointBefore = _getCheckpoint(totalSupply);
        uint256 checkPointAfter = _getCheckpoint(totalSupply + amount);

        if (checkPointBefore != checkPointAfter) {
            emit URI(uriForSupply(totalSupply + amount), 0);
        }

        totalSupply += amount;

        _mint(to, 0, amount, "");
    }

    function finalize() public onlyOwner {
        finalized = true;
        emit URI(string.concat(_baseURI, "f"), 0);
    }

    function setRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPremintStartTime(uint256 _premintStartTime) public onlyOwner {
        premintStartTime = _premintStartTime;
    }

    function withdraw(address tokenAddress, uint256 amount) public onlyOwner {
        if (tokenAddress == address(0)) {
            payable(owner).transfer(amount);
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(owner, amount);
        }
    }
}