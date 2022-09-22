//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./access/Governable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IVsp.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IVspOracle.sol";
import "./interfaces/IESVSP.sol";
import "./interfaces/IESVSP721.sol";

/**
 * @title VSP Minter contract
 * @notice Allows users to sell assets to the Vesper DAO in exchange for newly minted VSP
 */
contract VspMinter is Governable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IVsp;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant VERSION = "1.0.0";
    uint256 public constant MAX_BPS = 10_000;

    /**
     * @notice Holds data regarding a goal
     */
    struct Goal {
        // targetAmount: how much of the goal token the treasury wants
        uint256 targetAmount;
        // priceMultiplier: sets a premium or discount for the given token
        uint256 priceMultiplier;
        // oracle: oracle module for given token
        IOracle oracle;
    }

    /// @notice Minimum VSP acceptable price
    uint256 public vspSafeLowPriceInUsd;

    /// @notice treasury address
    /// @dev newly minted VSP and bonds sales goes there
    address public treasury;

    /// @notice Mapping of token => Goal information
    mapping(address => Goal) public goals;

    /// @dev Enumerable set for tokens' addresses
    EnumerableSet.AddressSet private tokens;

    /// @notice Address of vsp token
    IVsp public immutable vsp;

    /// @notice Address of esVSP
    IESVSP public immutable esVSP;

    /// @notice Address of esVSP721
    IESVSP721 public immutable esVSP721;

    /// @notice Address of vsp oracle module
    IVspOracle public vspOracle;

    /// @notice Emitted when treasury address is updated
    event TreasuryUpdated(address indexed _oldTreasury, address indexed _newTreasury);

    /// @notice Emitted when a new goal has been added to the goal list
    event GoalAdded(address indexed _token, uint256 _targetAmount, uint256 _priceMultiplier);

    /// @notice Emitted when an oracle module for a goal token is updated
    event GoalOracleUpdated(address indexed _token, IOracle indexed _oldOracle, IOracle indexed _newOracle);

    /// @notice Emitted when a new goal target for a token is updated
    event GoalTargetUpdated(address indexed _token, uint256 _oldTargetAmount, uint256 _newTargetAmount);

    /// @notice Emitted when a vsp price multiplier for a token is updated
    event GoalPriceMultiplierUpdated(address indexed _token, uint256 _oldMultiplier, uint256 _newMultiplier);

    /// @notice Emitted when an oracle module for VSP is updated
    event VSPOracleUpdated(IVspOracle indexed _oldOracle, IVspOracle indexed _newOracle);

    /// @notice Emitted when newly minted VSP goes to a recipient
    event VSPMinted(IERC20 indexed _goalToken, address indexed _recipient, uint256 _mintedAmount);

    /// @notice Emitted when VSP safe low price is updated
    event VspSafeLowPriceUpdated(uint256 _oldVspSafeLowPriceInUsd, uint256 _newVspSafeLowPriceInUsd);

    constructor(
        address _treasury,
        address _esVSP,
        IVspOracle _vspOracle,
        uint256 _vspSafeLowPriceInUsd
    ) {
        require(_esVSP != address(0), "esvsp-addr-is-zero");

        esVSP = IESVSP(_esVSP);
        esVSP721 = IESVSP721(esVSP.esVSP721());

        require(address(esVSP721) != address(0), "esvsp-not-initialized");

        vsp = IVsp(esVSP.VSP());

        vsp.safeApprove(address(_esVSP), type(uint256).max);

        _setVspOracle(_vspOracle);
        _setTreasury(_treasury);

        vspSafeLowPriceInUsd = _vspSafeLowPriceInUsd;
    }

    /**
     * @notice Helper function to get all goals' tokens
     * @dev This function is gas intensive and it's recommended to be only called off-chain
     */
    function getTokens() external view returns (address[] memory _tokens) {
        _tokens = tokens.values();
    }

    /**
     * @notice View-only function for estimating mintable VSP by a given token
     * @dev Does not revert in case a token is not in the goal list or target is 0
     * @param _token address of a token in the goal list
     * @param _tokenAmount amount to give in exchange for newly minted VSP
     */
    function mintableVspByToken(address _token, uint256 _tokenAmount) external view returns (uint256 _mintableVsp) {
        if (!tokens.contains(_token)) return 0;
        if (_tokenAmount > goals[_token].targetAmount) return 0;

        (_mintableVsp, ) = _mintableVspByToken(_token, _tokenAmount);
    }

    /**
     * @notice Mints new VSP by giving a _token to the treasury
     * @dev _token must be in the goal list
     * @param _token address of a token in the goal list
     * @param _tokenAmount amount to give in exchange for newly minted VSP
     * @param _lockPeriod How long newly minted VSP will be locked in esVSP
     */
    function mint(
        IERC20 _token,
        uint256 _tokenAmount,
        uint256 _lockPeriod
    ) external {
        _mintVspAndLock(msg.sender, _token, _tokenAmount, _lockPeriod);
    }

    /**
     * @notice Gets mintable VSP by a given token
     * @param _token address of a token in the goal list
     * @param _tokenAmount amount to give in exchange for newly minted VSP
     */
    function _mintableVspByToken(address _token, uint256 _tokenAmount)
        private
        view
        returns (uint256 _mintableVsp, uint256 _vspPriceInUsd)
    {
        require(tokens.contains(_token), "token-goal-not-set");
        Goal memory _goalInfo = goals[_token];
        require(_tokenAmount <= _goalInfo.targetAmount, "goal-limit-exceeded");

        uint256 _tokenAmountInUsd = (_tokenAmount * _goalInfo.oracle.getPriceInUsd(_token)) / 1e18;

        // Applies discount or premium price to VSP price
        _vspPriceInUsd = vspOracle.getPriceInUsd(address(vsp));
        uint256 _adjustedVspPrice = (_vspPriceInUsd * _goalInfo.priceMultiplier) / MAX_BPS;

        _mintableVsp = (_tokenAmountInUsd * 1e18) / _adjustedVspPrice;
    }

    /**
     * @notice Mints new VSP by giving a _token to the treasury
     * @dev _token must be in the goal list
     * @param _recipient address of recipient for newly minted VSP
     * @param _token address of the token to add in the goal list
     * @param _tokenAmount amount to give in exchange for newly minted VSP
     * @param _lockPeriod How long newly minted VSP will be locked in esVSP
     */
    function mintTo(
        address _recipient,
        IERC20 _token,
        uint256 _tokenAmount,
        uint256 _lockPeriod
    ) external {
        _mintVspAndLock(_recipient, _token, _tokenAmount, _lockPeriod);
    }

    /**
     * @notice Mints new VSP by giving a _token to the treasury
     * @dev Treasury receives 1:1 VSP minted to _recipient
     * minted VSP for _recipient are locked in esVSP
     * @param _recipient address of recipient for newly minted VSP
     * @param _token address of a token in the goal list
     * @param _tokenAmount amount to give in exchange for newly minted VSP
     * @param _lockPeriod How long newly minted VSP will be locked in esVSP
     */
    function _mintVspAndLock(
        address _recipient,
        IERC20 _token,
        uint256 _tokenAmount,
        uint256 _lockPeriod
    ) private {
        require(_recipient != address(0) && _recipient != address(this), "invalid-recipient-addr");
        require(_tokenAmount > 0, "token-amt-is-zero");

        uint256 _tokenBalanceBefore = _token.balanceOf(treasury);
        _token.safeTransferFrom(msg.sender, treasury, _tokenAmount);
        uint256 _actualTokenAmount = _token.balanceOf(treasury) - _tokenBalanceBefore;

        vspOracle.update();

        (uint256 _mintableVsp, uint256 _vspPriceInUsd) = _mintableVspByToken(address(_token), _actualTokenAmount);
        require(_vspPriceInUsd >= vspSafeLowPriceInUsd, "vsp-price-below-safe-price");

        if (_mintableVsp > 0) {
            goals[address(_token)].targetAmount -= _actualTokenAmount;

            vsp.mint(treasury, _mintableVsp);
            vsp.mint(address(this), _mintableVsp);
            esVSP.lockFor(_recipient, _mintableVsp, _lockPeriod);

            emit VSPMinted(_token, _recipient, _mintableVsp);
        }
    }

    /// @notice Sets the treasury address with safety checks
    function _setTreasury(address _newTreasury) private {
        address _currentTreasury = treasury;
        require(_newTreasury != address(0), "treasury-address-is-zero");
        require(_currentTreasury != _newTreasury, "same-treasury");
        emit TreasuryUpdated(_currentTreasury, _newTreasury);
        treasury = _newTreasury;
    }

    /// @notice Sets the VSP oracle module with safety checks
    function _setVspOracle(IVspOracle _newOracle) private {
        IVspOracle _currentVspOracle = vspOracle;
        require(_currentVspOracle != _newOracle, "same-vsp-oracle-addr");
        require(address(_newOracle) != address(0), "vsp-oracle-addr-is-zero");
        emit VSPOracleUpdated(_currentVspOracle, _newOracle);
        vspOracle = _newOracle;
    }

    /// @notice Accepts the ownership of VSP when it's transferred to this Minter
    function acceptOwnership() external onlyGovernor {
        vsp.acceptOwnership();
    }

    /// @notice Adds a new goal
    /// @param _token address of the token to add in the goal list
    /// @param _goal Goal struct holds the target amount wanted, the token oracle and its premium/discount
    function addGoal(address _token, Goal memory _goal) external onlyGovernor {
        require(address(_goal.oracle) != address(0), "oracle-address-is-null");
        require(_goal.priceMultiplier > 0, "multiplier-eq-zero");
        emit GoalAdded(_token, _goal.targetAmount, _goal.priceMultiplier);
        require(tokens.add(_token), "goal-already-exists");
        goals[_token] = _goal;
    }

    /// @notice Transfers VSP ownership to a new owner
    /// @dev _newOwner must then accept the ownership by calling vsp.acceptOwnership();
    function transferVSPOwnership(address _newOwner) external onlyGovernor {
        require(_newOwner != address(0), "new-vsp-owner-is-null");
        vsp.transferOwnership(_newOwner);
    }

    /// @notice Updates the premium or discount wanted for a token in the goal list
    function updateGoalMultiplier(address _token, uint256 _newPriceMultiplier) external onlyGovernor {
        require(tokens.contains(_token), "goal-does-not-exist");
        require(_newPriceMultiplier > 0, "multiplier-eq-zero");

        emit GoalPriceMultiplierUpdated(_token, goals[_token].priceMultiplier, _newPriceMultiplier);
        goals[_token].priceMultiplier = _newPriceMultiplier;
    }

    /// @notice Updates the oracle module for a token in the goal list
    function updateGoalOracle(address _token, IOracle _newOracle) external onlyGovernor {
        require(address(_newOracle) != address(0), "oracle-address-is-null");
        require(tokens.contains(_token), "goal-does-not-exist");
        IOracle _currentOracle = goals[_token].oracle;
        require(_currentOracle != _newOracle, "same-oracle");
        emit GoalOracleUpdated(_token, _currentOracle, _newOracle);
        goals[_token].oracle = _newOracle;
    }

    /// @notice Updates the target amount wanted for a token in the goal list
    function updateGoalTarget(address _token, uint256 _newTargetAmount) external onlyGovernor {
        require(tokens.contains(_token), "goal-does-not-exist");
        emit GoalTargetUpdated(_token, goals[_token].targetAmount, _newTargetAmount);
        goals[_token].targetAmount = _newTargetAmount;
    }

    /// @notice Updates the treasury address
    function updateTreasury(address _newTreasury) external onlyGovernor {
        _setTreasury(_newTreasury);
    }

    /// @notice Updates the oracle module for VSP
    function updateVspOracle(IVspOracle _oracle) external onlyGovernor {
        _setVspOracle(_oracle);
    }

    function updateVspSafeLowPrice(uint256 _vspSafeLowPriceInUsd) external onlyGovernor {
        emit VspSafeLowPriceUpdated(vspSafeLowPriceInUsd, _vspSafeLowPriceInUsd);
        vspSafeLowPriceInUsd = _vspSafeLowPriceInUsd;
    }
}