// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

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

error MaxProfiles();

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
    address public contract1;
    address public nftProfileHelperAddress;
    address public genesisKeyContract;
    address public signerAddress;

    mapping(uint256 => uint256) public genesisKeyClaimNumber; // genKey tokenId => number of profiles claimed
    mapping(uint256 => uint256) public lengthPremium; // premium multiple for profile length
    mapping(string => uint256) public ownedProfileStake; // genKey tokenId => staked token
    mapping(bytes32 => bool) public cancelledOrFinalized; // used hash
    mapping(address => uint256) public publicMinted; // record of profiles public minted per user

    address public emptySlot; // empty slot for now, to be used in future
    uint88 public maxProfilePerAddress; // max profiles that can be minted per address, set by DAO
    bool public publicClaimBool;

    event UpdatedProfileStake(string _profileUrl, uint256 _stake);
    event MintedProfile(address _user, string _val, uint256 tokenId, uint256 _duration, uint256 _fee);
    event ExtendLicense(address _receiver, string _profileUrl, uint256 _duration, uint256 _fee, bool _expired);
    event NewLengthPremium(uint256 _length, uint256 _premium);
    event NewYearlyFee(uint96 _fee);
    event YearsToOwn(uint96 _years);
    event NewMaxProfile(uint88 _max);

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
     @param _user user transferring tokens
     @param _amount number of tokens being transferred
    */
    function transferTokens(address _user, uint256 _amount) private returns (bool) {
        return IERC20Upgradeable(usdc_).transferFrom(_user, contract1, _amount);
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

    function setContract1(address _new) external onlyOwner {
        contract1 = _new;
    }

    function setContract2(address _new) external onlyOwner {
        contract2 = _new;
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

    function setMaxProfilePerAddress(uint88 _max) external onlyGovernor {
        maxProfilePerAddress = _max;
        emit NewMaxProfile(_max);
    }

    function setYearsToOwn(uint96 _years) external onlyGovernor {
        yearsToOwn = _years;
        emit YearsToOwn(_years);
    }

    function setGenKeyWhitelistOnly(bool _genKeyWhitelistOnly) external onlyGovernor {
        genKeyWhitelistOnly = _genKeyWhitelistOnly;
    }

    function setPublicMint(bool _val) external onlyGovernor {
        publicMintBool = _val;
    }

    function setPublicClaim(bool _val) external onlyGovernor {
        publicClaimBool = _val;
    }

    function hashTransaction(address sender, string memory profileUrl) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(sender, profileUrl)))
        );

        return hash;
    }

    // CLAIM FUNCTIONS
    /**
     * @dev allows gen key holder to claim a profile
     * @param profileUrl profileUrl to claim
     * @param tokenId tokenId of genesis key owned
     * @param recipient user who is calling the claim function
     */
    function genesisKeyClaimProfile(
        string memory profileUrl,
        uint256 tokenId,
        address recipient,
        bytes32 hash,
        bytes memory signature
    ) external validAndUnusedURI(profileUrl) nonReentrant {
        // checks
        require(IERC721EnumerableUpgradeable(genesisKeyContract).ownerOf(tokenId) == recipient, "gkp: !owner");
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
            0
        );
    }

    function genesisKeyBatchClaimProfile(
        BatchClaimProfile[] memory claims
    ) external nonReentrant {
        for (uint256 i = 0; i < claims.length; ) {
            string memory profileUrl = claims[i].profileUrl;
            uint256 tokenId = claims[i].tokenId;
            address recipient = claims[i].recipient;
            bytes32 hash = claims[i].hash;
            bytes memory signature = claims[i].signature;
            
            // checks
            require(IERC721EnumerableUpgradeable(genesisKeyContract).ownerOf(tokenId) == recipient, "gkp: !owner");
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
                0
            );

            unchecked {
                ++i;
            }
        }
    }

    // used for profile factory
    function publicClaim(
        string memory profileUrl,
        bytes32 hash,
        bytes memory signature
    ) external nonReentrant validAndUnusedURI(profileUrl) {
        // checks
        require(publicClaimBool, "pm: publicClaimBool");
        require(verifySignature(hash, signature) && !cancelledOrFinalized[hash], "pm: !sig");
        require(hashTransaction(msg.sender, profileUrl) == hash, "pm: !hash");
        if (publicMinted[msg.sender] >= maxProfilePerAddress) revert MaxProfiles();

        // effects
        publicMinted[msg.sender] += 1;

        // grace period of 1 year (unless DAO intervention)
        INftProfile(nftProfile).createProfile(msg.sender, profileUrl, 365 days);

        emit MintedProfile(msg.sender, profileUrl, INftProfile(nftProfile).totalSupply() - 1, 365 days, 0);
    }

    function publicMint(
        string memory profileUrl,
        uint256 duration,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 hash,
        bytes memory signature
    ) external nonReentrant validAndUnusedURI(profileUrl) {
        // checks
        require(publicMintBool, "pm: !publicMint");
        require(verifySignature(hash, signature) && !cancelledOrFinalized[hash], "pm: !sig");
        require(hashTransaction(msg.sender, profileUrl) == hash, "pm: !hash");

        // interactions
        if (IERC20Upgradeable(usdc_).allowance(msg.sender, address(this)) == 0) {
            permitNFT(msg.sender, address(this), v, r, s); // approve token
        }

        require(transferTokens(msg.sender, getFee(profileUrl, duration)), "pm: !funds");

        INftProfile(nftProfile).createProfile(msg.sender, profileUrl, duration);

        emit MintedProfile(
            msg.sender,
            profileUrl,
            INftProfile(nftProfile).totalSupply() - 1,
            duration,
            getFee(profileUrl, duration)
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
    ) external nonReentrant {
        require(publicMintBool, "el: public minting is disabled");

        if (IERC20Upgradeable(usdc_).allowance(msg.sender, address(this)) == 0) {
            permitNFT(msg.sender, address(this), v, r, s); // approve NFT token
        }

        require(transferTokens(msg.sender, getFee(profileUrl, duration)), "el: insufficient funds");

        INftProfile(nftProfile).extendLicense(profileUrl, duration, msg.sender);

        emit ExtendLicense(msg.sender, profileUrl, duration, getFee(profileUrl, duration), false);
    }

    function purchaseExpiredProfile(
        string memory profileUrl,
        uint256 duration,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        // checks
        require(publicMintBool, "pe: public minting is disabled");
        require(ownedProfileStake[profileUrl] == 0, "pe: profile is already staked");

        // effects
        // interactions
        if (IERC20Upgradeable(usdc_).allowance(msg.sender, address(this)) == 0) {
            permitNFT(msg.sender, address(this), v, r, s); // approve NFT token
        }

        require(transferTokens(msg.sender, getFee(profileUrl, duration)), "pe: insufficient funds");

        INftProfile(nftProfile).purchaseExpiredProfile(profileUrl, duration, msg.sender);

        emit ExtendLicense(msg.sender, profileUrl, duration, getFee(profileUrl, duration), true);
    }

    function ownProfile(string memory profileUrl) external nonReentrant {
        // checks
        require(publicMintBool, "op: public minting is disabled");
        require(ownedProfileStake[profileUrl] == 0); //
        uint256 xNftKeyReq = (getFee(profileUrl, 365 days) * yearsToOwn * IGenesisKeyStake(contract2).totalSupply()) /
            IGenesisKeyStake(contract2).totalStakedCoin();
        require(xNftKeyReq != 0, "op: !0");

        // effects
        ownedProfileStake[profileUrl] = xNftKeyReq;

        // interactions
        require(
            IERC20Upgradeable(contract2).transferFrom(msg.sender, address(this), xNftKeyReq),
            "op: insufficient funds"
        );

        emit UpdatedProfileStake(profileUrl, xNftKeyReq);
    }

    function redeemProfile(string memory profileUrl) public nonReentrant {
        // checks
        require(publicMintBool, "rp: public minting is disabled");
        require(ownedProfileStake[profileUrl] != 0, "rp: profile is not staked");
        require(INftProfile(nftProfile).profileOwner(profileUrl) == msg.sender, "rp: profile is not owned by user");

        // effects
        ownedProfileStake[profileUrl] = 0;

        // interactions
        require(IERC20Upgradeable(contract2).transferFrom(address(this), msg.sender, ownedProfileStake[profileUrl]));

        emit UpdatedProfileStake(profileUrl, 0);
    }
}