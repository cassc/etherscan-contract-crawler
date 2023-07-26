// SPDX-License-Identifier: MIT
/**
 _____
/  __ \
| /  \/ ___  _ ____   _____ _ __ __ _  ___ _ __   ___ ___
| |    / _ \| '_ \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
| \__/\ (_) | | | \ V /  __/ | | (_| |  __/ | | | (_|  __/
 \____/\___/|_| |_|\_/ \___|_|  \__, |\___|_| |_|\___\___|
                                 __/ |
                                |___/
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WlPresaleCvg is ERC721Enumerable, Ownable2Step {
    using SafeERC20 for IERC20;

    /// @dev Struct Info about whistelists
    struct PresaleInfo {
        uint256 vestingType; // Define the whitelist type
        uint256 cvgAmount; // Total CVG amount claimable for the nft owner
        uint256 stableInvested; // Stable already invested on the NFT
    }

    /// @dev Enum about Sale State
    enum SaleState {
        NOT_ACTIVE,
        WL,
        OVER
    }

    struct WlTypeInfo {
        uint256 minInvest;
        uint256 maxInvest;
        bytes32 merkleRoot;
        uint256 cvgRedeemable;
    }

    SaleState public saleState;

    IERC20 public immutable Dai;
    IERC20 public immutable Frax;

    /// @dev Types of whitelists
    uint256 private constant TYPE_WL_S = 2;
    uint256 private constant TYPE_WL_M = 3;
    uint256 private constant TYPE_WL_L = 4;

    /// @dev Prices Info
    uint256 public constant PRICE_WL = 22; // 0.22$
    uint256 public constant NUMERATOR = 100;

    /// @dev Init first tokenId
    uint256 public nextTokenId = 1;

    /// @dev Max supply and Current supply CVG
    uint256 public constant MAX_SUPPLY_PRESALE = 2_450_000 * 10 ** 18;
    uint256 public supply = MAX_SUPPLY_PRESALE;

    string internal baseURI;

    /// @dev TokenId associated to the presale Info
    mapping(uint256 => PresaleInfo) public presaleInfos; // tokenID => PresaleInfo

    /// @dev Identify if an address has already minted an NFT
    mapping(address => bool) public mintersToggle;

    /// @dev Information about all type of WL
    mapping(uint256 => WlTypeInfo) public wlParams;

    constructor(
        bytes32 _merkleRootWlS,
        bytes32 _merkleRootWlM,
        bytes32 _merkleRootWlL,
        IERC20 _Dai,
        IERC20 _Frax,
        address _treasuryDao
    ) ERC721("PresaleWl CVG", "pCVG") {
        wlParams[TYPE_WL_S] = WlTypeInfo({
            minInvest: 154 * 10 ** 18,
            maxInvest: 770 * 10 ** 18,
            merkleRoot: _merkleRootWlS,
            cvgRedeemable: 0
        });

        wlParams[TYPE_WL_M] = WlTypeInfo({
            minInvest: 385 * 10 ** 18,
            maxInvest: 1_925 * 10 ** 18,
            merkleRoot: _merkleRootWlM,
            cvgRedeemable: 0
        });

        wlParams[TYPE_WL_L] = WlTypeInfo({
            minInvest: 770 * 10 ** 18,
            maxInvest: 3_850 * 10 ** 18,
            merkleRoot: _merkleRootWlL,
            cvgRedeemable: 0
        });
        Dai = _Dai;
        Frax = _Frax;

        _transferOwnership(_treasuryDao);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            SETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /// @dev Set Sale State
    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    /// @dev Set Merkle Roots
    function setMerkleRootWl(bytes32 _newMerkleRootWl, uint256 _type) external onlyOwner {
        wlParams[_type].merkleRoot = _newMerkleRootWl;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            GETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function getTokenIdAndType(
        address _wallet,
        uint256 _index
    ) external view returns (uint256 tokenId, uint256 vestingType) {
        tokenId = tokenOfOwnerByIndex(_wallet, _index);
        vestingType = presaleInfos[tokenId].vestingType;
    }

    function getTokenIdsForWallet(address _wallet) external view returns (uint256[] memory) {
        uint256 range = balanceOf(_wallet);
        uint256[] memory tokenIds = new uint256[](range);
        for (uint256 i = 0; i < range; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokenIds;
    }

    /// @notice returns the amount of CVG already locked for vesting
    function getAmountCvgForVesting() external view returns (uint256) {
        return MAX_SUPPLY_PRESALE - supply;
    }

    function getTotalCvg() external view returns (uint256) {
        return
            wlParams[TYPE_WL_S].cvgRedeemable + wlParams[TYPE_WL_M].cvgRedeemable + wlParams[TYPE_WL_L].cvgRedeemable;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            EXTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /**
     * @notice Invest and mint an NFT presale
                    - function only usable with the dApp (we provide the merkleProof)
                    - Invest is possible multiple times (only with the WL address)
     * @param _merkleProof is the proof provided by the dApp
     * @param _amount of token to invest
     * @param _isDai whether the invested token is DAI or FRAX
     * @param _type invest type (small, medium or large)
     */
    function investMint(bytes32[] calldata _merkleProof, uint256 _amount, bool _isDai, uint256 _type) external {
        SaleState _saleState = saleState;

        require(_saleState > SaleState.NOT_ACTIVE, "PRESALE_NOT_STARTED");
        require(_saleState < SaleState.OVER, "PRESALE_ROUND_FINISHED");
        require(_amount > 0, "INVALID_AMOUNT");
        require(!mintersToggle[msg.sender], "ALREADY_MINTED");

        IERC20 token = _isDai ? Dai : Frax;
        uint256 cvgAmount = (_amount * NUMERATOR) / PRICE_WL;

        uint256 min;
        uint256 max;

        WlTypeInfo memory _wlParams = wlParams[_type];

        require(merkleVerifyWl(_merkleProof, _type), "INVALID_PROOF");
        min = _wlParams.minInvest;
        max = _wlParams.maxInvest;

        wlParams[_type].cvgRedeemable += cvgAmount;

        require(_amount >= min, "INSUFFICIENT_AMOUNT");
        require(_amount <= max, "TOO_MUCH_Q_WL");

        /// @dev Check the current presale supply
        require(cvgAmount <= supply, "NOT_ENOUGH_CVG_SUPPLY");

        /// @dev update & Associate the tokenId with the presales Info
        presaleInfos[nextTokenId] = PresaleInfo({vestingType: _type, cvgAmount: cvgAmount, stableInvested: _amount});

        /// @dev Update available supply
        supply -= cvgAmount;
        mintersToggle[msg.sender] = true;

        /// @dev Transfer
        token.transferFrom(msg.sender, address(this), _amount);

        /// @dev mint and update counter
        _mint(msg.sender, nextTokenId++);
    }

    /**
     * @notice Refill token with specified amount
     * @param _tokenId ID of the token to be refilled
     * @param _amount of token to refill the token with
     * @param _isDai whether the invested token is DAI or FRAX
     */
    function refillToken(uint256 _tokenId, uint256 _amount, bool _isDai) external {
        require(ownerOf(_tokenId) == msg.sender, "NOT_OWNED");

        IERC20 token = _isDai ? Dai : Frax;

        uint256 _vestingType = presaleInfos[_tokenId].vestingType;
        uint256 cvgAmount = (_amount * NUMERATOR) / PRICE_WL;

        wlParams[_vestingType].cvgRedeemable += cvgAmount;

        require(_amount + presaleInfos[_tokenId].stableInvested <= wlParams[_vestingType].maxInvest, "TOO_MUCH_Q_WL");

        /// @dev update the presales info for this address
        presaleInfos[_tokenId].cvgAmount += cvgAmount;
        presaleInfos[_tokenId].stableInvested += _amount;

        /// @dev Update available supply
        supply -= cvgAmount;

        /// @dev Transfer
        token.transferFrom(msg.sender, address(this), _amount);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            INTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /// @dev Check if a given address is on the White list S
    function merkleVerifyWl(bytes32[] calldata _merkleProofWl, uint256 _type) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProofWl, wlParams[_type].merkleRoot, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                        WITHDRAW OWNER
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function withdrawFunds() external onlyOwner {
        uint256 balanceDai = Dai.balanceOf(address(this));
        uint256 balanceFrax = Frax.balanceOf(address(this));
        require(balanceDai > 0 || balanceFrax > 0, "NO_FUNDS");

        if (balanceDai > 0 && balanceFrax > 0) {
            Dai.transfer(msg.sender, balanceDai);
            Frax.transfer(msg.sender, balanceFrax);
        } else if (balanceDai > 0) {
            Dai.transfer(msg.sender, balanceDai);
        } else {
            Frax.transfer(msg.sender, balanceFrax);
        }
    }

    function withdrawToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "WITHDRAW_LTE_0");

        _token.transfer(msg.sender, balance);
    }
}