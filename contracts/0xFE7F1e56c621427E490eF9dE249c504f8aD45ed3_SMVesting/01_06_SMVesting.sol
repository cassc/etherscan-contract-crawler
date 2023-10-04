// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20BackwardsCompatible.sol";

contract SMVesting is Ownable, ReentrancyGuard {
    address public immutable SMC;
    IERC20 public immutable smc;
    address public immutable SLP;
    IERC20 public immutable slp;

    mapping (address => uint256) public ethAmount;
    mapping (address => mapping (uint256 => bool)) public claims;
    mapping (address => uint256) public claimedTokens;
    mapping (address => uint256) public claimedLpTokens;
    uint256 public ethTotal = 84_000_000 ether;
    uint256 public start;
    uint256 public slpTotal;

    constructor (address _SMC, address _SLP) {
        SMC = _SMC;
        smc = IERC20(_SMC);
        SLP = _SLP;
        slp = IERC20(_SLP);

        //PRESALERS
        ethAmount[0xD18B0c6eFef33DaD909eC86D6e18eBf292836c72] = 139485.43616457 ether;
        ethAmount[0x96d5F564D347496f3217c2649599Bef3a1AD59Bc] = 1046140.77123428 ether;
        ethAmount[0x708F2D42c28659eEB32A6b091300079DE5Da762A] = 348713.590411425 ether;
        ethAmount[0x949710D6fF4D3D8030694b5582126Bad57250066] = 697427.18082285 ether;
        ethAmount[0xE4e11BfD7CE95036582CD7a86F6DabF54AB900f9] = 383584.949452568 ether;
        ethAmount[0xb7f64cd4A7cf08325b411A36Ee7ADd648E0B4752] = 348713.590411425 ether;
        ethAmount[0xCbA5dFee5A80aE669B97cD35E92641bE7B684D87] = 697427.18082285 ether;
        ethAmount[0x502452a508546016d35bd0381972B0833b8243ff] = 697427.18082285 ether;
        ethAmount[0x8B0ed17D29693b515ae216dc04583Ae936dC261c] = 209228.154246855 ether;
        ethAmount[0x610188A80d2659EDE5d68bD32b9cA8cDe47539FA] = 174356.795205713 ether;
        ethAmount[0x877b3E08682d1E131dBeAB76B2CDDc2cD4c03224] = 87178.3976028563 ether;
        ethAmount[0x8f3652E9E6fbb9CF49D21d203a11A1F33BbD447d] = 453327.667534853 ether;
        ethAmount[0xB26c2511f02025c3002962c0E0eaC7c5bC50D2bB] = 1046140.77123428 ether;
        ethAmount[0xC1bb5cBe54071f43cC7f96c5D0c7C82b6852Af35] = 217520.666497793 ether;
        ethAmount[0xDeABE8d70c4fb1D13ac46c5a5ab117EcBfC08186] = 348713.590411425 ether;
        ethAmount[0xBA94E79B45b04Da4feD98B3587B75DaCb2eF28bD] = 104614.077123428 ether;


        //WALLETS
        ethAmount[0x356815f53d5DFa738E5a38ffB261afa8731e45Be] = 7_000_000 ether; //fostering partnership synergies
        ethAmount[0x60e18f804FF8aB716b83ee65D2893B292481911F] = 30_000_000 ether; //cross-chain bridging
        ethAmount[0x25d2FCd5759C3B822672B4d78faf1e7DC350b2B5] = 10_000_000 ether; //philanthropy
        ethAmount[0x8Bf164d2aDf1167f9611B8067D1a845f89cdeA61] = 15_000_000 ether; //House Wallet 1
        ethAmount[0x7B85429fa9E1c7F83B2Cb3Ca4Be367Decb708886] = 15_000_000 ether; //House Wallet 2

        start = block.timestamp;
    }

    function setSLPTotal(uint256 _slpTotal) external nonReentrant onlyOwner {
        slpTotal = _slpTotal;
    }

    function getTokensPerAccount(address _account) public view returns (uint256) {
        if (ethAmount[_account] == 0) {
            return 0;
        }
        return ethAmount[_account];
    }

    function getLpTokensPerAccount(address _account) public view returns (uint256) {
        if (ethAmount[_account] == 0) {
            return 0;
        }
        return slpTotal * ethAmount[_account] / ethTotal;
    }

    function getClaimsByAccount(address _account) external view returns (uint256, uint256) {
        return (claimedTokens[_account], claimedLpTokens[_account]);
    }

    function claim() external nonReentrant {
        uint256 _tokens;
        uint256 _lpTokens;
        if ((block.timestamp) >= start && (!claims[msg.sender][0])) {
            _tokens += getTokensPerAccount(msg.sender) * 10000 / 60000;
            claimedTokens[msg.sender] += _tokens;
            claims[msg.sender][0] = true;
        }
        if ((block.timestamp >= start + (86400 * 7)) && (!claims[msg.sender][1])) {
            _tokens += getTokensPerAccount(msg.sender) * 10000 / 60000;
            _lpTokens += getLpTokensPerAccount(msg.sender) * 10000 / 50000;
            claimedTokens[msg.sender] += _tokens;
            claimedLpTokens[msg.sender] += _lpTokens;
            claims[msg.sender][1] = true;
        }
        if ((block.timestamp >= start + (86400 * 14)) && (!claims[msg.sender][2])) {
            _tokens += getTokensPerAccount(msg.sender) * 10000 / 60000;
            _lpTokens += getLpTokensPerAccount(msg.sender) * 10000 / 50000;
            claimedTokens[msg.sender] += _tokens;
            claimedLpTokens[msg.sender] += _lpTokens;
            claims[msg.sender][2] = true;
        }
        if ((block.timestamp >= start + (86400 * 21)) && (!claims[msg.sender][3])) {
            _tokens += getTokensPerAccount(msg.sender) * 10000 / 60000;
            _lpTokens += getLpTokensPerAccount(msg.sender) * 10000 / 50000;
            claimedTokens[msg.sender] += _tokens;
            claimedLpTokens[msg.sender] += _lpTokens;
            claims[msg.sender][3] = true;
        }
        if ((block.timestamp >= start + (86400 * 28)) && (!claims[msg.sender][4])) {
            _tokens += getTokensPerAccount(msg.sender) * 10000 / 60000;
            _lpTokens += getLpTokensPerAccount(msg.sender) * 10000 / 50000;
            claimedTokens[msg.sender] += _tokens;
            claimedLpTokens[msg.sender] += _lpTokens;
            claims[msg.sender][4] = true;
        }
        if ((block.timestamp >= start + (86400 * 35)) && (!claims[msg.sender][5])) {
            _tokens += getTokensPerAccount(msg.sender) * 10000 / 60000;
            _lpTokens += getLpTokensPerAccount(msg.sender) * 10000 / 50000;
            claimedTokens[msg.sender] += _tokens;
            claimedLpTokens[msg.sender] += _lpTokens;
            claims[msg.sender][5] = true;
        }
        if (_tokens > 0) {
            smc.transfer(msg.sender, _tokens);
        }
        if (_lpTokens > 0) {
            slp.transfer(msg.sender, _lpTokens);
        }
    }

    function emergencyWithdrawToken(address _token, uint256 _amount) external nonReentrant onlyOwner {
        IERC20BackwardsCompatible(_token).transfer(msg.sender, _amount);
    }

    function emergencyWithdrawETH(uint256 _amount) external nonReentrant onlyOwner {
        (bool success,) = payable(msg.sender).call{value : _amount}("");
    }

    receive() external payable {}
}