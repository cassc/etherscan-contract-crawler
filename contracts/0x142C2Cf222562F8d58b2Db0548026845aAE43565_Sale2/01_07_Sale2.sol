// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./lib/ISarugami.sol";

contract Sale2 is Ownable, ReentrancyGuard {
    bool public isHolderMintActive = true;
    bytes32 public merkleRootHolder = "0x";
    uint256 public maxHolder = 1;

    bool public isPublicMintActive = true;
    uint256 public publicPrice = 53000000000000000;
    uint256 public maxPublic = 5858;

    mapping(address => uint256) public walletHolderCount;
    mapping(address => uint256) public walletPublicCount;

    ISarugami public sarugami;

    constructor(
        address sarugamiAddress
    ) {
        sarugami = ISarugami(sarugamiAddress);
    }

    function mintFreeHolder(bytes32[] calldata merkleProof, uint256 amount) public nonReentrant {
        require(isHolderMintActive == true, "Holder free mint not open");
        require(isWalletListed(merkleProof, msg.sender) == true, "Invalid proof, your wallet isn't listed as holder");
        require(walletHolderCount[msg.sender] + amount <= maxHolder, "Max amount reached for this wallet");

        walletHolderCount[msg.sender] += amount;
        sarugami.mint(msg.sender, amount);
    }

    function mintPublic(uint256 amount) public payable nonReentrant {
        require(isPublicMintActive == true, "Public sale not open");
        require(amount > 0, "Invalid amount");
        require(walletPublicCount[msg.sender] + amount <= maxPublic, "Max amount reached for this wallet");
        require(msg.value == publicPrice * amount, "ETH sent does not match Sarugami value");

        walletPublicCount[msg.sender] += amount;
        sarugami.mint(msg.sender, amount);
    }

    function isWalletListed(
        bytes32[] calldata merkleProof,
        address wallet
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(merkleProof, merkleRootHolder, leaf);
    }

    function changePricePublic(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    function changePublicMintStatus() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function changeHolderMintStatus() external onlyOwner {
        isHolderMintActive = !isHolderMintActive;
    }

    function changeLimitPublicMint(uint256 amount) external onlyOwner {
        maxPublic = amount;
    }

    function changeLimitHolderMint(uint256 amount) external onlyOwner {
        maxHolder = amount;
    }

    function setMerkleTreeRootHolder(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootHolder = newMerkleRoot;
    }

    function withdrawStuckToken(address recipient, address token) external onlyOwner() {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    function removeDustFunds(address treasury) external onlyOwner {
        (bool success,) = treasury.call{value : address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }

    function removeFunds() external onlyOwner {
        uint256 funds = address(this).balance;

        (bool devShare,) = 0xDEcB0fB8d7BB68F0CE611460BE8Ca0665A72d47E.call{
        value : funds * 5 / 100
        }("");

        (bool makiShare,) = 0x83fEa2d7cB61174c55E6fFA794840FF91d889d00.call{
        value : funds * 15 / 100
        }("");

        (bool nikoShare,) = 0xeb3853d765870fF40318CF37f3b83B02Fd18b46C.call{
        value : funds * 3 / 100
        }("");

        (bool frankShare,) = 0xCE1f60EC76a7bBacED41816775b842067d8D17B3.call{
        value : funds * 3 / 100
        }("");

        (bool peresShare,) = 0x7F1a6c8DFF62e1595A699e9f0C93B654CcfC5Fe1.call{
        value : funds * 2 / 100
        }("");

        (bool guuhShare,) = 0x907c71f22d893CB75340C820fe794BC837079e8E.call{
        value : funds * 1 / 100
        }("");

        (bool luccaShare,) = 0x3bB05e56cb60C1e2D00d3e4d0B8Ae7501B2f5F50.call{
        value : funds * 1 / 100
        }("");

        (bool costShare,) = 0x3bB05e56cb60C1e2D00d3e4d0B8Ae7501B2f5F50.call{
        value : funds * 10 / 100
        }("");

        (bool pedroShare,) = 0x289660e62ff872536330938eb843607FC53E0a34.call{
        value : funds * 30 / 100
        }("");

        (bool digaoShare,) = 0xDEEf09D53355E838db08E1DBA9F86a5A7DfF2124.call{
        value : address(this).balance
        }("");

        require(
            devShare &&
            makiShare &&
            nikoShare &&
            frankShare &&
            peresShare &&
            guuhShare &&
            luccaShare &&
            costShare &&
            pedroShare &&
            digaoShare,
            "funds were not sent properly"
        );
    }
}