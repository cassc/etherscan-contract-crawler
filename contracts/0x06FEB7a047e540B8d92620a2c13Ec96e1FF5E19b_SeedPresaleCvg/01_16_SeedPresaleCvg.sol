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
import "@openzeppelin/contracts/access/Ownable.sol";

contract SeedPresaleCvg is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;

    /// @dev Struct Info about presalers
    struct PresaleInfo {
        uint256 vestingType; // Define the presaler type
        uint256 cvgAmount; // Total CVG amount claimable for the nft owner
    }

    /// @dev Struct Info about Allocation
    struct AllocationInfo {
        uint256 allocation;
        bool isClaimed;
    }

    /// @dev Enum about Sale State
    enum SaleState {
        NOT_ACTIVE,
        PRESEED,
        SEED,
        OVER
    }

    /// @dev Types of Presalers
    uint256 private constant TYPE_PRESEED_SEED = 1;

    /// @dev Prices Info
    uint256 public constant PRICE_PRESEED = 10; //0.10$
    uint256 public constant PRICE_SEED = 13; //0.13$
    uint256 public constant NUMERATOR = 100;

    /// @dev Max supply PRESEED & SEED
    uint256 public constant MAX_SUPPLY_PRESEED = 3_500_000 * 10**18;
    uint256 public constant MAX_SUPPLY_SEED = 6_800_000 * 10**18;

    uint256 public constant MAX_STABLE_PRESEED = 350_000 * 10**18;
    uint256 public constant MAX_STABLE_SEED = 884_000 * 10**18;

    /// @dev Total Invested per Types
    uint256 public totalCvgPreseed;
    uint256 public totalCvgSeed;

    /// @dev Init first tokenId
    uint256 public nextTokenId = 1;

    // @dev Current allocations stable (DAI/FRAX) for type
    uint256 public allocationStablePreseed;
    uint256 public allocationStableSeed;

    /// @dev TokenId associated to the presale Info
    mapping(uint256 => PresaleInfo) public presaleInfoTokenId; // tokenID => PresaleInfo

    /// @dev address associated to the allocation Info (Preseed)
    mapping(address => AllocationInfo) public allocationPreseed; // wallet => amountAllocated,isClaimed

    /// @dev address associated to the allocation Info (Seed)
    mapping(address => AllocationInfo) public allocationSeed; // wallet => amountAllocated,isClaimed

    IERC20 public immutable Dai;
    IERC20 public immutable Frax;

    SaleState public saleState;

    string internal baseURI;

    constructor(
        IERC20 _Dai,
        IERC20 _Frax,
        address multisig
    ) ERC721("PresaleSeed CVG", "pCVG") {
        Dai = _Dai;
        Frax = _Frax;
        transferOwnership(multisig);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            MODIFIERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /// @dev Allow only wallets (EOA) to use the function
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "ONLY_EOA");
        _;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            GETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function getTokenIdAndType(address _wallet, uint256 _index)
        external
        view
        returns (uint256 tokenId, uint256 vestingType)
    {
        tokenId = tokenOfOwnerByIndex(_wallet, _index);
        vestingType = presaleInfoTokenId[tokenId].vestingType;
    }

    function getTokenIdsForWallet(address _wallet) external view returns (uint256[] memory) {
        uint256 range = balanceOf(_wallet);
        uint256[] memory tokenIds = new uint256[](range);
        for (uint256 i = 0; i < range; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokenIds;
    }

    function getRemainingCvgPreseed() external view returns (uint256) {
        return MAX_SUPPLY_PRESEED - totalCvgPreseed;
    }

    function getRemainingCvgSeed() external view returns (uint256) {
        return MAX_SUPPLY_SEED - totalCvgSeed;
    }

    function getTotalCvg() external view returns (uint256) {
        return totalCvgSeed + totalCvgPreseed;
    }

    function getAllocation(address _wallet)
        external
        view
        returns (uint256 allocationStable, uint256 allocationCvg)
    {
        if (saleState == SaleState.PRESEED) {
            allocationStable = allocationPreseed[_wallet].allocation;
            allocationCvg = (allocationStable * NUMERATOR) / PRICE_PRESEED;
        } else if (saleState == SaleState.SEED) {
            allocationStable = allocationSeed[_wallet].allocation;
            allocationCvg = (allocationStable * NUMERATOR) / PRICE_SEED;
        }
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            SETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /// @dev Set Sale State
    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    /// @dev Set allocation for Preseed
    function grantPreseed(address _wallet, uint256 _amount) external onlyOwner {
        require(saleState < SaleState.OVER, "PRESALE_ROUND_FINISHED");
        _grantPreseed(_wallet, _amount);
    }

    /// @dev Set allocation for Seed
    function grantSeed(address _wallet, uint256 _amount) external onlyOwner {
        require(saleState < SaleState.OVER, "PRESALE_ROUND_FINISHED");
        _grantSeed(_wallet, _amount);
    }

    /// @dev Set Base Uri string
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            EXTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /**
     * @notice Invest and mint a NFT presale
                    - only wallets can trigger this function
                    - Invest is possible only one time and for a fixed amount
     * @param _isDai true if invest with DAI, false if invest with FRAX
     */
    function investMint(bool _isDai) external onlyEOA {
        SaleState _saleState = saleState;
        require(_saleState > SaleState.NOT_ACTIVE, "PRESALE_NOT_ACTIVE");
        require(_saleState < SaleState.OVER, "PRESALE_ROUND_FINISHED");

        IERC20 token;
        token = _isDai ? Dai : Frax;

        uint256 tokenAmount;
        uint256 typePrice;
        uint256 cvgAmount;

        if (_saleState == SaleState.PRESEED) {
            (tokenAmount, typePrice, cvgAmount) = _setPreseedSupply();
        } else {
            (tokenAmount, typePrice, cvgAmount) = _setSeedSupply();
        }

        uint256 _nextTokenId = nextTokenId;

        //Update & Associate the tokenId with the presales Info
        presaleInfoTokenId[_nextTokenId] = PresaleInfo(TYPE_PRESEED_SEED, cvgAmount);

        // Mint
        _mint(msg.sender, _nextTokenId);

        //Update for next presaler
        nextTokenId++;

        // Transfer
        token.transferFrom(msg.sender, address(this), tokenAmount);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            INTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function _setPreseedSupply()
        internal
        returns (
            uint256 tokenAmount,
            uint256 typePrice,
            uint256 cvgAmount
        )
    {
        require(saleState == SaleState.PRESEED, "PRESALE_ROUND_PRESEED_INACTIVE");
        tokenAmount = allocationPreseed[msg.sender].allocation;
        typePrice = PRICE_PRESEED;
        require(tokenAmount > 0, "NOT_AUTHORIZED_TO_INVEST");
        require(!allocationPreseed[msg.sender].isClaimed, "ALREADY_CLAIMED");
        //calculate CVG amount
        cvgAmount = (tokenAmount * NUMERATOR) / typePrice;
        //Check the current supply Preseed
        require(
            cvgAmount <= MAX_SUPPLY_PRESEED - totalCvgPreseed,
            "NOT_ENOUGH_CVG_SUPPLY_PRESEED"
        );
        // update total Preseed (for vesting)
        totalCvgPreseed += cvgAmount;
        //Reset allocation for the given address
        allocationPreseed[msg.sender].isClaimed = true;
    }

    function _setSeedSupply()
        internal
        returns (
            uint256 tokenAmount,
            uint256 typePrice,
            uint256 cvgAmount
        )
    {
        require(saleState == SaleState.SEED, "PRESALE_ROUND_SEED_INACTIVE");
        tokenAmount = allocationSeed[msg.sender].allocation;
        typePrice = PRICE_SEED;
        require(tokenAmount > 0, "NOT_AUTHORIZED_TO_INVEST");
        require(!allocationSeed[msg.sender].isClaimed, "ALREADY_CLAIMED");
        //calculate CVG amount
        cvgAmount = (tokenAmount * NUMERATOR) / typePrice;
        //Check the current supplyfor Seed
        require(cvgAmount <= MAX_SUPPLY_SEED - totalCvgSeed, "NOT_ENOUGH_CVG_SUPPLY_SEED");
        //update total Seed (for vesting)
        totalCvgSeed += cvgAmount;
        //Reset allocation for the given address
        allocationSeed[msg.sender].isClaimed = true;
    }

    function _grantPreseed(address _wallet, uint256 _amount) internal {
        uint256 allocationWallet = allocationPreseed[_wallet].allocation;
        //Check for wallet wich have an amount already allocated and if is not already claimed by the user
        if (allocationWallet > 0) {
            require(!allocationPreseed[_wallet].isClaimed, "ALREADY_CLAIMED");
        }
        if (allocationWallet > _amount) {
            allocationStablePreseed -= allocationWallet - _amount;
        } else if (allocationWallet < _amount) {
            allocationStablePreseed += _amount - allocationWallet;
        }
        allocationPreseed[_wallet].allocation = _amount;
        require(allocationStablePreseed <= MAX_STABLE_PRESEED, "PRESEED_MAX_LIMIT_ALLOCATION");
    }

    function _grantSeed(address _wallet, uint256 _amount) internal {
        uint256 allocationWallet = allocationSeed[_wallet].allocation;
        //Check for wallet wich have an amount already allocated and if is not already claimed by the user
        if (allocationWallet > 0) {
            require(!allocationSeed[_wallet].isClaimed, "ALREADY_CLAIMED");
        }
        if (allocationWallet > _amount) {
            allocationStableSeed -= allocationWallet - _amount;
        } else if (allocationWallet < _amount) {
            allocationStableSeed += _amount - allocationWallet;
        }
        allocationSeed[_wallet].allocation = _amount;
        require(allocationStableSeed <= MAX_STABLE_SEED, "SEED_MAX_LIMIT_ALLOCATION");
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
        require(balanceDai > 0 || balanceFrax > 0, "0_DAI_FRAX");
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
        require(balance > 0, "LTE");
        _token.transfer(msg.sender, balance);
    }
}