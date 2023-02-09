// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/YEETY.eth - Co-Founder/CTO, Virtue Labs

// * ————————————————————————————————————————————————————————————————————————————————— *
// |                                                                                   |
// |    SSSSS K    K EEEEEE L      EEEEEE PPPPP  H    H U    U N     N K    K  SSSSS   |
// |   S      K   K  E      L      E      P    P H    H U    U N N   N K   K  S        |
// |    SSSS  KKKK   EEE    L      EEE    PPPPP  HHHHHH U    U N  N  N KKKK    SSSS    |
// |        S K   K  E      L      E      P      H    H U    U N   N N K   K       S   |
// |   SSSSS  K    K EEEEEE LLLLLL EEEEEE P      H    H  UUUU  N     N K    K SSSSS    |
// |                                                                                   |
// | * AN ETHEREUM-BASED INDENTITY PLATFORM BROUGHT TO YOU BY NEUROMANTIC INDUSTRIES * |
// |                                                                                   |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@                              |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@                              |
// |                          @@@,,,,,,,,,,,,,,,,,,,,,,,,@@@                           |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@@@@@@@@,,,,,,,,,,@@@@@@,,,,,,,@@@                        |
// |                       @@@@@@@@@@,,,,,,,,,,@@@@@@,,,,,,,@@@                        |
// |                       @@@@@@@@@@,,,,,,,,,,@@@@@@,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,@@@@@@,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,@@@@@@,,,,,,,,,,,,,,,,,@@@                        |
// |                          @@@,,,,,,,,,,,,,,,,,,,,,,,,@@@                           |
// |                          @@@,,,,,,,,,,,,,,,,,,,,@@@@@@@                           |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@@@@                           |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@@@@                           |
// |                             @@@@,,,,,,,,,,,,,,,,@@@@,,,@@@                        |
// |                                 @@@@@@@@@@@@@@@@,,,,@@@                           |
// |                                           @@@,,,,,,,,,,@@@                        |
// |                                           @@@,,,,,,,,,,@@@                        |
// |                                              @@@,,,,@@@                           |
// |                                           @@@,,,,,,,,,,@@@                        |
// |                                                                                   |
// |  * ————————————————————————————————————————————————————————————————————

pragma solidity ^0.8.17;

import "./ERC721Y.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Skelephunks is ERC721Y, Ownable, DefaultOperatorFilterer {
    using Address for address;
    using Strings for uint256;
    string public PROVENANCE;
    bool provenanceSet;

    mapping(address => uint256) public numMinted;

    mapping(uint256 => string) private _gdToPath;

    /*************************************************************************/
    /*** PAYMENT VARIABLES (Start) *******************************************/
    address[] public payees;
    mapping(address => uint256) private paymentInfo;
    uint256 totalReceived = 0;
    mapping(address => uint256) amountsWithdrawn;
    bool canEmergencyWithdrawTokens = true;

    modifier onlyPayee() {
        _isPayee();
        _;
    }
    function _isPayee() internal view virtual {
        require(paymentInfo[msg.sender] > 0, "not a payee");
    }
    function isPayee(address addr) public view returns (bool) {
        return (paymentInfo[addr] > 0);
    }
    /*** PAYMENT VARIABLES (End) *******************************************/
    /***********************************************************************/

    uint256 public mintPrice = 0.033 ether;
    uint256 private maxPaidTokens = 10;

    enum MintStatus {
        PreMint,
        Phunks,
        AllowList,
        Public,
        PublicExtended,
        ReserveOnly,
        Finished
    }

    MintStatus public mintStatus = MintStatus.PreMint;
    bool public paused = false;

    uint256 public maxPossibleSupply = 9999;
    uint256 public maxMintableSupply = 6666;
    uint256 public numMintedRegular = 0;
    uint256 public maxReserveSupply = 3333;
    uint256 public numMintedReserve = 0;
    uint256 private _maxMintsPerWallet;

    string collectionDescription = "Skelephunks is a universal, adaptive PFP for the Ethereum community.";
    string collectionImg = "";
    string externalLink = "https://skelephunks.com";

