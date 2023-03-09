// SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.8.0 <=0.8.19;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IERC1155SelfMinter {
    struct Supply {
        uint256 max;
        uint256 total;
    }

    function saleId() external view returns (uint256);
    function supplyPerId(uint256 saleId) external view returns (Supply memory);
    function batchMint(address mintAddress, uint256 amount) external;
}

contract ERC1155PaymentProxy is ERC1155, ReentrancyGuard, DefaultOperatorFilterer, Ownable {   
    struct Tier {
        uint256 start;
        uint256 end;
        bytes32 merkleRoot;
        uint256 limitPerWalletPerTier;
        bool isPublic;
    }

    struct Supply {
        uint256 max;
        uint256 total;
    }

    IERC20 public tokenContract;
    IERC1155SelfMinter public originalContract;

    address tokenAddress;
    address originalContractAddress;
    address public treasuryWallet;

    uint256 public mintFee;
    uint256 public minimumUserBalance = 0;

    mapping(uint256 => Tier) public tiers;
    mapping(address => uint256) public mintedPerAddress;
    mapping(address => bool) public isAdmin;

    bool public initialized;

    function _onlyAdminOrOwner(address _address) private view {
        require(
            isAdmin[_address] || _address == owner(),
            "This address is not allowed"
        );
    }

    modifier onlyAdminOrOwner(address _address) {
        _onlyAdminOrOwner(_address);
        _;
    }

    event TierMint(address indexed user, uint256 indexed _tier, uint256 indexed _amount);

    constructor() ERC1155(""){}

    function initialize(
        address _originalContractAddress,
        address _tokenAddress,
        address _treasuryWallet,
        uint256 _mintFee,
        uint256 _minimumUserBalance
    ) public onlyAdminOrOwner(msg.sender) {
        require (!initialized, "Contract already initialized");
        require (address(0) != _treasuryWallet, "Invalid treasury wallet");
    
        originalContractAddress = _originalContractAddress;
        tokenAddress = _tokenAddress;
        mintFee = _mintFee;
        treasuryWallet = _treasuryWallet;
        minimumUserBalance = _minimumUserBalance;
        initialized = true;

        originalContract = IERC1155SelfMinter(_originalContractAddress);
        tokenContract = IERC20(_tokenAddress);
    }

    function setTiersConfig(
        uint256[] memory tiersNumbers,
        uint256[] memory limitPerWalletPerTier,
        uint256[] memory starts,
        uint256[] memory ends,
        bytes32[] memory merkleRoots,
        bool[] memory isTierPublic
    ) public onlyAdminOrOwner(msg.sender) {
        require (tiersNumbers.length == starts.length, "Starts array is invalid");
        require (tiersNumbers.length == ends.length, "Ends array is invalid");
        require (tiersNumbers.length == merkleRoots.length, "Merkle Roots array is invalid");
        require (tiersNumbers.length == limitPerWalletPerTier.length, "Limits per wallet array invalid");
        require (tiersNumbers.length == isTierPublic.length, "Is Public Tier array is invalid");

        for (uint256 i = 0; i < tiersNumbers.length; i++) {
            tiers[tiersNumbers[i]] = Tier(starts[i], ends[i], merkleRoots[i], limitPerWalletPerTier[i], isTierPublic[i]);
        }
    }

    function setContractOwnership(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    function setContractAdmin(address _address) public onlyOwner {
        isAdmin[_address] = true;
    }

    function deleteContractAdmin(address _address) public onlyOwner {
        isAdmin[_address] = false;
    }

    function setTreasury(address _treasuryWallet) public onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function setMintFee(uint256 _mintFee) public onlyAdminOrOwner(msg.sender) {
        mintFee = _mintFee;
    }

    function setMinimumUserBalance(uint256 _minimumUserBalance) public onlyAdminOrOwner(msg.sender) {
        minimumUserBalance = _minimumUserBalance;
    }

    function getTier(uint256 tierNo) public view returns (Tier memory) {
        return tiers[tierNo];
    }

    function getSaleId() public view returns (uint256) {
        return originalContract.saleId();
    }

    function supplyPerId(uint256 _saleId) public view returns (Supply memory) {
         IERC1155SelfMinter.Supply memory originalSupply = originalContract.supplyPerId(_saleId);

         return Supply(originalSupply.max, originalSupply.total);
    }
    
    function tierMint(
        address mintAddress,
        uint256 tierNo,
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) external {
        uint256 payment = mintFee * amount;

        _mintValidation(mintAddress, tierNo, amount, _merkleProof);
        _mintFeeCheck(msg.sender, amount);

        tokenContract.transferFrom(msg.sender, treasuryWallet, payment);

        mintedPerAddress[mintAddress] += amount;

        originalContract.batchMint(mintAddress, amount);

        emit TierMint(mintAddress, tierNo, amount);
    }

    function _mintFeeCheck(address user, uint256 amount) internal view {
        require(
            tokenContract.balanceOf(user) >= mintFee * amount,
            "doesn't have enough tokens to mint the NFT"
        );
    }

    function _mintValidation(
        address mintAddress,
        uint256 tierNo,
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) internal view {
        require (tierNo > 0, "Tier number incorrect");

        Tier memory tier = getTier(tierNo);

        require (tier.start <= block.timestamp, "Tier period hasn't started yet");
        require (tier.end > block.timestamp, "Tier period has already ended");
        require (tier.isPublic || MerkleProof.verify(_merkleProof, tier.merkleRoot, keccak256(abi.encodePacked(mintAddress, tierNo))), "Invalid proof");
        require (mintedPerAddress[mintAddress] + amount <= tiers[tierNo].limitPerWalletPerTier, "Mint limit reached");
        require(
            ERC20(tokenAddress).balanceOf(mintAddress) >= minimumUserBalance,
            "The amount of coins in the wallet is below the eligibility threshold"
        );
    }
}