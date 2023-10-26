// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "solady/src/tokens/ERC721.sol";
import "solady/src/auth/Ownable.sol";
import "solady/src/utils/ECDSA.sol";
import "solady/src/utils/LibString.sol";

contract Prime is ERC721, Ownable {
    using ECDSA for bytes;

    error InvalidValue();
    error MismatchLength(uint256 expecting);
    error NameUsed();
    error InvalidReferral();
    error FailedToSendFee();
    error NothingToClaim();
    error ClaimsClosed();
    error ContractDepleted();
    error QueryForNonexistantToken();
    error InvalidWhitelistClaim();
    error AlreadyClaimed();
    error InvalidDiscountValue();
    error MustUseSameRefCode(string code);
    error MintIsNotLive();

    uint256 public PRICE = 0.018777 * 1 ether;
    uint256 public DISCOUNT_PRICE = 0.0169 * 1 ether;
    uint256 public WHITELIST_PRICE = 0.0142 * 1 ether;
    uint256 public totalSupply = 0;
    uint256 public totalRefClaims = 0;

    string public baseURI = "https://app.sukuri.io/api/";

    bool public IS_LIVE = false;
    bool public CLAIMS_LIVE = false;

    address signer;

    mapping(uint256 tokenID => string name) public namespace;
    mapping(string name => address owner) public nameOwner;
    mapping(address referee => string referral) public usedRefs;

    mapping(address owner => uint256 balance) refClaim;

    mapping(address whitelistee => uint256 claimed) public wlClaim;

    constructor(address signer_) {
        _initializeOwner(msg.sender);
        signer = signer_;
    }

    function whitelistMint(
        string calldata _name,
        string memory referral,
        bytes calldata signature
    ) external payable {
        if (!IS_LIVE) {
            revert MintIsNotLive();
        }

        if (msg.value != WHITELIST_PRICE) {
            revert InvalidValue();
        }

        if (wlClaim[msg.sender] != 0) {
            revert AlreadyClaimed();
        }

        bytes32 message = keccak256(abi.encode(msg.sender, _name, referral));
        if (
            ECDSA.recover(ECDSA.toEthSignedMessageHash(message), signature) !=
            signer
        ) {
            revert InvalidWhitelistClaim();
        }

        if (nameOwner[_name] != address(0)) {
            revert NameUsed();
        }

        _checkAndUpdateRefClaims(referral);

        uint256 tokenId = ++totalSupply;
        namespace[tokenId] = _name;
        nameOwner[_name] = msg.sender;
        wlClaim[msg.sender]++;
        _mint(msg.sender, tokenId);
    }

    function mint(
        string calldata _name,
        string memory referral
    ) external payable {
        if (!IS_LIVE) {
            revert MintIsNotLive();
        }
        bytes memory refTmp = bytes(referral);
        if (refTmp.length > 0 && msg.value != DISCOUNT_PRICE) {
            revert InvalidDiscountValue();
        } else if (refTmp.length == 0 && msg.value != PRICE) {
            revert InvalidValue();
        }

        if (nameOwner[_name] != address(0)) {
            revert NameUsed();
        }

        _checkAndUpdateRefClaims(referral);

        uint256 tokenId = ++totalSupply;
        namespace[tokenId] = _name;
        nameOwner[_name] = msg.sender;
        _mint(msg.sender, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override {
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }
        nameOwner[namespace[id]] = to;
    }

    function claimFees() external {
        if (!CLAIMS_LIVE) {
            revert ClaimsClosed();
        }
        uint256 claim = refClaim[msg.sender];
        if (claim == 0) {
            revert NothingToClaim();
        }
        if (address(this).balance < claim) {
            revert ContractDepleted();
        }
        refClaim[msg.sender] = 0;
        totalRefClaims -= claim;
        (bool success, ) = address(msg.sender).call{value: claim}("");
        if (!success) {
            revert FailedToSendFee();
        }
    }

    function adminMint(
        address[] calldata tos,
        string[] calldata names
    ) external onlyOwner {
        if (tos.length != names.length) {
            revert MismatchLength({expecting: tos.length});
        }
        uint256 tokenId = totalSupply;
        for (uint i; i < tos.length; ) {
            tokenId++;
            _mint(tos[i], tokenId);
            namespace[tokenId] = names[i];
            nameOwner[names[i]] = tos[i];
            unchecked {
                i++;
            }
        }
        totalSupply += tos.length;
    }

    function withdraw() external onlyOwner {
        if (address(this).balance < totalRefClaims) {
            revert ContractDepleted();
        }
        (bool success, ) = address(owner()).call{
            value: address(this).balance - totalRefClaims
        }("");
        if (!success) {
            revert FailedToSendFee();
        }
    }

    // This should never be called unless nobody is claiming, the claim balances are extremely low
    // and we need to get the ETH out of the contract so it's not burned. Claim periods will be live
    // for a long time so this should not happen.
    function forceWithdrawl() external onlyOwner {
        (bool success, ) = address(owner()).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert FailedToSendFee();
        }
    }

    function setIsLive(bool status) external onlyOwner {
        IS_LIVE = status;
    }

    function setClaimLive(bool status) external onlyOwner {
        CLAIMS_LIVE = status;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        PRICE = price;
    }

    function checkClaim(address ref) public view returns (uint256) {
        return refClaim[ref];
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance - totalRefClaims;
    }

    function name() public pure override returns (string memory) {
        return "Sukuri Prime";
    }

    function symbol() public pure override returns (string memory) {
        return "PRIME";
    }

    function contractURI() public view returns (string memory) {
        return LibString.concat(baseURI, "contractURI");
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (id > totalSupply || id == 0) {
            revert QueryForNonexistantToken();
        }
        return
            LibString.concat(
                LibString.concat(baseURI, "tokenURI/"),
                LibString.toString(id)
            );
    }

    function _checkAndUpdateRefClaims(string memory referral) internal {
        bytes memory refTmp = bytes(referral);
        if (refTmp.length > 0) {
            address ref = nameOwner[referral];
            if (
                LibString.packOne(usedRefs[msg.sender]) != bytes32(0) &&
                !LibString.eq(usedRefs[msg.sender], referral)
            ) {
                revert MustUseSameRefCode({code: usedRefs[msg.sender]});
            }
            if (ref == address(0)) {
                revert InvalidReferral();
            }

            usedRefs[msg.sender] = referral;

            bool refHasRef = LibString.packOne(usedRefs[ref]) != bytes32(0);
            uint256 refFee = (msg.value * 5) / 100;
            uint256 refRefFee = refHasRef ? (msg.value * 5) / 1000 : 0;
            unchecked {
                refClaim[nameOwner[usedRefs[ref]]] += refRefFee;
                refClaim[ref] += refFee;
                totalRefClaims += (refFee + refRefFee);
            }
        }
    }
}