// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LandDAO is ERC20, ERC20Permit, Ownable {
    using ECDSA for bytes32;

    IERC721 public immutable dlsNft;
    uint256 public immutable startDate;
    address public immutable messageSigner;
    uint256 public constant landOwnersSupply = 90_000_000e18;
    uint256 public landOwnersSpent;
    mapping(string => uint256) public supplyData;
    mapping(uint256 => bool) public dlsNftOwnerClaimed;
    mapping(address => uint8) public landOwnerClaimed;
    bool public claimEnabled;
    bool public allowlistEnabled;
    bool public unclaimedTokensTransferred;

    // CONSTRUCTOR
    constructor(string memory name_, string memory symbol_, address dlsNftAddress) ERC20(name_, symbol_) ERC20Permit(name_) {
        dlsNft = IERC721(dlsNftAddress);
        startDate = block.timestamp;
        messageSigner = msg.sender;
        _mint(address(this), 1e27);
        supplyData["poolRewards"] = 340_000_000e18;
        supplyData["singleStakingRewards"] = 30_000_000e18;
        supplyData["liquidityPoolRewards"] = 70_000_000e18;
        supplyData["dlsDao"] = 90_000_000e18;
        supplyData["liquidityManagement"] = 20_000_000e18;
        supplyData["treasury"] = 100_000_000e18;
        supplyData["team"] = 120_000_000e18;
        supplyData["strategicSale"] = 50_000_000e18;
    }

    function sendTokens(string memory supplyName, address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "LandDao: Should sent to someone");
        uint256 supply = supplyData[supplyName];
        require(supply > 0, "LandDao: not eligible");
        _transfer(address(this), contractAddress, supply);
        supplyData[supplyName] = 0;
    }

    function claim(uint256 amount, bytes memory signature, bytes memory allowlistSignature, uint256[] memory tokenIds) external {
        if (!claimEnabled) {
            require(allowlistEnabled, "LandDao: you can not claim yet");
            require(allowlistSignature.length > 0, "LandDao: you can not claim yet unless you provide allowlist data");
            bytes32 message = bytes32(uint256(uint160(msg.sender)));
            bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
            address signatureAddress = hash.recover(allowlistSignature);
            require(signatureAddress == messageSigner, "LandDAO: invalid whitelist signature");
        }
        if (amount > 0) {
            claimLandOwner(amount, signature);
        }
        if (tokenIds.length > 0) {
            claimNftOwner(tokenIds);
        }
    }

    // Land Owners logic
    function claimLandOwner(uint256 amount, bytes memory signature) internal {
        bytes32 message = bytes32((uint256(uint160(msg.sender)) << 96) + amount);
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        address signatureAddress = hash.recover(signature);
        require(signatureAddress == messageSigner, "LandDAO: invalid landowner signature");
        uint256 _halfDate = startDate + 60 days;
        uint256 _endDate = _halfDate + 120 days;
        require(block.timestamp <= _endDate, "LandDAO: date out of range");
        uint8 claimed = landOwnerClaimed[msg.sender];
        require(claimed < 2, "LandDAO: already claimed");
        if (block.timestamp < _halfDate) {
            require(claimed == 0, "LandDAO: already claimed");
            claimed = 1;
            amount = amount / 2;
        } else {
            if (claimed == 1) {
                amount = amount / 2;
            }
            claimed = 2;
        }
        require(landOwnersSpent + amount <= landOwnersSupply, "LandDAO: not allowed to overspend supply");
        landOwnerClaimed[msg.sender] = claimed;
        landOwnersSpent += amount;
        _transfer(address(this), msg.sender, amount);
    }

    function transferringUnclaimedTokens(address treasuryManager) public onlyOwner {
        require(block.timestamp > startDate + 180 days, "LandDAO: landowners claim not finished yet");
        require(!unclaimedTokensTransferred);
        unclaimedTokensTransferred = true;
        _transfer(address(this), treasuryManager, landOwnersSupply - landOwnersSpent);
    }

    // DLS NFT Logic
    function claimNftOwner(uint256[] memory tokenIds) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(!dlsNftOwnerClaimed[tokenId], "LandDAO: tokens for NFT already claimed");
            require(dlsNft.ownerOf(tokenId) == msg.sender, "LandDAO: NFT belongs to different address");
            dlsNftOwnerClaimed[tokenId] = true;
        }
        uint256 amount = 9_000e18 * tokenIds.length;
        _transfer(address(this), msg.sender, amount);
    }

    function setClaimEnabled(bool claimEnabled_) external onlyOwner {
        claimEnabled = claimEnabled_;
    }

    function setAllowlistEnabled(bool allowlistEnabled_) external onlyOwner {
        allowlistEnabled = allowlistEnabled_;
    }
}