// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./Interfaces/IStorage.sol";
import "./Interfaces/AggregatorV3Interface.sol";
import "./Interfaces/ILogicContract.sol";
import "./Interfaces/IStrategyContract.sol";
import "./utils/OwnableUpgradeableAdminable.sol";
import "./utils/LogicUpgradeable.sol";

contract MultiLogic is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct singleStrategy {
        address logicContract;
        address strategyContract;
    }

    address private storageContract;
    singleStrategy[] private multiStrategy;
    mapping(address => bool) private approvedTokens;
    mapping(address => bool) private approvedTokensLogic;
    mapping(address => mapping(address => uint256)) private dividePercentage;
    mapping(address => mapping(address => uint256)) private tokenAvailableLogic;
    mapping(address => mapping(address => uint256)) private tokenBalanceLogic;
    uint256 public multiStrategyLength;

    event UpdateTokenAvailableLogic(
        uint256 balance,
        address token,
        address logic
    );
    event UpdateTokenBalanceLogic(
        uint256 balance,
        address token,
        address logic
    );
    event TakeToken(address token, address logic, uint256 amount);
    event ReturnToken(address token, uint256 amount);
    event ReleaseToken(address token, uint256 amount);
    event SetStrategy(uint256 index, singleStrategy strategy);
    event SetLogicTokenAvailable(
        uint256 amount,
        address token,
        uint256 deposit_flag
    );

    function __MultiLogicProxy_init() public initializer {
        LogicUpgradeable.initialize();
        multiStrategyLength = 0;
    }

    receive() external payable {}

    modifier onlyStorage() {
        require(msg.sender == storageContract, "M1");
        _;
    }

    /*** User function ***/

    /**
     * @notice Returns the available amount of token for the logic
     * @param _token deposit token
     * @param _logicAddress logic Address
     */
    function _getTokenAvailable(address _token, address _logicAddress)
        internal
        view
        returns (uint256)
    {
        return tokenAvailableLogic[_token][_logicAddress];
    }

    /**
     * @notice Returns the balance amount of token for the logic
     * @param _token deposit token
     * @param _logicAddress logic Address
     */
    function _getTokenBalance(address _token, address _logicAddress)
        internal
        view
        returns (uint256)
    {
        return tokenBalanceLogic[_token][_logicAddress];
    }

    /**
     * @notice Set the dividing percentage
     * @param _percentages percentage array
     */
    function setPercentages(address _token, uint256[] calldata _percentages)
        external
        onlyOwnerAndAdmin
    {
        uint256 _count = multiStrategyLength;
        uint256 sum = 0;
        uint256 sumAvailable = 0;
        uint256 index;
        require(_percentages.length == _count, "M2");
        for (index = 0; index < _count; ) {
            sum += _percentages[index];
            unchecked {
                ++index;
            }
        }
        require(sum == 10000, "M3");
        for (index = 0; index < _count; ) {
            sumAvailable += tokenAvailableLogic[_token][
                multiStrategy[index].logicContract
            ];
            dividePercentage[_token][
                multiStrategy[index].logicContract
            ] = _percentages[index];
            unchecked {
                ++index;
            }
        }
        if (sumAvailable > 0) {
            for (index = 0; index < _count; ) {
                tokenAvailableLogic[_token][
                    multiStrategy[index].logicContract
                ] = (sumAvailable * _percentages[index]) / 10000;
            }
        }
    }

    /**
     * @notice Set the Logic address into MultiLogicProxy
     * @param _multiStrategy strategy array
     */
    function addStrategy(singleStrategy[] calldata _multiStrategy)
        external
        onlyOwnerAndAdmin
    {
        multiStrategyLength = _multiStrategy.length;
        for (uint256 i = 0; i < multiStrategyLength; ) {
            multiStrategy.push(_multiStrategy[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set the Logic address into MultiLogicProxy
     * @param _index index of strategy
     * @param _multiStrategy strategy array
     */
    function setStrategy(uint256 _index, singleStrategy memory _multiStrategy)
        external
        onlyOwnerAndAdmin
    {
        require(_index < multiStrategyLength, "M2");
        multiStrategy[_index] = _multiStrategy;

        emit SetStrategy(_index, _multiStrategy);
    }

    /**
     * @notice Transfer amount of token from Storage to Logic Contract.
     * @param _amount Amount of token
     * @param _token Address of token
     */
    function takeToken(uint256 _amount, address _token) external {
        require(isExistLogic(msg.sender), "M4");
        uint256 tokenAvailable = _getTokenAvailable(_token, msg.sender);
        require(_amount <= tokenAvailable, "M6");

        IStorage(storageContract).takeToken(_amount, _token);

        if (_token == address(0)) {
            require(address(this).balance >= _amount, "M7");
            _send(payable(msg.sender), _amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
        }

        tokenAvailableLogic[_token][msg.sender] -= _amount;
        tokenBalanceLogic[_token][msg.sender] += _amount;

        emit UpdateTokenAvailableLogic(
            tokenAvailableLogic[_token][msg.sender],
            _token,
            msg.sender
        );
        emit UpdateTokenBalanceLogic(
            tokenBalanceLogic[_token][msg.sender],
            _token,
            msg.sender
        );
        emit TakeToken(_token, msg.sender, _amount);
    }

    /**
     * @notice Transfer amount of token from Logic to Storage Contract.
     * @param _amount Amount of token
     * @param _token Address of token
     */
    function releaseToken(uint256 _amount, address _token)
        external
        onlyStorage
    {
        uint256 _count = multiStrategyLength;
        uint256 _amount_show = _amount;
        if (_token != address(0) && !approvedTokens[_token]) {
            //if token not approved for storage
            IERC20Upgradeable(_token).approve(
                storageContract,
                type(uint256).max
            );
            approvedTokens[_token] = true;
        }

        for (uint256 i = 0; i < _count; i++) {
            singleStrategy memory sStrategy = multiStrategy[i];

            uint256 releaseAmount = _amount;
            if (
                tokenBalanceLogic[_token][sStrategy.logicContract] <
                releaseAmount
            ) {
                releaseAmount = tokenBalanceLogic[_token][
                    sStrategy.logicContract
                ];
            }

            if (releaseAmount > 0) {
                IStrategyContract(sStrategy.strategyContract).releaseToken(
                    releaseAmount,
                    _token
                );
                tokenBalanceLogic[_token][
                    sStrategy.logicContract
                ] -= releaseAmount;

                if (_token != address(0)) {
                    IERC20Upgradeable(_token).safeTransferFrom(
                        sStrategy.logicContract,
                        address(this),
                        releaseAmount
                    );
                }
            }
            tokenAvailableLogic[_token][
                sStrategy.logicContract
            ] += releaseAmount;

            _amount -= releaseAmount;
            if (_amount <= 0) break;
        }

        if (_token == address(0)) {
            require(address(this).balance >= _amount_show, "M7");
            _send(payable(storageContract), _amount_show);
        }

        emit ReleaseToken(_token, _amount_show);
    }

    /**
     * @notice Transfer amount of token from Logic to Storage Contract.
     * @param _amount Amount of token
     * @param _token Address of token
     */
    function returnToken(uint256 _amount, address _token) external {
        require(isExistLogic(msg.sender), "M4");
        require(_amount <= tokenBalanceLogic[_token][msg.sender], "M6");

        if (_token == address(0)) {
            require(address(this).balance >= _amount, "M7");
            _send(payable(storageContract), _amount);
        } else {
            if (!approvedTokens[_token]) {
                //if token not approved for storage
                IERC20Upgradeable(_token).approve(
                    storageContract,
                    type(uint256).max
                );
                approvedTokens[_token] = true;
            }

            IERC20Upgradeable(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        IStorage(storageContract).returnToken(_amount, _token);

        tokenAvailableLogic[_token][msg.sender] += _amount;
        tokenBalanceLogic[_token][msg.sender] -= _amount;

        emit UpdateTokenAvailableLogic(
            tokenAvailableLogic[_token][msg.sender],
            _token,
            msg.sender
        );
        emit UpdateTokenBalanceLogic(
            tokenBalanceLogic[_token][msg.sender],
            _token,
            msg.sender
        );
        emit ReturnToken(_token, _amount);
    }

    /**
     * @notice Set Token balance for each logic
     * @param _amount deposit amount
     * @param _token deposit token
     * @param _deposit_withdraw flag for deposit or withdraw
     */
    function setLogicTokenAvailable(
        uint256 _amount,
        address _token,
        uint256 _deposit_withdraw
    ) external {
        require(msg.sender == owner() || msg.sender == storageContract, "M1");

        uint256 _count = multiStrategyLength;
        uint256 _amount_s = _amount;
        for (uint256 i = 0; i < _count; i++) {
            address logicAddress = multiStrategy[i].logicContract;
            if (_deposit_withdraw == 1) {
                //deposit
                uint256 cleftAmount = ((_amount_s *
                    dividePercentage[_token][logicAddress]) / 10000);
                tokenAvailableLogic[_token][logicAddress] += cleftAmount;
            } else {
                //withdraw
                if (tokenAvailableLogic[_token][logicAddress] >= _amount_s) {
                    tokenAvailableLogic[_token][logicAddress] -= _amount_s;
                    _amount_s = 0;
                } else {
                    _amount_s -= tokenAvailableLogic[_token][logicAddress];
                    tokenAvailableLogic[_token][logicAddress] = 0;
                }
                if (_amount_s <= 0) break;
            }
        }

        emit SetLogicTokenAvailable(_amount, _token, _deposit_withdraw);
    }

    /**
     * @notice Take amount BLID from Logic contract  and distributes earned BLID
     * @param _amount Amount of distributes earned BLID
     * @param _blidToken blidToken address
     */
    function addEarn(uint256 _amount, address _blidToken) external {
        require(isExistLogic(msg.sender), "M4");

        IERC20Upgradeable(_blidToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (!approvedTokens[_blidToken]) {
            //if token not approved for storage
            IERC20Upgradeable(_blidToken).approve(
                storageContract,
                type(uint256).max
            );
            approvedTokens[_blidToken] = true;
        }

        IStorage(storageContract).addEarn(_amount);
    }

    /**
     * @notice set Storage address
     * @param _storage storage address
     */
    function setStorage(address _storage) external {
        require(storageContract == address(0), "M5");
        storageContract = _storage;
    }

    /**
     * @notice Return deposited usd
     */
    function getTotalDeposit() external view returns (uint256) {
        return IStorage(storageContract).getTotalDeposit();
    }

    /**
     * @notice Returns the balance amount of token for the logic
     * @param _token deposit token
     * @param _logicAddress logic Address
     */
    function getTokenBalance(address _token, address _logicAddress)
        external
        view
        returns (uint256)
    {
        return _getTokenBalance(_token, _logicAddress);
    }

    /**
     * @notice Returns the available amount of token for the logic
     * @param _token deposit token
     * @param _logicAddress logic Address
     */
    function getTokenAvailable(address _token, address _logicAddress)
        external
        view
        returns (uint256)
    {
        return _getTokenAvailable(_token, _logicAddress);
    }

    /**
     * @notice Return deposited token from account
     * @param _account deposit account
     * @param _token deposit token
     * @param _logicAddress logic Address
     */
    function getTokenDeposit(
        address _account,
        address _token,
        address _logicAddress
    ) external view returns (uint256) {
        return
            (IStorage(storageContract).getTokenDeposit(_account, _token) *
                dividePercentage[_token][_logicAddress]) / 10000;
    }

    /**
     * @notice Return percentage value
     * @param _token deposit token
     */
    function getPercentage(address _token)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _count = multiStrategyLength;
        uint256[] memory ret = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            ret[i] = dividePercentage[_token][multiStrategy[i].logicContract];
        }
        return ret;
    }

    /**
     * @notice Set the Logic address into MultiLogicProxy
     * @param index strategy index
     */
    function strategyInfo(uint256 index)
        external
        view
        returns (address, address)
    {
        require(index <= multiStrategyLength);
        return (
            multiStrategy[index].logicContract,
            multiStrategy[index].strategyContract
        );
    }

    /**
     * @notice Check if the logic address exist
     * @param _logicAddress logic address for checking
     */
    function isExistLogic(address _logicAddress) public view returns (bool) {
        uint256 _count = multiStrategyLength;
        for (uint256 i; i < _count; ) {
            if (multiStrategy[i].logicContract == _logicAddress) return true;
            unchecked {
                ++i;
            }
        }
        return false;
    }

    /**
     * @notice Send ETH to address
     * @param _to target address to receive ETH
     * @param amount ETH amount (wei) to be sent
     */
    function _send(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "M8");
    }
}