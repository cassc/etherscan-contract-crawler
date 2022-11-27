// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MiniProxySweetMiner.sol";
import "./IMiniProxySweet.sol";


contract SweetBathXen is Ownable {

    address private immutable original;

    address private immutable deployer;

    address public immutable _miniProxy;

    mapping(address => uint256) public countSweetMint;

    mapping(address => uint256) public countSweetReward;

    mapping(address => bool) public miners;

    uint256 public initializeMinerFee;

    uint256 public totalSupplySweetMint;

    uint256 public totalSupplySweetReward;

    constructor(uint256 _initMinerFee, address _xenAddress){
        original = address(this);
        deployer = msg.sender;
        miners[msg.sender] = true;
        initializeMinerFee = _initMinerFee;
        _miniProxy = address(new MiniProxySweetMiner(original, _xenAddress));
    }

    event SweetBatchMint(address miner, uint256 users, uint256 term);

    event SweetBatchReward (address miner, uint256 users);

    event SweetBatchRewardIndex(address miner, uint256 start, uint256 end);

    event PaymentReceived(address from, uint256 amount);

    event InitializeMiner(address miner);


    /**
     * @dev Throws if called by any miner other than the owner.
     */
    modifier onlyMiner() {
        _checkMiner();
        _;
    }


    /**
     * @dev Throws if the sender is not the miner.
     */
    function _checkMiner() internal view virtual {
        require(miners[_msgSender()], "Not yet miner");
    }


    function setMiner(address[] calldata _miners) external
    onlyOwner {
        for (uint256 i; i < _miners.length; i++) {
            _setMiner(_miners[i]);
        }
    }

    function _setMiner(address _miner) internal {
        miners[_miner] = true;
    }

    function setInitializeMinerFee(uint256 _initializeMinerFee) external
    onlyOwner {
        initializeMinerFee = _initializeMinerFee;
    }


    function initializeMiner() external payable {
        require(msg.value == initializeMinerFee, "Initialize batch miner failed");
        require(!miners[_msgSender()], "Miner repeated initialize");
        _setMiner(_msgSender());
        require(miners[_msgSender()], "Failed to initialize Miner!");
        emit InitializeMiner(_msgSender());
    }

    function sweetMint(uint256 users, uint256 term) external onlyMiner {
        require(users > 0, "users Greater than 0");
        require(term > 0, "Term Greater than 0");
        uint256 sm = countSweetMint[msg.sender];
        for (uint i = sm; i < sm + users; i++) {
            bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
            address proxy = Clones.cloneDeterministic(_miniProxy, salt);
            IMiniProxySweet(proxy).sweetClaimRank(term);
        }
        countSweetMint[msg.sender] = sm + users;
        totalSupplySweetMint = totalSupplySweetMint + users;
        emit SweetBatchMint(msg.sender, users, term);
    }


    function proxyFor(address sender, uint256 i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        return Clones.predictDeterministicAddress(_miniProxy, salt);
    }

    function sweetReward(uint256 users) external onlyMiner {
        require(countSweetMint[msg.sender] > 0, "No mint record yet");
        require(users > 0, "Users Greater than 0");
        uint256 sm = countSweetMint[msg.sender];
        uint256 sr = countSweetReward[msg.sender];
        uint256 s = sr + users < sm ? sr + users : sm;
        uint256 rsi;
        for (uint i = sr; i < s; i++) {
            address proxy = proxyFor(msg.sender, i);
            if (!_contractExists(proxy)) {
                continue;
            }
            IMiniProxySweet(proxy).sweetClaimRewardTo(msg.sender);
            rsi++;
        }
        countSweetReward[msg.sender] = s;
        totalSupplySweetReward = totalSupplySweetReward + rsi;
        emit SweetBatchReward(msg.sender, users);
    }

    function _contractExists(address proxy) internal view returns (bool){
        uint size;
        assembly {
            size := extcodesize(proxy)
        }
        return size > 0;
    }


    function sweetBatchRewardIndex(uint256 _userSI, uint256 _userEI) external onlyMiner {
        require(_userSI < _userEI, "_userSI greater than _userEI");
        require(countSweetMint[msg.sender] > 0, "No mint record yet");
        require(_userEI <= countSweetMint[msg.sender], "Claim Reward Limit Exceeded");
        uint256 rsi;
        for (uint i = _userSI; i <= _userEI; i++) {
            address proxy = proxyFor(msg.sender, i);
            if (!_contractExists(proxy)) {
                continue;
            }
            IMiniProxySweet(proxy).sweetClaimRewardTo(msg.sender);
            rsi++;
        }
        totalSupplySweetReward = totalSupplySweetReward + rsi;
        emit SweetBatchRewardIndex(msg.sender, _userSI, _userEI);
    }

    function withdraw(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No balance to withdraw");
            (bool success,) = payable(msg.sender).call{value : balance}("");
            require(success, "Failed to withdraw payment");
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 _ercBalance = erc20token.balanceOf(address(this));
        require(_ercBalance > 0, "No balance to withdraw");
        bool _ercSuccess = erc20token.transfer(owner(), _ercBalance);
        require(_ercSuccess, "Failed to withdraw payment");
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
}