//    mapping(uint256 => uint256) private _genderDirection;

    bytes32 public phunksMerkleRoot = 0x2df951fbc5be4633d24a81d65bfa4cf92133f3ada0d2a884f39955bd22444b24;
    uint256 public maxPhunkClaims = 105;

    bytes32 public merkleRoot = 0xdb815420d65ef8b0dec059847253b71b167965c78bd17b5a961dc8688ded7cfd;
    uint256 public maxAllowlistClaims = 1561;

    mapping(address => uint256) private _claimsInfo;
    mapping(address => uint256) private _claimTypes;

    function phunkClaimsMade() public view returns (uint256) {
        return _claimsInfo[address(0)]%(1<<128);
    }

    function allowlistClaimsMade() public view returns (uint256) {
        return _claimsInfo[address(0)]>>128;
    }

    function phunkListClaimed(address addr) public view returns (bool) {
        require(addr != address(0), "0");
        return ((_claimsInfo[addr]%2) == 1);
    }

    function allowlistClaimed(address addr) public view returns (bool) {
        require(addr != address(0), "0");
        return ((_claimsInfo[addr]>>1) == 1);
    }

    mapping(address => bool) private _reserveAuths;
    address public keysContract;
    uint256 public keyRedemptionAmt = 3;

    modifier onlyReserveAuth() {
        require(getReserveAuthStatus(msg.sender), "ra");
        _;
    }

    bool private royaltySwitch = true;
    modifier onlyAllowedOperator(address from) virtual override {
        if (royaltySwitch) {
            if (from != msg.sender) {
                _checkFilterOperator(msg.sender);
            }
        }
        _;
    }
    modifier onlyAllowedOperatorApproval(address operator) virtual override {
        if (royaltySwitch) {
            _checkFilterOperator(operator);
        }
        _;
    }

    bool public preMintLocked = false;

    //////////

    constructor (
        string memory name_,
        string memory symbol_,
        uint256 maxMintsPerWallet_,
        address[] memory payees_,
        uint256[] memory basisPoints_
    ) ERC721Y(name_, symbol_, maxPossibleSupply) {
        _maxMintsPerWallet = maxMintsPerWallet_;

        require(payees_.length == basisPoints_.length, "l");
        payees = payees_;
        for (uint256 i = 0; i < payees_.length; i++) {
            paymentInfo[payees_[i]] = basisPoints_[i];
        }

        _gdToPath[0] = "phunk/male";
        _gdToPath[1] = "phunk/female";
        _gdToPath[2] = "punk/male";
        _gdToPath[3] = "punk/female";
    }

    //////////

    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    function setMintStatus(MintStatus newMintStatus) public onlyOwner {
        require(newMintStatus != MintStatus.PreMint && mintStatus != MintStatus.Finished, "ms");
        mintStatus = newMintStatus;
    }

    function preMint(
        address[] calldata recipients,
        uint256[] calldata numsToMint,
        uint256[] calldata gds,
        bool lock
    ) public onlyOwner {
        require(!preMintLocked, "pml");
        for (uint256 i = 0; i < numsToMint.length; i++) {
            require(gds[i] < 4, "bad gad");
            _mintMain(recipients[i], numsToMint[i], 0, gds[i], false);
        }
        preMintLocked = lock;
    }

    function min(uint256 x, uint256 y) private pure returns (uint256) {
        if (x < y) {
            return x;
        }

        return y;
    }

    function _mintClaimsMade(address minter) private view returns (uint256) {
        return _claimTypes[minter]%(1<<128);
    }

    function _otherClaimsMade(address minter) private view returns (uint256) {
        return _claimTypes[minter]>>128;
    }

    function totalClaimsMade(address minter) public view returns (uint256) {
        return _mintClaimsMade(minter) + _otherClaimsMade(minter);
    }

    function phunkClaimsRemain() public view returns (bool) {
        return (phunkClaimsMade() < maxPhunkClaims);
    }

    function eligibleForPhunk(
        address minter,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        return ((!(phunkListClaimed(minter))) && MerkleProof.verify(
            _proof, phunksMerkleRoot, keccak256(abi.encodePacked(minter))
        ) && phunkClaimsRemain());
    }

    function allowlistClaimsRemain() public view returns (bool) {
        return (allowlistClaimsMade() < maxAllowlistClaims);
    }

    function eligibleForAllowlist(
        address minter,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        return (MerkleProof.verify(
            _proof, merkleRoot, keccak256(abi.encodePacked(minter))
        ) && allowlistClaimsRemain());
    }

    //////////

    function maxMintsInternal(
        address wallet,
        bytes32[] calldata _phunkProof,
        bytes32[] calldata _alProof
    ) private view returns (uint256) {
        uint256 mms = maxMintableSupply;
        uint256 nmr = numMintedRegular;
        uint256 _mmpw = _maxMintsPerWallet;

        bool efp = eligibleForPhunk(wallet, _phunkProof);
        bool efal = eligibleForAllowlist(wallet, _alProof);

        if (mintStatus == MintStatus.PreMint) {
            return 0;
        }
        else if (mintStatus == MintStatus.Phunks) {
            return (efp ? 1 : 0);
        }
        else if (mintStatus == MintStatus.AllowList) {
            if (efal) {
                return min(_mmpw - numMinted[wallet], mms - nmr);
            }
            else if (efp) { return 1; }
            else { return 0; }
        }
        else if (mintStatus == MintStatus.Public) {
            return min(_mmpw - numMinted[wallet], mms - nmr);
        }
        else if (mintStatus == MintStatus.PublicExtended) {
            return (mms - nmr);
        }
        else if (mintStatus == MintStatus.ReserveOnly) {
            return (efal ? 1 : 0) +
            (efp ? 1 : 0);
        }

        return 0;
    }

    function maxMintsPerWallet(
        address wallet,
        bytes32[] calldata _phunkProof,
        bytes32[] calldata _alProof
    ) public view returns (uint256) {
        return min(100, maxMintsInternal(wallet, _phunkProof, _alProof));
    }

    function walletCanMint(
        address wallet,
        bytes32[] calldata _phunkProof,
        bytes32[] calldata _alProof
    ) public view returns (bool) {
        return (maxMintsPerWallet(wallet, _phunkProof, _alProof) > 0);
    }

    function _generalGetNumFree(
        address wallet,
        uint256 quantity,
        bytes32[] calldata _phunkProof,
        bytes32[] calldata _alProof
    ) private view returns (uint256) {
        uint256 toReturn;

        if (quantity == maxMintsPerWallet(wallet, _phunkProof, _alProof)) {
            toReturn = 3 - _mintClaimsMade(wallet);
            toReturn = min(toReturn, quantity);
        }
        else {
            toReturn = (eligibleForPhunk(wallet, _phunkProof) ? 1 : 0) +
                ((eligibleForAllowlist(wallet, _alProof) && (!(allowlistClaimed(wallet)))) ? 1 : 0);
            toReturn = min(toReturn, quantity);
        }

        return toReturn;
    }

    function getNumFree(
        address wallet,
        uint256 quantity,
        bytes32[] calldata _phunkProof,
        bytes32[] calldata _alProof
    ) public view returns (uint256) {
        bool efp = eligibleForPhunk(wallet, _phunkProof);
        uint256 ggnf = _generalGetNumFree(wallet, quantity, _phunkProof, _alProof);

        if (mintStatus == MintStatus.PreMint) {
            return 0;
        }
        else if (mintStatus == MintStatus.Phunks) {
            return (efp ? 1 : 0);
        }
        else if (mintStatus == MintStatus.AllowList) {
            if (eligibleForAllowlist(wallet, _alProof)) {
                return ggnf;
            }
            else if (efp) { return 1; }
            else { return 0; }
        }
        else if (mintStatus == MintStatus.Public || mintStatus == MintStatus.PublicExtended) {
            return ggnf;
        }
        else if (mintStatus == MintStatus.ReserveOnly) {
            return maxMintsInternal(wallet, _phunkProof, _alProof);
        }

        return 0;
    }

    function getMintCost(
        address wallet,
        uint256 quantity,
        bytes32[] calldata _phunkProof,
        bytes32[] calldata _alProof
    ) public view returns (uint256) {
        uint256 numFree = getNumFree(wallet, quantity, _phunkProof, _alProof);

        return mintPrice*(quantity - numFree);
    }

    //////////

    function _mintMain(address _to, uint256 _quantity, uint256 _numFree, uint256 _gd, bool isReserve) private {
        require(!paused, "p");
        require(_gd < 4, "v");

        _mintRandom(_to, _quantity, _gd);

        numMinted[_to] += _quantity;

        if (isReserve) {
            numMintedReserve += _quantity;
        }
        else {
            numMintedRegular += _quantity - _numFree;
            numMintedReserve += _numFree;
        }

        if (numMintedRegular == maxMintableSupply) {
            mintStatus = MintStatus.ReserveOnly;
        }

        if (mintStatus == MintStatus.ReserveOnly) {
            if (numMintedReserve == maxReserveSupply) {
                mintStatus = MintStatus.Finished;
            }
        }
    }

    function mint(
        uint256 _quantity,
        uint256 genderDirection,
        bytes32[] calldata _phunkProof,
        bytes32[] calldata _alProof
    ) public payable {
        require(msg.sender == tx.origin, "no contracts fam");
        uint256 numFree = getNumFree(msg.sender, _quantity, _phunkProof, _alProof);
        require(msg.value == mintPrice*(_quantity - numFree), "poor");
        require(_quantity <= maxMintsPerWallet(msg.sender, _phunkProof, _alProof), "mmpw");
        require(numMintedRegular + (_quantity - numFree) <= maxMintableSupply, "mms");
        require(numMintedReserve + numFree <= maxReserveSupply, "mrs");

        uint256 numFreeCopy = numFree;
        if (numFreeCopy > 0) {
            if (eligibleForPhunk(msg.sender, _phunkProof)) {
                _claimsInfo[msg.sender] += 1;
                _claimTypes[msg.sender] += 1;
                numFreeCopy -= 1;

                _claimsInfo[address(0)] += 1;
            }
        }
        if (numFreeCopy > 0) {
            if (eligibleForAllowlist(msg.sender, _alProof) && (!allowlistClaimed(msg.sender))) {
                _claimsInfo[msg.sender] += 2;
                _claimTypes[msg.sender] += 1;
                numFreeCopy -= 1;

                _claimsInfo[address(0)] += 1<<128;
            }
        }
        _claimTypes[msg.sender] += numFreeCopy;


        totalReceived += msg.value;
        _mintMain(msg.sender, _quantity, numFree, genderDirection, false);
    }

    function mintReserve(
        address _to,
        uint256 _quantity,
        uint256 genderDirection
    ) public onlyReserveAuth {
        _mintReserve(_to, _quantity, genderDirection);
    }

    function redeemKeyForSkelephunks(
        uint256 keyId,
        uint256 genderDirection
    ) public {
        require(msg.sender == tx.origin, "no contracts fam");
        _mintReserve(msg.sender, keyRedemptionAmt, genderDirection);
        SkeleKeysProto(keysContract).redeemKey(keyId);
    }

    function _mintReserve(
        address _to,
        uint256 _quantity,
        uint256 genderDirection
    ) private {
        _mintMain(_to, _quantity, 0, genderDirection, true);
        _claimTypes[_to] += (_quantity<<128);
    }

    //////////

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintsPerWallet(uint256 __maxMintsPerWallet) public onlyOwner {
        _maxMintsPerWallet = __maxMintsPerWallet;
    }

    function setMerkleRoots(
        bytes32 _newPhunksMerkleRoot,
        bytes32 _newAllowlistMerkleRoot
    ) public onlyOwner {
        phunksMerkleRoot = _newPhunksMerkleRoot;
        merkleRoot = _newAllowlistMerkleRoot;
    }

    //////////

    function getGenderAndDirection(uint256 tokenId) public view returns (uint256) {
        return gadOf(tokenId);
    }

    function setGenderAndDirection(uint256 tokenId, uint256 gender, uint256 direction) public {
        require(gender < 2 && direction < 2, "v");
        setGAD(tokenId, direction*2 + gender);
    }

    //////////

    function setKeysContract(address keysAddr) public onlyOwner {
        setReserveAuthStatus(keysContract, false);
        keysContract = keysAddr;
        setReserveAuthStatus(keysContract, true);
    }

    function setReserveAuthStatus(address addr, bool isAuthorized) public onlyOwner {
        _reserveAuths[addr] = isAuthorized;
    }

    function getReserveAuthStatus(address addr) public view returns (bool) {
        return _reserveAuths[addr];
    }

    function setKeyRedemptionAmt(uint256 _newAmt) public onlyOwner {
        keyRedemptionAmt = _newAmt;
    }

    //////////

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "z");

        if (bytes(_basedURI).length > 0) {
            return string(
                abi.encodePacked(
                    _basedURI, "/", _gdToPath[getGenderAndDirection(tokenId)], "/",
                    tokenId.toString()));
        }
        else {
            return _preRevealURI;
        }
    }

    function setPreRevealURI(string memory preRevealURI_) public onlyOwner {
        _setPreRevealURI(preRevealURI_);
    }

    function setBasedURI(string memory basedURI_) public onlyOwner {
        _setBasedURI(basedURI_);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet);
        PROVENANCE = provenanceHash;
        provenanceSet = true;
    }

    //////////

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //////////

    function setCollectionDescription(string memory _collectionDescription) public onlyOwner {
        collectionDescription = _collectionDescription;
    }

    function setCollectionImg(string memory _collectionImg) public onlyOwner {
        collectionImg = _collectionImg;
    }

    function setExternalLink(string memory _externalLink) public onlyOwner {
        externalLink = _externalLink;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", name(),"\",",
                "\"description\":\"", collectionDescription, "\",",
                "\"image\":\"", collectionImg, "\",",
                "\"external_link\":\"", externalLink, "\",",
                "\"seller_fee_basis_points\":666,\"fee_recipient\":\"",
                uint256(uint160(address(this))).toHexString(), "\"}"
            )
        );
    }

    function flipRoyaltySwitch() public onlyOwner {
        royaltySwitch = !royaltySwitch;
    }

    /*********************************************************************/
    /*** PAYMENT LOGIC (Start) *******************************************/
    receive() external payable {
        totalReceived += msg.value;
    }

    function withdraw() public onlyPayee {
        uint256 totalForPayee = (totalReceived/10000)*paymentInfo[msg.sender];
        uint256 toWithdraw = totalForPayee - amountsWithdrawn[msg.sender];
        amountsWithdrawn[msg.sender] = totalForPayee;
        (bool success, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(success, "Payment failed!");
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 toWithdraw = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(success, "Payment failed!");
    }

    function withdrawTokens(address tokenAddress) external onlyPayee {
        for (uint256 i = 0; i < payees.length; i++) {
            IERC20(tokenAddress).transfer(
                payees[i],
                (IERC20(tokenAddress).balanceOf(address(this))/10000)*paymentInfo[payees[i]]
            );
        }
    }

    function disableEWT() public onlyOwner {
        canEmergencyWithdrawTokens = false;
    }

    function emergencyWithdrawTokens(address tokenAddress) external onlyOwner {
        require(canEmergencyWithdrawTokens, "!ew");
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    /*** PAYMENT LOGIC (End) *******************************************/
    /*******************************************************************/
}

////////////////////

abstract contract ERC721Proto {
    function balanceOf(address owner) public view virtual returns (uint256);
}

//////////

abstract contract SkeleKeysProto {
    function redeemKey(uint256 keyId) public virtual;
}

////////////////////////////////////////