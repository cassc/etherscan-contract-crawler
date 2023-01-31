// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "../interface/INftProfileHelper.sol";
import "../interface/IGenesisKeyStake.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

interface INftProfile {
    function createProfile(
        address receiver,
        string memory _profileURI,
        uint256 _expiry
    ) external;

    function totalSupply() external view returns (uint256);

    function extendLicense(
        string memory _profileURI,
        uint256 _duration,
        address _licensee
    ) external;

    function purchaseExpiredProfile(
        string memory _profileURI,
        uint256 _duration,
        address _receiver
    ) external;

    function tokenUsed(string memory _string) external view returns (bool);

    function profileOwner(string memory _string) external view returns (address);
}

struct BatchClaimProfile {
    string profileUrl;
    uint256 tokenId;
    address recipient;
    bytes32 hash;
    bytes signature;
}

contract ProfileAuction is Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using StringUtils for *;
    using ECDSAUpgradeable for bytes32;

    address public governor;
    uint96 public yearlyFee; // public fee for mint price

    address public owner;
    uint96 public yearsToOwn; // number of years of license to pay to own a profile

    address public usdc_;
    bool public publicMintBool; // true to allow public mint
    bool public genKeyWhitelistOnly; // true to only allow merkle claims

    address public nftProfile;
    address public contract2;
    address public mintFeesAddress;
    address public nftProfileHelperAddress;
    address public genesisKeyContract;
    address public signerAddress;

    mapping(uint256 => uint256) public genesisKeyClaimNumber; // genKey tokenId => number of profiles claimed
    mapping(uint256 => uint256) public lengthPremium; // premium multiple for profile length
    mapping(string => uint256) public ownedProfileStake; // genKey tokenId => staked token
    mapping(bytes32 => bool) public cancelledOrFinalized; // used hash
    mapping(address => uint256) public publicMinted; // record of profiles public minted per user

    address public extendFeesAddress; // empty slot for now, to be used in future
    uint88 public maxProfilePerAddress; // unusued
    bool public publicClaimBool; // unusued

    event MintedProfile(
        address _user,
        string _val,
        uint256 tokenId,
        uint256 _duration,
        uint256 _fee,
        address _paymentToken
    );
    event NewLengthPremium(uint256 _length, uint256 _premium);
    event NewYearlyFee(uint96 _fee);

    modifier validAndUnusedURI(string memory _profileURI) {
        require(validURI(_profileURI));
        require(!INftProfile(nftProfile).tokenUsed(_profileURI));
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function initialize(
        address _nftProfile,
        address _governor,
        address _nftProfileHelperAddress,
        address _genesisKeyContract
    ) public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        nftProfile = _nftProfile;
        nftProfileHelperAddress = _nftProfileHelperAddress;

        owner = msg.sender;
        governor = _governor;
        genesisKeyContract = _genesisKeyContract;
        genKeyWhitelistOnly = true;

        lengthPremium[1] = 1024;
        lengthPremium[2] = 512;
        lengthPremium[3] = 128;
        lengthPremium[4] = 32;
        yearlyFee = 100 * 10**18;
        yearsToOwn = 2;

        signerAddress = 0x9EfcD5075cDfB7f58C26e3fB3F22Bb498C6E3174;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     @notice helper function transfer tokens
     @param _amount number of tokens being transferred
    */
    function transferTokens(address recipient, uint256 _amount) private returns (bool) {
        if (usdc_ == address(0)) {
            if (msg.value >= _amount) {
                safeTransferETH(recipient, _amount); // send amount to recipient
                safeTransferETH(msg.sender, msg.value - _amount); // refund excess
                return true;
            } else {
                return false;
            }
        } else {
            // send amount to recipient
            return IERC20Upgradeable(usdc_).transferFrom(msg.sender, recipient, _amount);
        }
    }

    /**
     @notice helper function to add permit
    */
    function permitNFT(
        address _owner,
        address spender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        return IERC20PermitUpgradeable(usdc_).permit(_owner, spender, type(uint256).max, type(uint256).max, v, r, s);
    }

    function validURI(string memory _name) private view returns (bool) {
        return INftProfileHelper(nftProfileHelperAddress)._validURI(_name);
    }

    // GOV FUNCTIONS
    function setOwner(address _new) external onlyOwner {
        owner = _new;
    }

    function setGovernor(address _new) external onlyGovernor {
        governor = _new;
    }

    function setSigner(address _signer) external onlyOwner {
        signerAddress = _signer;
    }

    function setUsdc(address _usdc) external onlyOwner {
        usdc_ = _usdc;
    }

    function setMintFeesAddress(address _new) external onlyOwner {
        mintFeesAddress = _new;
    }

    function setContract2(address _new) external onlyOwner {
        contract2 = _new;
    }

    function setExtendFeeAddress(address _new) external onlyOwner {
        extendFeesAddress = _new;
    }

    function verifySignature(bytes32 hash, bytes memory signature) public view returns (bool) {
        return signerAddress == hash.recover(signature);
    }

    function setLengthPremium(uint256 _length, uint256 _premium) external onlyGovernor {
        lengthPremium[_length] = _premium;
        emit NewLengthPremium(_length, _premium);
    }

    function setYearlyFee(uint96 _fee) external onlyGovernor {
        yearlyFee = _fee;
        emit NewYearlyFee(_fee);
    }

    function setGenKeyWhitelistOnly(bool _genKeyWhitelistOnly) external onlyGovernor {
        genKeyWhitelistOnly = _genKeyWhitelistOnly;
    }

    function setPublicMint(bool _val) external onlyGovernor {
        publicMintBool = _val;
    }

    function hashTransaction(address sender, string memory profileUrl) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(sender, profileUrl)))
        );

        return hash;
    }

    // CLAIM FUNCTIONS
    function genesisKeyBatchClaimProfile(
        BatchClaimProfile[] memory claims
    ) external nonReentrant {
        uint256 claimsLength = claims.length;
        for (uint256 i = 0; i < claimsLength; ) {
            string memory profileUrl = claims[i].profileUrl;
            uint256 tokenId = claims[i].tokenId;
            address recipient = claims[i].recipient;
            bytes32 hash = claims[i].hash;
            bytes memory signature = claims[i].signature;
            
            // checks
            require(IERC721EnumerableUpgradeable(genesisKeyContract).ownerOf(tokenId) == recipient, "gkp: !owner");
            require(validURI(profileUrl), "gkp: !validURI");
            require(!INftProfile(nftProfile).tokenUsed(profileUrl), "gkp: !unused");
            require(verifySignature(hash, signature) && !cancelledOrFinalized[hash], "gkp: !sig");
            require(hashTransaction(msg.sender, profileUrl) == hash, "gkp: !hash");
            uint256 profilesAllowed = genKeyWhitelistOnly ? 4 : 7;
            require(genesisKeyClaimNumber[tokenId] != profilesAllowed);

            // effects
            genesisKeyClaimNumber[tokenId] += 1;

            // interactions
            INftProfile(nftProfile).createProfile(
                recipient,
                profileUrl,
                genesisKeyClaimNumber[tokenId] <= 4 ? 1000 * (365 days) : 365 days
            );

            emit MintedProfile(
                recipient,
                profileUrl,
                INftProfile(nftProfile).totalSupply() - 1,
                genesisKeyClaimNumber[tokenId] <= 4 ? 1000 * (365 days) : 365 days,
                0,
                usdc_
            );

            unchecked {
                ++i;
            }
        }
    }

    function publicMint(
        string memory profileUrl,
        uint256 duration,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 hash,
        bytes memory signature
    ) external payable nonReentrant validAndUnusedURI(profileUrl) {
        // checks
        require(publicMintBool, "pm: !publicMint");
        require(verifySignature(hash, signature) && !cancelledOrFinalized[hash], "pm: !sig");
        require(hashTransaction(msg.sender, profileUrl) == hash, "pm: !hash");
        require(duration >= 365 days, "pm: !t");

        // interactions
        if (usdc_ != address(0) && IERC20Upgradeable(usdc_).allowance(msg.sender, address(this)) == 0) {
            permitNFT(msg.sender, address(this), v, r, s); // approve token
        }

        require(transferTokens(mintFeesAddress, getFee(profileUrl, duration)), "pm: !funds");

        INftProfile(nftProfile).createProfile(msg.sender, profileUrl, duration);

        emit MintedProfile(
            msg.sender,
            profileUrl,
            INftProfile(nftProfile).totalSupply() - 1,
            duration,
            getFee(profileUrl, duration),
            usdc_
        );
    }

    function getFee(string memory profileUrl, uint256 duration) public view returns (uint256) {
        uint256 baseFee = (yearlyFee * duration) / 365 days;
        uint256 premium = lengthPremium[profileUrl.strlen()];

        // if premium is not set, then use base fee, otherwise, multiply
        return premium == 0 ? baseFee : baseFee * premium;
    }

    /**
     * @dev allows any user to pay to extend a profile
     * @param profileUrl profileUrl to extend
     * @param duration number of seconds to extend
     */
    function extendLicense(
        string memory profileUrl,
        uint256 duration,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        require(publicMintBool, "el: public minting is disabled");

        if (usdc_ != address(0) && IERC20Upgradeable(usdc_).allowance(msg.sender, address(this)) == 0) {
            permitNFT(msg.sender, address(this), v, r, s);
        }

        require(transferTokens(extendFeesAddress, getFee(profileUrl, duration)), "el: insufficient funds");

        INftProfile(nftProfile).extendLicense(profileUrl, duration, msg.sender);
    }

    function purchaseExpiredProfile(
        string memory profileUrl,
        uint256 duration,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        // checks
        require(publicMintBool, "pe: public minting is disabled");
        require(ownedProfileStake[profileUrl] == 0, "pe: profile is already staked");

        // effects
        // interactions
        if (usdc_ != address(0) && IERC20Upgradeable(usdc_).allowance(msg.sender, address(this)) == 0) {
            permitNFT(msg.sender, address(this), v, r, s);
        }

        require(transferTokens(extendFeesAddress, getFee(profileUrl, duration)), "pe: insufficient funds");

        INftProfile(nftProfile).purchaseExpiredProfile(profileUrl, duration, msg.sender);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "STE");
    }
}