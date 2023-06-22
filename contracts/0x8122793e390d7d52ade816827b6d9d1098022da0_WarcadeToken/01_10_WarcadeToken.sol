// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// free claim 10%
// early access 20%
// liquidity 5%
// marketing 5%
// dev fund 40%, 3 year vesting
// nft fund 20%, 6 months lockup

contract WarcadeToken is Ownable, ERC20, ERC20Burnable {
    using ECDSA for bytes32;

    uint256 constant public MAX_SUPPLY = (10**10) * (10**18); // 10 billion WAR
    address public devWallet;
    address public nftAddress;
    address private signerAddress;

    // free claim variables
    uint256 constant public MAX_CLAIM_TOKENS = MAX_SUPPLY *10 / 100 ;
    uint256 public weiClaimed;
    mapping(address => bool) private claimed;

    // early access variables
    uint256 constant public EA_RATE = 4 * 10**7; // 1eth = 40mil WAR
    uint256 public maxEaValuePerAddress = 0.5 ether;
    uint256 public maxEaValue = 50 ether;
    uint256 public weiRaised;
    mapping(address => uint256) private contributions;
    error EarlyAccessFilled();
    error ClaimFilled();
    error MaxContributionReached();
    error TokenPurchaseFailed();
    error TokenRefundFailed();
    error RefundUnavailable();
    error WithdrawUnavailable();

    // vesting and lock variables
    uint64 public vestingStartTS;
    uint64 public constant devVestingCliff = 7890000; //3 months
    uint64 public constant devVestingDuration = 94608000; //3 years
    uint64 public constant nftLockDuration = 15780000; //6 months

    uint256 public constant devAllowance = MAX_SUPPLY * 40 / 100;
    uint256 public constant nftAllowance = MAX_SUPPLY * 20 / 100;
    uint256 private devFundDistributed;
    bool private nftFundDistributed;

    error NftDistributionFailed();
    error NftAddressZero();
    error BadSignature();
    error AlreadyClaimed();

    constructor() ERC20("Warcade", "WAR") {
        devWallet = msg.sender;
        signerAddress = 0xF984081d716Ec25edE5D4759b000A1Afc67b0F76;
        vestingStartTS = uint64(block.timestamp);
        _mint(msg.sender, MAX_SUPPLY * 10 / 100); // v2 liquidity  + marketing fund
    }

    fallback() external payable {
        buyTokens();
    }
    receive() external payable{
        buyTokens();
    }

    function setDevWallet(address _devWallet) public onlyOwner {
        devWallet = _devWallet;
    }

    function setNftAddress(address _nftAddress) public onlyOwner {
        nftAddress = _nftAddress;
    }

    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    function setMaxEaValue(uint256 _maxEaValue) public onlyOwner {
        maxEaValue = _maxEaValue;
    }
    function setMaxEaValuePerAddress(uint256 _maxEaValuePerAddress) public onlyOwner {
        maxEaValuePerAddress = _maxEaValuePerAddress;
    }

    function withdraw(uint256 amount) public onlyOwner{
        if(!(weiRaised == maxEaValue)) { revert WithdrawUnavailable();}
        (bool success,) = owner().call{value: amount}("");
        success;
    }

    function getContribution(address beneficiary) public view returns (uint256) {
        return contributions[beneficiary];
    }

    function getRemainingEarlyAccessAmount() public view returns (uint256) {
        return maxEaValue - weiRaised;
    }

    function buyTokens() public payable {
        if(msg.value + weiRaised > maxEaValue ){ revert EarlyAccessFilled();}
        if(msg.value + contributions[msg.sender] > maxEaValuePerAddress) { revert MaxContributionReached();}
        contributions[msg.sender] += msg.value;
        weiRaised += msg.value;
    }

    function withdrawTokens() public {
        if(!(weiRaised == maxEaValue)) { revert WithdrawUnavailable();}
        uint256 warTokenAmount = contributions[msg.sender] * EA_RATE;
        contributions[msg.sender] = 0;
        _mint(msg.sender, warTokenAmount);
    }

    function refundTokens() public {
        if(weiRaised == maxEaValue) { revert RefundUnavailable();}
        uint256 refundValue = contributions[msg.sender];
        contributions[msg.sender] = 0;
        weiRaised -= refundValue;
        (bool sent, ) = msg.sender.call{value: refundValue}("");
        if(!sent) { revert TokenRefundFailed();}
    }

    function _hash(address sender, uint256 quantity) internal view returns (bytes32) {
        return keccak256(abi.encode(address(this),sender, quantity)).toEthSignedMessageHash();
    }

    function _verify( bytes memory signature, uint256 quantity) internal view returns (bool) {
        return (_hash(msg.sender, quantity).recover(signature) == signerAddress);
    }

    function claim(bytes calldata signature, uint256 quantity) public {
        if (claimed[msg.sender]) { revert AlreadyClaimed();}
        if (weiClaimed + quantity > MAX_CLAIM_TOKENS) { revert ClaimFilled();}
        if (!(_verify(signature, quantity))) { revert BadSignature();}
        claimed[msg.sender] = true;
        weiClaimed += quantity;
        _mint(msg.sender, quantity);
    }

    function devRelease() public {
        uint256 amount = devReleasableAmount();
        devFundDistributed += amount;
        _mint(devWallet, amount);
    }

    function devReleasableAmount() public view returns (uint256) {
        return devVestedAmount() - devFundDistributed;
    }

    function devVestedAmount() public view returns (uint256) {
        if (block.timestamp > vestingStartTS + devVestingDuration) {
            return devAllowance;
        } else if (block.timestamp < vestingStartTS + devVestingCliff) {
            return 0;
        } else {
            uint256 elapsedSeconds = block.timestamp - vestingStartTS;
            uint256 bps = (elapsedSeconds * 1000) / devVestingDuration;
            uint256 subValue = (devAllowance * bps) / 1000;
            return subValue;
        }
    }

    function nftRelease() public {
        if (nftFundDistributed) { revert NftDistributionFailed();}
        if (nftAddress == address(0)) { revert NftAddressZero();}
        if (block.timestamp > vestingStartTS + nftLockDuration) {
            nftFundDistributed = true;
            _mint(nftAddress, nftAllowance);
        }
    }
}