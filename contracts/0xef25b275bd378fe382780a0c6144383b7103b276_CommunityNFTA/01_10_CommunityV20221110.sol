// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

error SoldOut();
error NotWhiteListed();
error InvalidPrice();
error WithdrawFailed();
error InvalidQuantity();
error NotTransferrable();

contract CommunityNFTA is ERC721A, ERC2981, Ownable {

    event UserMinting(address indexed user, uint256 price, uint256 startIdx, uint256 quantity);

    struct CommunityConfig {
        string name;
        string symbol;
        // if totalSupply_ is 0, then unlimited supply
        uint256  totalSupply;
        uint256  price;
        string   description;
        uint256  maxPerWallet;
        // if accessCode is "", then no restricted access
        string  accessCode;
        string  tokenUriCommon;
        uint96  royaltyAmount;
        bool isTransferable;
    }

    address[] public withdrawAddresses_;
    uint256[] public withdrawPercentages_;

    // if totalSupply_ is 0, then unlimited supply
    uint256 public totalSupply_ = 0;
    uint256 public totalMinted_ = 0;
    uint256 public price_;
    uint96 public royalty_ = 0;
    string  private tokenUriCommon_;
    string  private description_;
    uint256 public maxPerWallet_;
    string private accessCode_ = "";    
    bool public isTransferable_ = true;
    bool public isMintable_ = true;
    bool public accessCodeEnabled_ = false;

    mapping(address => uint256) public addressMintBalance;
    mapping(uint256 => bool) public tokenInitiated;
    mapping(uint256 => string) public tokenUri;

    constructor(CommunityConfig memory config) ERC721A(config.name, config.symbol) {
        tokenUriCommon_ = config.tokenUriCommon;
        totalSupply_ = config.totalSupply;
        price_ = config.price;
        description_ = config.description;
        maxPerWallet_ = config.maxPerWallet;
        accessCode_ = config.accessCode;
        isTransferable_ = config.isTransferable;
        _setDefaultRoyalty(owner(), config.royaltyAmount);
        royalty_ = config.royaltyAmount;

        if(keccak256(abi.encodePacked(config.accessCode)) == keccak256(abi.encodePacked(""))) {
            accessCodeEnabled_ = false;
        } else {
            accessCodeEnabled_ = true;
        }
    }

    function _initFeeCollector() private {
        withdrawAddresses_[0] = 0x4BCdD74A35e028DaE62cb1D48528E71843e2AC7d;
        withdrawPercentages_[0] = 1;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price_ = newPrice;
    }
    
    function setPerWalletMax(uint256 _val) external onlyOwner {
        maxPerWallet_ = _val;
    }

    function setTotalSupply(uint256 supply) external onlyOwner {
        require(supply > totalMinted_, "Total Supply can only be increased and not reduced");
        totalSupply_ = supply;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
        royalty_ = feeBasisPoints;
    }
    
    function setAccessCode(string memory accessCode) external onlyOwner {
        accessCode_ = accessCode;
        if(keccak256(abi.encodePacked(accessCode)) == keccak256(abi.encodePacked(""))) {
            accessCodeEnabled_ = false;
        } else {
            accessCodeEnabled_ = true;
        }
    }

    function setIsMintable(bool isMintable) external onlyOwner {
        isMintable_ = isMintable;
    }

    function setTokenUriCommon(string memory tokenUriCommon) external onlyOwner {
        tokenUriCommon_ = tokenUriCommon;
    }

    function setTransferable(bool isTransferable) external onlyOwner {
        isTransferable_ = isTransferable;
    }

    function addWithdrawRecipient(address payable _address, uint256 _percentage) external onlyOwner {
        withdrawAddresses_.push(_address);
        withdrawPercentages_.push(_percentage);
    }

    function mint(
        uint256 quantity,
        string memory accessCode
    ) external payable {
        if (!isMintable_) revert("Minting ended");
        if (totalSupply_ > 0 && totalMinted_ + quantity > totalSupply_) revert("Token Overflow");
        if (price_ > 0 && msg.value < price_ * quantity) revert("Insufficient Payment Amount");
        if (keccak256(abi.encodePacked(accessCode)) != keccak256(abi.encodePacked(accessCode_))) revert("No access code provided");
        if (maxPerWallet_ > 0 && addressMintBalance[msg.sender] + quantity > maxPerWallet_) revert("over limit for maxPerWallet");
        uint256 nextId = _nextTokenId();
        _mint(msg.sender, quantity);
        addressMintBalance[msg.sender] += quantity;
        totalMinted_ += quantity;
        for (uint256 i = 0; i < quantity; ++i) {
            tokenInitiated[nextId+i] = true;
        }
        emit UserMinting(msg.sender, price_, nextId, quantity);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        if (!success) revert WithdrawFailed();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        for (uint256 i; i < withdrawAddresses_.length; i++) {
            _withdraw(withdrawAddresses_[i], (balance * withdrawPercentages_[i]) / 100);
        }
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(tokenId <= totalMinted_, "Token not found");
        return tokenUriCommon_;
    }

    /// @dev The following functions are overrides required by Solidity.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override(ERC721A) {
       super._beforeTokenTransfers(from, to, tokenId, quantity);
       require(isTransferable_ || !tokenInitiated[tokenId], "token is not transferrable");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}