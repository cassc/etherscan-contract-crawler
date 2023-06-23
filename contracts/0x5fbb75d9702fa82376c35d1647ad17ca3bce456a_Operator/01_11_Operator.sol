// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Interface/IMint.sol";
import "./Interface/IVault.sol";

contract Operator is AccessControl, ReentrancyGuard {
    enum WalletType {
        futureDistribution,
        projectFoundation
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SignerChanged(
        address indexed previousSigner,
        address indexed newSigner
    );
    event RewardPaymentRecTransferred(
        address indexed previousReciver,
        address indexed newReciver
    );
    event NonRewardPaymentRecTransferred(
        address indexed previousReciver,
        address indexed newReciver
    );
    event TokensClaimed(
        address indexed user, 
        uint256 amount
    );
    event TokensClaimedByOwners(
        uint256 futureDistributionAmt, 
        uint256 projectFoundationAmt
    );
    event ClaimDurationChanged(uint256 claimDuration);
    event MinimumUSD(uint256 minimumUSD);
    
    //contract owner
    address public owner;
    //signer
    address public signer;

    address public rewardPaymentRec =0x25B51E42c54592048c78a7e3383F06B99839Db7e;
    address public nonRewardPaymentRec =0xBE4478202984f2DD6ED235a944E12eA324D21E5A;

    uint256 public minimumUSD = 300;
    uint256 public immutable communityMintingPer;
    address[] public futureDistributionWallets;
    address[] public projectFoundationWallets;

    IVault public immutable vault;
    IMint public immutable RewardToken;
    IMint public immutable NFT;
    uint256 public claimDuration = 7 * 1 days;

    mapping(uint256 => bool) private usedNonce;
    mapping(uint256 => UserDetails) private users;

    struct UserDetails {
        uint256 amount;
        uint256 initialTime;
    }

    struct TokenDistribution {
        address[] distributionWallets;
        uint16[] distributionPercentage;
        uint256 overallPercentage;
        uint256 reservedAmt;
    }

    mapping(WalletType => TokenDistribution) private tokenDistribution;

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    constructor(
        IMint _RewardToken,
        IMint _NFT,
        IVault _vault,
        address _signer,
        uint256 _communityMintingPer,
        uint256 _futureDistributionPer,
        uint256 _projectFoundationPer,
        address[] memory _futureDistributionWallets,
        address[] memory _projectFoundationWallets,
        uint16[] memory _futureDistributionPercentage,
        uint16[] memory _projectFoundationPercentage
        
    ) {
        require(
            _futureDistributionWallets.length ==
                _futureDistributionPercentage.length,
            "FutureDistribution length mismatch"
        );
        require(
            _projectFoundationWallets.length ==
                _projectFoundationPercentage.length,
            "ProjectFoundation length mismatch"
        );
        RewardToken = _RewardToken;
        NFT = _NFT;
        vault = _vault;
        communityMintingPer = _communityMintingPer;
        tokenDistribution[WalletType(0)]
            .distributionWallets = _futureDistributionWallets;
        tokenDistribution[WalletType(1)]
            .distributionWallets = _projectFoundationWallets;
        tokenDistribution[WalletType(0)]
            .overallPercentage = _futureDistributionPer;
        tokenDistribution[WalletType(1)]
            .overallPercentage = _projectFoundationPer;
        tokenDistribution[WalletType(0)]
            .distributionPercentage = _futureDistributionPercentage;
        tokenDistribution[WalletType(1)]
            .distributionPercentage = _projectFoundationPercentage;
        _grantRole("ADMIN_ROLE", msg.sender);
        _grantRole("SIGNER_ROLE", _signer);
        owner = msg.sender;
        signer = _signer;
    }

    function setClaimPeriod(
        uint256 _claimDuration
    ) external onlyRole("ADMIN_ROLE") returns (bool) {
        claimDuration = _claimDuration;
        emit ClaimDurationChanged(_claimDuration);
        return true;
    }

    function setMinimumAmount(
        uint256 _minimumUSD
    ) external onlyRole("ADMIN_ROLE") returns (bool) {
        minimumUSD = _minimumUSD;
        emit MinimumUSD(minimumUSD);
        return true;
    }

    /**
        transfers the contract ownership to newowner address.    
        @param newOwner address of newOwner
     */

    function transferOwnership(
        address newOwner
    ) external onlyRole("ADMIN_ROLE") returns (bool) {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _grantRole("ADMIN_ROLE", newOwner);
        return true;
    }

    /**
        change the signer of tthis contract   
        @param newSigner address of newSigner
     */

    function changeSigner(
        address newSigner
    ) external onlyRole("SIGNER_ROLE") returns (bool) {
        require(
            newSigner != address(0),
            "Ownable: new signer is the zero address"
        );
        _revokeRole("SIGNER_ROLE", signer);
        emit SignerChanged(signer, newSigner);
        signer = newSigner;
        _grantRole("SIGNER_ROLE", newSigner);
        return true;
    }

    function changeRewardPaymentRec(
        address _rewardPaymentRec
    ) external onlyRole("ADMIN_ROLE") {
        require(
            _rewardPaymentRec != address(0),
            "New rewardPaymentRec is the zero address"
        );
        emit RewardPaymentRecTransferred(rewardPaymentRec, _rewardPaymentRec);
        rewardPaymentRec = _rewardPaymentRec;
    }

    function changeNonRewardPaymentRec(
        address _nonRewardPaymentRec
    ) external onlyRole("ADMIN_ROLE") {
        require(
            _nonRewardPaymentRec != address(0),
            "New rewardPaymentRec is the zero address"
        );
        emit NonRewardPaymentRecTransferred(nonRewardPaymentRec, _nonRewardPaymentRec);
        nonRewardPaymentRec = _nonRewardPaymentRec;
    }

    function changeFundingwallets(
        WalletType _tupe,
        address[] calldata wallets
    ) external onlyRole("ADMIN_ROLE") returns (bool) {
        require(
            _tupe == WalletType.futureDistribution ||
                _tupe == WalletType.projectFoundation,
            "Inalid type"
        ); //[email protected]
        require(
            tokenDistribution[WalletType(_tupe)].distributionWallets.length ==
                wallets.length,
            "Invalid Length"
        );
        tokenDistribution[WalletType(_tupe)].distributionWallets = wallets;
        return true;
    }

    function mintNft(
        string memory _tokenURI,
        uint256 ethPerUSDPrice,
        bool rewardFlag,
        Sign calldata sign
    ) external payable {
        require(msg.value >= minimumUSD * ethPerUSDPrice, "Invalid eth");
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifyOwnerSign(msg.sender, msg.value, ethPerUSDPrice, _tokenURI, rewardFlag, sign);
        bool success;
        if(rewardFlag){
            (success, ) = rewardPaymentRec.call{value: msg.value}("");
        }
        else{
            (success, ) = nonRewardPaymentRec.call{value: msg.value}("");
        }
        require(success, "Failed to send Ether");
        uint256 tokenID = NFT.safeMint(msg.sender, _tokenURI, rewardFlag);
        require(tokenID != 0, "ERC721: Minting failed");
        if (tokenID < 150001)
            distributeToken(tokenID);
    }

    function claimTokens(uint256 claimID) external nonReentrant {
        require(users[claimID].amount != 0, "Invalid ID ");
        require(msg.sender == NFT.ownerOf(claimID), "Invalid user");
        require(
            block.timestamp >=
                users[claimID].initialTime + claimDuration ,
            "Claim time not reached"
        );
        uint256 amount = users[claimID].amount;
        delete users[claimID];
        require(
            vault.transferFromVault(msg.sender, amount),
            "ERC20: Failure while Minting"
        );
        emit TokensClaimed(msg.sender, amount);
    }

    function claimTokensOwners() external onlyRole("ADMIN_ROLE") {
        require(
            tokenDistribution[WalletType(0)].reservedAmt != 0 &&
                tokenDistribution[WalletType(1)].reservedAmt != 0
        );

        uint256 length0 = tokenDistribution[WalletType(0)]
            .distributionWallets
            .length;
        uint256 length1 = tokenDistribution[WalletType(1)]
            .distributionWallets
            .length;

        for (uint8 i; i < length0; ) {
            uint256 amt = ((tokenDistribution[WalletType(0)].reservedAmt *
                tokenDistribution[WalletType(0)].distributionPercentage[i]) /
                10000);
            require(
                vault.transferFromVault(
                    tokenDistribution[WalletType(0)].distributionWallets[i],
                    amt
                ),
                "ERC20: Failure while transfering"
            );
            unchecked {
                i++;
            }
        }

        for (uint8 i; i < length1; ) {
            uint256 amt = ((tokenDistribution[WalletType(1)].reservedAmt *
                tokenDistribution[WalletType(1)].distributionPercentage[i]) /
                10000);
            require(
                vault.transferFromVault(
                    tokenDistribution[WalletType(1)].distributionWallets[i],
                    amt
                ),
                "ERC20: Failure while Minting"
            );
            unchecked {
                i++;
            }
        }
        tokenDistribution[WalletType(0)].reservedAmt = 0;
        tokenDistribution[WalletType(1)].reservedAmt = 0;
        emit TokensClaimedByOwners(tokenDistribution[WalletType(0)].reservedAmt, tokenDistribution[WalletType(1)].reservedAmt);
    }

    function walletData(
        WalletType _tupe
    ) public view returns (TokenDistribution memory) {
        return tokenDistribution[_tupe];
    }

    function userData(uint256 id) public view returns (UserDetails memory) {
        return users[id];
    }

    function calculateTier(
        uint256 tokenID
    ) public pure returns (uint256 amount) {
        if (tokenID >= 1 && tokenID <= 2500) {
            return 15000 * 1e18;
        } else if (tokenID >= 2501 && tokenID <= 7500) {
            return 14250 * 1e18;
        } else if (tokenID >= 7501 && tokenID <= 15000) {
            return 12825 * 1e18;
        } else if (tokenID >= 15001 && tokenID <= 22500) {
            return 10900 * 1e18;
        } else if (tokenID >= 22501 && tokenID <= 30000) {
            return 8720 * 1e18;
        } else if (tokenID >= 30001 && tokenID <= 40000) {
            return 6540 * 1e18;
        } else if (tokenID >= 40001 && tokenID <= 50000) {
            return 4578 * 1e18;
        } else if (tokenID >= 50001 && tokenID <= 75000) {
            return 2975 * 1e18;
        } else if (tokenID >= 75001 && tokenID <= 100000) {
            return 1785 * 1e18;
        } else if (tokenID >= 100001 && tokenID <= 150000) {
            return 980 * 1e18;
        }
    }

    function distributeToken(uint256 tokenID) internal {
        uint256 rewardAmount = calculateTier(tokenID);
        uint256 minterRewardAmt = (rewardAmount * communityMintingPer) / 100;
        tokenDistribution[WalletType(0)].reservedAmt =
            (rewardAmount *
                tokenDistribution[WalletType(0)].overallPercentage) /
            100;
        tokenDistribution[WalletType(1)].reservedAmt =
            (rewardAmount *
                tokenDistribution[WalletType(1)].overallPercentage) /
            100;
        users[tokenID] = UserDetails(minterRewardAmt, block.timestamp);
        require(
            RewardToken.mint(address(vault), rewardAmount),
            "failed to mint"
        );
    }

    /**
        returns the signer of given signature.
     */
    function getSigner(
        bytes32 hash,
        Sign memory sign // [email protected] function
    ) internal pure returns (address) {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                sign.v,
                sign.r,
                sign.s
            );
    }

    function verifyOwnerSign(
        address to,
        uint256 amount,
        uint256 perUSDPrice,
        string memory tokenURI,
        bool rewardFlag,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(to, amount, perUSDPrice, tokenURI, rewardFlag, sign.nonce)
        );
        require(signer == getSigner(hash, sign), "sign verification failed");
    }
}