pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IOmniApp.sol";
import "../../interfaces/IOmnichainRouter.sol";
import { SendPointsParams } from "../../structs/OmniseaPointsStructs.sol";

contract OmniseaPointsRepository is Ownable, IOmniApp {
    event OmReceived(string srcChain, address srcOA);

    mapping (address => bool) public agents;
    IERC20 public token;
    mapping (address => uint256) public points;
    uint256 public totalPoints;
    string public chainName;
    mapping(string => address) public remoteChainToOA;
    IOmnichainRouter public omnichainRouter;
    address private _redirectionsBudgetManager;

    modifier onlyAgent() {
        require(isAgent(msg.sender), "!agent");
        _;
    }

    constructor(IERC20 _token, IOmnichainRouter _router) {
        token = _token;
        chainName = "BSC";
        omnichainRouter = _router;
        _redirectionsBudgetManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    }

    function setAgent(address _agent, bool _isAgent) external onlyOwner {
        agents[_agent] = _isAgent;
    }

    function isAgent(address _agent) public view returns (bool) {
        return _agent == address(this) || agents[_agent];
    }

    function getPoints(address _account) public view returns (uint256) {
        return points[_account];
    }

    function isEnoughPoints(address _account, uint256 _quantity) public view returns (bool) {
        return getPoints(_account) >= _quantity;
    }

    function claim() external {
        uint256 claimable = getPoints(msg.sender);
        require(claimable > 0, "!claimable");
        _subtract(msg.sender, claimable);
        token.transfer(msg.sender, claimable);
    }

    function purchase(uint256 _quantity) external {
        require(token.allowance(msg.sender, address(this)) >= _quantity, "!approved");

        _add(msg.sender, _quantity);
        token.transferFrom(msg.sender, address(this), _quantity);
    }

    function sendPoints(SendPointsParams calldata params) external payable {
        require(isOA(params.dstChainName, remoteChainToOA[params.dstChainName]));
        _subtract(msg.sender, params.quantity);

        omnichainRouter.send{value : msg.value}(
            params.dstChainName,
            remoteChainToOA[params.dstChainName],
            abi.encode(params, msg.sender),
            params.gas,
            msg.sender,
            params.redirectFee
        );
    }

    function add(address _receiver, uint256 _quantity) external onlyAgent {
        if (_receiver == owner()) {
            require(msg.sender != owner(), "!fair");
        }
        _add(_receiver, _quantity);
    }

    function subtract(address _receiver, uint256 _quantity) external onlyAgent {
        _subtract(_receiver, _quantity);
    }

    /**
     * @notice Handles the incoming ERC721 collection creation task from other chains received from Omnichain Router.
     *         Validates User Application.

     * @param _payload Encoded CreateParams data.
     * @param srcOA Address of the remote OA.
     * @param srcChain Name of the remote OA chain.
     */
    function omReceive(bytes calldata _payload, address srcOA, string memory srcChain) external override {
        emit OmReceived(srcChain, srcOA);
        require(isOA(srcChain, srcOA), "!OA");

        (SendPointsParams memory params, address account) = abi.decode(_payload, (SendPointsParams, address));
        _add(account, params.quantity);
    }

    /**
     * @notice Sets the remote Omnichain Applications ("OA") addresses to meet omReceive() validation.
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function setOA(string calldata remoteChainName, address remoteOA) external onlyOwner {
        remoteChainToOA[remoteChainName] = remoteOA;
    }

    /**
     * @notice Checks the presence of the selected remote User Application ("OA").
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function isOA(string memory remoteChainName, address remoteOA) public view returns (bool) {
        return remoteOA != address(0) && remoteChainToOA[remoteChainName] == remoteOA;
    }

    function setRouter(IOmnichainRouter _router) external onlyOwner {
        omnichainRouter = _router;
    }

    function setRedirectionsBudgetManager(address _newManager) external onlyOwner {
        _redirectionsBudgetManager = _newManager;
    }

    function withdrawOARedirectFees() external onlyOwner {
        omnichainRouter.withdrawOARedirectFees(_redirectionsBudgetManager);
    }

    function setChainName(string memory _chainName) external onlyOwner {
        chainName = _chainName;
    }

    function withdrawRemaining() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance - totalPoints);
    }

    function _add(address _receiver, uint256 _quantity) private {
        require(_quantity > 0, "!quantity");
        points[_receiver] += _quantity;
        totalPoints += _quantity;
    }

    function _subtract(address _receiver, uint256 _quantity) private {
        require(_quantity > 0, "!quantity");
        require(isEnoughPoints(_receiver, _quantity), "!balance");
        points[_receiver] -= _quantity;
        totalPoints -= _quantity;
    }
}