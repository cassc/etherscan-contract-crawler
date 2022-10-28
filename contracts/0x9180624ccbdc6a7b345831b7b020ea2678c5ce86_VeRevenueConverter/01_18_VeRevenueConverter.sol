// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: [email protected]

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@interfaces/IVoterProxy.sol";
import "@interfaces/IIncentivesStash.sol";
import "@interfaces/IDepositor.sol";
import "@interfaces/IWrapperOracle.sol";
import "@interfaces/IFeeRegistry.sol";

contract VeRevenueConverter is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event ProtocolAdded(
        uint256 protocolId,
        address voterProxy,
        address depositor,
        address rewardToken,
        address pitchWrappedToken,
        address rewardDistroContract,
        uint256 gaugeCount
    );

    event GovernanceRevenueHarvested(uint256 protocolId, uint256 amount, uint256 valueInWeiPer);
    event AllGovernanceRevenueHarvested(uint256 protocolHarvestCount);
    event FeeRecovered(address token, uint256 amount);

    struct Protocol {
        address voterProxy;
        address depositor;
        address rewardToken;
        address pitchToken;
        address targetRewardDistro;
        address[] gaugeAddresses;
        uint256[] gaugeWeights; // IN BPS (so, 25% = 2500)
        uint256 active;
        address wrapperOracle;
    }

    Protocol[] public protocols;

    address public constant FEE_MANAGER = address(0x8Df8f06DC2dE0434db40dcBb32a82A104218754c);
    address public constant INCENTIVES_STASH = address(0x5D135C1a7604BF0b78018a21bA722e9A06e6D096);
    address public constant FEE_REGISTRY = address(0x0Bc9DF52Ff655932D08DAaCBA33881C0D268Cd46);
    uint256 public constant FEE_DENOMINATOR = 10000;

    function initialize() public initializer {
        __UUPSUpgradeable_init_unchained();
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function getProtocolCount() external view returns (uint256) {
        return protocols.length;
    }

    function getProtocolGaugesAndWeights(uint256 _protocolId)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        return (protocols[_protocolId].gaugeAddresses, protocols[_protocolId].gaugeWeights);
    }

    /**
    * @dev Add Frax & Saddle on deployment
    * FRAX Addresses
        address voterProxy = 0x78ec75e69A5f2150c1095E5FEffc1Fe17362aCC0
        address depositor = 0xdfa1F69774ad2924Cebd43d75AaDfb92403C5335
        address rewardToken = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0
        address pitchToken = 0x11EBe21e9d7BF541A18e1E3aC94939018Ce88F0b
        address targetRewardDistro = 0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872
        address gaugeAddress = 0xa632Fab76Fe013199c8271Ac22b466b9D11BFe88 // FraxswapV2 pitchFXS/FRAX LP
    * Saddle Addresses
        address voterProxy = 0xF942f26188229025AA81aE96cc0D19408Bd62dd9
        address depositor = 0x17A67BDb5cfB7A21781240997505d69A398813Bc
        address rewardToken = 0xf1Dc500FdE233A4055e25e5BbF516372BC4F6871
        address pitchToken = 0x1a381C7a8A47E2e7247d45eC374391129d1B6021
        address targetRewardDistro = 0xabd040A92d29CDC59837e79651BB2979EA66ce04 // this should also claim from veSDLRewards:0xD2751CdBED54B87777E805be36670D7aeAe73bb2
        address gaugeAddress = TODO We using Saddle's App? We need pitchSDL LP & gauge address (saddle uses snapshot)
     */

    /// @notice Add a new protocol to the converter
    /// @param _voterProxy The address of the voter proxy contract
    /// @param _depositor The address of the depositor contract
    /// @param _rewardToken The address of the reward token
    /// @param _pitchToken The address of the pitch token
    /// @param _targetRewardDistro The address of the target reward distro contract
    /// @param _gaugeAddresses The addresses of the gauges
    /// @param _gaugeWeights The weights of the gauges
    /// @param _wrapperOracle The address of the wrapper oracle
    function addProtocol(
        address _voterProxy,
        address _depositor,
        address _rewardToken,
        address _pitchToken,
        address _targetRewardDistro,
        address[] memory _gaugeAddresses,
        uint256[] memory _gaugeWeights,
        address _wrapperOracle
    ) external onlyOwner {
        protocols.push(
            Protocol(
                _voterProxy,
                _depositor,
                _rewardToken,
                _pitchToken,
                _targetRewardDistro,
                _gaugeAddresses,
                _gaugeWeights,
                1,
                _wrapperOracle
            )
        );

        IERC20Upgradeable(_rewardToken).safeApprove(_depositor, type(uint256).max);
        IERC20Upgradeable(_pitchToken).safeApprove(INCENTIVES_STASH, type(uint256).max);

        emit ProtocolAdded(
            protocols.length - 1,
            _voterProxy,
            _depositor,
            _rewardToken,
            _pitchToken,
            _targetRewardDistro,
            _gaugeAddresses.length
        );
    }

    /// @notice Update a protocol's gauges & weights
    /// @param _protocolId The protocol to update
    /// @param _gaugeAddresses The addresses of the gauges
    /// @param _gaugeWeights The weights of the gauges
    function updateGaugesAndWeights(
        uint256 _protocolId,
        address[] memory _gaugeAddresses,
        uint256[] memory _gaugeWeights
    ) external onlyOwner {
        protocols[_protocolId].gaugeAddresses = _gaugeAddresses;
        protocols[_protocolId].gaugeWeights = _gaugeWeights;
    }

    /// @notice Deactivate the defined protocol parameters
    /// @param _protocolId The protocol to deactivate
    /// @dev Useful if needing to update other address parameters
    function deactivateProtocol(uint256 _protocolId) external onlyOwner {
        protocols[_protocolId].active = 0;
    }

    /// @notice Harvests `protocolId` voter proxy's governance rewards, locks assets into depositor & deposits to gauge
    /// @param _protocolId The protocol to harvest
    function harvestProtocol(uint256 _protocolId) external {
        _harvestProtocol(_protocolId);
    }

    /// @notice Harvests all protocols & deposits to the correct gauge incentive in one transaction
    /// @dev OK to call by anyone since there's no way to remove those funds from the contract
    function harvestAll() external {
        // harvest from all voter proxies
        // convert from reward token into pitchWrapped token
        // send to the gauge incentives for pitchWrapped token LP
        uint256 harvests;
        for (uint256 i; i < protocols.length; i++) {
            if (protocols[i].active == 1) {
                _harvestProtocol(i);
                harvests++;
            }
        }

        emit AllGovernanceRevenueHarvested(harvests);
    }

    function _harvestProtocol(uint256 _protocolId) internal {
        // Note: FRAXFARM DOES NOT ALLOW SINGLE SIDED DEPOSITS OF FXS
        //       Could sell the yielded FXS for FRAX & buy pitchFXS, for example

        // ensure that the protocol parameters are allowed/active
        require(protocols[_protocolId].active == 1, "Protocol is not active");

        // first, checkpoint the voter proxy
        IVoterProxy(protocols[_protocolId].voterProxy).checkpointFeeRewards(protocols[_protocolId].targetRewardDistro);

        // claim the revenue
        uint256 amount = IVoterProxy(protocols[_protocolId].voterProxy).claimFees(
            protocols[_protocolId].targetRewardDistro,
            protocols[_protocolId].rewardToken,
            address(this)
        );

        // process fees (if any)
        amount -= _processFees(_protocolId);

        // deposit the revenue into the depositor to convert to pitchWrapped token
        IDepositor(protocols[_protocolId].depositor).deposit(amount, true);

        // get the current price of the pitch token
        uint256 currentPriceInWei = IWrapperOracle(protocols[_protocolId].wrapperOracle).getUSDPrice(
            protocols[_protocolId].pitchToken
        );

        // deposit to incentives for each gauge listed
        for (uint256 i; i < protocols[_protocolId].gaugeAddresses.length; i++) {
            // calculate the amount of reward to send to the gauge incentive
            // prevents there being leftover tokens in the contract
            uint256 rwdAmt;
            if (i != protocols[_protocolId].gaugeAddresses.length - 1) {
                rwdAmt = ((amount * protocols[_protocolId].gaugeWeights[i]) / FEE_DENOMINATOR);
            } else {
                rwdAmt = IERC20Upgradeable(protocols[_protocolId].pitchToken).balanceOf(address(this));
            }

            // add the reward to the incentives stash
            IIncentivesStash(INCENTIVES_STASH).addReward(
                protocols[_protocolId].gaugeAddresses[i],
                protocols[_protocolId].pitchToken,
                rwdAmt,
                // ((amount * protocols[_protocolId].gaugeWeights[i]) / FEE_DENOMINATOR),
                currentPriceInWei
            );
        }

        emit GovernanceRevenueHarvested(_protocolId, amount, currentPriceInWei);
    }

    /// @notice For use if more than 1 ERC20 token is yielded as a reward
    /// @param _token The token to withdraw
    /// @param _amount The amount to withdraw
    /// @param _to The address to send the tokens to
    function recoverAdditionalERC20(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        IERC20Upgradeable(_token).transfer(_to, _amount);
    }

    // used to manage upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _processFees(uint256 _protocolId) internal returns (uint256 sendAmount) {
        // Get fee rate from fee registry
        uint256 fee = IFeeRegistry(FEE_REGISTRY).veRevenueFee();

        // Send FXS fees to fee deposit address
        uint256 balance = IERC20Upgradeable(protocols[_protocolId].rewardToken).balanceOf(address(this));
        sendAmount = (balance * fee) / FEE_DENOMINATOR;

        if (sendAmount > 0) {
            IERC20Upgradeable(protocols[_protocolId].rewardToken).transfer(
                IFeeRegistry(FEE_REGISTRY).feeAddress(),
                sendAmount
            );

            emit FeeRecovered(protocols[_protocolId].rewardToken, sendAmount);
        }
    }
}