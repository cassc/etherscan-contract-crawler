// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

contract Charity is VRFConsumerBaseV2, AccessControl {

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20 public immutable GWD;
    VRFCoordinatorV2Interface public immutable COORDINATOR;
    IUniswapV2Router01 public immutable ROUTER;

    address[] public PATH;

    uint256[2] public minAndMax = [50000000000, 500000000000];

    uint256 public totalDonated;

    bytes32 public chainlinkParameterKeyHash;
    uint64 public chainlinkParameterSubId;
    uint16 public chainlinkParameterMinimumRequestConfirmations;
    uint32 public chainlinkParameterCallbackGasLimit = 75000;

    bool public randomnessAndSwapEnabled;
    bool public randomnessRequested;

    uint256 private toSwapAt;

    mapping(address => uint256) public donated;

    modifier whenDisabled() {
        require(!randomnessAndSwapEnabled, "Randomness and swap are not disabled");
        _;
    }

    constructor(address _gwd, address _coordinator, IUniswapV2Router01 _router, bytes32 _keyHash, uint64 _subId, uint16 _minimumRequestConfirmations) VRFConsumerBaseV2(_coordinator) {
        GWD = IERC20(_gwd);
        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
        ROUTER = _router;
        PATH.push(_gwd);
        PATH.push(_router.WETH());
        chainlinkParameterKeyHash = _keyHash;
        chainlinkParameterSubId = _subId;
        chainlinkParameterMinimumRequestConfirmations = _minimumRequestConfirmations;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _gwd);
    }

    receive() external payable {}

    function addToCharity(uint256 amount, address user) external onlyRole(MANAGER_ROLE) {
        totalDonated += amount;
        donated[user] += amount;
        if (randomnessAndSwapEnabled && GWD.balanceOf(address(this)) >= minAndMax[0] && toSwapAt == 0 && !randomnessRequested) {
            try COORDINATOR.requestRandomWords(chainlinkParameterKeyHash, chainlinkParameterSubId, chainlinkParameterMinimumRequestConfirmations, chainlinkParameterCallbackGasLimit, 1) {
                randomnessRequested = true;
            }
            catch {}
        }
    }

    function swapNow() external onlyRole(MANAGER_ROLE) {
        if (randomnessAndSwapEnabled && toSwapAt > 0 && GWD.balanceOf(address(this)) >= toSwapAt) {
            GWD.approve(address(ROUTER), GWD.balanceOf(address(this)));
            try ROUTER.swapExactTokensForETH(GWD.balanceOf(address(this)), 0, PATH, address(this), block.timestamp) {
                toSwapAt = 0;
            }
            catch {}
        }
    }

    function setRandomnessAndSwapEnabled(bool _randomnessAndSwapEnabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        randomnessAndSwapEnabled = _randomnessAndSwapEnabled;
    }

    function setMinAndMax(uint256[2] calldata _minAndMax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minAndMax[0] < _minAndMax[1] && _minAndMax[0] > 0, "Invalid parameters");
        minAndMax = _minAndMax;
    }

    function setChainlinkParameterKeyHash(bytes32 _keyHash) external onlyRole(DEFAULT_ADMIN_ROLE) whenDisabled {
        chainlinkParameterKeyHash = _keyHash;
    }

    function setChainlinkParameterSubId(uint64 _subId) external onlyRole(DEFAULT_ADMIN_ROLE) whenDisabled {
        chainlinkParameterSubId = _subId;
    }

    function setChainlinkParameterMinimumRequestConfirmations(uint16 _minimumRequestConfirmations) external onlyRole(DEFAULT_ADMIN_ROLE) whenDisabled {
        chainlinkParameterMinimumRequestConfirmations = _minimumRequestConfirmations;
    }

    function setChainlinkParameterCallbackGasLimit(uint32 _callbackGasLimit) external onlyRole(DEFAULT_ADMIN_ROLE) whenDisabled {
        chainlinkParameterCallbackGasLimit = _callbackGasLimit;
    }

    function collectGWD() external onlyRole(DEFAULT_ADMIN_ROLE) whenDisabled {
        GWD.transfer(_msgSender(), GWD.balanceOf(address(this)));
    }

    function collectETH() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        randomnessRequested = false;
        toSwapAt = randomWords[0] % (minAndMax[1] - minAndMax[0]) + minAndMax[0];
    }
}