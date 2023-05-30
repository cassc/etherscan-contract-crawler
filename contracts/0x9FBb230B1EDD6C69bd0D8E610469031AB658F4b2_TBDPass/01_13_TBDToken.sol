// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ICalculator {
    function price() external view returns (uint256);
}

contract TBDPass is ERC1155, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    // - events
    event BurnerStateChanged(address indexed burner, bool indexed newState);
    event ContractToggled(bool indexed newState);
    event FloatingCapUpdated(uint256 indexed newCap);
    event PriceCalculatorUpdated(address indexed calc);
    event VerifiedSignerSet(address indexed signer);

    // - constants
    uint256 public constant PASS_ID = 0;
    uint256 public constant STAGE1_CAP = 2000;                           // initial floating cap
    uint256 public constant RESERVE_CAP = 2000;                          // global limit on the tokens mintable by owner
    uint256 public constant HARD_CAP = 10000;                            // global limit on the tokens mintable by anyone
    uint256 public constant MAX_MINT = 250;                              // global per-account limit of mintable tokens

    uint256 public constant PRICE = .06 ether;                           // initial token price
    uint256 public constant PRICE_INCREMENT = .05 ether;                 // increment it by this amount
    uint256 public constant PRICE_TIER_SIZE = 500;                       // every ... tokens
    address private constant TIP_RECEIVER =
        0x3a6E4D326aeb315e85E3ac0A918361672842a496;                      //

    // - storage variables; 
    uint256 public totalSupply;                                          // all tokens minted
    uint256 public reserveSupply;                                        // minted by owner; never exceeds RESERVE_CAP
    uint256 public reserveSupplyThisPeriod;                              // minted by owner this release period, never exceeds reserveCap
    uint256 public reserveCapThisPeriod;                                 // current reserve cap; never exceeds RESERVE_CAP - reserveSupply 
    uint256 public floatingCap;                                          // current upper boundary of the floating cap; never exceeds HARD_CAP
    uint256 public releasePeriod;                                        // counter of floating cap updates; changing this invalidates wl signatures
    bool public paused;                                                  // control wl minting and at-cost minting
    address public verifiedSigner;                                       // wl requests must be signed by this account 
    ICalculator public calculator;                                       // external price source
    mapping(address => bool) public burners;                             // accounts allowed to burn tokens
    mapping(uint256 => mapping(address => uint256)) public allowances;   // tracked wl allowances for current release cycle
    mapping(address => uint256) public mints;                            // lifetime accumulators for tokens minted


    constructor() ERC1155("https://studio-tbd.io/tokens/default.json") {
        floatingCap = STAGE1_CAP;
    }

    function price() external view returns (uint256) {
        return _price();
    }

    function getAllowance() external view returns (uint256) {
        uint256 allowance = allowances[releasePeriod][msg.sender];
        if (allowance > 1) {
            return allowance - 1;
        } else {
            return 0;
        }
    }

    function whitelistMint(
        uint256 qt,
        uint256 initialAllowance,
        bytes calldata signature
    ) external {
        _whenNotPaused();

        // Signatures from previous `releasePeriod`s will not check out.
        _validSignature(msg.sender, initialAllowance, signature);

        // Set account's allowance on first use of the signature.
        // The +1 offset allows to distinguish between a) first-time
        // call; and b) fully claimed allowance. If the first use tx 
        // executes successfully, ownce never goes below 1. 
        mapping(address => uint256) storage ownce = allowances[releasePeriod];
        if (ownce[msg.sender] == 0) {
            ownce[msg.sender] = initialAllowance + 1;
        }

        // The actual allowance is always ownce -1;
        // must be above 0 to proceed.
        uint256 allowance = ownce[msg.sender] - 1;
        require(allowance > 0, "OutOfAllowance");

        // If the qt requested is 0, mint up to max allowance:
        uint256 qt_ = (qt == 0)? allowance : qt;
        // qt_ is never 0, since if it's 0, it assumes allowance,
        // and that would revert earlier if 0.
        assert(qt_ > 0);
    
        // It is possible, however, that qt is non-zero and exceeds allowance:
        require(qt_ <= allowance, "MintingExceedsAllowance");

        // Observe lifetime per-account limit:
        require(qt_ + mints[msg.sender] <= MAX_MINT, "MintingExceedsLifetimeLimit");

        // In order to assess whether it's cool to extend the floating cap by qt_, 
        // calculate the extension upper bound. The gist: extend as long as 
        // the team's reserve is guarded.
        uint256 reserveVault = (RESERVE_CAP - reserveSupply) - (reserveCapThisPeriod - reserveSupplyThisPeriod);
        uint256 extensionMintable = HARD_CAP - floatingCap - reserveVault;

        // split between over-the-cap supply and at-cost supply
        uint256 mintableAtCost = _mintableAtCost();
        uint256 wlMintable = extensionMintable + mintableAtCost;
        require(qt_ <= wlMintable, "MintingExceedsAvailableSupply");
        
        // adjust fc
        floatingCap += (qt_ > extensionMintable)? extensionMintable : qt_; 

        // decrease caller's allowance in the current period
        ownce[msg.sender] -= qt_;

        _mintN(msg.sender, qt_);
    }

    function mint(uint256 qt) external payable {
        _whenNotPaused();
        require(qt > 0, "ZeroTokensRequested");
        require(qt <= _mintableAtCost(), "MintingExceedsFloatingCap");
        require(
            mints[msg.sender] + qt <= MAX_MINT,
            "MintingExceedsLifetimeLimit"
        );
        require(qt * _price() == msg.value, "InvalidETHAmount");
    
        _mintN(msg.sender, qt);
    }


    function withdraw() external {
        _onlyOwner();
        uint256 tip = address(this).balance * 2 / 100;
        payable(TIP_RECEIVER).transfer(tip);
        payable(owner()).transfer(address(this).balance);
    }

    function setCalculator(address calc) external {
        _onlyOwner();
        require(calc != address(0), "ZeroCalculatorAddress");
        emit PriceCalculatorUpdated(calc);
        calculator = ICalculator(calc);
    }

    function setVerifiedSigner(address signer) external {
        _onlyOwner();
        require(signer != address(0), "ZeroSignerAddress");
        emit VerifiedSignerSet(signer);
        verifiedSigner = signer;
    }

    function setFloatingCap(uint256 cap, uint256 reserve) external {
        _onlyOwner();
        require(reserveSupply + reserve <= RESERVE_CAP, "OwnerReserveExceeded");
        require(cap >= floatingCap, "CapUnderCurrentFloatingCap");
        require(cap <= HARD_CAP, "HardCapExceeded");
        require((RESERVE_CAP - reserveSupply - reserve) <= (HARD_CAP - cap), 
            "OwnerReserveViolation");
        require(cap - totalSupply >= reserve, "ReserveExceedsTokensAvailable");

        reserveCapThisPeriod = reserve;
        reserveSupplyThisPeriod = 0;
        emit FloatingCapUpdated(cap);
        floatingCap = cap;
        _nextPeriod();
    }

    function reduceReserve(uint256 to) external {
        _onlyOwner();
        require(to >= reserveSupplyThisPeriod, "CannotDecreaseBelowMinted");
        require(to < reserveCapThisPeriod, "CannotIncreaseReserve");
        
        // supply above floatingCap must be still sufficient to compensate
        // for potentially excessive reduction
        uint256 capExcess = HARD_CAP - floatingCap;
        bool reserveViolated = capExcess < (RESERVE_CAP - reserveSupply) - (to - reserveSupplyThisPeriod);
        require(!reserveViolated, "OwnerReserveViolation");
        
        reserveCapThisPeriod = to;
    }

    function nextPeriod() external {
        _onlyOwner();
        _nextPeriod();
    }

    function setBurnerState(address burner, bool state) external {
        _onlyOwner();
        require(burner != address(0), "ZeroBurnerAddress");
        emit BurnerStateChanged(burner, state);
        burners[burner] = state;
    }

    function burn(address holder, uint256 qt) external {
        _onlyBurners();
        _burn(holder, PASS_ID, qt);
        _mint(0x000000000000000000000000000000000000dEaD, PASS_ID, qt, "");
    }

    function setURI(string memory uri_) external {
        _onlyOwner();
        _setURI(uri_);
    }

    function toggle() external {
        _onlyOwner();
        emit ContractToggled(!paused);
        paused = !paused;
    }

    function teamdrop(address to, uint256 qt) external {
        _onlyOwner();
        require(to != address(0), "ZeroReceiverAddress");
        require(qt > 0, "ZeroTokensRequested");
        require(releasePeriod > 0, "PrematureMintingByOwner");
        require(reserveSupplyThisPeriod + qt <= reserveCapThisPeriod, "MintingExceedsPeriodReserve");
        reserveSupply += qt;
        reserveSupplyThisPeriod += qt;
        _mintN(to, qt);
    }

    // - internals
    function _nextPeriod() internal {
        releasePeriod++;
    }

    function _mintN(address to, uint256 qt) internal nonReentrant {
        totalSupply += qt;
        mints[to] += qt;
        _mint(to, PASS_ID, qt, "");
    }

    function _mintableAtCost() internal view returns (uint256) {
        return floatingCap - totalSupply - 
            (reserveCapThisPeriod - reserveSupplyThisPeriod);
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner(), "UnauthorizedAccess");
    }

    function _onlyBurners() internal view {
        require(burners[msg.sender], "UnauthorizedAccess");
    }

    function _whenNotPaused() internal view {
        require(!paused, "ContractPaused");
    }

    function _validSignature(
        address account,
        uint256 allowance,
        bytes calldata signature
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(account, releasePeriod, allowance))
            )
        );
        require(
            hash.recover(signature) == verifiedSigner,
            "InvalidSignature."
        );
    }

    function _price() internal view returns (uint256 price_) {
        if (calculator != ICalculator(address(0))) {
            price_ = calculator.price();
        } else {
            price_ = PRICE + PRICE_INCREMENT * (totalSupply / PRICE_TIER_SIZE);
        }
    }
}