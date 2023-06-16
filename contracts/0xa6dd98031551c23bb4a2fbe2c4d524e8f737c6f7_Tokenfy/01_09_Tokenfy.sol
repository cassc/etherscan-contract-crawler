// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// .___________.  ______    __  ___  _______ .__   __.  ___________    ____ 
// |           | /  __  \  |  |/  / |   ____||  \ |  | |   ____\   \  /   / 
// `---|  |----`|  |  |  | |  '  /  |  |__   |   \|  | |  |__   \   \/   /  
//     |  |     |  |  |  | |    <   |   __|  |  . `  | |   __|   \_    _/   
//     |  |     |  `--'  | |  .  \  |  |____ |  |\   | |  |        |  |     
//     |__|      \______/  |__|\__\ |_______||__| \__| |__|        |__|     

contract Tokenfy is ERC20, EIP712, Ownable {
    
    // max supply
    uint256 public constant MAX_SUPPLY = uint256(1e9 ether);

    // for staking
    uint256 public constant STAKING_AMOUNT = MAX_SUPPLY / 100 * 20;
    address public constant STAKING_ADDRESS = 0x34d2F783c894F898e61162719029058f12Ed2C0a;

    // for LP
    uint256 public constant LP_AMOUNT = MAX_SUPPLY / 100 * 10;
    address public constant LP_ADDRESS = 0xb4abB3A17E48F49B72079f9db42c6A443BE8C30c;

    // for platform development and marketing
    uint256 public constant TREASURY_AMOUNT = MAX_SUPPLY / 100 * 5;
    address public constant TREASURY_ADDRESS = 0x269Fb5d729bA03710C522B0b4644CA2414F72f79;

    // for team, advisors, investors
    uint256 public constant TEAM_AMOUNT = MAX_SUPPLY / 100 * 10;
    address public constant TEAM_ADDRESS = 0xDf5deF1866f934A638454BFa80b75D5Bc1A301D2;

    // for referrals
    uint256 public constant REFERRALS_AMOUNT = MAX_SUPPLY / 100 * 5;

    // for free claim
    uint256 public constant AIRDROP_AMOUNT = MAX_SUPPLY - (STAKING_AMOUNT + LP_AMOUNT + TREASURY_AMOUNT + TEAM_AMOUNT + REFERRALS_AMOUNT);

    // claimed airdrop statuses
    mapping (address => bool) public claimed;

    // amount signer
    address public immutable signerAddress;

    // is free claim now live
    bool public claimLive = false;
    uint256 public claimedAmount = 0;
    uint256 public rewardsAmount = 0;

    // has minted to treasury
    bool public treasuryMint = false;

    bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address receiver,uint256 amount)");

    constructor(
        string memory _name, 
        string memory _symbol, 
        address _signerAddress,
        address stakingFeeAddress_,
        address LPFeeAddress_,
        address DAOFeeAddess_,
        address treasuryAddress_
    ) ERC20(_name, _symbol, stakingFeeAddress_, LPFeeAddress_, DAOFeeAddess_, treasuryAddress_) EIP712("Tokenfy", "1") {
        _mint(STAKING_ADDRESS, STAKING_AMOUNT);
        _mint(LP_ADDRESS, LP_AMOUNT);
        _mint(TREASURY_ADDRESS, TREASURY_AMOUNT);
        _mint(TEAM_ADDRESS, TEAM_AMOUNT);
        
        signerAddress = _signerAddress;
    }

    /**
    * @dev mints free claim tokens and referral rewards
    * Referrals must claim to receive rewards from invitees
    */
    function claim(uint256 amountV, bytes32 r, bytes32 s, address referral) external {
        require(claimLive, "Tokenfy: claim is not live");

        uint256 amount = uint248(amountV);
        uint8 v = uint8(amountV >> 248);
        uint256 total = totalSupply() + amount;
        require(total <= MAX_SUPPLY, "Tokenfy: > max supply");
        require(!claimed[msg.sender], "Tokenfy: Already claimed");
        require(signerValid(v, r, s, msg.sender, amount, referral), "Tokenfy: Invalid signer");
        
        claimed[msg.sender] = true;
        _mint(msg.sender, amount);
        claimedAmount += amount;

        if (referral != address(0) && claimed[referral] && referral != msg.sender && ((total + amount / 10) <= MAX_SUPPLY)) {
            uint256 reward = amount / 10;
            _mint(referral, reward);
            rewardsAmount += reward;
        }
    }

    /**
    * @dev checks signature validity
    */
    function signerValid(uint8 v, bytes32 r, bytes32 s, address sender, uint256 amount, address referral) private view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(
                ECDSA.toTypedDataHash(_domainSeparatorV4(),
                    keccak256(abi.encode(MINT_CALL_HASH_TYPE, sender, amount))),
                referral))
        ));
        
        return ecrecover(digest, v, r, s) == signerAddress;
    }

    /**
    * @dev starts/stops free claim
    */
    function setClaimLive(bool live) external onlyOwner {
        claimLive = live;
    }

    /**
    * @dev changes addresses that receive fees on transfer
    */
    function setTransferFeesAddresses(
        address stakingAddress_,
        address LPAddress_,
        address DAOAddess_,
        address treasuryAddress_
    ) external onlyOwner {
        _stakingAddress = stakingAddress_;
        _LPAddress = LPAddress_;
        _DAOAddess = DAOAddess_;
        _treasuryAddress = treasuryAddress_;
    }

    /**
    * @dev transfers unclaimed tokens to the treasury
    */
    function transferToTreasury(address treasury) external onlyOwner {
        require(!claimLive, "Tokenfy: claim is live");
        require(!treasuryMint, "Tokenfy: already transferred");
        uint256 remainingTokens = AIRDROP_AMOUNT + REFERRALS_AMOUNT - claimedAmount - rewardsAmount;

        _mint(treasury, remainingTokens);
        treasuryMint = true;
    }

    /**
    * @dev changes status of address in the whitelist
    */
    function changeWhitelistStatus(address whitelisted, bool from, bool to) external onlyOwner {
        whitelistedFrom[whitelisted] = from;
        whitelistedTo[whitelisted] = to;
    }

}