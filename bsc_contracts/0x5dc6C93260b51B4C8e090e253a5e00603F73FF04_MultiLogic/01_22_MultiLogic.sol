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
    string[] public multiStrategyName;
    mapping(string => singleStrategy) private multiStrategyData;
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
    event AddStrategy(string name, singleStrategy strategies);
    event InitStrategy(string[] strategiesName, singleStrategy[] strategies);
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
     * @notice Set the dividing percentage
     * @param _token token address
     * @param _percentages percentage array
     */
    function setPercentages(address _token, uint256[] calldata _percentages)
        external
        onlyOwner
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
            singleStrategy memory _multiStrategy = multiStrategyData[
                multiStrategyName[index]
            ];
            sumAvailable += tokenAvailableLogic[_token][
                _multiStrategy.logicContract
            ];
            dividePercentage[_token][
                _multiStrategy.logicContract
            ] = _percentages[index];
            unchecked {
                ++index;
            }
        }
        if (sumAvailable > 0) {
            for (index = 0; index < _count; ) {
                tokenAvailableLogic[_token][
                    multiStrategyData[multiStrategyName[index]].logicContract
                ] = (sumAvailable * _percentages[index]) / 10000;
                unchecked {
                    ++index;
                }
            }
        }
    }

    /**
     * @notice Init the Logic address into MultiLogicProxy
     * @param _strategyName strategy name array
     * @param _multiStrategy strategy array
     */
    function initStrategies(
        string[] calldata _strategyName,
        singleStrategy[] calldata _multiStrategy
    ) external onlyOwner {
        delete multiStrategyName;
        uint256 count = _multiStrategy.length;
        uint256 nameCount = _strategyName.length;
        require(count == nameCount);

        for (uint256 i = 0; i < count; ) {
            multiStrategyName.push(_strategyName[i]);
            multiStrategyData[_strategyName[i]] = _multiStrategy[i];
            unchecked {
                ++i;
            }
        }
        multiStrategyLength = count;

        emit InitStrategy(_strategyName, _multiStrategy);
    }

    /**
     * @notice Set the Logic address into MultiLogicProxy
     * @param _strategyName strategy name
     * @param _multiStrategy strategy
     * @param _overwrite overwrite flag
     */
    function addStrategy(
        string memory _strategyName,
        singleStrategy memory _multiStrategy,
        bool _overwrite
    ) external onlyOwner {
        bool exist = false;
        for (uint256 i = 0; i < multiStrategyLength; ) {
            if (
                keccak256(abi.encodePacked((multiStrategyName[i]))) ==
                keccak256(abi.encodePacked((_strategyName)))
            ) {
                require(_overwrite, "M9");
                exist = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!exist) {
            multiStrategyName.push(_strategyName);
            multiStrategyLength++;
        }
        multiStrategyData[_strategyName] = _multiStrategy;
        emit AddStrategy(_strategyName, _multiStrategy);
    }

    /**
     * @notice Transfer amount of token from Storage to Logic Contract.
     * @param _amount Amount of token
     * @param _token Address of token
     */
    function takeToken(uint256 _amount, address _token) external {
        require(isExistLogic(msg.sender), "M4");
        uint256 tokenAvailable = getTokenAvailable(_token, msg.sender);
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
            singleStrategy memory sStrategy = multiStrategyData[
                multiStrategyName[i]
            ];

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
            // We don't update tokenAvaliable, because it is updated in Storage

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
     * @param _deposit_withdraw flag for deposit or withdraw 1 : increase, 0: decrease, 2: set
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
            address logicAddress = multiStrategyData[multiStrategyName[i]]
                .logicContract;
            if (_deposit_withdraw == 1) {
                //deposit
                uint256 cleftAmount = ((_amount_s *
                    dividePercentage[_token][logicAddress]) / 10000);
                tokenAvailableLogic[_token][logicAddress] += cleftAmount;
            } else if (_deposit_withdraw == 0) {
                //withdraw
                if (tokenAvailableLogic[_token][logicAddress] >= _amount_s) {
                    tokenAvailableLogic[_token][logicAddress] -= _amount_s;
                    _amount_s = 0;
                } else {
                    _amount_s -= tokenAvailableLogic[_token][logicAddress];
                    tokenAvailableLogic[_token][logicAddress] = 0;
                }
                if (_amount_s <= 0) break;
            } else {
                uint256 cleftAmount = ((_amount_s *
                    dividePercentage[_token][logicAddress]) / 10000);
                tokenAvailableLogic[_token][logicAddress] = cleftAmount;
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
     * @notice Returns the available amount of token for the logic
     * @param _token deposit token
     * @param _logicAddress logic Address
     */
    function getTokenAvailable(address _token, address _logicAddress)
        public
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
    function getTokenBalance(address _token, address _logicAddress)
        public
        view
        returns (uint256)
    {
        return tokenBalanceLogic[_token][_logicAddress];
    }

    /**
     * @notice Return deposited token from account
     * @param _token deposit token
     * @param _logicAddress logic Address
     */
    function getTokenDeposited(address _token, address _logicAddress)
        external
        view
        returns (uint256)
    {
        return
            tokenAvailableLogic[_token][_logicAddress] +
            tokenBalanceLogic[_token][_logicAddress];
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
            ret[i] = dividePercentage[_token][
                multiStrategyData[multiStrategyName[i]].logicContract
            ];
        }
        return ret;
    }

    /**
     * @notice Set the Logic address into MultiLogicProxy
     * @param _name strategy name
     */
    function strategyInfo(string memory _name)
        external
        view
        returns (address, address)
    {
        bool exist = false;
        for (uint256 i = 0; i < multiStrategyLength; ) {
            if (
                keccak256(abi.encodePacked((multiStrategyName[i]))) ==
                keccak256(abi.encodePacked((_name)))
            ) {
                exist = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        require(exist == true, "M10");
        return (
            multiStrategyData[_name].logicContract,
            multiStrategyData[_name].strategyContract
        );
    }

    /**
     * @notice Check if the logic address exist
     * @param _logicAddress logic address for checking
     */
    function isExistLogic(address _logicAddress) public view returns (bool) {
        uint256 _count = multiStrategyLength;
        for (uint256 i; i < _count; ) {
            if (
                multiStrategyData[multiStrategyName[i]].logicContract ==
                _logicAddress
            ) return true;
            unchecked {
                ++i;
            }
        }
        return false;
    }

    /**
     * @notice Get used tokens in storage
     */
    function getUsedTokensStorage() external view returns (address[] memory) {
        return IStorage(storageContract).getUsedTokens();
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