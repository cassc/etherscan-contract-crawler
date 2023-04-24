/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MythDivisionAgentID is ERC721, Ownable {

    using ECDSA for bytes32;
    using Strings for uint256;

    address public apeCoinAddress;
    address public signerAddress;
    

    mapping (address => uint) public signatureNonce;

    string public baseURI;

    uint public totalSupply = 0;

    uint public monthlyPriceStandard = 0.02 ether;
    uint public monthlyPricePlus = 0.06 ether;
    uint public monthlyPriceVip = 0.1 ether;

    uint public agentIDPurchasePrice = 0.001 ether;

    uint public agentIDRevokeGracePeriod = 7 days;

    enum Tier {
        Standard,
        Plus,
        VIP
    }

    struct Tokens {
        Tier tier;
        uint256 paidTime;
        uint256 activationTime;
    }

    mapping (uint256 => Tokens) public tokens;

    constructor(
        address _apeCoinAddress,
        address _signer
    ) ERC721("MythDivisionAgentID", "MDAID") {
        apeCoinAddress = _apeCoinAddress;
        signerAddress = _signer;
    }

    modifier activationCheck(uint tokenID) {
        require(ownerOf(tokenID) == msg.sender, "You are not the owner of this NFT!");
        require(!isActive(tokenID), "Token already active!");

        // if token was already activated in the past but has expired, will be reactivated with brand new stats
        if (tokens[tokenID].activationTime > 0) {
          delete tokens[tokenID];
        }
        _;
    }

    modifier renewalCheck(uint tokenID) {
        require(tokens[tokenID].activationTime > 0, "Token not activated!");
        _;
    }

    function freeMintAgentID(bytes32 messageHash, bytes calldata signature) external {
        require(messageHash == hashfreeMintAgentID(msg.sender, address(this), signatureNonce[msg.sender]), "Wrong message hash!");
        require(verifyAddressSigner(messageHash, signature), "Invalid address signerAddress!");

        _mint(msg.sender, totalSupply);

        unchecked {
            totalSupply++;
            signatureNonce[msg.sender]++;
        }
    }

    function purchaseAgentID(uint tokenID) payable external {
        require(msg.value == agentIDPurchasePrice, "Invalid ETH amount!");

        transferFrom(address(this), msg.sender, tokenID);
    }

    function revokeAgentID(uint tokenID) external {
        require(!isRevokable(tokenID), "Agent ID is not revokable!");

        transferFrom(ownerOf(tokenID), address(this), tokenID);      
    }
    
    function activateETH(uint256 tokenID, Tier tier, uint months) activationCheck(tokenID) external payable {
        if(tier == Tier.VIP) {
            require(msg.value == monthlyPriceVip * months, "Incorrect amount sent!");
        } else if (tier == Tier.Plus) {
            require(msg.value == monthlyPricePlus * months, "Incorrect amount sent!");
        } else if (tier == Tier.Standard) {
            require(msg.value == monthlyPriceStandard * months, "Incorrect amount sent!");            
        } else {
            revert("Invalid tier");
        }

        tokens[tokenID].paidTime = 30 days * months;
        tokens[tokenID].tier = tier;
        tokens[tokenID].activationTime = block.timestamp;
    }

    // must perform approval first
    function activateAPE(uint256 tokenID, Tier tier, uint256 apeCoinAmount, uint256 months, uint256 expiry, bytes32 messageHash, bytes calldata signature) activationCheck(tokenID) external {
        // validation for proper APE coin amount is conducted off chain
        require(messageHash == hashActivateWithApe(tokenID, uint256(tier), apeCoinAmount, months, expiry, signatureNonce[msg.sender]), "Wrong message hash!");
        require(verifyAddressSigner(messageHash, signature), "Invalid address signerAddress!");
        require(block.timestamp < expiry, "Signature expired");

        IERC20(apeCoinAddress).transferFrom(msg.sender, address(this), apeCoinAmount);

        tokens[tokenID].paidTime = 30 days * months;
        tokens[tokenID].tier = tier;
        tokens[tokenID].activationTime = block.timestamp;

        unchecked {
            signatureNonce[msg.sender]++;
        }
    }

    function renewETH(uint256 tokenID, uint months) renewalCheck(tokenID) external payable {
        Tier existingTier = tokens[tokenID].tier;

        if(existingTier == Tier.VIP) {
            require(msg.value == monthlyPriceVip * months, "Incorrect amount sent!");
        } else if (existingTier == Tier.Plus) {
            require(msg.value == monthlyPricePlus * months, "Incorrect amount sent!");
        } else {
            require(msg.value == monthlyPriceStandard * months, "Incorrect amount sent!");
        }

        tokens[tokenID].paidTime += 30 days * months;
    }

    // must perform approval first
    function renewAPE(uint256 tokenID, uint256 apeCoinAmount, uint months, uint expiry, bytes32 messageHash, bytes calldata signature) renewalCheck(tokenID) external {
        // validation for proper APE coin amount is conducted off chain
        require(messageHash == hashTopUpWithApe(tokenID, apeCoinAmount, months, expiry, signatureNonce[msg.sender]), "Wrong message hash!");
        require(verifyAddressSigner(messageHash, signature), "Invalid address signerAddress");
        require(block.timestamp < expiry, "Signature expired");

        IERC20(apeCoinAddress).transferFrom(msg.sender, address(this), apeCoinAmount);

        tokens[tokenID].paidTime += 30 days * months;

        unchecked {
            signatureNonce[msg.sender]++;
        }
    }

    function hashfreeMintAgentID(address sender, address thisContract, uint nonce) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, thisContract, nonce));
    }

    function hashActivateWithApe(uint256 tokenID, uint256 tier, uint256 apeCoinAmount, uint months, uint expiry, uint nonce) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenID, tier, apeCoinAmount, months, expiry, nonce));
    }

    function hashTopUpWithApe(uint256 tokenID, uint256 apeCoinAmount, uint months, uint expiry, uint nonce) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenID, apeCoinAmount, months, expiry, nonce));
    }

    function verifyAddressSigner(bytes32 messageHash, bytes calldata signature) private view returns (bool) {
        address recovery = messageHash.toEthSignedMessageHash().recover(signature);
        return signerAddress == recovery;
    }

    function getRemaingTime(uint256 tokenID) public view returns (uint256) {
        return (tokens[tokenID].paidTime - (block.timestamp - tokens[tokenID].activationTime));
    }

    function isActive(uint tokenID) public view returns (bool) {
        if (block.timestamp > tokens[tokenID].activationTime + tokens[tokenID].paidTime) {
            return false;
        }
        return true;
    }

    function getActivationTime(uint tokenID) public view returns (uint) {
        return tokens[tokenID].activationTime;
    }

    function getPaidTime(uint tokenID) public view returns (uint) {
        return tokens[tokenID].paidTime;
    }

    function getTier(uint tokenID) public view returns (Tier) {
        return tokens[tokenID].tier;
    }

    function isRevokable(uint tokenID) public view returns (bool) {
      require(tokens[tokenID].activationTime > 0, "Must have been activated to revoke");
      if (block.timestamp > tokens[tokenID].activationTime + tokens[tokenID].paidTime + agentIDRevokeGracePeriod) {
        return true;
      }
      return false;
    }

    function tokenURI(uint tokenID) public view override returns (string memory){
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
    }
    
    function updateSigner(address _signer) external onlyOwner {
        signerAddress = _signer;
    }

    function updateBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function updateMonthlyPriceStandard(uint _monthlyPriceStandard) external onlyOwner {
        monthlyPriceStandard = _monthlyPriceStandard;
    }

    function updateMonthlyPricePlus(uint _monthlyPricePlus) external onlyOwner {
        monthlyPricePlus = _monthlyPricePlus;
    }

    function updateMonthlyPriceVip(uint _monthlyPriceVip) external onlyOwner {
        monthlyPriceVip = _monthlyPriceVip;
    }

    function updateAgentIDRevokeGracePeriod(uint _agentIDRevokeGracePeriod) external onlyOwner {
        agentIDRevokeGracePeriod = _agentIDRevokeGracePeriod;
    }

    function updateAgentIDPurchasePrice(uint _agentIDPurchasePrice) external onlyOwner {
        agentIDPurchasePrice = _agentIDPurchasePrice;
    }

    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    // transferFrom override for revoke.
    function transferFrom(address from, address to, uint256 id) public override {
        require(from == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id] || msg.sender == address(this),
            "NOT_AUTHORIZED"
        );
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }
        _ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
    }

}